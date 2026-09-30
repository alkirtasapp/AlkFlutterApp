import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alkirtas/models/home_section.dart';
import 'package:alkirtas/features/authentication/screens/home/editorial/editorial_department.dart';
import 'package:alkirtas/features/authentication/screens/home/editorial/editorial_home.dart';
import 'package:alkirtas/features/authentication/screens/home/editorial/editorial_product.dart';
import 'package:alkirtas/features/authentication/screens/home/editorial/editorial_repository.dart';
import 'package:alkirtas/features/authentication/screens/home/editorial/editorial_widgets.dart';

EditorialProduct product(String id, {int stock = 3}) => EditorialProduct(
      id: id,
      name: 'Une belle sélection pour toutes les envies',
      brand: 'Alkirtas',
      brandId: '1',
      reference: 'REF',
      description: '',
      stock: stock,
      imageUrl: '',
      imageUrls: [],
      discountText: '20%',
      oldPrice: '50.00',
      newPrice: '40.00',
    );

class FixtureRepository extends EditorialRepository {
  FixtureRepository(this.items);
  final List<HomeSection> items;
  final List<int> requested = [];
  @override
  Future<List<HomeSection>> sections() async => items;
  @override
  Future<List<EditorialProduct>> deals() async => [];
  @override
  Future<List<EditorialProduct>> category(int id) async {
    requested.add(id);
    return [product('$id'), product('${id + 1}')];
  }
}

HomeSection section(String layout, {String title = 'Un nouvel univers'}) =>
    HomeSection(
      title: title,
      icon: Icons.shopping_bag_outlined,
      layout: layout,
      headline: 'Des idées pour toutes vos envies',
      tabs: [
        CategoryTab(name: 'Première sélection', categoryId: 290),
        CategoryTab(name: 'Autres idées', categoryId: 293)
      ],
    );

void main() {
  test(
      'old configuration remains valid and optional image/layout fields survive caching',
      () {
    final old = HomeSection.fromJson({
      'title': 'Custom',
      'icon': 'gift',
      'tabs': [
        {'name': 'A', 'categoryId': 4}
      ]
    });
    expect(old.layout, 'auto');
    final configured = HomeSection.fromJson({
      ...old.toJson(),
      'layout': 'discovery',
      'image': 'https://example.com/hero.jpg',
      'headline': 'Discover',
      'backgroundColor': '#ABCDEF',
      'categoryId': 30,
      'tabs': [
        {'name': 'A', 'categoryId': 4, 'image': 'https://example.com/a.jpg'}
      ]
    });
    final roundtrip = HomeSection.fromJson(configured.toJson());
    expect(roundtrip.image, configured.image);
    expect(roundtrip.tabs.first.image, configured.tabs.first.image);
    expect(roundtrip.categoryId, 30);
    expect(resolveEditorialLayout(roundtrip, 99), 'discovery');
    expect(resolveEditorialLayout(section('unknown'), 0), 'products');
  });

  for (final layout in ['products', 'discovery', 'shelf', 'campaign']) {
    for (final width in [320.0, 800.0]) {
      testWidgets(
          '$layout works at $width with enlarged text and image fallbacks',
          (tester) async {
        tester.view.physicalSize = Size(width, 1100);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final config = section(layout);
        final repo = FixtureRepository([config]);
        int? destination;
        await tester.pumpWidget(GetMaterialApp(
            home: MediaQuery(
          data: MediaQueryData(
              size: Size(width, 1100),
              textScaler: const TextScaler.linear(1.5)),
          child: Scaffold(
              body: SingleChildScrollView(
                  child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: EditorialDepartment(
                        section: config,
                        index: 0,
                        repository: repo,
                        onCategory: (id, _) => destination = id,
                      )))),
        )));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Tout voir →'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(ListTile, 'Autres idées'));
        await tester.pumpAndSettle();
        expect(destination, 293);
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets(
      'config order is preserved and category chips load their own products',
      (tester) async {
    final items = [
      section('products', title: 'First from config'),
      section('campaign', title: 'Second from config')
    ];
    final repo = FixtureRepository(items);
    await tester.pumpWidget(GetMaterialApp(
        home: EditorialHomeScreen(
            repository: repo,
            showCartCounter: false,
            onCategory: (_, __) {},
            onCart: () {},
            onMenu: () {})));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final departments = tester
        .widgetList<EditorialDepartment>(find.byType(EditorialDepartment))
        .toList();
    expect(departments.map((widget) => widget.section.title),
        ['First from config', 'Second from config']);
    await tester
        .ensureVisible(find.widgetWithText(ChoiceChip, 'Autres idées').first);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Autres idées').first);
    await tester.pumpAndSettle();
    expect(repo.requested, contains(293));
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'quick add is disabled for sold-out products and enabled for stock',
      (tester) async {
    var added = false;
    Future<void> render(int stock) async {
      await tester.pumpWidget(GetMaterialApp(
          home: Scaffold(
              body: SizedBox(
                  width: 180,
                  height: 310,
                  child: EditorialProductCard(
                      product: product('1', stock: stock),
                      onOpen: () {},
                      onAdd: () => added = true)))));
      await tester.pumpAndSettle();
    }

    await render(0);
    expect(
        tester.widget<IconButton>(find.byType(IconButton)).onPressed, isNull);
    await render(3);
    await tester.tap(find.byIcon(Icons.add));
    expect(added, isTrue);
    expect(tester.takeException(), isNull);
  });
}
