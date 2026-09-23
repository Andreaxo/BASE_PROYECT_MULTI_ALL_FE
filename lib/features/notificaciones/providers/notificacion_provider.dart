import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notificacion_model.dart';
import '../services/notificacion_service.dart';

class NotificacionProvider extends ChangeNotifier {
  final NotificacionService _service = NotificacionService();

  int _unreadCount = 0;
  List<NotificacionModel> _notificaciones = [];
  bool _isLoading = false;
  Timer? _pollingTimer;

  int get unreadCount => _unreadCount;
  List<NotificacionModel> get notificaciones => _notificaciones;
  bool get isLoading => _isLoading;

  /// Inicia el polling periódico cada 30 segundos (solo activo cuando el usuario es superadmin)
  void startPolling() {
    _pollingTimer?.cancel();
    fetchUnreadCount();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      fetchUnreadCount();
    });
  }

  /// Detiene el polling periódico (ej. al cerrar sesión o cambiar de rol)
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _unreadCount = 0;
    _notificaciones = [];
    notifyListeners();
  }

  /// Actualiza únicamente el conteo de notificaciones no leídas
  Future<void> fetchUnreadCount() async {
    try {
      final count = await _service.getCountNoLeidas();
      if (_unreadCount != count) {
        _unreadCount = count;
        notifyListeners();
      }
    } catch (_) {
      // Manejo silencioso de errores de red en segundo plano
    }
  }

  /// Carga el listado completo de notificaciones recientes
  Future<void> fetchNotificaciones() async {
    _isLoading = true;
    notifyListeners();
    try {
      _notificaciones = await _service.getNotificaciones(limit: 20);
      // Sincronizar unreadCount basado en la respuesta si es posible
      _unreadCount = _notificaciones.where((n) => !n.leido).length;
    } catch (_) {
      _notificaciones = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Marca una notificación individual como leída
  Future<void> marcarComoLeida(int id) async {
    final index = _notificaciones.indexWhere((n) => n.id == id);
    if (index != -1 && !_notificaciones[index].leido) {
      _notificaciones[index] = _notificaciones[index].copyWith(leido: true);
      if (_unreadCount > 0) _unreadCount--;
      notifyListeners();
    }

    try {
      await _service.marcarLeida(id);
    } catch (_) {
      // Revertir en caso de falla crítica si es necesario
    }
  }

  /// Marca todas las notificaciones pendientes como leídas
  Future<void> marcarTodasComoLeidas() async {
    _unreadCount = 0;
    _notificaciones = _notificaciones.map((n) => n.copyWith(leido: true)).toList();
    notifyListeners();

    try {
      await _service.marcarTodasLeidas();
    } catch (_) {
      fetchNotificaciones();
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}
