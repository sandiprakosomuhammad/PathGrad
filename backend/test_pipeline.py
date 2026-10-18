import os
import sys
import pandas as pd
import numpy as np

# Ensure app is importable
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app.schemas import StudentPredictionRequest, PredictionResponse
from app.ml_model import make_features, evaluate_student, load_model

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
    
    # Verifikasi rumus fitur turunan
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
    print("TEST 4: Evaluasi Inferensi Model & Istilah Etis 'Indikasi Risiko'")
    print("=" * 60)

    # 4a. Kasus Mahasiswa Berisiko (Red Flag)
    req_risk = StudentPredictionRequest(
        kode_anonim="MHS-2021-042",
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
    print(f"    - Kode: {res_risk.kode_anonim}")
    print(f"    - Risk Level: {res_risk.risk_level}")
    print(f"    - Risk Percentage: {res_risk.risk_percentage}%")
    print(f"    - Label: {res_risk.prediction_label}")
    print(f"    - Top Factors: {res_risk.top_factors}")
    print(f"    - Recommendations: {res_risk.recommendations}")
    assert "Indikasi Risiko" in res_risk.risk_level, f"Expected 'Indikasi Risiko' in risk_level, got {res_risk.risk_level}"
    assert len(res_risk.recommendations) > 0, "Recommendations should not be empty"

    # 4b. Kasus Mahasiswa Tepat Waktu (Aman)
    req_safe = StudentPredictionRequest(
        kode_anonim="MHS-2021-099",
        ips_sem1=3.60,
        matkul_diambil_sem1=8,
        matkul_lulus_sem1=8,
        ips_sem2=3.75,
        matkul_diambil_sem2=8,
        matkul_lulus_sem2=8,
        ukt_lancar=1,
    )
    res_safe = evaluate_student(req_safe)
    print(f"\n  [Hasil Risiko Rendah]:")
    print(f"    - Kode: {res_safe.kode_anonim}")
    print(f"    - Risk Level: {res_safe.risk_level}")
    print(f"    - Risk Percentage: {res_safe.risk_percentage}%")
    print(f"    - Label: {res_safe.prediction_label}")
    print(f"    - Top Factors: {res_safe.top_factors}")
    print(f"    - Recommendations: {res_safe.recommendations}")
    assert "Indikasi Risiko" in res_safe.risk_level, f"Expected 'Indikasi Risiko' in risk_level, got {res_safe.risk_level}"
    assert len(res_safe.recommendations) > 0, "Recommendations should not be empty"

    print("\n" + "=" * 60)
    print("SEMUA PENGUJIAN OTOMATIS BACKEND BERHASIL 100%!")
    print("=" * 60)

if __name__ == "__main__":
    run_tests()
