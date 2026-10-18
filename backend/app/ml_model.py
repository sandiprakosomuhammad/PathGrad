import os
import joblib
import numpy as np
import pandas as pd
from app.schemas import StudentPredictionRequest, PredictionResponse

# ─────────────────────────────────────────────────────────────────────────────
# Path Model
# ─────────────────────────────────────────────────────────────────────────────
MODEL_DIR  = os.path.dirname(os.path.abspath(__file__))
MODEL_PATH = os.path.join(MODEL_DIR, "lightgbm_model.joblib")


# ─────────────────────────────────────────────────────────────────────────────
# Feature Engineering  — WAJIB identik dengan pipeline di Google Colab
# ─────────────────────────────────────────────────────────────────────────────
def make_features(df_input: pd.DataFrame) -> pd.DataFrame:
    """
    Membuat fitur turunan dari data mentah mahasiswa.
    Urutan kolom wajib sama persis dengan urutan saat training di Colab.
    """
    df_feat = df_input.copy()

    df_feat['rata_rata_ips']    = (df_feat['ips_sem1'] + df_feat['ips_sem2']) / 2.0
    df_feat['tren_ips']         = df_feat['ips_sem2'] - df_feat['ips_sem1']
    df_feat['matkul_gagal_sem1'] = df_feat['matkul_diambil_sem1'] - df_feat['matkul_lulus_sem1']
    df_feat['matkul_gagal_sem2'] = df_feat['matkul_diambil_sem2'] - df_feat['matkul_lulus_sem2']
    df_feat['rasio_lulus_sem1'] = np.where(
        df_feat['matkul_diambil_sem1'] > 0,
        df_feat['matkul_lulus_sem1'] / df_feat['matkul_diambil_sem1'],
        0.0
    )
    df_feat['rasio_lulus_sem2'] = np.where(
        df_feat['matkul_diambil_sem2'] > 0,
        df_feat['matkul_lulus_sem2'] / df_feat['matkul_diambil_sem2'],
        0.0
    )

    urutan_fitur = [
        'ips_sem1', 'matkul_diambil_sem1', 'matkul_lulus_sem1',
        'ips_sem2', 'matkul_diambil_sem2', 'matkul_lulus_sem2', 'ukt_lancar',
        'rata_rata_ips', 'tren_ips', 'matkul_gagal_sem1', 'matkul_gagal_sem2',
        'rasio_lulus_sem1', 'rasio_lulus_sem2'
    ]
    return df_feat[urutan_fitur]


# ─────────────────────────────────────────────────────────────────────────────
# Load Model — hanya dari file .joblib yang sudah dilatih
# ─────────────────────────────────────────────────────────────────────────────
def load_model():
    if not os.path.exists(MODEL_PATH):
        raise FileNotFoundError(
            f"[PathGrad] Model tidak ditemukan di '{MODEL_PATH}'. "
            "Pastikan file 'lightgbm_model.joblib' sudah ada di folder backend/app/."
        )
    print(f"[PathGrad] Memuat model LightGBM dari: {MODEL_PATH}")
    return joblib.load(MODEL_PATH)


# Inisialisasi model saat modul diimpor pertama kali
model_instance = load_model()


