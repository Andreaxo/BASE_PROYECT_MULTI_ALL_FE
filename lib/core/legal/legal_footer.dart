import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/theme_provider.dart';
import 'legal_constants.dart';
import 'legal_modal.dart';

class LegalFooter extends StatelessWidget {
  final bool compact;

  const LegalFooter({
    super.key,
    this.compact = false,
  });

  Future<void> _openSic() async {
    final uri = Uri.parse(LegalConstants.sicUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final linkColor = isDark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: compact ? 12 : 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Links Row
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildLink(
                context,
                label: 'Términos y Condiciones',
                onTap: () => LegalModal.show(context, initialTab: LegalTab.terms),
                linkColor: linkColor,
              ),
              _buildSeparator(textMuted),
              _buildLink(
                context,
                label: 'Política de Privacidad',
                onTap: () => LegalModal.show(context, initialTab: LegalTab.privacy),
                linkColor: linkColor,
              ),
              _buildSeparator(textMuted),
              _buildLink(
                context,
                label: 'Política de Cookies',
                onTap: () => LegalModal.show(context, initialTab: LegalTab.cookies),
                linkColor: linkColor,
              ),
              _buildSeparator(textMuted),
              _buildLink(
                context,
                label: 'Reembolsos y Retracto',
                onTap: () => LegalModal.show(context, initialTab: LegalTab.refunds),
                linkColor: linkColor,
              ),
              _buildSeparator(textMuted),
              _buildLink(
                context,
                label: 'Datos del Negocio',
                onTap: () => LegalModal.show(context, initialTab: LegalTab.company),
                linkColor: linkColor,
              ),
              _buildSeparator(textMuted),
              // SIC Official Link (Obligatorio Ley 1480 Art. 50)
              InkWell(
                onTap: _openSic,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.open_in_new_rounded, size: 12, color: linkColor),
                      const SizedBox(width: 4),
                      Text(
                        'Superintendencia de Industria y Comercio (SIC)',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: linkColor,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Business Information & Copyright
          Text(
            '${LegalConstants.brandName} es operado por ${LegalConstants.companyName} • NIT: ${LegalConstants.nit} • ${LegalConstants.address}',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Atención al Consumidor: ${LegalConstants.contactEmail} | Tel/WhatsApp: ${LegalConstants.contactPhone}',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: FontWeight.w400,
              color: textMuted.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLink(
    BuildContext context, {
    required String label,
    required VoidCallback onTap,
    required Color linkColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: linkColor,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }

  Widget _buildSeparator(Color color) {
    return Text(
      '•',
      style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.6)),
    );
  }
}
