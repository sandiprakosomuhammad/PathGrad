from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from app.schemas import StudentPredictionRequest, PredictionResponse
from app.ml_model import evaluate_student

app = FastAPI(
    title="PathGrad — API Prediksi Risiko Keterlambatan Kelulusan",
    description=(
        "Backend API untuk memprediksi risiko keterlambatan kelulusan mahasiswa "
        "menggunakan algoritma LightGBM yang dilatih pada Dataset UCI ID-697. "
        "Cocok digunakan untuk kebutuhan penelitian dan artikel jurnal."
    ),
    version="2.0.0",
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


@app.get("/", tags=["Root"])
def root():
    return {
        "status": "online",
        "service": "PathGrad LightGBM Prediction API",
        "algorithm": "LightGBM Classifier (UCI Dataset ID: 697)",
        "version": "2.0.0",
        "docs_url": "/docs",
    }


@app.get("/api/health", tags=["Health"])
def health():
    return {"status": "healthy"}


@app.post(
    "/api/predict",
    response_model=PredictionResponse,
    tags=["Prediction"],
    summary="Analisis Indikasi Risiko Keterlambatan Kelulusan Mahasiswa",
    description=(
        "Menerima 7 parameter akademik semester 1 & 2, mengekstraksi 6 fitur turunan "
        "(total 13 fitur), dan menjalankan inferensi model LightGBM untuk menghasilkan "
        "probabilitas, kategori Indikasi Risiko (Tinggi/Sedang/Rendah), faktor penentu, "
        "serta rekomendasi tindak lanjut akademik secara etis."
    ),
)
def predict(request: StudentPredictionRequest):
    try:
        return evaluate_student(request)
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Terjadi kesalahan saat inferensi model LightGBM: {str(e)}",
        )
