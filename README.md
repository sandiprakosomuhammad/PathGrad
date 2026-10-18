# PathGrad — Sistem Prediksi Risiko Keterlambatan Kelulusan Mahasiswa

PathGrad adalah aplikasi fullstack berbasis **Machine Learning (LightGBM)** dan **Flutter** yang dirancang sebagai instrumen skrining preventif dini untuk memprediksi potensi keterlambatan kelulusan mahasiswa berdasarkan rekam akademik tahun pertama (Semester 1 & 2).

---

## 🛠️ Tech Stack & Spesifikasi

- **Sistem Operasi**: Windows 11 / WSL2
- **Backend API**: Python 3.11/3.13, FastAPI, Uvicorn, Pydantic v2
- **Machine Learning**: LightGBM Classifier, Scikit-Learn, Pandas, NumPy, Joblib
- **Frontend Mobile**: Flutter (Dart), Material Design 3
- **Containerization**: Docker Desktop & Docker Compose
- **Version Control**: Git & GitHub

---

## 📊 Dataset & Fitur Model

Model Machine Learning dilatih menggunakan dataset akademik standar (**UCI Machine Learning Repository ID: 697**).

### Parameter Input (7 Fitur):
1. `ips_sem1`: Indeks Prestasi Semester 1 (0.00 – 4.00)
2. `matkul_diambil_sem1`: Jumlah Mata Kuliah Diambil Semester 1 (minimal 1)
3. `matkul_lulus_sem1`: Jumlah Mata Kuliah Lulus Semester 1
4. `ips_sem2`: Indeks Prestasi Semester 2 (0.00 – 4.00)
5. `matkul_diambil_sem2`: Jumlah Mata Kuliah Diambil Semester 2 (minimal 1)
6. `matkul_lulus_sem2`: Jumlah Mata Kuliah Lulus Semester 2
7. `ukt_lancar`: Status Pembayaran UKT (0 = Menunggak, 1 = Lancar/Lunas)
8. *(Opsional)* `kode_anonim`: Kode pencatatan identitas anonim tanpa nama/NIM asli.

### Fitur Rekayasa Turunan (6 Fitur Otomatis):
- `rata_rata_ips`: Rata-rata IPS dua semester
- `tren_ips`: Selisih performa IPS ($IPS_2 - IPS_1$)
- `matkul_gagal_sem1`: Mata kuliah tidak lulus semester 1
- `matkul_gagal_sem2`: Mata kuliah tidak lulus semester 2
- `rasio_lulus_sem1`: Rasio kelulusan mata kuliah semester 1
- `rasio_lulus_sem2`: Rasio kelulusan mata kuliah semester 2

### Output Prediksi (Etis Akademis):
- **Indikasi Risiko Rendah** (Probabilitas < 35%): Indikasi Sesuai Jalur (Aman)
- **Indikasi Risiko Sedang** (Probabilitas 35% – < 65%): Indikasi Perlu Perhatian (Waspada)
- **Indikasi Risiko Tinggi** (Probabilitas $\ge$ 65%): Indikasi Berisiko Terlambat

---

## 📁 Struktur Direktori

```text
prediksi_kelulusan/
├── .gitignore                  # Konfigurasi pengabaian file Git
├── README.md                   # Dokumentasi proyek
├── backend/                    # Layanan Backend FastAPI & Model ML
│   ├── Dockerfile              # Konfigurasi container backend
│   ├── docker-compose.yml      # Orkestrasi Docker Compose
│   ├── requirements.txt        # Daftar dependency Python
│   ├── test_pipeline.py        # Pengujian otomatis pipeline ML
│   └── app/
│       ├── main.py             # Entrypoint FastAPI & routing API
│       ├── ml_model.py         # Feature engineering & inferensi LightGBM
│       ├── schemas.py          # Validasi skema request & response Pydantic
│       └── lightgbm_model.joblib # Model biner LightGBM 13 fitur
└── mobile/                     # Aplikasi Frontend Flutter
    ├── pubspec.yaml            # Konfigurasi package Flutter
    └── lib/
        ├── main.dart           # Inisialisasi tema & routing
        ├── models/             # Data class model request, response, record
        ├── screens/            # Halaman UI (Dashboard, Input Prediksi, Riwayat, Shell)
        └── services/           # Service API HTTP & State Management Riwayat
```

---

## 🚀 Cara Menjalankan Proyek

### 1. Menjalankan Backend (Pilih salah satu)

**Opsi A — Menggunakan Python Lokal:**
```powershell
cd backend
py -3.11 -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

**Opsi B — Menggunakan Docker Desktop:**
```powershell
cd backend
docker compose up --build
```
> Buka dokumentasi Swagger API interaktif di: `http://localhost:8000/docs`

---

### 2. Menjalankan Aplikasi Mobile Flutter

```powershell
cd mobile
flutter run
```
Atau jika ingin membuat file APK rilis:
```powershell
flutter build apk --release
```

---

## 🧪 Pengujian Otomatis

Untuk memverifikasi keakuratan model, validasi data, dan pembentukan 13 fitur:
```powershell
cd backend
py -3.11 test_pipeline.py
```
Hasil pengujian validasi Pydantic, pembacaan model, serta inferensi risiko akan ditampilkan secara komprehensif.
