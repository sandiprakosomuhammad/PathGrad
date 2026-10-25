from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from app.schemas import StudentPredictionRequest, PredictionResponse, HistoryResponse
from app.ml_model import evaluate_student, evaluate_core
from app.database import init_db, get_all_history, insert_record, get_next_student_identity

app = FastAPI(
    title="PathGrad — API Prediksi Risiko Keterlambatan Kelulusan",
    description=(
        "Backend API untuk memprediksi risiko keterlambatan kelulusan mahasiswa "
        "menggunakan algoritma LightGBM yang dilatih pada Dataset UCI ID-697. "
        "Cocok digunakan untuk kebutuhan penelitian dan artikel jurnal."
    ),
    version="2.1.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

# ── CORS: izinkan semua origin agar Flutter bisa akses dari emulator / device ──
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
def on_startup():
    print("[PathGrad] Inisialisasi Database SQLite...")
    init_db(ml_evaluator=evaluate_core)


@app.get("/", tags=["Root"])
def root():
    return {
        "status": "online",
        "service": "PathGrad LightGBM Prediction API",
        "algorithm": "LightGBM Classifier (UCI Dataset ID: 697)",
        "version": "2.1.0",
        "docs_url": "/docs",
    }


@app.get("/api/health", tags=["Health"])
def health():
    return {"status": "healthy"}


@app.get(
    "/api/history",
    response_model=HistoryResponse,
    tags=["History"],
    summary="Daftar Riwayat Skrining Mahasiswa",
    description="Mengambil seluruh riwayat skrining mahasiswa dari database SQLite lokal beserta ringkasan statistik.",
)
def get_history():
    try:
        return get_all_history()
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Terjadi kesalahan saat mengambil riwayat: {str(e)}",
        )


@app.post(
    "/api/predict",
    response_model=PredictionResponse,
    tags=["Prediction"],
    summary="Analisis Indikasi Risiko Keterlambatan Kelulusan Mahasiswa",
    description=(
        "Menerima 7 parameter akademik semester 1 & 2, mengekstraksi 6 fitur turunan "
        "(total 13 fitur), dan menjalankan inferensi model LightGBM untuk menghasilkan "
        "probabilitas, kategori Indikasi Risiko, penyebab utama, dan faktor pemicu objektif."
    ),
)
def predict(request: StudentPredictionRequest):
    try:
        if request.simpan_riwayat or (request.nim and request.nim.strip()):
            next_kode, default_nim = get_next_student_identity()
            final_nim = request.nim.strip() if request.nim and request.nim.strip() else default_nim
            eval_res = evaluate_core(
                ips_sem1=request.ips_sem1,
                matkul_diambil_sem1=request.matkul_diambil_sem1,
                matkul_lulus_sem1=request.matkul_lulus_sem1,
                ips_sem2=request.ips_sem2,
                matkul_diambil_sem2=request.matkul_diambil_sem2,
                matkul_lulus_sem2=request.matkul_lulus_sem2,
                ukt_lancar=request.ukt_lancar,
                kode_mhs=next_kode,
                nim=final_nim
            )
            # Simpan ke SQLite
            insert_record({
                "kode_mhs": next_kode,
                "nim": final_nim,
                "ips_sem1": request.ips_sem1,
                "matkul_diambil_sem1": request.matkul_diambil_sem1,
                "matkul_lulus_sem1": request.matkul_lulus_sem1,
                "ips_sem2": request.ips_sem2,
                "matkul_diambil_sem2": request.matkul_diambil_sem2,
                "matkul_lulus_sem2": request.matkul_lulus_sem2,
                "ukt_lancar": request.ukt_lancar,
                "persentase_bulat": eval_res["persentase_bulat"],
                "kategori_risiko": eval_res["kategori_risiko"],
                "penyebab_utama": eval_res["penyebab_utama"],
                "faktor_pemicu": eval_res["faktor_pemicu"],
            })

            return PredictionResponse(
                kode_anonim=next_kode,
                kode_mhs=next_kode,
                nim=final_nim,
                risk_level=eval_res["risk_level"],
                risk_percentage=eval_res["risk_percentage"],
                persentase_bulat=eval_res["persentase_bulat"],
                prediction_label=eval_res["prediction_label"],
                penyebab_utama=eval_res["penyebab_utama"],
                faktor_pemicu=eval_res["faktor_pemicu"],
                top_factors=eval_res["top_factors"],
                recommendations=[]
            )
        else:
            return evaluate_student(request)
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Terjadi kesalahan saat inferensi model LightGBM: {str(e)}",
        )
