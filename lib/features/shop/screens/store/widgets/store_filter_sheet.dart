import 'dart:async';

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../controllers/store_controller.dart';
import '../models/store_filter_state.dart';
import '../../../../../utils/constants/colors.dart';

/// Debounce window between a checkbox toggle and the facet refresh request.
/// Short enough to feel responsive, long enough to coalesce rapid clicks.
const Duration _kFacetRefreshDebounce = Duration(milliseconds: 300);

/// Show the filter bottom sheet for the active store category.
Future<void> showStoreFilterSheet(BuildContext context) {
  final controller = context.read<StoreController>();

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => ChangeNotifierProvider.value(
      value: controller,
      child: const _StoreFilterSheet(),
    ),
  );
}

class _StoreFilterSheet extends StatefulWidget {
  const _StoreFilterSheet();

  @override
  State<_StoreFilterSheet> createState() => _StoreFilterSheetState();
}

class _StoreFilterSheetState extends State<_StoreFilterSheet> {
  late StoreFilterState _draft;
  Timer? _debounce;

  // UI-only state
  RangeValues? _priceRange;
  bool _showAllManufacturers = false;
  final Map<int, bool> _showAllFeatureValues = {};

  @override
  void initState() {
    super.initState();
    _draft = context.read<StoreController>().activeFilter;
    // Always refresh on open so counts reflect the currently-applied filter
    // (and not stale data from a previous category or session).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<StoreController>().loadFacets(withFilter: _draft);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  /// Schedule a debounced facet refresh that respects the current draft + price range.
  void _scheduleRefresh() {
    _debounce?.cancel();
    _debounce = Timer(_kFacetRefreshDebounce, () {
      if (!mounted) return;
      context.read<StoreController>().loadFacets(withFilter: _draftWithPrice());
    });
  }

  /// Bake the in-progress price slider value into the draft so server-side
  /// facet counts reflect the user's chosen price range.
  StoreFilterState _draftWithPrice() {
    final facets = context.read<StoreController>().availableFacets;
    if (facets == null || _priceRange == null) return _draft;
    final atDefault = _priceRange!.start <= facets.priceMin &&
        _priceRange!.end >= facets.priceMax;
    return _draft.copyWith(
      priceMin: atDefault ? null : _priceRange!.start,
      priceMax: atDefault ? null : _priceRange!.end,
      clearPriceMin: atDefault,
      clearPriceMax: atDefault,
    );
  }

  /// Make sure _priceRange is non-null and clamped to the current facet bounds.
  /// Called on every build because a facet refresh can narrow the range and
  /// leave the slider's stored values outside [min, max] — which would crash RangeSlider.
  void _ensureValidPriceRange(StoreFacets facets) {
    if (facets.priceMax <= facets.priceMin) {
      _priceRange = null;
      return;
    }
    if (_priceRange == null) {
      final start = (_draft.priceMin ?? facets.priceMin)
          .clamp(facets.priceMin, facets.priceMax)
          .toDouble();
      final end = (_draft.priceMax ?? facets.priceMax)
          .clamp(facets.priceMin, facets.priceMax)
          .toDouble();
      _priceRange = RangeValues(start, end);
      return;
    }
    // Existing range — re-clamp in case the bounds moved after a facet refresh.
    final start = _priceRange!.start.clamp(facets.priceMin, facets.priceMax).toDouble();
    final end = _priceRange!.end.clamp(facets.priceMin, facets.priceMax).toDouble();
    if (start != _priceRange!.start || end != _priceRange!.end) {
      _priceRange = RangeValues(start, end);
    }
  }

  void _toggleManufacturer(int id) {
    setState(() {
      final s = Set<int>.from(_draft.manufacturerIds);
      s.contains(id) ? s.remove(id) : s.add(id);
      _draft = _draft.copyWith(manufacturerIds: s);
    });
    _scheduleRefresh();
  }

  void _toggleFeatureValue(int featureId, int valueId) {
    setState(() {
      final m = <int, Set<int>>{
        for (final e in _draft.selectedFeatures.entries) e.key: Set<int>.from(e.value),
      };
      final cur = m.putIfAbsent(featureId, () => <int>{});
      cur.contains(valueId) ? cur.remove(valueId) : cur.add(valueId);
      if (cur.isEmpty) m.remove(featureId);
      _draft = _draft.copyWith(selectedFeatures: m);
    });
    _scheduleRefresh();
  }

  void _resetAll(StoreFacets facets) {
    setState(() {
      _draft = const StoreFilterState();
      _priceRange = facets.priceMax > facets.priceMin
          ? RangeValues(facets.priceMin, facets.priceMax)
          : null;
      _showAllManufacturers = false;
      _showAllFeatureValues.clear();
    });
    _scheduleRefresh();
  }

  void _apply() {
    _debounce?.cancel();
    context.read<StoreController>().applyFilter(_draftWithPrice());
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Consumer<StoreController>(
          builder: (context, controller, _) {
            final facets = controller.availableFacets;

            // First-time load: full-sheet spinner
            if (facets == null) return _buildLoading();

            _ensureValidPriceRange(facets);

            return Column(
              children: [
                _buildHeader(context, facets),
                // Subtle progress strip while a refresh is in flight
                if (controller.isLoadingFacets)
                  const LinearProgressIndicator(minHeight: 2)
                else
                  const Divider(height: 1),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      if (facets.hasPriceFilter) _buildPriceSection(facets),
                      if (facets.manufacturers.isNotEmpty) _buildManufacturerSection(facets),
                      ...facets.features.map(_buildFeatureSection),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                _buildApplyBar(facets),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildLoading() {
    return const SizedBox(
      height: 300,
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildHeader(BuildContext context, StoreFacets facets) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Filtres',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          if (_draft.isNotEmpty)
            TextButton(
              onPressed: () => _resetAll(facets),
              child: const Text('Réinitialiser'),
            ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSection(StoreFacets facets) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        key: const PageStorageKey('filter-price'),
        initiallyExpanded: true,
        leading: const Icon(Iconsax.tag_2),
        title: const Text('Prix', style: TextStyle(fontWeight: FontWeight.w600)),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                RangeSlider(
                  values: _priceRange!,
                  min: facets.priceMin,
                  max: facets.priceMax,
                  divisions: 50,
                  activeColor: AlkColors.AppSecColor,
                  labels: RangeLabels(
                    _priceRange!.start.toStringAsFixed(2),
                    _priceRange!.end.toStringAsFixed(2),
                  ),
                  onChanged: (v) => setState(() => _priceRange = v),
                  // Refresh facets only when the user releases the slider
                  // (not on every pixel of drag).
                  onChangeEnd: (_) => _scheduleRefresh(),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${_priceRange!.start.toStringAsFixed(2)} ${facets.currencySign}'),
                    Text('${_priceRange!.end.toStringAsFixed(2)} ${facets.currencySign}'),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManufacturerSection(StoreFacets facets) {
    final visible = _showAllManufacturers
        ? facets.manufacturers
        : facets.manufacturers.take(8).toList();
    final hidden = facets.manufacturers.length - visible.length;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        key: const PageStorageKey('filter-mfg'),
        leading: const Icon(Iconsax.shop),
        title: const Text('Marques', style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: _draft.manufacturerIds.isEmpty
            ? null
            : Text('${_draft.manufacturerIds.length} sélectionnée(s)',
                style: TextStyle(fontSize: 12, color: AlkColors.AppSecColor)),
        children: [
          ...visible.map((m) => CheckboxListTile(
                dense: true,
                value: _draft.manufacturerIds.contains(m.id),
                title: Text(m.name),
                secondary: Text('${m.count}', style: const TextStyle(color: Colors.grey)),
                onChanged: (_) => _toggleManufacturer(m.id),
                controlAffinity: ListTileControlAffinity.leading,
              )),
          if (hidden > 0)
            TextButton(
              onPressed: () => setState(() => _showAllManufacturers = true),
              child: Text('Voir tout ($hidden)'),
            ),
        ],
      ),
    );
  }

  Widget _buildFeatureSection(FacetGroup group) {
    final selected = _draft.selectedFeatures[group.id] ?? const <int>{};
    final showAll = _showAllFeatureValues[group.id] ?? false;
    final visible = showAll ? group.values : group.values.take(6).toList();
    final hidden = group.values.length - visible.length;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        key: PageStorageKey('filter-feat-${group.id}'),
        leading: const Icon(Iconsax.category),
        title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: selected.isEmpty
            ? null
            : Text('${selected.length} sélectionnée(s)',
                style: TextStyle(fontSize: 12, color: AlkColors.AppSecColor)),
        children: [
          ...visible.map((v) => CheckboxListTile(
                dense: true,
                value: selected.contains(v.id),
                title: Text(v.name),
                secondary: Text('${v.count}', style: const TextStyle(color: Colors.grey)),
                onChanged: (_) => _toggleFeatureValue(group.id, v.id),
                controlAffinity: ListTileControlAffinity.leading,
              )),
          if (hidden > 0)
            TextButton(
              onPressed: () =>
                  setState(() => _showAllFeatureValues[group.id] = true),
              child: Text('Voir tout ($hidden)'),
            ),
        ],
      ),
    );
  }

  Widget _buildApplyBar(StoreFacets facets) {
    final count = facets.totalFiltered;
    final label = count > 0 ? 'Appliquer ($count produits)' : 'Aucun produit';
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AlkColors.AppSecColor,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade400,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: count > 0 ? _apply : null,
            child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }
}
