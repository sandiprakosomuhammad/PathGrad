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


def insert_record(data: Dict[str, Any]) -> int:
    """
    Menyimpan data hasil skrining baru ke SQLite.
    """
    with get_connection() as conn:
        cursor = conn.cursor()
        now_iso = datetime.now().isoformat()
        cursor.execute("""
            INSERT INTO riwayat_skrining (
                kode_mhs, nim, ips_sem1, matkul_diambil_sem1, matkul_lulus_sem1,
                ips_sem2, matkul_diambil_sem2, matkul_lulus_sem2, ukt_lancar,
                persentase_bulat, kategori_risiko, penyebab_utama, faktor_pemicu, created_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            data["kode_mhs"],
            data["nim"],
            data["ips_sem1"],
            data["matkul_diambil_sem1"],
            data["matkul_lulus_sem1"],
            data["ips_sem2"],
            data["matkul_diambil_sem2"],
            data["matkul_lulus_sem2"],
            data["ukt_lancar"],
            data["persentase_bulat"],
            data["kategori_risiko"],
            data["penyebab_utama"],
            json.dumps(data["faktor_pemicu"]),
            now_iso
        ))
        conn.commit()
        return cursor.lastrowid


def get_all_history() -> Dict[str, Any]:
    """
    Mengambil semua data riwayat dari SQLite beserta ringkasan statistik.
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

            records.append({
                "id": r["id"],
                "kode_mhs": r["kode_mhs"],
                "nim": r["nim"],
                "ips_sem1": r["ips_sem1"],
                "matkul_diambil_sem1": r["matkul_diambil_sem1"],
                "matkul_lulus_sem1": r["matkul_lulus_sem1"],
                "ips_sem2": r["ips_sem2"],
                "matkul_diambil_sem2": r["matkul_diambil_sem2"],
                "matkul_lulus_sem2": r["matkul_lulus_sem2"],
                "ukt_lancar": r["ukt_lancar"],
                "persentase_bulat": r["persentase_bulat"],
                "kategori_risiko": r["kategori_risiko"],
                "penyebab_utama": r["penyebab_utama"],
                "faktor_pemicu": json.loads(r["faktor_pemicu"]) if isinstance(r["faktor_pemicu"], str) else r["faktor_pemicu"],
                "created_at": r["created_at"]
            })

        return {
            "total_mahasiswa": len(records),
            "total_rendah": total_rendah,
            "total_sedang": total_sedang,
            "total_tinggi": total_tinggi,
            "records": records
        }
