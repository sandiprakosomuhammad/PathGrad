# Uji beban PathGrad: 3 tingkat pengguna, masing-masing 30 detik.
# Jalankan dari folder backend/ (ada locustfile.py dan sampel_uji_konsistensi.csv)
# dengan Docker sudah aktif di http://localhost:8000
#
# Parameter (ini yang ditulis di Bab 2, Tabel 5):
#   10 pengguna  laju 2 pengguna/detik   30 detik
#   50 pengguna  laju 5 pengguna/detik   30 detik
#   100 pengguna laju 10 pengguna/detik  30 detik

$alamat = "http://localhost:8000"

try {
    $h = Invoke-RestMethod "$alamat/api/health" -TimeoutSec 5
    Write-Host "Layanan aktif: $($h.status)"
} catch {
    Write-Host "Layanan tidak aktif di $alamat. Jalankan docker compose up -d dulu."
    exit 1
}

$tingkat = @(
    @{ u = 10;  r = 2;  nama = "u10"  },
    @{ u = 50;  r = 5;  nama = "u50"  },
    @{ u = 100; r = 10; nama = "u100" }
)

foreach ($t in $tingkat) {
    Write-Host ""
    Write-Host "=== $($t.u) pengguna, laju $($t.r)/detik, 30 detik ==="
    python -m locust -f locustfile.py --headless -u $t.u -r $t.r -t 30s --host $alamat --csv "hasil_$($t.nama)"
    Start-Sleep -Seconds 5
}

Write-Host ""
Write-Host "Selesai. Berkas hasil: hasil_u10_stats.csv, hasil_u50_stats.csv, hasil_u100_stats.csv (dan *_stats_history.csv)"
