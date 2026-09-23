import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/notificacion_model.dart';
import '../providers/notificacion_provider.dart';

class NotificacionBell extends StatefulWidget {
  const NotificacionBell({super.key});

  @override
  State<NotificacionBell> createState() => _NotificacionBellState();
}

class _NotificacionBellState extends State<NotificacionBell> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    final provider = context.read<NotificacionProvider>();
    provider.fetchNotificaciones();

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) {
      setState(() => _isOpen = false);
    }
  }

  OverlayEntry _createOverlayEntry() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          // Dismiss area
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _closeDropdown,
            ),
          ),
          Positioned(
            width: 380,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: const Offset(-330, 48),
              child: Material(
                elevation: 12,
                borderRadius: BorderRadius.circular(16),
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                shadowColor: Colors.black.withValues(alpha: 0.25),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  constraints: const BoxConstraints(maxHeight: 480),
                  child: Consumer<NotificacionProvider>(
                    builder: (context, provider, _) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Dropdown Header
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.notifications_active, size: 20, color: Color(0xFF2563EB)),
                                const SizedBox(width: 8),
                                const Text(
                                  'Notificaciones',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const Spacer(),
                                if (provider.unreadCount > 0)
                                  TextButton(
                                    onPressed: () => provider.marcarTodasComoLeidas(),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      'Marcar leídas',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Content
                          if (provider.isLoading)
                            const Padding(
                              padding: EdgeInsets.all(32),
                              child: Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            )
                          else if (provider.notificaciones.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(36),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.notifications_none,
                                    size: 40,
                                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No tienes notificaciones pendientes',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Flexible(
                              child: ListView.separated(
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                itemCount: provider.notificaciones.length,
                                separatorBuilder: (_, __) => Divider(
                                  height: 1,
                                  color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                                ),
                                itemBuilder: (context, index) {
                                  final notif = provider.notificaciones[index];
                                  return _NotificationItem(
                                    notificacion: notif,
                                    isDark: isDark,
                                    onTap: () {
                                      if (!notif.leido) {
                                        provider.marcarComoLeida(notif.id);
                                      }
                                    },
                                  );
                                },
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _closeDropdown();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Consumer<NotificacionProvider>(
        builder: (context, provider, _) {
          final unread = provider.unreadCount;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: Icon(
                  _isOpen ? Icons.notifications : Icons.notifications_outlined,
                  size: 22,
                ),
                tooltip: 'Notificaciones',
                onPressed: _toggleDropdown,
              ),
              if (unread > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      unread > 99 ? '99+' : '$unread',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final NotificacionModel notificacion;
  final bool isDark;
  final VoidCallback onTap;

  const _NotificationItem({
    required this.notificacion,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isAprobado = notificacion.tipo == 'pago_membresia_aprobado';
    final iconColor = isAprobado ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final iconBgColor = isAprobado
        ? (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.4) : const Color(0xFFD1FAE5))
        : (isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.4) : const Color(0xFFFEE2E2));
    final icon = isAprobado ? Icons.check_circle_outline : Icons.error_outline;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: !notificacion.leido
            ? (isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.15) : const Color(0xFFEFF6FF))
            : Colors.transparent,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notificacion.titulo,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: notificacion.leido ? FontWeight.w500 : FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notificacion.mensaje,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : const Color(0xFF475569),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatTime(notificacion.createAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.grey[500] : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            if (!notificacion.leido)
              Container(
                margin: const EdgeInsets.only(top: 4, left: 6),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF2563EB),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Hace un momento';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} m';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} d';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
