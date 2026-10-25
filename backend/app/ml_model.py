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

    df_feat['rata_rata_ips']     = (df_feat['ips_sem1'] + df_feat['ips_sem2']) / 2.0
    df_feat['tren_ips']          = df_feat['ips_sem2'] - df_feat['ips_sem1']
    df_feat['matkul_gagal_sem1'] = df_feat['matkul_diambil_sem1'] - df_feat['matkul_lulus_sem1']
    df_feat['matkul_gagal_sem2'] = df_feat['matkul_diambil_sem2'] - df_feat['matkul_lulus_sem2']
    df_feat['rasio_lulus_sem1']  = np.where(
        df_feat['matkul_diambil_sem1'] > 0,
        df_feat['matkul_lulus_sem1'] / df_feat['matkul_diambil_sem1'],
        0.0
    )
    df_feat['rasio_lulus_sem2']  = np.where(
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
# Load Model — mendukung model langsung maupun bundel dictionary (.joblib)
# ─────────────────────────────────────────────────────────────────────────────
def load_model():
    if not os.path.exists(MODEL_PATH):
        raise FileNotFoundError(
            f"[PathGrad] Model tidak ditemukan di '{MODEL_PATH}'. "
            "Pastikan file 'lightgbm_model.joblib' sudah ada di folder backend/app/."
        )
    print(f"[PathGrad] Memuat model LightGBM dari: {MODEL_PATH}")
    loaded_obj = joblib.load(MODEL_PATH)
    if isinstance(loaded_obj, dict) and "model" in loaded_obj:
        return loaded_obj["model"]
    return loaded_obj


# Inisialisasi model saat modul diimpor pertama kali
model_instance = load_model()


# ─────────────────────────────────────────────────────────────────────────────
# Logika Evaluasi Inti (Faktor Pemicu Risiko & Penyebab Utama)
# ─────────────────────────────────────────────────────────────────────────────
def evaluate_core(
    ips_sem1: float,
    matkul_diambil_sem1: int,
    matkul_lulus_sem1: int,
    ips_sem2: float,
    matkul_diambil_sem2: int,
    matkul_lulus_sem2: int,
    ukt_lancar: int,
    kode_mhs: str = "MHS-ANON",
    nim: str = "-"
) -> dict:
    global model_instance
    if model_instance is None:
        model_instance = load_model()

    df_raw = pd.DataFrame([{
        'ips_sem1':            ips_sem1,
        'matkul_diambil_sem1': matkul_diambil_sem1,
        'matkul_lulus_sem1':   matkul_lulus_sem1,
        'ips_sem2':            ips_sem2,
        'matkul_diambil_sem2': matkul_diambil_sem2,
        'matkul_lulus_sem2':   matkul_lulus_sem2,
        'ukt_lancar':          ukt_lancar,
    }])

    df_feat = make_features(df_raw)

    proba          = model_instance.predict_proba(df_feat)[0]
    prob_terlambat = float(proba[1]) if len(proba) > 1 else float(proba[0])
    risk_percentage  = round(prob_terlambat * 100, 1)
    persentase_bulat = int(round(prob_terlambat * 100))

    BATAS_SEDANG, BATAS_TINGGI = 0.40, 0.70

    if prob_terlambat >= BATAS_TINGGI:
        risk_level = "Indikasi Risiko Tinggi"
        label      = "Indikasi Berisiko Terlambat"
    elif prob_terlambat >= BATAS_SEDANG:
        risk_level = "Indikasi Risiko Sedang"
        label      = "Indikasi Perlu Perhatian (Waspada)"
    else:
        risk_level = "Indikasi Risiko Rendah"
        label      = "Indikasi Risiko Rendah"

    rata_rata_ips    = (ips_sem1 + ips_sem2) / 2.0
    tren_ips         = ips_sem2 - ips_sem1
    gagal_sem1       = matkul_diambil_sem1 - matkul_lulus_sem1
    gagal_sem2       = matkul_diambil_sem2 - matkul_lulus_sem2
    rasio_lulus_sem1 = matkul_lulus_sem1 / matkul_diambil_sem1
    rasio_lulus_sem2 = matkul_lulus_sem2 / matkul_diambil_sem2

    faktor_pemicu: list[str] = []

    # 1. Mata kuliah belum lulus Semester 2 (Faktor kontributor utama)
    if gagal_sem2 >= 1 or rasio_lulus_sem2 < 0.85:
        faktor_pemicu.append(
            f"Terdapat {gagal_sem2} mata kuliah belum lulus di Semester 2 "
            f"(rasio kelulusan: {rasio_lulus_sem2 * 100:.0f}%)"
        )

    # 2. Mata kuliah belum lulus Semester 1
    if gagal_sem1 >= 1 or rasio_lulus_sem1 < 0.85:
        faktor_pemicu.append(
            f"Terdapat {gagal_sem1} mata kuliah belum lulus di Semester 1 "
            f"(rasio kelulusan: {rasio_lulus_sem1 * 100:.0f}%)"
        )

    # 3. Status UKT menunggak
    if ukt_lancar == 0:
        faktor_pemicu.append(
            "Status pembayaran UKT: Menunggak (berpotensi menghambat administrasi studi)"
        )

    # 4. IPS rata-rata tahun pertama rendah
    if rata_rata_ips < 2.75:
        faktor_pemicu.append(
            f"Rata-rata IPS tahun pertama relatif rendah ({rata_rata_ips:.2f} < 2.75)"
        )

    # 5. Penurunan performa IPS
    if tren_ips < -0.3:
        faktor_pemicu.append(
            f"Tren IPS mengalami penurunan dari Semester 1 ke Semester 2 (Δ = {tren_ips:+.2f})"
        )

    # Fallback jika tidak ada observasi negatif terpicu
    if not faktor_pemicu:
        if prob_terlambat >= BATAS_SEDANG:
            faktor_pemicu.append(
                "Pola kombinasi capaian nilai dan kelulusan mata kuliah menyerupai profil historis mahasiswa berisiko"
            )
        else:
            faktor_pemicu.append(
                f"Kinerja akademik tahun pertama relatif terkendali: rata-rata IPS {rata_rata_ips:.2f}, "
                f"rasio lulus Sem 1 ({rasio_lulus_sem1 * 100:.0f}%), "
                f"Sem 2 ({rasio_lulus_sem2 * 100:.0f}%)"
            )

    # Tentukan penyebab utama (teks ringkas untuk tampilan card tabel)
    if gagal_sem2 >= 1:
        penyebab_utama = f"{gagal_sem2} matkul belum lulus di Semester 2"
    elif gagal_sem1 >= 1:
        penyebab_utama = f"{gagal_sem1} matkul belum lulus di Semester 1"
    elif ukt_lancar == 0:
        penyebab_utama = "Status pembayaran UKT menunggak"
    elif rata_rata_ips < 2.75:
        penyebab_utama = f"Rata-rata IPS tahun pertama rendah ({rata_rata_ips:.2f})"
    elif tren_ips < -0.3:
        penyebab_utama = f"Tren IPS mengalami penurunan (Δ {tren_ips:+.2f})"
    elif prob_terlambat < BATAS_SEDANG:
        penyebab_utama = "Akademik stabil & mata kuliah tuntas"
    else:
        penyebab_utama = "Kombinasi pola performa akademik tahun pertama"

    return {
        "kode_mhs": kode_mhs,
        "nim": nim,
        "risk_level": risk_level,
        "kategori_risiko": risk_level,
        "risk_percentage": risk_percentage,
        "persentase_bulat": persentase_bulat,
        "prediction_label": label,
        "penyebab_utama": penyebab_utama,
        "faktor_pemicu": faktor_pemicu,
        "top_factors": faktor_pemicu,
        "recommendations": []  # Ditiadakan sesuai tugas Dosen PA
    }


def evaluate_student(data: StudentPredictionRequest) -> PredictionResponse:
    res = evaluate_core(
        ips_sem1=data.ips_sem1,
        matkul_diambil_sem1=data.matkul_diambil_sem1,
        matkul_lulus_sem1=data.matkul_lulus_sem1,
        ips_sem2=data.ips_sem2,
        matkul_diambil_sem2=data.matkul_diambil_sem2,
        matkul_lulus_sem2=data.matkul_lulus_sem2,
        ukt_lancar=data.ukt_lancar,
        kode_mhs=data.kode_anonim,
        nim=data.nim or "-"
    )
    return PredictionResponse(
        kode_anonim=data.kode_anonim,
        kode_mhs=res["kode_mhs"],
        nim=res["nim"],
        risk_level=res["risk_level"],
        risk_percentage=res["risk_percentage"],
        persentase_bulat=res["persentase_bulat"],
        prediction_label=res["prediction_label"],
        penyebab_utama=res["penyebab_utama"],
        faktor_pemicu=res["faktor_pemicu"],
        top_factors=res["top_factors"],
        recommendations=[]
    )