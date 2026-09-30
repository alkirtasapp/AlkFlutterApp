import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alkirtas/data/controllers/low_stock_service.dart';

void main() {
  group('LowStockBadge.fromJson', () {
    test('parses a full badge payload from the module', () {
      final badge = LowStockBadge.fromJson({
        'id_product': 52929,
        'quantity': 2,
        'threshold': 3,
        'message': 'Reste 2 piece(s) en stock',
        'bg': '#0802a3',
        'fg': '#ffffff',
      });

      expect(badge, isNotNull);
      expect(badge!.quantity, 2);
      expect(badge.message, 'Reste 2 piece(s) en stock');
      expect(badge.background, const Color(0xFF0802A3));
      expect(badge.foreground, const Color(0xFFFFFFFF));
    });

    test('accepts numeric fields sent as strings', () {
      final badge = LowStockBadge.fromJson({
        'quantity': '4',
        'message': 'Plus que 4',
        'bg': '#DC143C',
        'fg': '#1c1c1e',
      });

      expect(badge!.quantity, 4);
      expect(badge.background, const Color(0xFFDC143C));
      expect(badge.foreground, const Color(0xFF1C1C1E));
    });

    test('expands three-digit hex colours', () {
      final badge = LowStockBadge.fromJson({
        'quantity': 1,
        'message': 'Dernier',
        'bg': '#f00',
        'fg': '#fff',
      });

      expect(badge!.background, const Color(0xFFFF0000));
      expect(badge.foreground, const Color(0xFFFFFFFF));
    });

    test('tolerates a hex colour with no leading hash', () {
      final badge = LowStockBadge.fromJson({
        'quantity': 1,
        'message': 'Dernier',
        'bg': '00ff00',
      });

      expect(badge!.background, const Color(0xFF00FF00));
    });

    test('falls back to module defaults when colours are missing or invalid', () {
      final badge = LowStockBadge.fromJson({
        'quantity': 3,
        'message': 'Stock faible',
        'bg': 'not-a-colour',
      });

      // Same default as the module's DEFAULT_COLOR, white text.
      expect(badge!.background, const Color(0xFF0802A3));
      expect(badge.foreground, Colors.white);
    });

    test('returns null when the message is empty, so nothing renders', () {
      expect(
        LowStockBadge.fromJson({'quantity': 2, 'message': '', 'bg': '#0802a3'}),
        isNull,
      );
      expect(
        LowStockBadge.fromJson({'quantity': 2, 'bg': '#0802a3'}),
        isNull,
      );
    });

    test('defaults quantity to 0 when absent rather than throwing', () {
      final badge = LowStockBadge.fromJson({'message': 'Stock faible'});
      expect(badge!.quantity, 0);
    });
  });
}
