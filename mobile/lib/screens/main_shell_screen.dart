import 'package:flutter/material.dart';
import '../models/prediction_model.dart';
import 'dashboard_screen.dart';
import 'history_screen.dart';
import 'prediction_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _currentIndex = 0;

  void _openPredictionScreen([ScreeningRecord? record]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PredictionScreen(
          initialRecord: record,
          onBackToDashboard: () {
            Navigator.pop(context);
            setState(() => _currentIndex = 0);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(
        onNavigateToPrediction: _openPredictionScreen,
        onNavigateToHistory: () => setState(() => _currentIndex = 1),
      ),
      HistoryScreen(onNavigateToPrediction: _openPredictionScreen),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: SizedBox(
          height: 80,
          child: Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              // Bottom bar container
              Container(
                height: 66,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x0F000000),
                      blurRadius: 12,
                      offset: Offset(0, -3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Garis biru di atas navbar sesuai referensi foto
                    Container(
                      height: 2.5,
                      color: const Color(0xFF1D4ED8),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          // Tab Kiri: Beranda
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _currentIndex = 0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _currentIndex == 0 ? Icons.home_rounded : Icons.home_outlined,
                                    color: _currentIndex == 0 ? const Color(0xFF1D4ED8) : const Color(0xFF94A3B8),
                                    size: 26,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Beranda',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: _currentIndex == 0 ? FontWeight.bold : FontWeight.w500,
                                      color: _currentIndex == 0 ? const Color(0xFF1D4ED8) : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Ruang tengah untuk tombol bulat PathGrad
                          const SizedBox(width: 84),

                          // Tab Kanan: Riwayat
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _currentIndex = 1),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _currentIndex == 1 ? Icons.receipt_long_rounded : Icons.receipt_long_outlined,
                                    color: _currentIndex == 1 ? const Color(0xFF1D4ED8) : const Color(0xFF94A3B8),
                                    size: 26,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Riwayat',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: _currentIndex == 1 ? FontWeight.bold : FontWeight.w500,
                                      color: _currentIndex == 1 ? const Color(0xFF1D4ED8) : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Tombol Bulat Biru di Tengah (Logo PathGrad)
              Positioned(
                top: -18,
                child: GestureDetector(
                  onTap: _openPredictionScreen,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E40AF), Color(0xFF2563EB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1E40AF).withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.school_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                        SizedBox(height: 1),
                        Text(
                          'PathGrad',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
