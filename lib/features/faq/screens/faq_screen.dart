import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

class FaqItem {
  final String question;
  final String answer;
  final String category;
  final IconData icon;

  const FaqItem({
    required this.question,
    required this.answer,
    required this.category,
    required this.icon,
  });
}

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Todos';

  final List<String> _categories = [
    'Todos',
    'General',
    'Membresía',
    'Beneficios',
    'Rifas y Sorteos',
    'Referidos',
    'Negocios Aliados',
  ];

  final List<FaqItem> _faqList = const [
    FaqItem(
      category: 'General',
      icon: Icons.info_outline_rounded,
      question: '¿Qué es Conexiate y cómo funciona?',
      answer:
          'Conexiate es una plataforma integral de beneficios, bienestar y fidelización que conecta a personas y familias con una amplia red de comercios y negocios aliados. Como miembro accedes a descuentos exclusivos, cupones, promociones especiales y participación en rifas y sorteos periódicos.',
    ),
    FaqItem(
      category: 'General',
      icon: Icons.person_add_alt_1_rounded,
      question: '¿Cómo me registro en la plataforma?',
      answer:
          'Puedes registrarte fácilmente desde la pantalla principal en la pestaña "Registrarse". Solo necesitas ingresar tu nombre, correo electrónico y una contraseña segura. Si fuiste invitado por un amigo o perteneces a una empresa aliada, puedes ingresar su código o NIT para disfrutar de beneficios adicionales.',
    ),
    FaqItem(
      category: 'Membresía',
      icon: Icons.card_membership_rounded,
      question: '¿Cuánto cuesta la membresía y qué incluye?',
      answer:
          'La membresía Conexiate tiene una tarifa accesible de suscripción mensual que te da acceso inmediato a todos los descuentos y promociones en comercios aliados, redención de beneficios sin límites, acumulación de puntos por referidos y derecho a reclamar los premios en rifas y sorteos.',
    ),
    FaqItem(
      category: 'Membresía',
      icon: Icons.payment_rounded,
      question: '¿Cuáles son los métodos de pago disponibles?',
      answer:
          'A través de nuestra pasarela segura Wompi (Bancolombia), puedes realizar tu pago mediante tarjetas de crédito o débito (Visa, Mastercard, American Express), transferencias PSE con cualquier banco o billetera digital como Nequi y Daviplata.',
    ),
    FaqItem(
      category: 'Beneficios',
      icon: Icons.local_offer_rounded,
      question: '¿Cómo redimo un beneficio en un comercio aliado?',
      answer:
          'Ingresa a la sección "Beneficios", selecciona la promoción que deseas y presiona "Redimir". La plataforma generará un código único con QR que podrás mostrar directamente en el establecimiento aliado para que sea validado y se aplique tu descuento.',
    ),
    FaqItem(
      category: 'Beneficios',
      icon: Icons.store_rounded,
      question: '¿Por qué no veo los beneficios de algún comercio?',
      answer:
          'Para garantizar una experiencia confiable y de calidad, la plataforma desactiva automáticamente los beneficios de aquellos comercios que no tengan su membresía o suscripción al día. En cuanto el comercio regularice su suscripción, sus beneficios vuelven a estar activos para todos los usuarios.',
    ),
    FaqItem(
      category: 'Rifas y Sorteos',
      icon: Icons.confirmation_number_rounded,
      question: '¿Quiénes pueden participar en las rifas?',
      answer:
          '¡Todos los usuarios registrados en Conexiate están automáticamente incluidos en los sorteos con al menos un boleto base! La participación está abierta a todos los miembros de la comunidad sin costo adicional.',
    ),
    FaqItem(
      category: 'Rifas y Sorteos',
      icon: Icons.emoji_events_rounded,
      question: '¿Cuál es el requisito indispensable para reclamar un premio?',
      answer:
          'Aunque todos los usuarios participan en la rifa, es requisito INDISPENSABLE tener tu membresía activa y al día al momento del sorteo para poder hacerte acreedor del premio y que sea entregado oficialmente.',
    ),
    FaqItem(
      category: 'Rifas y Sorteos',
      icon: Icons.stars_rounded,
      question: '¿Qué es un "Premio Mayor" y cómo aumentan mis posibilidades?',
      answer:
          'Cuando un sorteo es catalogado como "Premio Mayor", los usuarios que inviten a más personas mediante su código de referido obtienen mayores probabilidades de ganar. Cada referido registrado durante ese periodo de juego suma boletos y oportunidades adicionales para el participante. En sorteos estándar, todos los participantes tienen exactamente la misma probabilidad.',
    ),
    FaqItem(
      category: 'Rifas y Sorteos',
      icon: Icons.shuffle_rounded,
      question: '¿Cómo se garantiza que el sorteo sea 100% aleatorio y transparente?',
      answer:
          'La selección del ganador se realiza mediante un algoritmo criptográficamente aleatorio certificado y se proyecta a través de una animación de ruleta/tómbola en tiempo real, garantizando total transparencia e imparcialidad para toda la comunidad.',
    ),
    FaqItem(
      category: 'Referidos',
      icon: Icons.group_add_rounded,
      question: '¿Cómo funciona el sistema de referidos?',
      answer:
          'En tu perfil encontrarás tu Código Único de Referido. Puedes compartirlo con amigos, familiares y conocidos. Cada vez que una persona se registre y active su membresía con tu código, sumarás beneficios, oportunidades adicionales en rifas de Premios Mayores y recompensas del programa.',
    ),
    FaqItem(
      category: 'Negocios Aliados',
      icon: Icons.business_center_rounded,
      question: '¿Cómo puede una empresa vincular y referir a sus empleados?',
      answer:
          'Las empresas aliadas cuentan con un NIT y un código corporativo. Al momento de que un empleado se registre ingresando el NIT de la empresa, queda automáticamente agrupado dentro del convenio de la empresa, lo que permite a la compañía caracterizar su impacto y brindar bienestar a su equipo de trabajo.',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppTheme.darkThemeColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredFaqs = _faqList.where((item) {
      final matchesCat =
          _selectedCategory == 'Todos' || item.category == _selectedCategory;
      if (!matchesCat) return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesQuery = item.question.toLowerCase().contains(q) ||
            item.answer.toLowerCase().contains(q);
        if (!matchesQuery) return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0C29) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: themeColors.cardBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: themeColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Volver',
        ),
        title: Text(
          'Preguntas Frecuentes',
          style: GoogleFonts.outfit(
            color: themeColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Hero Banner ──
                Container(
                  padding: const EdgeInsets.all(26),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF3B82F6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6C63FF).withValues(alpha: 0.28),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.help_outline_rounded,
                          size: 34,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Centro de Ayuda y Preguntas',
                              style: GoogleFonts.outfit(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Encuentra respuestas claras y rápidas sobre membresías, beneficios, sorteos y comercios aliados.',
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                color: Colors.white.withValues(alpha: 0.9),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Search Input ──
                Container(
                  decoration: BoxDecoration(
                    color: themeColors.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: themeColors.borderColor.withValues(alpha: 0.6),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    style: GoogleFonts.inter(color: themeColors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Buscar duda o palabra clave (ej: rifas, pago, referidos)...',
                      hintStyle: GoogleFonts.inter(color: themeColors.textSecondary),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.accent),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Categories Bar ──
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _selectedCategory = cat),
                          backgroundColor: themeColors.cardBackground,
                          selectedColor: AppColors.primary.withValues(alpha: 0.2),
                          checkmarkColor: AppColors.accent,
                          labelStyle: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? AppColors.accent : themeColors.textSecondary,
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.primary
                                : themeColors.borderColor.withValues(alpha: 0.5),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),

                // ── FAQ Accordion List ──
                if (filteredFaqs.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(40),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: themeColors.cardBackground,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: themeColors.borderColor),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 48,
                          color: themeColors.textSecondary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No se encontraron respuestas para tu búsqueda',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: themeColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Intenta con términos más generales o selecciona otra categoría.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: themeColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredFaqs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final faq = filteredFaqs[index];
                      return Material(
                        color: themeColors.cardBackground,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: themeColors.borderColor.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            dividerColor: Colors.transparent,
                          ),
                          child: ExpansionTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(faq.icon, color: AppColors.accent, size: 20),
                            ),
                            title: Text(
                              faq.question,
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: themeColors.textPrimary,
                              ),
                            ),
                            iconColor: AppColors.accent,
                            collapsedIconColor: themeColors.textSecondary,
                            childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                            children: [
                              Text(
                                faq.answer,
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  color: themeColors.textPrimary.withValues(alpha: 0.85),
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 36),

                // ── Footer CTA: Volver al Login ──
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('Volver al Inicio de Sesión'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 3,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
