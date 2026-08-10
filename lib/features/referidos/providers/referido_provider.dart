import 'package:flutter/material.dart';
import '../models/referido_model.dart';
import '../services/referido_service.dart';

/// Manages referidos state across the app.
class ReferidoProvider extends ChangeNotifier {
  // — State for "Mis Referidos" (user view) —
  List<Referido> _misReferidos = [];
  String _codeRefer = '';
  bool _isLoadingMis = false;

  // — State for admin view (all referidos) —
  List<Referido> _allReferidos = [];
  bool _isLoadingAll = false;

  // — Shared —
  String? _errorMessage;

  // — Getters —
  List<Referido> get misReferidos => _misReferidos;
  String get codeRefer => _codeRefer;
  bool get isLoadingMis => _isLoadingMis;
  List<Referido> get allReferidos => _allReferidos;
  bool get isLoadingAll => _isLoadingAll;
  String? get errorMessage => _errorMessage;

  // ── User: Load my referidos + my code ─────────────────────────────────────

  Future<void> loadMisReferidos() async {
    _isLoadingMis = true;
    _errorMessage = null;
    _misReferidos = [];
    _codeRefer = '';
    notifyListeners();

    try {
      final results = await Future.wait([
        ReferidoApiService.getMisReferidos(),
        ReferidoApiService.getMyCodeRefer(),
      ]);
      _misReferidos = results[0] as List<Referido>;
      _codeRefer = results[1] as String;
      _isLoadingMis = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _misReferidos = [];
      _isLoadingMis = false;
      notifyListeners();
    }
  }

  /// Clears state WITHOUT notifying listeners — safe to call from initState().
  void resetSilent() {
    _misReferidos = [];
    _codeRefer = '';
    _allReferidos = [];
    _isLoadingMis = false;
    _isLoadingAll = false;
    _errorMessage = null;
  }

  void clearState() {
    _misReferidos = [];
    _codeRefer = '';
    _allReferidos = [];
    _isLoadingMis = false;
    _isLoadingAll = false;
    _errorMessage = null;
    notifyListeners();
  }

  // ── User: Create a referral invitation ────────────────────────────────────

  Future<bool> createReferido(CreateReferidoRequest request) async {
    _errorMessage = null;
    notifyListeners();

    try {
      final newReferido = await ReferidoApiService.create(request);
      _misReferidos.insert(0, newReferido);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ── Admin: Load all referidos ─────────────────────────────────────────────

  Future<void> loadAllReferidos() async {
    _isLoadingAll = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allReferidos = await ReferidoApiService.getAll();
      _isLoadingAll = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoadingAll = false;
      notifyListeners();
    }
  }

  // ── Admin: Afiliar referido ───────────────────────────────────────────────

  Future<bool> afiliarReferido(int id) async {
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await ReferidoApiService.afiliar(id);
      _updateInList(updated);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ── Admin: Otorgar recompensa ─────────────────────────────────────────────

  Future<bool> otorgarRecompensa(int id) async {
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await ReferidoApiService.otorgarRecompensa(id);
      _updateInList(updated);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ── Admin: Delete referido ────────────────────────────────────────────────

  Future<bool> deleteReferido(int id) async {
    _errorMessage = null;
    notifyListeners();

    try {
      await ReferidoApiService.delete(id);
      _allReferidos.removeWhere((r) => r.id == id);
      _misReferidos.removeWhere((r) => r.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ── Helper ────────────────────────────────────────────────────────────────

  void _updateInList(Referido updated) {
    final allIdx = _allReferidos.indexWhere((r) => r.id == updated.id);
    if (allIdx != -1) _allReferidos[allIdx] = updated;
    final misIdx = _misReferidos.indexWhere((r) => r.id == updated.id);
    if (misIdx != -1) _misReferidos[misIdx] = updated;
  }
}
