"""
Uji fungsional endpoint /api/predict: masukan valid, nilai batas, dan tidak valid.
Cara pakai (dari folder backend/):  python test_fungsional.py
Hasil ditulis ke hasil_fungsional.csv (bisa dijadikan tabel di Bab 3).
"""
import os
import sys

import pandas as pd
from fastapi.testclient import TestClient

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from app.main import app  # noqa: E402

BASE = {
    "kode_anonim": "UJI-FUNGSIONAL",
    "ips_sem1": 2.5, "matkul_diambil_sem1": 6, "matkul_lulus_sem1": 4,
    "ips_sem2": 2.0, "matkul_diambil_sem2": 6, "matkul_lulus_sem2": 3,
    "ukt_lancar": 1,
}


def ubah(**kw):
    d = dict(BASE)
    d.update(kw)
    return d


def tanpa(kolom):
    d = dict(BASE)
    d.pop(kolom)
    return d


# (nama kasus, jenis, payload, status HTTP yang diharapkan)
KASUS = [
    ("Masukan valid umum", "Valid", BASE, 200),
    ("IPS = 0,0 (batas bawah)", "Batas", ubah(ips_sem1=0.0, ips_sem2=0.0), 200),
    ("IPS = 4,0 (batas atas)", "Batas", ubah(ips_sem1=4.0, ips_sem2=4.0), 200),
    ("Matkul diambil = 1 (batas bawah)", "Batas",
     ubah(matkul_diambil_sem1=1, matkul_lulus_sem1=1,
          matkul_diambil_sem2=1, matkul_lulus_sem2=1), 200),
    ("Matkul lulus = 0", "Batas", ubah(matkul_lulus_sem1=0, matkul_lulus_sem2=0), 200),
    ("Matkul lulus = diambil", "Batas",
     ubah(matkul_lulus_sem1=6, matkul_lulus_sem2=6), 200),
    ("UKT menunggak (0)", "Valid", ubah(ukt_lancar=0), 200),
    ("IPS sem 1 = 4,5 (di atas batas)", "Tidak valid", ubah(ips_sem1=4.5), 422),
    ("IPS sem 2 = -0,1 (negatif)", "Tidak valid", ubah(ips_sem2=-0.1), 422),
    ("Matkul diambil sem 1 = 0", "Tidak valid",
     ubah(matkul_diambil_sem1=0, matkul_lulus_sem1=0), 422),
    ("Matkul diambil sem 2 = 0", "Tidak valid",
     ubah(matkul_diambil_sem2=0, matkul_lulus_sem2=0), 422),
    ("Matkul lulus > diambil (sem 1)", "Tidak valid", ubah(matkul_lulus_sem1=8), 422),
    ("Matkul lulus > diambil (sem 2)", "Tidak valid", ubah(matkul_lulus_sem2=8), 422),
    ("Matkul lulus negatif", "Tidak valid", ubah(matkul_lulus_sem1=-1), 422),
    ("UKT = 2 (di luar 0/1)", "Tidak valid", ubah(ukt_lancar=2), 422),
    ("IPS bukan angka", "Tidak valid", ubah(ips_sem1="abc"), 422),
    ("Field ips_sem1 hilang", "Tidak valid", tanpa("ips_sem1"), 422),
    ("Field ukt_lancar hilang", "Tidak valid", tanpa("ukt_lancar"), 422),
]


def main():
    client = TestClient(app)
    baris = []
    for nama, jenis, payload, harapan in KASUS:
        r = client.post("/api/predict", json=payload)
        ok = r.status_code == harapan
        ringkas = ""
        if r.status_code == 200:
            b = r.json()
            ringkas = f"{b['risk_level']} ({b['risk_percentage']}%)"
        baris.append({"kasus": nama, "jenis": jenis, "harapan": harapan,
                      "hasil": r.status_code, "keluaran": ringkas,
                      "lolos": "Ya" if ok else "TIDAK"})

    # endpoint pendukung
    for path in ("/", "/api/health"):
        r = client.get(path)
        baris.append({"kasus": f"GET {path}", "jenis": "Endpoint", "harapan": 200,
                      "hasil": r.status_code, "keluaran": "",
                      "lolos": "Ya" if r.status_code == 200 else "TIDAK"})

    df = pd.DataFrame(baris)
    df.to_csv("hasil_fungsional.csv", index=False)
    print(df.to_string(index=False))
    lolos = (df["lolos"] == "Ya").sum()
    print(f"\nLolos: {lolos}/{len(df)}")
    if lolos != len(df):
        sys.exit(1)


if __name__ == "__main__":
    main()
