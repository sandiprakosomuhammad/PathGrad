"""
Uji kinerja dengan Locust. Payload diambil dari sampel_uji_konsistensi.csv
(data asli dari dataset, tanpa nama), bukan data karangan.

Jalankan API dulu (mis. docker compose up, atau uvicorn app.main:app --port 8000), lalu:

    pip install locust
    locust -f locustfile.py --headless -u 10  -r 5  -t 60s --host http://localhost:8000 --csv hasil_u10
    locust -f locustfile.py --headless -u 50  -r 10 -t 60s --host http://localhost:8000 --csv hasil_u50
    locust -f locustfile.py --headless -u 100 -r 20 -t 60s --host http://localhost:8000 --csv hasil_u100

Catat spesifikasi mesin (CPU, RAM, OS, jumlah worker uvicorn) di artikel.
Hasil: hasil_uXX_stats.csv (p50/p95/p99, RPS, jumlah gagal).
"""
import itertools

import pandas as pd
from locust import HttpUser, between, task

_df = pd.read_csv("sampel_uji_konsistensi.csv")
_payloads = [
    {
        "kode_anonim": f"LOAD-{i:03d}",
        "ips_sem1": float(r["ips_sem1"]),
        "matkul_diambil_sem1": int(r["matkul_diambil_sem1"]),
        "matkul_lulus_sem1": int(r["matkul_lulus_sem1"]),
        "ips_sem2": float(r["ips_sem2"]),
        "matkul_diambil_sem2": int(r["matkul_diambil_sem2"]),
        "matkul_lulus_sem2": int(r["matkul_lulus_sem2"]),
        "ukt_lancar": int(r["ukt_lancar"]),
    }
    for i, r in _df.iterrows()
]
_siklus = itertools.cycle(_payloads)


class PengunaPathGrad(HttpUser):
    wait_time = between(0.5, 1.5)  # jeda wajar antar permintaan pengguna

    @task(10)
    def prediksi(self):
        self.client.post("/api/predict", json=next(_siklus), name="/api/predict")

    @task(1)
    def health(self):
        self.client.get("/api/health", name="/api/health")
