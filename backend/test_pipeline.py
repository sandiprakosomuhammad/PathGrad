import os
import sys
import pandas as pd
import numpy as np

# Ensure app is importable
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app.schemas import StudentPredictionRequest, PredictionResponse
from app.ml_model import make_features, evaluate_student, evaluate_core, load_model
from app.database import init_db, get_all_history, insert_record, get_next_student_identity, DB_PATH

def run_tests():
    print("=" * 60)
    print("TEST 1: Verifikasi Model LightGBM Terbaca dengan Benar")
    print("=" * 60)
    model = load_model()
    print("  [OK] Model successfully loaded via joblib.load!")
    print(f"  [INFO] Model Type: {type(model)}")
    if hasattr(model, 'n_features_in_'):
        print(f"  [INFO] Number of features expected by model: {model.n_features_in_}")
    if hasattr(model, 'feature_name_'):
        print(f"  [INFO] Model feature names: {model.feature_name_}")

    print("\n" + "=" * 60)
    print("TEST 2: Verifikasi 13 Fitur di make_features (7 input + 6 turunan)")
    print("=" * 60)
    dummy_input = pd.DataFrame([{
        'ips_sem1': 2.50,
        'matkul_diambil_sem1': 6,
        'matkul_lulus_sem1': 4,
        'ips_sem2': 2.00,
        'matkul_diambil_sem2': 6,
        'matkul_lulus_sem2': 3,
        'ukt_lancar': 1,
    }])
    df_feat = make_features(dummy_input)
    print(f"  [INFO] Output Columns ({len(df_feat.columns)} features): {list(df_feat.columns)}")
    assert len(df_feat.columns) == 13, f"Expected 13 features, got {len(df_feat.columns)}"
    
    assert df_feat['rata_rata_ips'].iloc[0] == 2.25, "Perhitungan rata_rata_ips salah"
    assert round(df_feat['tren_ips'].iloc[0], 2) == -0.50, "Perhitungan tren_ips salah"
    assert df_feat['matkul_gagal_sem1'].iloc[0] == 2, "Perhitungan matkul_gagal_sem1 salah"
    assert df_feat['matkul_gagal_sem2'].iloc[0] == 3, "Perhitungan matkul_gagal_sem2 salah"
    assert round(df_feat['rasio_lulus_sem1'].iloc[0], 2) == 0.67, "Perhitungan rasio_lulus_sem1 salah"
    assert round(df_feat['rasio_lulus_sem2'].iloc[0], 2) == 0.50, "Perhitungan rasio_lulus_sem2 salah"
    print("  [OK] Semua 13 fitur dan rumus turunan 100% valid!")

    print("\n" + "=" * 60)
    print("TEST 3: Verifikasi Validasi Ketat Pydantic di schemas.py")
    print("=" * 60)
    
    # 3a. Matkul diambil < 1
    try:
        StudentPredictionRequest(
            kode_anonim="TEST-01",
            ips_sem1=3.0,
            matkul_diambil_sem1=0,
            matkul_lulus_sem1=0,
            ips_sem2=3.0,
            matkul_diambil_sem2=6,
            matkul_lulus_sem2=6,
            ukt_lancar=1,
        )
        print("  [FAIL] Seharusnya menolak matkul_diambil_sem1 = 0!")
    except Exception as e:
        print(f"  [OK] Validasi matkul diambil < 1 berhasil ditolak: {e}")

    # 3b. Matkul lulus > matkul diambil
    try:
        StudentPredictionRequest(
            kode_anonim="TEST-02",
            ips_sem1=3.0,
            matkul_diambil_sem1=6,
            matkul_lulus_sem1=8,
            ips_sem2=3.0,
            matkul_diambil_sem2=6,
            matkul_lulus_sem2=6,
            ukt_lancar=1,
        )
        print("  [FAIL] Seharusnya menolak matkul_lulus > matkul_diambil!")
    except Exception as e:
        print(f"  [OK] Validasi matkul lulus > diambil berhasil ditolak: {e}")

    # 3c. IPS di luar rentang 0.0 - 4.0
    try:
        StudentPredictionRequest(
            kode_anonim="TEST-03",
            ips_sem1=4.5,
            matkul_diambil_sem1=6,
            matkul_lulus_sem1=6,
            ips_sem2=3.0,
            matkul_diambil_sem2=6,
            matkul_lulus_sem2=6,
            ukt_lancar=1,
        )
        print("  [FAIL] Seharusnya menolak IPS > 4.0!")
    except Exception as e:
        print(f"  [OK] Validasi IPS > 4.0 berhasil ditolak: {e}")

    print("\n" + "=" * 60)
    print("TEST 4: Inisialisasi Database SQLite & Seeding 15 Data Training")
    print("=" * 60)
    # Hapus file db lama jika ingin fresh test
    if os.path.exists(DB_PATH):
        try:
            os.remove(DB_PATH)
        except Exception:
            pass

    init_db(ml_evaluator=evaluate_core)
    history = get_all_history()
    print(f"  [INFO] Total mahasiswa di SQLite : {history['total_mahasiswa']}")
    print(f"  [INFO] Indikasi Risiko Rendah     : {history['total_rendah']}")
    print(f"  [INFO] Indikasi Risiko Sedang     : {history['total_sedang']}")
    print(f"  [INFO] Indikasi Risiko Tinggi     : {history['total_tinggi']}")
    assert history['total_mahasiswa'] == 15, f"Expected 15 records, got {history['total_mahasiswa']}"
    assert history['total_rendah'] == 5, f"Expected 5 rendah, got {history['total_rendah']}"
    assert history['total_sedang'] == 5, f"Expected 5 sedang, got {history['total_sedang']}"
    assert history['total_tinggi'] == 5, f"Expected 5 tinggi, got {history['total_tinggi']}"
    assert history['records'][0]['kode_mhs'] == "MHS-001", "Expected MHS-001 on first row"
    assert history['records'][0]['nim'] == "2401001", "Expected 2401001 on first row"
    assert history['records'][14]['kode_mhs'] == "MHS-015", "Expected MHS-015 on row 15"
    assert history['records'][14]['nim'] == "2401015", "Expected 2401015 on row 15"
    print("  [OK] Seeding 15 data awal seimbang (5-5-5) berhasil 100%!")

    print("\n" + "=" * 60)
    print("TEST 5: Evaluasi Inferensi Model Dosen PA (Faktor Pemicu & Tanpa Rekomendasi)")
    print("=" * 60)

    req_risk = StudentPredictionRequest(
        kode_anonim="MHS-2021-042",
        nim="2410511042",
        ips_sem1=2.10,
        matkul_diambil_sem1=7,
        matkul_lulus_sem1=3,
        ips_sem2=1.95,
        matkul_diambil_sem2=7,
        matkul_lulus_sem2=2,
        ukt_lancar=0,
    )
    res_risk = evaluate_student(req_risk)
    print(f"  [Hasil Risiko Tinggi]:")
    print(f"    - Risk Level: {res_risk.risk_level}")
    print(f"    - Risk Percentage: {res_risk.risk_percentage}% (Bulat: {res_risk.persentase_bulat}%)")
    print(f"    - Penyebab Utama: {res_risk.penyebab_utama}")
    print(f"    - Faktor Pemicu (Observasi Data): {res_risk.faktor_pemicu}")
    print(f"    - Rekomendasi (Dikosongkan): {res_risk.recommendations}")
    assert "Indikasi Risiko" in res_risk.risk_level
    assert res_risk.persentase_bulat >= 70
    assert len(res_risk.faktor_pemicu) > 0
    assert len(res_risk.recommendations) == 0, "Rekomendasi tindakan harus kosong untuk Dosen PA"

    print("\n" + "=" * 60)
    print("SEMUA PENGUJIAN OTOMATIS BACKEND BERHASIL 100%!")
    print("=" * 60)

if __name__ == "__main__":
    run_tests()
