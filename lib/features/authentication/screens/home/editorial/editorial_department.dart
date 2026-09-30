import 'package:flutter/material.dart';
import 'package:alkirtas/models/home_section.dart';
import 'package:alkirtas/utils/constants/colors.dart';
import 'editorial_product.dart';
import 'editorial_repository.dart';
import 'editorial_widgets.dart';

String resolveEditorialLayout(HomeSection section, int index) {
  const layouts = ['products', 'discovery', 'shelf', 'campaign', 'campaign'];
  return layouts.contains(section.layout)
      ? section.layout
      : layouts[index % layouts.length];
}

class EditorialDepartment extends StatefulWidget {
  const EditorialDepartment(
      {super.key,
      required this.section,
      required this.index,
      required this.repository,
      required this.onCategory});
  final HomeSection section;
  final int index;
  final EditorialRepository repository;
  final void Function(int id, String name) onCategory;
  @override
  State<EditorialDepartment> createState() => _EditorialDepartmentState();
}

class _EditorialDepartmentState extends State<EditorialDepartment> {
  int _selected = 0;
  @override
  void didUpdateWidget(covariant EditorialDepartment oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.section != widget.section) _selected = 0;
  }

  void _openDepartment() {
    final section = widget.section;
    if (section.categoryId != null) {
      widget.onCategory(section.categoryId!, section.title);
      return;
    }
    if (section.tabs.length == 1) {
      widget.onCategory(section.tabs.first.categoryId, section.tabs.first.name);
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheet) => SafeArea(
          child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(section.title, style: editorialTitle(context)),
          const SizedBox(height: 12),
          Flexible(
              child: ListView(shrinkWrap: true, children: [
            for (final tab in section.tabs)
              ListTile(
                title: Text(tab.name.trim()),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () {
                  Navigator.pop(sheet);
                  widget.onCategory(tab.categoryId, tab.name.trim());
                },
              ),
          ])),
        ]),
      )),
    );
  }

  Widget _chips() => SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: widget.section.tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => ChoiceChip(
          label: Text(widget.section.tabs[i].name.trim()),
          selected: _selected == i,
          onSelected: (_) => setState(() => _selected = i),
          showCheckmark: false,
          selectedColor: AlkColors.AppFirstColor.withOpacity(0.12),
          backgroundColor: editorialPaper(context),
          side: BorderSide.none,
          labelStyle: TextStyle(
              fontSize: 12,
              color: _selected == i
                  ? AlkColors.AppFirstColor
                  : editorialInk(context)),
          shape: const StadiumBorder(),
        ),
      ));

  Widget _products({bool narrow = false}) {
    final tab = widget.section.tabs[_selected];
    return FutureBuilder<List<EditorialProduct>>(
      key: ValueKey(tab.categoryId),
      future: widget.repository.category(tab.categoryId),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return SizedBox(
              height: narrow ? 260 : 290,
              child: Row(children: [
                for (var i = 0; i < 2; i++)
                  Expanded(
                      child: Container(
                          margin: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                              color: editorialPaper(context),
                              borderRadius: BorderRadius.circular(16)))),
              ]));
        }
        final products = snapshot.data ?? [];
        if (products.isEmpty) {
          return Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () =>
                    widget.onCategory(tab.categoryId, tab.name.trim()),
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: Text('Explorer ${tab.name.trim()}'),
              ));
        }
        return EditorialProductShelf(products: products, narrow: narrow);
      },
    );
  }

  Widget _campaign() {
    final section = widget.section;
    final background = int.tryParse(
        (section.backgroundColor ?? '').replaceFirst('#', ''),
        radix: 16);
    return FutureBuilder<List<EditorialProduct>>(
      future: widget.repository.category(section.tabs[_selected].categoryId),
      builder: (context, snapshot) => EditorialCampaign(
        image: section.image ?? '',
        fallbackImage: (snapshot.data?.isNotEmpty ?? false)
            ? snapshot.data!.first.imageUrl
            : '',
        headline: section.headline ?? 'Des idées à découvrir',
        background: background == null
            ? const Color(0xFFF0E4DA)
            : Color(0xFF000000 | background),
        icon: section.icon,
        onTap: _openDepartment,
      ),
    );
  }

  Widget _discovery() => LayoutBuilder(builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
        return SizedBox(
          height: 250 + (scale - 1).clamp(0, 2) * 65,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: widget.section.tabs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final tab = widget.section.tabs[index];
              return SizedBox(
                width: (constraints.maxWidth / 2.06).clamp(140.0, 240.0),
                child: FutureBuilder<List<EditorialProduct>>(
                  future: widget.repository.category(tab.categoryId),
                  builder: (context, snapshot) {
                    final fallback = (snapshot.data?.isNotEmpty ?? false)
                        ? snapshot.data!.first.imageUrl
                        : '';
                    return Material(
                      color: editorialPaper(context),
                      borderRadius: BorderRadius.circular(16),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                          onTap: () => widget.onCategory(
                              tab.categoryId, tab.name.trim()),
                          child: Stack(fit: StackFit.expand, children: [
                            EditorialImage(
                                url: tab.image ?? '',
                                fallbackUrl: fallback,
                                icon: widget.section.icon),
                            const DecoratedBox(
                                decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                  Colors.transparent,
                                  Color(0xB322211F)
                                ],
                                        stops: [
                                  0.4,
                                  1
                                ]))),
                            Positioned(
                                left: 14,
                                right: 14,
                                bottom: 16,
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(tab.name.trim(),
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 19,
                                              height: 1.2,
                                              fontWeight: FontWeight.w700)),
                                      const SizedBox(height: 8),
                                      const Text('Découvrir  →',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12)),
                                    ])),
                          ])),
                    );
                  },
                ),
              );
            },
          ),
        );
      });

  @override
  Widget build(BuildContext context) {
    final section = widget.section;
    if (section.tabs.isEmpty) return const SizedBox.shrink();
    final layout = resolveEditorialLayout(section, widget.index);
    final hasCampaign = layout != 'discovery' &&
        (layout == 'campaign' || (section.image?.trim().isNotEmpty ?? false));
    return Padding(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
                child: Text(section.title, style: editorialTitle(context))),
            TextButton(
                onPressed: _openDepartment, child: const Text('Tout voir →')),
          ]),
          if (section.headline != null && !hasCampaign) ...[
            Text(section.headline!,
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
          ],
          if (layout == 'discovery') ...[
            const SizedBox(height: 8),
            _discovery(),
            const SizedBox(height: 16),
            _products(narrow: true),
          ] else ...[
            if (hasCampaign) ...[
              const SizedBox(height: 8),
              _campaign(),
              const SizedBox(height: 14),
            ],
            if (section.tabs.length > 1) ...[
              _chips(),
              const SizedBox(height: 12)
            ],
            _products(narrow: layout == 'shelf'),
          ],
        ]));
  }
}
