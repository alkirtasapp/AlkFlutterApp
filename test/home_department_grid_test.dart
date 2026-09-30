import 'package:alkirtas/features/authentication/screens/home/widgets/home_department_grid.dart';
import 'package:alkirtas/models/home_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final school =
      HomeSection(title: 'Alkirtas School', icon: Icons.school, tabs: [
    CategoryTab(name: 'Sac à Dos', categoryId: 290),
    CategoryTab(name: 'Fournitures Scolaires', categoryId: 524),
  ]);
  for (final width in [320.0, 800.0]) {
    testWidgets(
        'departments fit width $width and navigate to the selected category',
        (tester) async {
      tester.view.resetPhysicalSize();
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      int? selected;
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: SingleChildScrollView(
        child: Padding(
            padding: const EdgeInsets.all(16),
            child: HomeDepartmentGrid(
              sections: [
                school,
                HomeSection(
                    title: 'Alkirtas Gifts',
                    icon: Icons.card_giftcard,
                    tabs: [CategoryTab(name: 'Idées cadeaux', categoryId: 838)])
              ],
              onCategorySelected: (_, category) =>
                  selected = category.categoryId,
            )),
      ))));
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('School'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.widgetWithText(ListTile, 'Fournitures Scolaires'));
      await tester.pumpAndSettle();
      expect(selected, 524);
      expect(find.text('Choisissez une catégorie'), findsNothing);
      await tester.tap(find.text('Gifts'));
      await tester.pumpAndSettle();
      expect(selected, 838);
      expect(tester.takeException(), isNull);
    });
  }
}
