"""
Uji konsistensi: skor dari API harus sama dengan skor model di notebook
untuk masukan yang sama.

Cara pakai (dari folder backend/):
    1. Buat sampel_uji_konsistensi.csv dari notebook (lihat snippet Colab).
    2. Taruh CSV itu di folder backend/.
    3. python test_konsistensi.py

Hasil ditulis ke hasil_konsistensi.csv.
"""
import os
import sys

import pandas as pd
from fastapi.testclient import TestClient

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from app.main import app  # noqa: E402

CSV_SAMPEL = "sampel_uji_konsistensi.csv"
INPUT_COLS = [
    "ips_sem1", "matkul_diambil_sem1", "matkul_lulus_sem1",
    "ips_sem2", "matkul_diambil_sem2", "matkul_lulus_sem2", "ukt_lancar",
]
BATAS_SEDANG, BATAS_TINGGI = 0.40, 0.70  # sama dengan notebook
TOLERANSI_PERSEN = 0.051  # API membulatkan ke 1 desimal


def kategori_notebook(p: float) -> str:
    if p >= BATAS_TINGGI:
        return "Tinggi"
    if p >= BATAS_SEDANG:
        return "Sedang"
    return "Rendah"


def main():
    df = pd.read_csv(CSV_SAMPEL)
    kolom_wajib = INPUT_COLS + ["skor_notebook"]
    hilang = [c for c in kolom_wajib if c not in df.columns]
    if hilang:
        sys.exit(f"Kolom hilang di {CSV_SAMPEL}: {hilang}")

    client = TestClient(app)
    hasil = []
    for i, row in df.iterrows():
        payload = {
            "kode_anonim": f"UJI-{i:03d}",
            "ips_sem1": float(row["ips_sem1"]),
            "matkul_diambil_sem1": int(row["matkul_diambil_sem1"]),
            "matkul_lulus_sem1": int(row["matkul_lulus_sem1"]),
            "ips_sem2": float(row["ips_sem2"]),
            "matkul_diambil_sem2": int(row["matkul_diambil_sem2"]),
            "matkul_lulus_sem2": int(row["matkul_lulus_sem2"]),
            "ukt_lancar": int(row["ukt_lancar"]),
        }
        r = client.post("/api/predict", json=payload)
        if r.status_code != 200:
            hasil.append({"baris": i, "status": r.status_code, "ok": False,
                          "catatan": r.text[:120]})
            continue
        body = r.json()
        p_nb = float(row["skor_notebook"])
        persen_api = float(body["risk_percentage"])
        selisih = abs(persen_api - p_nb * 100)
        kat_api = body["risk_level"].split()[-1]  # Tinggi / Sedang / Rendah
        kat_nb = kategori_notebook(p_nb)
        hasil.append({
            "baris": i, "status": 200,
            "skor_notebook": p_nb, "persen_api": persen_api,
            "selisih_persen": round(selisih, 4),
            "kategori_notebook": kat_nb, "kategori_api": kat_api,
            "ok": selisih <= TOLERANSI_PERSEN and kat_api == kat_nb,
            "catatan": "",
        })

    out = pd.DataFrame(hasil)
    out.to_csv("hasil_konsistensi.csv", index=False)

    n = len(out)
    n_ok = int(out["ok"].sum())
    print("=" * 60)
    print("UJI KONSISTENSI API vs NOTEBOOK")
    print("=" * 60)
    print(f"Jumlah sampel            : {n}")
    print(f"Status HTTP 200          : {(out['status'] == 200).sum()}")
    if "selisih_persen" in out:
        print(f"Selisih maks (poin %)    : {out['selisih_persen'].max()}")
        mism = (out["kategori_api"] != out["kategori_notebook"]).sum()
        print(f"Kategori berbeda         : {mism}")
    print(f"Lolos                    : {n_ok}/{n}")
    print("HASIL:", "LULUS" if n_ok == n else "GAGAL (lihat hasil_konsistensi.csv)")
    if n_ok != n:
        sys.exit(1)


if __name__ == "__main__":
    main()
