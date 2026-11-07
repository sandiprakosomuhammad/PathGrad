"""
Uji fungsional endpoint /api/predict: masukan valid, nilai batas, dan tidak valid.
Cara pakai (dari folder backend/):  python test_fungsional.py
Hasil ditulis ke hasil_fungsional.csv (bisa dijadikan tabel di Bab 3).
"""
import os
import sys

import pandas as pd

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# Opsional: uji API yang sedang berjalan (mis. di Docker) lewat HTTP.
#   PowerShell:  $env:PATHGRAD_URL="http://localhost:8000"; python test_fungsional.py
BASE_URL = os.environ.get("PATHGRAD_URL")


def buat_client():
    if BASE_URL:
        import httpx
        print(f"[Mode HTTP] menguji {BASE_URL}")
        return httpx.Client(base_url=BASE_URL, timeout=30)
    from fastapi.testclient import TestClient
    from app.main import app
    print("[Mode TestClient] menguji aplikasi langsung (tanpa Docker)")
    return TestClient(app)

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
    client = buat_client()
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

    # endpoint pendukung (hanya membaca, tidak menulis ke database)
    for path in ("/", "/api/health", "/api/history"):
        r = client.get(path)
        ok = r.status_code == 200
        ket = ""
        if path == "/api/history" and ok:
            b = r.json()
            kunci = ("total_mahasiswa", "total_rendah", "total_sedang",
                     "total_tinggi", "records")
            ok = all(k in b for k in kunci) and (
                b["total_mahasiswa"] == len(b["records"])
                == b["total_rendah"] + b["total_sedang"] + b["total_tinggi"])
            ket = f"{b.get('total_mahasiswa', '?')} mahasiswa"
        baris.append({"kasus": f"GET {path}", "jenis": "Endpoint", "harapan": 200,
                      "hasil": r.status_code, "keluaran": ket,
                      "lolos": "Ya" if ok else "TIDAK"})

    df = pd.DataFrame(baris)
    df.to_csv("hasil_fungsional.csv", index=False)
    print(df.to_string(index=False))
    lolos = (df["lolos"] == "Ya").sum()
    print(f"\nLolos: {lolos}/{len(df)}")
    if lolos != len(df):
        sys.exit(1)


if __name__ == "__main__":
    main()
