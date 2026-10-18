import 'package:flutter_test/flutter_test.dart';
import 'package:prediksi_kelulusan_app/main.dart';

void main() {
  testWidgets('App smoke test - SplashScreen and Navigation Bar', (WidgetTester tester) async {
    // Jalankan aplikasi
    await tester.pumpWidget(const PrediksiKelulusanApp());

    // Validasi branding PathGrad di SplashScreen
    expect(find.text('Path'), findsOneWidget);
    expect(find.text('Grad'), findsOneWidget);

    // Selesaikan timer transisi otomatis SplashScreen (2.4 detik)
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // Validasi bahwa navbar bawah (Beranda & Riwayat) berhasil dimuat
    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Riwayat'), findsOneWidget);
  });
}
