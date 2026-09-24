import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/theme_provider.dart';
import 'legal_constants.dart';

enum LegalTab { terms, privacy, cookies, refunds, company }

class LegalModal extends StatefulWidget {
  final LegalTab initialTab;

  const LegalModal({
    super.key,
    this.initialTab = LegalTab.terms,
  });

  static Future<void> show(
    BuildContext context, {
    LegalTab initialTab = LegalTab.terms,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => LegalModal(initialTab: initialTab),
    );
  }

  @override
  State<LegalModal> createState() => _LegalModalState();
}

class _LegalModalState extends State<LegalModal> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<_TabItem> _tabs = [
    _TabItem(
      label: 'Términos',
      icon: Icons.gavel_rounded,
      title: 'Términos y Condiciones de Uso',
      content: LegalConstants.termsAndConditions,
      tab: LegalTab.terms,
    ),
    _TabItem(
      label: 'Privacidad',
      icon: Icons.shield_rounded,
      title: 'Política de Privacidad y Habeas Data',
      content: LegalConstants.privacyPolicy,
      tab: LegalTab.privacy,
    ),
    _TabItem(
      label: 'Cookies',
      icon: Icons.cookie_rounded,
      title: 'Política de Cookies y Almacenamiento',
      content: LegalConstants.cookiePolicy,
      tab: LegalTab.cookies,
    ),
    _TabItem(
      label: 'Reembolsos',
      icon: Icons.assignment_return_rounded,
      title: 'Política de Reembolsos y Retracto',
      content: LegalConstants.refundPolicy,
      tab: LegalTab.refunds,
    ),
    _TabItem(
      label: 'Empresa',
      icon: Icons.business_rounded,
      title: 'Información Corporativa & SIC',
      content: LegalConstants.businessInfo,
      tab: LegalTab.company,
    ),
  ];

  @override
  void initState() {
    super.initState();
    int initialIndex = _tabs.indexWhere((t) => t.tab == widget.initialTab);
    if (initialIndex < 0) initialIndex = 0;
    _tabController = TabController(length: _tabs.length, vsync: this, initialIndex: initialIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 768;

    final dialogBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final primaryColor = const Color(0xFF3B82F6);

    return Dialog(
      backgroundColor: dialogBg,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 32,
        vertical: isMobile ? 16 : 28,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: borderColor, width: 1),
      ),
      child: Container(
        width: isMobile ? double.infinity : 860,
        height: isMobile ? size.height * 0.90 : 700,
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 760),
        child: Column(
          children: [
            // ── Header ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(bottom: BorderSide(color: borderColor, width: 1)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.verified_user_rounded, color: primaryColor, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Centro Legal y Transparencia',
                          style: GoogleFonts.inter(
                            fontSize: isMobile ? 16 : 18,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        Text(
                          '${LegalConstants.companyName} • NIT: ${LegalConstants.nit}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: textMuted),
                    tooltip: 'Cerrar ventana legal',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // ── Tab Bar ──
            Container(
              decoration: BoxDecoration(
                color: cardBg.withValues(alpha: 0.6),
                border: Border(bottom: BorderSide(color: borderColor, width: 1)),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: primaryColor,
                unselectedLabelColor: textMuted,
                labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                unselectedLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
                indicatorColor: primaryColor,
                indicatorWeight: 2.5,
                tabs: _tabs.map((tab) {
                  return Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(tab.icon, size: 16),
                        const SizedBox(width: 6),
                        Text(tab.label),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            // ── Tab Views (Content) ──
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _tabs.map((tab) {
                  return _buildLegalContent(
                    context,
                    title: tab.title,
                    content: tab.content,
                    isDark: isDark,
                    textColor: textColor,
                    textMuted: textMuted,
                    cardBg: cardBg,
                    borderColor: borderColor,
                    isCompanyTab: tab.tab == LegalTab.company,
                  );
                }).toList(),
              ),
            ),

            // ── Footer with Authority Badge (SIC) ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                border: Border(top: BorderSide(color: borderColor, width: 1)),
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  // SIC Link
                  InkWell(
                    onTap: () => _openUrl(LegalConstants.sicUrl),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.open_in_new_rounded, size: 15, color: primaryColor),
                          const SizedBox(width: 6),
                          Text(
                            'Superintendencia de Industria y Comercio (SIC)',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Close button
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      'Entendido',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalContent(
    BuildContext context, {
    required String title,
    required String content,
    required bool isDark,
    required Color textColor,
    required Color textMuted,
    required Color cardBg,
    required Color borderColor,
    required bool isCompanyTab,
  }) {
    final lines = content.split('\n');

    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...lines.map((line) {
              final trimmed = line.trim();

              if (trimmed.startsWith('# ')) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    trimmed.substring(2),
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                );
              }

              if (trimmed.startsWith('### ')) {
                return Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 6),
                  child: Text(
                    trimmed.substring(4),
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
                    ),
                  ),
                );
              }

              if (trimmed.startsWith('- ')) {
                return Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• ', style: TextStyle(color: textColor, fontSize: 14)),
                      Expanded(
                        child: Text(
                          trimmed.substring(2),
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            height: 1.5,
                            color: textColor.withValues(alpha: 0.90),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (trimmed == '---') {
                return Divider(color: borderColor, height: 24, thickness: 1);
              }

              if (trimmed.isEmpty) {
                return const SizedBox(height: 8);
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  trimmed,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    height: 1.55,
                    color: textColor.withValues(alpha: 0.92),
                  ),
                ),
              );
            }),

            if (isCompanyTab) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF3B82F6).withValues(alpha: 0.3) : const Color(0xFFBFDBFE),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.shield_outlined, color: Color(0xFF3B82F6), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Garantía de Legalidad y Protección al Consumidor',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF1E3A8A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Conexiate opera bajo la razón social ${LegalConstants.companyName} (NIT: ${LegalConstants.nit}) en estricto cumplimiento del Estatuto del Consumidor (Ley 1480 de 2011) y la Ley de Habeas Data (Ley 1581 de 2012) de la República de Colombia.',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        height: 1.5,
                        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF1E40AF),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TabItem {
  final String label;
  final IconData icon;
  final String title;
  final String content;
  final LegalTab tab;

  _TabItem({
    required this.label,
    required this.icon,
    required this.title,
    required this.content,
    required this.tab,
  });
}
