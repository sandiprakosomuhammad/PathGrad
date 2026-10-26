import os
import sqlite3
import json
from datetime import datetime
from typing import Dict, Any, List, Optional
import pandas as pd

DB_PATH = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "pathgrad.db"))
CSV_SAMPLE_PATH = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "sampel_uji_konsistensi.csv"))


def get_connection() -> sqlite3.Connection:
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def init_db(ml_evaluator=None):
    """
    Inisialisasi tabel SQLite riwayat_skrining.
    Jika masih kosong, lakukan seeding 15 data seimbang dari sampel_uji_konsistensi.csv.
    """
    with get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS riwayat_skrining (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                kode_mhs TEXT NOT NULL,
                nim TEXT NOT NULL,
                ips_sem1 REAL NOT NULL,
                matkul_diambil_sem1 INTEGER NOT NULL,
                matkul_lulus_sem1 INTEGER NOT NULL,
                ips_sem2 REAL NOT NULL,
                matkul_diambil_sem2 INTEGER NOT NULL,
                matkul_lulus_sem2 INTEGER NOT NULL,
                ukt_lancar INTEGER NOT NULL,
                persentase_bulat INTEGER NOT NULL,
                kategori_risiko TEXT NOT NULL,
                penyebab_utama TEXT NOT NULL,
                faktor_pemicu TEXT NOT NULL,
                created_at TEXT NOT NULL
            );
        """)
        conn.commit()

        # Cek apakah tabel sudah berisi data
        cursor.execute("SELECT COUNT(*) FROM riwayat_skrining")
        count = cursor.fetchone()[0]

        if count == 0 and os.path.exists(CSV_SAMPLE_PATH) and ml_evaluator is not None:
            seed_initial_data(conn, ml_evaluator)


def seed_initial_data(conn: sqlite3.Connection, ml_evaluator):
    """
    Seeding 15 data awal dari sampel_uji_konsistensi.csv:
    - 5 Indikasi Risiko Rendah (<40%)
    - 5 Indikasi Risiko Sedang (40% - 69%)
    - 5 Indikasi Risiko Tinggi (>=70%)
    Dengan kode_mhs: MHS-001 s/d MHS-015 dan nim: 2401001 s/d 2401015.
    """
    df = pd.read_csv(CSV_SAMPLE_PATH)

    df_rendah = df[df["skor_notebook"] < 0.40].head(5)
    df_sedang = df[(df["skor_notebook"] >= 0.40) & (df["skor_notebook"] < 0.70)].head(5)
    df_tinggi = df[df["skor_notebook"] >= 0.70].head(5)

    df_seed = pd.concat([df_rendah, df_sedang, df_tinggi], ignore_index=True)

    cursor = conn.cursor()
    now_iso = datetime.now().isoformat()

    for idx, row in df_seed.iterrows():
        seq_num = idx + 1
        kode_mhs = f"MHS-{seq_num:03d}"
        nim = f"2401{seq_num:03d}"

        # Evaluasi data menggunakan model LightGBM
        eval_res = ml_evaluator(
            ips_sem1=float(row["ips_sem1"]),
            matkul_diambil_sem1=int(row["matkul_diambil_sem1"]),
            matkul_lulus_sem1=int(row["matkul_lulus_sem1"]),
            ips_sem2=float(row["ips_sem2"]),
            matkul_diambil_sem2=int(row["matkul_diambil_sem2"]),
            matkul_lulus_sem2=int(row["matkul_lulus_sem2"]),
            ukt_lancar=int(row["ukt_lancar"]),
            kode_mhs=kode_mhs,
            nim=nim,
        )

        cursor.execute("""
            INSERT INTO riwayat_skrining (
                kode_mhs, nim, ips_sem1, matkul_diambil_sem1, matkul_lulus_sem1,
                ips_sem2, matkul_diambil_sem2, matkul_lulus_sem2, ukt_lancar,
                persentase_bulat, kategori_risiko, penyebab_utama, faktor_pemicu, created_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            kode_mhs,
            nim,
            float(row["ips_sem1"]),
            int(row["matkul_diambil_sem1"]),
            int(row["matkul_lulus_sem1"]),
            float(row["ips_sem2"]),
            int(row["matkul_diambil_sem2"]),
            int(row["matkul_lulus_sem2"]),
            int(row["ukt_lancar"]),
            eval_res["persentase_bulat"],
            eval_res["kategori_risiko"],
            eval_res["penyebab_utama"],
            json.dumps(eval_res["faktor_pemicu"]),
            now_iso
        ))

    conn.commit()
    print(f"[PathGrad DB] Berhasil melakukan seeding {len(df_seed)} data awal ke SQLite ({DB_PATH}).")


