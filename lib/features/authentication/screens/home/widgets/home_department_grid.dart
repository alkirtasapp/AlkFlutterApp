import 'package:flutter/material.dart';
import 'package:alkirtas/models/home_section.dart';
import 'package:alkirtas/utils/constants/colors.dart';

/// Compact department navigation, using the same server-managed category tabs.
class HomeDepartmentGrid extends StatelessWidget {
  const HomeDepartmentGrid(
      {super.key, required this.sections, required this.onCategorySelected});
  final List<HomeSection> sections;
  final void Function(HomeSection section, CategoryTab category)
      onCategorySelected;

  void _openDepartment(BuildContext context, HomeSection section) {
    if (section.tabs.length == 1) {
      onCategorySelected(section, section.tabs.first);
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(
              leading: Icon(section.icon, color: AlkColors.AppFirstColor),
              title: Text(section.title,
                  style: Theme.of(context).textTheme.titleLarge),
              subtitle: const Text('Choisissez une catégorie'),
            ),
            Flexible(
                child: ListView(shrinkWrap: true, children: [
              for (final category in section.tabs)
                ListTile(
                  title: Text(category.name.trim()),
                  trailing: const Icon(Icons.arrow_forward_rounded, size: 19),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    onCategorySelected(section, category);
                  },
                ),
            ])),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final departments =
        sections.where((section) => section.tabs.isNotEmpty).toList();
    const accents = [
      Color(0xFF5365C7),
      Color(0xFFD48236),
      Color(0xFF318777),
      Color(0xFF547B94),
      Color(0xFFB85A80)
    ];
    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth >= 650 ? 3 : 2;
      final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
      return Wrap(spacing: 12, runSpacing: 12, children: [
        for (var i = 0; i < departments.length; i++)
          SizedBox(
            width: width,
            child: Material(
              color: accents[i % accents.length].withOpacity(0.09),
              borderRadius: BorderRadius.circular(20),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _openDepartment(context, departments[i]),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.85),
                                    borderRadius: BorderRadius.circular(14)),
                                child: Icon(departments[i].icon,
                                    color: accents[i % accents.length],
                                    size: 30),
                              ),
                              Icon(Icons.north_east_rounded,
                                  color: accents[i % accents.length], size: 19),
                            ]),
                        const SizedBox(height: 16),
                        Text(
                            departments[i].title.replaceFirst(
                                RegExp(r'^Alkirtas\s+', caseSensitive: false),
                                ''),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(
                            departments[i]
                                .tabs
                                .take(2)
                                .map((tab) => tab.name.trim())
                                .join(' · '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(height: 1.4)),
                      ]),
                ),
              ),
            ),
          ),
      ]);
    });
  }
}
