import 'package:flutter/foundation.dart';
import '../models/prediction_model.dart';
import 'api_service.dart';

class HistoryRepository extends ChangeNotifier {
  static final HistoryRepository _instance = HistoryRepository._internal();
  factory HistoryRepository() => _instance;

  HistoryRepository._internal() {
    refreshFromApi();
  }

  final List<ScreeningRecord> _records = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ScreeningRecord> get records => List.unmodifiable(_records);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get totalCount  => _records.length;
  int get rendahCount => _records.where((r) => r.kategoriRisiko.contains('Rendah')).length;
  int get sedangCount => _records.where((r) => r.kategoriRisiko.contains('Sedang')).length;
  int get tinggiCount => _records.where((r) => r.kategoriRisiko.contains('Tinggi')).length;

  Future<void> refreshFromApi() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final stats = await ApiService.fetchHistory();
      _records.clear();
      _records.addAll(stats.records);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void addRecord(ScreeningRecord record) {
    _records.insert(0, record);
    notifyListeners();
  }
}
