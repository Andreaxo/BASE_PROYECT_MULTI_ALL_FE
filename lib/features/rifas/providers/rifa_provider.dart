import 'package:flutter/material.dart';
import '../models/rifa_model.dart';
import '../services/rifa_service.dart';

class RifaProvider with ChangeNotifier {
  Rifa? _activeRifa;
  List<ParticipacionRifa> _misParticipaciones = [];
  List<RifaHistorialItem> _historialRifas = [];

  List<Rifa> _allRifas = [];
  List<ParticipacionRifa> _selectedRifaParticipaciones = [];
  List<GanadorRifa> _selectedRifaGanadores = [];

  bool _isLoadingActive = false;
  bool _isLoadingMis = false;
  bool _isLoadingHistorial = false;
  bool _isLoadingAll = false;
  bool _isLoadingParticipaciones = false;
  bool _isLoadingGanadores = false;

  bool _isLoadingAction = false;

  String? _errorMessage;

  // Getters
  Rifa? get activeRifa => _activeRifa;
  List<ParticipacionRifa> get misParticipaciones => _misParticipaciones;
  List<RifaHistorialItem> get historialRifas => _historialRifas;

  List<Rifa> get allRifas => _allRifas;
  List<ParticipacionRifa> get selectedRifaParticipaciones => _selectedRifaParticipaciones;
  List<GanadorRifa> get selectedRifaGanadores => _selectedRifaGanadores;

  bool get isLoadingActive => _isLoadingActive;
  bool get isLoadingMis => _isLoadingMis;
  bool get isLoadingHistorial => _isLoadingHistorial;
  bool get isLoadingAll => _isLoadingAll;
  bool get isLoadingParticipaciones => _isLoadingParticipaciones;
  bool get isLoadingGanadores => _isLoadingGanadores;
  bool get isLoadingAction => _isLoadingAction;

  String? get errorMessage => _errorMessage;

  // --- User Methods ---

  Future<bool> participarEnRifa(int rifaId) async {
    _isLoadingAction = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newTicket = await RifaApiService.participar(rifaId);
      _misParticipaciones.insert(0, newTicket);
      _isLoadingAction = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoadingAction = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadUserViewData() async {
    await Future.wait([
      loadActiveRifa(),
      loadMisParticipaciones(),
      loadHistorial(),
    ]);
  }

  Future<void> loadActiveRifa() async {
    _isLoadingActive = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _activeRifa = await RifaApiService.getActiva();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoadingActive = false;
      notifyListeners();
    }
  }

  Future<void> loadMisParticipaciones() async {
    _isLoadingMis = true;
    _errorMessage = null;
    _misParticipaciones = [];
    notifyListeners();

    try {
      _misParticipaciones = await RifaApiService.getMisParticipaciones();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoadingMis = false;
      notifyListeners();
    }
  }

  /// Clears state WITHOUT notifying listeners — safe to call from initState().
  void resetSilent() {
    _activeRifa = null;
    _misParticipaciones = [];
    _historialRifas = [];
    _allRifas = [];
    _selectedRifaParticipaciones = [];
    _selectedRifaGanadores = [];
    _isLoadingActive = false;
    _isLoadingMis = false;
    _isLoadingHistorial = false;
    _isLoadingAll = false;
    _isLoadingParticipaciones = false;
    _isLoadingGanadores = false;
    _isLoadingAction = false;
    _errorMessage = null;
  }

  void clearState() {
    _activeRifa = null;
    _misParticipaciones = [];
    _historialRifas = [];
    _allRifas = [];
    _selectedRifaParticipaciones = [];
    _selectedRifaGanadores = [];
    _isLoadingActive = false;
    _isLoadingMis = false;
    _isLoadingHistorial = false;
    _isLoadingAll = false;
    _isLoadingParticipaciones = false;
    _isLoadingGanadores = false;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> loadHistorial() async {
    _isLoadingHistorial = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _historialRifas = await RifaApiService.getHistorial();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoadingHistorial = false;
      notifyListeners();
    }
  }

  // --- Admin Methods ---

  Future<void> loadAllRifas() async {
    _isLoadingAll = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allRifas = await RifaApiService.getAll();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoadingAll = false;
      notifyListeners();
    }
  }

  Future<Rifa?> createRifa(CreateRifaRequest req) async {
    _errorMessage = null;
    notifyListeners();

    try {
      final newRifa = await RifaApiService.create(req);
      await loadAllRifas();
      await loadActiveRifa();
      return newRifa;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  Future<Rifa?> updateRifa(int id, UpdateRifaRequest req) async {
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await RifaApiService.update(id, req);
      await loadAllRifas();
      if (_activeRifa?.id == id) {
        await loadActiveRifa();
      }
      return updated;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  Future<bool> activarRifa(int id) async {
    _errorMessage = null;
    notifyListeners();

    try {
      await RifaApiService.activar(id);
      await loadAllRifas();
      await loadActiveRifa();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> cerrarRifa(int id) async {
    _errorMessage = null;
    notifyListeners();

    try {
      await RifaApiService.cerrar(id);
      await loadAllRifas();
      await loadActiveRifa();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> sortearRifa(int id) async {
    _errorMessage = null;
    notifyListeners();

    try {
      await RifaApiService.sortear(id);
      await loadAllRifas();
      await loadActiveRifa();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelarRifa(int id) async {
    _errorMessage = null;
    notifyListeners();

    try {
      await RifaApiService.cancelar(id);
      await loadAllRifas();
      await loadActiveRifa();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> loadParticipaciones(int rifaId) async {
    _isLoadingParticipaciones = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedRifaParticipaciones = await RifaApiService.getParticipaciones(rifaId);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoadingParticipaciones = false;
      notifyListeners();
    }
  }

  Future<bool> agregarParticipacionManual(int rifaId, int usuarioId) async {
    _errorMessage = null;
    notifyListeners();

    try {
      await RifaApiService.agregarParticipacionManual(
        rifaId,
        AgregarParticipacionManualRequest(usuarioId: usuarioId),
      );
      await loadParticipaciones(rifaId);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> loadGanadores(int rifaId) async {
    _isLoadingGanadores = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedRifaGanadores = await RifaApiService.getGanadores(rifaId);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoadingGanadores = false;
      notifyListeners();
    }
  }

  Future<bool> registrarGanador(int rifaId, int participacionId) async {
    _errorMessage = null;
    notifyListeners();

    try {
      await RifaApiService.registrarGanador(
        rifaId,
        RegistrarGanadorRequest(participacionId: participacionId),
      );
      await loadGanadores(rifaId);
      await loadHistorial();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> actualizarEntrega(int ganadorId, String nuevoEstado, {int? rifaId}) async {
    _errorMessage = null;
    notifyListeners();

    try {
      await RifaApiService.actualizarEntrega(
        ganadorId,
        ActualizarEntregaRequest(estadoEntrega: nuevoEstado),
      );
      if (rifaId != null) {
        await loadGanadores(rifaId);
      }
      await loadHistorial();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
