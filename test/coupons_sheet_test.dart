import 'dart:io';

import 'package:alkirtas/features/shop/widgets/coupons_sheet.dart';
import 'package:alkirtas/providers/coupon_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('coupons_test');
    Hive.init(dir.path);
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(CouponAdapter());
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await Hive.close();
  });

  Future<CouponProvider> seeded(WidgetTester tester, List<Coupon> coupons) async {
    late CouponProvider provider;
    await tester.runAsync(() async {
      final box = await Hive.openBox<Coupon>('couponsBox');
      await box.clear();
      for (final c in coupons) {
        await box.add(c);
      }
      provider = CouponProvider();
      await Future.delayed(const Duration(milliseconds: 200));
    });
    return provider;
  }

  Widget host(CouponProvider p, Widget child) => ChangeNotifierProvider.value(
        value: p,
        child: MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child))),
      );

  final now = DateTime.now();
  final sample = [
    Coupon(id: 1, code: 'SUMMER20', reductionPercent: 20, reductionAmount: 0,
        name: 'Soldes d\'été sur toute la librairie', expiryDate: now.add(const Duration(days: 40))),
    Coupon(id: 2, code: 'WELCOME5', reductionPercent: 0, reductionAmount: 5,
        name: 'Bienvenue', expiryDate: now.add(const Duration(days: 3))),
    Coupon(id: 3, code: 'FREESHIP', reductionPercent: 0, reductionAmount: 0,
        name: '', expiryDate: DateTime(now.year, now.month, now.day, 23, 59, 59)),
  ];

  testWidgets('sheet renders coupons without layout errors', (tester) async {
    final p = await seeded(tester, sample);
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: p,
      child: MaterialApp(home: Builder(builder: (ctx) => Scaffold(
        body: Center(child: ElevatedButton(onPressed: () => showCouponsSheet(ctx), child: const Text('open'))),
      ))),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('SUMMER20'), findsOneWidget);
    expect(find.text('-20%'), findsOneWidget);
    expect(find.text('-5 TND'), findsOneWidget);
    expect(find.text('Expire dans 3 jours'), findsOneWidget);
    expect(find.text('Expire aujourd\'hui'), findsOneWidget);

    // Empty submit shows inline error.
    await tester.tap(find.text('Ajouter'));
    await tester.pump();
    expect(find.text('Saisissez un code promo.'), findsOneWidget);

    // Delete flow with confirmation.
    await tester.tap(find.byTooltip('Supprimer').first);
    await tester.pumpAndSettle();
    // Real async so removeCoupon's Hive writes can complete.
    await tester.runAsync(() async {
      await tester.tap(find.widgetWithText(TextButton, 'Supprimer'));
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();
    expect(find.text('WELCOME5'), findsNothing);
    expect(p.coupons.length, 2);
  });

  testWidgets('empty sheet shows empty state', (tester) async {
    final p = await seeded(tester, []);
    await tester.pumpWidget(host(p, const CouponsSheet()));
    expect(find.text('Aucun coupon pour le moment'), findsOneWidget);
  });

  testWidgets('checkout block selects / deselects and shows savings', (tester) async {
    final p = await seeded(tester, sample);
    await tester.pumpWidget(host(p, const CheckoutCouponBlock(subtotal: 50)));
    expect(find.text('Vous économisez 10.00 TND'), findsOneWidget);
    await tester.tap(find.text('SUMMER20'));
    await tester.pump();
    expect(p.selectedCoupon?.code, 'SUMMER20');
    expect(find.text('Retirer le coupon'), findsOneWidget);
    await tester.tap(find.text('SUMMER20'));
    await tester.pump();
    expect(p.selectedCoupon, isNull);
  });

  test('discountOn is capped at subtotal', () {
    expect(sample[1].discountOn(3), 3);
    expect(sample[0].discountOn(50), 10);
    expect(sample[2].discountOn(50), 0);
  });
}
