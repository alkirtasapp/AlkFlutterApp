import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alkirtas/config/section_artwork.dart';
import 'package:alkirtas/models/home_section.dart';
import 'package:alkirtas/features/authentication/screens/home/editorial/editorial_widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HomeSection department(String title,
          {String? image, String layout = 'auto'}) =>
      HomeSection(
        title: title,
        icon: Icons.school,
        image: image,
        layout: layout,
        tabs: [CategoryTab(name: 'Category', categoryId: 676)],
      );
  test('artwork preserves remote department order and explicit overrides',
      () async {
    final raw = await rootBundle
        .loadString('lib/assets/images/departments/presentation.json');
    final presentation = Map<String, dynamic>.from(json.decode(raw));
    final input = [
      department('Custom'),
      department('Alkirtas Gifts'),
      department('Alkirtas School',
          image: 'https://example.com/custom.jpg', layout: 'shelf')
    ];
    final result = SectionArtwork.applyDefaults(input, presentation);
    expect(result.map((s) => s.title), input.map((s) => s.title));
    expect(identical(result.first, input.first), isTrue);
    expect(result[1].image, 'lib/assets/images/departments/gifts.png');
    expect(result[2].image, 'https://example.com/custom.jpg');
    expect(result[2].layout, 'shelf');
    expect(result[1].tabs.first.categoryId, 676);
    final fun =
        SectionArtwork.applyDefaults([department('Alkirtas Fun')], presentation)
            .first;
    expect(fun.tabs.first.image, 'lib/assets/images/departments/beach.png');
  });
  test('all six supplied images are bundled and decodable', () async {
    for (final name in [
      'school',
      'books',
      'office',
      'gifts',
      'beach',
      'outdoor'
    ]) {
      final bytes =
          await rootBundle.load('lib/assets/images/departments/$name.png');
      final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      expect(frame.image.width, greaterThan(700));
      expect(frame.image.height, greaterThan(700));
      frame.image.dispose();
      codec.dispose();
    }
  });
  testWidgets('supplied campaign photos render under their headlines',
      (tester) async {
    tester.view.physicalSize = const Size(430, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const key = Key('campaign-capture');
    final captions = {
      'school': 'Prêts pour de nouvelles aventures',
      'books': 'Votre prochaine belle histoire',
      'office': 'Un bureau qui inspire',
      'gifts': 'Le plaisir de faire plaisir'
    };
    await tester.runAsync(() async {
      final font = FontLoader('Cairo')
        ..addFont(rootBundle.load('lib/assets/fonts/Cairo-Bold.ttf'));
      await font.load();
    });
    await tester.pumpWidget(MaterialApp(
        theme: ThemeData(fontFamily: 'Cairo'),
        home: Scaffold(
            body: RepaintBoundary(
          key: key,
          child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(children: [
                for (final entry in captions.entries)
                  Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: EditorialCampaign(
                        image: 'lib/assets/images/departments/${entry.key}.png',
                        headline: entry.value,
                        onTap: () {},
                      )),
              ])),
        ))));
    await tester.runAsync(() async {
      final context = tester.element(find.byKey(key));
      for (final name in captions.keys) {
        await precacheImage(
            AssetImage('lib/assets/images/departments/$name.png'), context);
      }
    });
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(Image), findsNWidgets(4));
    if (const bool.fromEnvironment('CAPTURE_SECTION_ARTWORK')) {
      final boundary =
          tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
      await tester.runAsync(() async {
        final capture = await boundary.toImage(pixelRatio: 1.5);
        final bytes = await capture.toByteData(format: ui.ImageByteFormat.png);
        await File('docs/editorial-home/installed-campaigns.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        capture.dispose();
      });
    }
  });
}
