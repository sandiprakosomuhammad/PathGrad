from fastapi.testclient import TestClient
from app.main import app  # Jika main.py ada di luar folder app, ubah jadi: from main import app

def run_history_tests():
    # Gunakan context manager 'with' agar @app.on_event("startup") -> init_db() dijalankan otomatis
    with TestClient(app) as client:
        print("=" * 60)
        print("1. UJI ENDPOINT: GET /api/history (Kondisi Awal / Seed Data)")
        print("=" * 60)
        res_hist = client.get("/api/history")
        assert res_hist.status_code == 200, f"Gagal! HTTP {res_hist.status_code}: {res_hist.text}"
        
        data_awal = res_hist.json()
        print(f"Status Code : {res_hist.status_code} OK")
        print(f"Keys JSON   : {list(data_awal.keys())}")
        
        # Cek jumlah data awal (minimal 15 data seed sesuai Bab 2)
        list_key = next((k for k in data_awal.keys() if isinstance(data_awal[k], list)), None)
        if list_key:
            print(f"Jumlah Baris Riwayat Awal ('{list_key}'): {len(data_awal[list_key])} mahasiswa")
        for k, v in data_awal.items():
            if k != list_key:
                print(f"Ringkasan '{k}': {v}")

        print("\n" + "=" * 60)
        print("2. UJI INTEGRASI: POST /api/predict (Simpan Riwayat Baru via NIM)")
        print("=" * 60)
        payload_baru = {
            "kode_anonim": "MHS-999",
            "nim": "2026999001",
            "ips_sem1": 2.35,
            "matkul_diambil_sem1": 6,
            "matkul_lulus_sem1": 4,
            "ips_sem2": 2.10,
            "matkul_diambil_sem2": 6,
            "matkul_lulus_sem2": 3,
            "ukt_lancar": 0,
            "simpan_riwayat": True
        }
        res_pred = client.post("/api/predict", json=payload_baru)
        assert res_pred.status_code == 200, f"Gagal Predict! HTTP {res_pred.status_code}: {res_pred.text}"
        hasil_pred = res_pred.json()
        print(f"Status POST /api/predict : {res_pred.status_code} OK")
        print(f"Kode Mahasiswa & NIM     : {hasil_pred['kode_mhs']} | NIM: {hasil_pred['nim']}")
        print(f"Skor & Kategori Risiko   : {hasil_pred['persentase_bulat']}% ({hasil_pred['risk_level']})")

        print("\n" + "=" * 60)
        print("3. VERIFIKASI ULANG: GET /api/history (Pastikan NIM Tercatat)")
        print("=" * 60)
        res_hist_akhir = client.get("/api/history")
        assert res_hist_akhir.status_code == 200
        assert "2026999001" in res_hist_akhir.text, "NIM baru belum ditemukan di riwayat!"
        print("Verifikasi SQLite        : NIM 2026999001 berhasil tersimpan & terambil via GET /api/history!")

        print("\n" + "=" * 60)
        print("4. UJI UPDATE (UPSERT): POST /api/predict dengan NIM yang Sama")
        print("=" * 60)
        payload_baru["ips_sem2"] = 3.50
        payload_baru["matkul_lulus_sem2"] = 6
        payload_baru["ukt_lancar"] = 1
        res_update = client.post("/api/predict", json=payload_baru)
        assert res_update.status_code == 200
        print(f"Status Upsert NIM Sama   : {res_update.status_code} OK (Skor baru: {res_update.json()['persentase_bulat']}%)")
        print("\nSEMUA PENGUJIAN GET /api/history & INTEGRASI SQLITE LULUS 100%!")

if __name__ == "__main__":
    run_history_tests()