def get_next_student_identity() -> tuple[str, str]:
    """
    Menghasilkan kode_mhs dan default nim berurutan berikutnya.
    Contoh: Jika sudah ada 15 baris, return ("MHS-016", "2401016").
    """
    with get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT MAX(id), COUNT(*) FROM riwayat_skrining")
        row = cursor.fetchone()
        max_id = row[0] or 0
        total_count = row[1] or 0
        next_num = max(max_id, total_count) + 1
        return f"MHS-{next_num:03d}", f"2401{next_num:03d}"


def upsert_record(data: Dict[str, Any]) -> tuple[int, str, str, bool]:
    """
    Jika mahasiswa dengan kode_mhs atau nim sudah ada di SQLite, lakukan UPDATE.
    Jika belum ada, lakukan INSERT.
    Return (id, final_kode_mhs, final_nim, is_updated).
    """
    with get_connection() as conn:
        cursor = conn.cursor()
        now_iso = datetime.now().isoformat()

        target_kode = data.get("kode_mhs")
        target_nim = data.get("nim")

        existing_row = None
        if target_kode and target_kode != "MHS-ANON":
            cursor.execute("SELECT id, kode_mhs, nim FROM riwayat_skrining WHERE kode_mhs = ?", (target_kode,))
            existing_row = cursor.fetchone()

        if existing_row is None and target_nim and target_nim.strip() and target_nim.strip() != "-":
            cursor.execute("SELECT id, kode_mhs, nim FROM riwayat_skrining WHERE nim = ?", (target_nim.strip(),))
            existing_row = cursor.fetchone()

        faktor_pemicu_json = (
            json.dumps(data["faktor_pemicu"])
            if isinstance(data["faktor_pemicu"], list)
            else str(data["faktor_pemicu"])
        )

        if existing_row is not None:
            # UPDATE record yang sudah ada
            rec_id = existing_row["id"]
            final_kode = existing_row["kode_mhs"]
            final_nim = target_nim.strip() if target_nim and target_nim.strip() and target_nim.strip() != "-" else existing_row["nim"]

            cursor.execute("""
                UPDATE riwayat_skrining SET
                    nim = ?,
                    ips_sem1 = ?,
                    matkul_diambil_sem1 = ?,
                    matkul_lulus_sem1 = ?,
                    ips_sem2 = ?,
                    matkul_diambil_sem2 = ?,
                    matkul_lulus_sem2 = ?,
                    ukt_lancar = ?,
                    persentase_bulat = ?,
                    kategori_risiko = ?,
                    penyebab_utama = ?,
                    faktor_pemicu = ?,
                    created_at = ?
                WHERE id = ?
            """, (
                final_nim,
                float(data["ips_sem1"]),
                int(data["matkul_diambil_sem1"]),
                int(data["matkul_lulus_sem1"]),
                float(data["ips_sem2"]),
                int(data["matkul_diambil_sem2"]),
                int(data["matkul_lulus_sem2"]),
                int(data["ukt_lancar"]),
                int(data["persentase_bulat"]),
                data["kategori_risiko"],
                data["penyebab_utama"],
                faktor_pemicu_json,
                now_iso,
                rec_id
            ))
            conn.commit()
            return rec_id, final_kode, final_nim, True
        else:
            # INSERT record baru
            next_kode, default_nim = get_next_student_identity()
            final_kode = target_kode if (target_kode and target_kode != "MHS-ANON") else next_kode
            final_nim = target_nim.strip() if (target_nim and target_nim.strip() and target_nim.strip() != "-") else default_nim

            cursor.execute("""
                INSERT INTO riwayat_skrining (
                    kode_mhs, nim, ips_sem1, matkul_diambil_sem1, matkul_lulus_sem1,
                    ips_sem2, matkul_diambil_sem2, matkul_lulus_sem2, ukt_lancar,
                    persentase_bulat, kategori_risiko, penyebab_utama, faktor_pemicu, created_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                final_kode,
                final_nim,
                float(data["ips_sem1"]),
                int(data["matkul_diambil_sem1"]),
                int(data["matkul_lulus_sem1"]),
                float(data["ips_sem2"]),
                int(data["matkul_diambil_sem2"]),
                int(data["matkul_lulus_sem2"]),
                int(data["ukt_lancar"]),
                int(data["persentase_bulat"]),
                data["kategori_risiko"],
                data["penyebab_utama"],
                faktor_pemicu_json,
                now_iso
            ))
            conn.commit()
            return cursor.lastrowid, final_kode, final_nim, False


def insert_record(data: Dict[str, Any]) -> int:
    rec_id, _, _, _ = upsert_record(data)
    return rec_id


def get_all_history() -> Dict[str, Any]:
    """
    Mengambil semua data riwayat dari SQLite beserta ringkasan statistik dan 6 fitur rekayasa.
    """
    with get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM riwayat_skrining ORDER BY id ASC")
        rows = cursor.fetchall()

        records = []
        total_rendah = 0
        total_sedang = 0
        total_tinggi = 0

        for r in rows:
            kat = r["kategori_risiko"]
            if "Rendah" in kat:
                total_rendah += 1
            elif "Sedang" in kat:
                total_sedang += 1
            elif "Tinggi" in kat:
                total_tinggi += 1

            ips1 = float(r["ips_sem1"])
            ips2 = float(r["ips_sem2"])
            ambil1 = int(r["matkul_diambil_sem1"])
            lulus1 = int(r["matkul_lulus_sem1"])
            ambil2 = int(r["matkul_diambil_sem2"])
            lulus2 = int(r["matkul_lulus_sem2"])

            rata_rata_ips = round((ips1 + ips2) / 2.0, 2)
            tren_ips = round(ips2 - ips1, 2)
            if tren_ips > 0:
                tren_ips_label = f"+{tren_ips:.2f} (Naik)"
            elif tren_ips < 0:
                tren_ips_label = f"{tren_ips:.2f} (Turun)"
            else:
                tren_ips_label = "0.00 (Stabil)"

            rasio_lulus_sem1_persen = int(round((lulus1 / ambil1) * 100)) if ambil1 > 0 else 0
            matkul_gagal_sem1 = max(0, ambil1 - lulus1)
            rasio_lulus_sem2_persen = int(round((lulus2 / ambil2) * 100)) if ambil2 > 0 else 0
            matkul_gagal_sem2 = max(0, ambil2 - lulus2)

            records.append({
                "id": r["id"],
                "kode_mhs": r["kode_mhs"],
                "nim": r["nim"],
                "ips_sem1": ips1,
                "matkul_diambil_sem1": ambil1,
                "matkul_lulus_sem1": lulus1,
                "ips_sem2": ips2,
                "matkul_diambil_sem2": ambil2,
                "matkul_lulus_sem2": lulus2,
                "ukt_lancar": int(r["ukt_lancar"]),
                "persentase_bulat": int(r["persentase_bulat"]),
                "kategori_risiko": r["kategori_risiko"],
                "penyebab_utama": r["penyebab_utama"],
                "faktor_pemicu": json.loads(r["faktor_pemicu"]) if isinstance(r["faktor_pemicu"], str) else r["faktor_pemicu"],
                "created_at": r["created_at"],
                "rata_rata_ips": rata_rata_ips,
                "tren_ips": tren_ips,
                "tren_ips_label": tren_ips_label,
                "rasio_lulus_sem1_persen": rasio_lulus_sem1_persen,
                "matkul_gagal_sem1": matkul_gagal_sem1,
                "rasio_lulus_sem2_persen": rasio_lulus_sem2_persen,
                "matkul_gagal_sem2": matkul_gagal_sem2,
            })

        return {
            "total_mahasiswa": len(records),
            "total_rendah": total_rendah,
            "total_sedang": total_sedang,
            "total_tinggi": total_tinggi,
            "records": records
        }
