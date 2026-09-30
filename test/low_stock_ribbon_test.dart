import 'package:alkirtas/common/widgets/products/low_stock_ribbon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('an absent badge does not collapse a positioned product image',
      (tester) async {
    const imageKey = Key('product-image');
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 300,
          child: Column(
            children: [
              SizedBox(
                height: 240,
                child: Stack(
                  children: [
                    Positioned.fill(
                        child: ColoredBox(key: imageKey, color: Colors.blue)),
                    LowStockRibbon(
                        productId: '0', variant: LowStockRibbonVariant.cover),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ));
    expect(tester.getSize(find.byKey(imageKey)), const Size(300, 240));
    await tester.pump();
    expect(tester.getSize(find.byKey(imageKey)), const Size(300, 240));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'removing a ribbon without a badge does not create a ticker during disposal',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Stack(children: [LowStockRibbon(productId: '0')]),
      ),
    ));
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });
}
