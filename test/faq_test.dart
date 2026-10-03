import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multicliente_app/features/faq/screens/faq_screen.dart';

void main() {
  group('FAQ Tests', () {
    test('FaqItem should correctly instantiate with properties', () {
      const item = FaqItem(
        question: '¿Cómo funciona la membresía?',
        answer: 'Incluye descuentos y rifas exclusivas.',
        category: 'Membresía',
        icon: Icons.star_rounded,
      );

      expect(item.question, '¿Cómo funciona la membresía?');
      expect(item.category, 'Membresía');
      expect(item.icon, Icons.star_rounded);
    });

    test('Filter logic should filter items by search query and category', () {
      final items = [
        const FaqItem(
          question: '¿Qué es Conexiate?',
          answer: 'Plataforma de beneficios.',
          category: 'General',
          icon: Icons.info,
        ),
        const FaqItem(
          question: '¿Cómo participo en las rifas?',
          answer: 'Todos los usuarios registrados participan con sus boletos.',
          category: 'Rifas y Sorteos',
          icon: Icons.casino,
        ),
        const FaqItem(
          question: '¿Qué es el Premio Mayor en rifas?',
          answer: 'Sorteo especial donde los referidos dan más probabilidades.',
          category: 'Rifas y Sorteos',
          icon: Icons.stars,
        ),
      ];

      // Test 1: Category filter
      final rifasOnly = items.where((i) => i.category == 'Rifas y Sorteos').toList();
      expect(rifasOnly.length, 2);

      // Test 2: Search filter
      const query = 'premio mayor';
      final searchResult = items.where((i) {
        return i.question.toLowerCase().contains(query) ||
            i.answer.toLowerCase().contains(query);
      }).toList();

      expect(searchResult.length, 1);
      expect(searchResult.first.question, '¿Qué es el Premio Mayor en rifas?');
    });
  });
}
