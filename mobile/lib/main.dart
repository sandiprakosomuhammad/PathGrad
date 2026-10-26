import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const PrediksiKelulusanApp());
}

class PrediksiKelulusanApp extends StatelessWidget {
  const PrediksiKelulusanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PathGrad - Prediksi Risiko Kelulusan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E40AF),
          primary: const Color(0xFF1E40AF),
          secondary: const Color(0xFF2563EB),
          surface: Colors.white,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF0F172A),
          elevation: 0,
          scrolledUnderElevation: 0.5,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          color: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1E40AF), width: 2),
          ),
          labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
        ),
      ),
      builder: (context, child) {
        return Container(
          color: const Color(0xFFCBD5E1),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 350),
            child: AspectRatio(
              aspectRatio: 9 / 19.5,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(
                    color: const Color(0xFF1E293B),
                    width: 8,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x38000000),
                      blurRadius: 30,
                      spreadRadius: 2,
                      offset: Offset(0, 10),
                    ),
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Container(
                    color: const Color(0xFFF8FAFC),
                    child: Column(
                      children: [
                        // ── Top Phone Status Bar (Tinggi 28px) ──
                        Container(
                          height: 28,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          color: Colors.white,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Jam 09:41
                              const SizedBox(
                                width: 38,
                                child: Text(
                                  '09:41',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                              // Dynamic Island / Camera Notch (72px x 15px)
                              Container(
                                width: 72,
                                height: 15,
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(7.5),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(right: 6),
                                      width: 5,
                                      height: 5,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF1E293B),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Sinyal, WiFi, Baterai
                              const SizedBox(
                                width: 48,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Icon(Icons.signal_cellular_alt_rounded, size: 12, color: Color(0xFF0F172A)),
                                    SizedBox(width: 3),
                                    Icon(Icons.wifi_rounded, size: 12, color: Color(0xFF0F172A)),
                                    SizedBox(width: 3),
                                    Icon(Icons.battery_full_rounded, size: 14, color: Color(0xFF0F172A)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ── App Screen Content ──
                        Expanded(
                          child: LayoutBuilder(
                            builder: (ctx, constraints) {
                              final media = MediaQuery.of(context);
                              return MediaQuery(
                                data: media.copyWith(
                                  size: Size(constraints.maxWidth, constraints.maxHeight),
                                  padding: EdgeInsets.zero,
                                  viewPadding: EdgeInsets.zero,
                                ),
                                child: child ?? const SizedBox(),
                              );
                            },
                          ),
                        ),

                        // ── Bottom Home Indicator Bar (100px x 4px) ──
                        Container(
                          height: 16,
                          color: Colors.white,
                          alignment: Alignment.center,
                          child: Container(
                            width: 100,
                            height: 4,
                            decoration: BoxDecoration(
                              color: const Color(0xFF94A3B8),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      home: const SplashScreen(),
    );
  }
}