# ─────────────────────────────────────────────────────────────────────────────
# Inferensi & Analisis Faktor Risiko
# ─────────────────────────────────────────────────────────────────────────────
def evaluate_student(data: StudentPredictionRequest) -> PredictionResponse:
    global model_instance
    if model_instance is None:
        model_instance = load_model()

    # Bangun DataFrame dari data input
    df_raw = pd.DataFrame([{
        'ips_sem1':            data.ips_sem1,
        'matkul_diambil_sem1': data.matkul_diambil_sem1,
        'matkul_lulus_sem1':   data.matkul_lulus_sem1,
        'ips_sem2':            data.ips_sem2,
        'matkul_diambil_sem2': data.matkul_diambil_sem2,
        'matkul_lulus_sem2':   data.matkul_lulus_sem2,
        'ukt_lancar':          data.ukt_lancar,
    }])

    # Feature Engineering (sama persis dengan Colab)
    df_feat = make_features(df_raw)

    # Inferensi LightGBM → probabilitas keterlambatan (Class 1)
    proba         = model_instance.predict_proba(df_feat)[0]
    prob_terlambat = float(proba[1]) if len(proba) > 1 else float(proba[0])
    risk_percentage = round(prob_terlambat * 100, 1)

    # Penentuan kategori risiko menggunakan istilah etis akademis
    if risk_percentage >= 65.0:
        risk_level = "Indikasi Risiko Tinggi"
        label      = "Indikasi Berisiko Terlambat"
    elif risk_percentage >= 35.0:
        risk_level = "Indikasi Risiko Sedang"
        label      = "Indikasi Perlu Perhatian (Waspada)"
    else:
        risk_level = "Indikasi Risiko Rendah"
        label      = "Indikasi Sesuai Jalur (Aman)"

    # ── Derivasi nilai fitur untuk analisis faktor ─────────────────────────
    rata_rata_ips     = (data.ips_sem1 + data.ips_sem2) / 2.0
    tren_ips          = data.ips_sem2 - data.ips_sem1
    gagal_sem1        = data.matkul_diambil_sem1 - data.matkul_lulus_sem1
    gagal_sem2        = data.matkul_diambil_sem2 - data.matkul_lulus_sem2
    rasio_lulus_sem1  = data.matkul_lulus_sem1 / data.matkul_diambil_sem1
    rasio_lulus_sem2  = data.matkul_lulus_sem2 / data.matkul_diambil_sem2

    top_factors: list[str] = []
    recommendations: list[str] = []

    # IPS rata-rata rendah
    if rata_rata_ips < 2.75:
        top_factors.append(
            f"Rata-rata IPS dua semester rendah ({rata_rata_ips:.2f} < 2.75)"
        )
        recommendations.append(
            "Tingkatkan IPS minimal 3.00 di semester berikutnya untuk memperbaiki "
            "kecenderungan akademik."
        )

    # Tren IPS menurun
    if tren_ips < -0.3:
        top_factors.append(
            f"Tren IPS menurun dari Sem 1 ke Sem 2 (Δ = {tren_ips:+.2f})"
        )
        recommendations.append(
            "Lakukan evaluasi metode belajar bersama Dosen Pembimbing Akademik "
            "sebelum perwalian semester 3."
        )

    # Mata kuliah gagal Semester 1
    if gagal_sem1 >= 2:
        top_factors.append(
            f"Terdapat {gagal_sem1} mata kuliah tidak lulus di Semester 1 "
            f"(rasio lulus: {rasio_lulus_sem1 * 100:.0f}%)"
        )
        recommendations.append(
            "Prioritaskan perbaikan mata kuliah Semester 1 melalui kelas ulang "
            "atau Semester Pendek (SP)."
        )

    # Mata kuliah gagal Semester 2
    if gagal_sem2 >= 2:
        top_factors.append(
            f"Terdapat {gagal_sem2} mata kuliah tidak lulus di Semester 2 "
            f"(rasio lulus: {rasio_lulus_sem2 * 100:.0f}%)"
        )
        recommendations.append(
            "Segera daftarkan diri ke kelas remedi atau SP untuk mata kuliah "
            "yang gagal di Semester 2."
        )

    # UKT menunggak
    if data.ukt_lancar == 0:
        top_factors.append(
            "Status pembayaran UKT: Menunggak (berpotensi hambat proses akademik)"
        )
        recommendations.append(
            "Segera urus cicilan atau keringanan UKT ke Bagian Keuangan kampus "
            "agar tidak terhambat dalam pengisian KRS."
        )

    # Tidak ada faktor kritis → mahasiswa aman
    if not top_factors:
        top_factors.append(
            f"Kinerja akademik stabil: rata-rata IPS {rata_rata_ips:.2f}, "
            f"rasio lulus Sem1 {rasio_lulus_sem1 * 100:.0f}%, "
            f"Sem2 {rasio_lulus_sem2 * 100:.0f}%"
        )
        recommendations.append(
            "Pertahankan konsistensi akademik dan mulai persiapkan topik "
            "Tugas Akhir/Skripsi sejak dini."
        )

    return PredictionResponse(
        kode_anonim=data.kode_anonim,
        risk_level=risk_level,
        risk_percentage=risk_percentage,
        prediction_label=label,
        top_factors=top_factors,
        recommendations=recommendations,
    )
