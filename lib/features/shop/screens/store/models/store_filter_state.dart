/// State of the store-screen filter sheet.
/// Maps directly to the productenriched/api?action=getProductsFiltered query params.
class StoreFilterState {
  final double? priceMin;
  final double? priceMax;
  final Set<int> manufacturerIds;
  final Map<int, Set<int>> selectedFeatures;

  const StoreFilterState({
    this.priceMin,
    this.priceMax,
    this.manufacturerIds = const {},
    this.selectedFeatures = const {},
  });

  bool get isEmpty =>
      priceMin == null &&
      priceMax == null &&
      manufacturerIds.isEmpty &&
      selectedFeatures.isEmpty;

  bool get isNotEmpty => !isEmpty;

  StoreFilterState copyWith({
    double? priceMin,
    double? priceMax,
    bool clearPriceMin = false,
    bool clearPriceMax = false,
    Set<int>? manufacturerIds,
    Map<int, Set<int>>? selectedFeatures,
  }) {
    return StoreFilterState(
      priceMin: clearPriceMin ? null : (priceMin ?? this.priceMin),
      priceMax: clearPriceMax ? null : (priceMax ?? this.priceMax),
      manufacturerIds: manufacturerIds ?? this.manufacturerIds,
      selectedFeatures: selectedFeatures ?? this.selectedFeatures,
    );
  }

  /// Build the query-string params expected by getProductsFiltered.
  Map<String, String> toQueryParams() {
    final params = <String, String>{};
    if (priceMin != null) params['price_min'] = priceMin!.toStringAsFixed(2);
    if (priceMax != null) params['price_max'] = priceMax!.toStringAsFixed(2);
    if (manufacturerIds.isNotEmpty) {
      params['manufacturers'] = manufacturerIds.join(',');
    }
    if (selectedFeatures.isNotEmpty) {
      final pairs = <String>[];
      selectedFeatures.forEach((featureId, valueIds) {
        for (final vid in valueIds) {
          pairs.add('$featureId:$vid');
        }
      });
      if (pairs.isNotEmpty) params['features'] = pairs.join(',');
    }
    return params;
  }

  /// Total number of individual filter selections (for display: "3 filtres actifs").
  int get activeCount {
    int count = 0;
    if (priceMin != null || priceMax != null) count += 1;
    count += manufacturerIds.length;
    selectedFeatures.forEach((_, vs) => count += vs.length);
    return count;
  }
}

/// Available filter options for the current category, returned by getFacets.
class StoreFacets {
  final int totalProducts;
  final int totalFiltered;
  final double priceMin;
  final double priceMax;
  final bool hasPriceFilter;
  final String currencySign;
  final List<FacetOption> manufacturers;
  final List<FacetGroup> features;

  const StoreFacets({
    required this.totalProducts,
    required this.totalFiltered,
    required this.priceMin,
    required this.priceMax,
    required this.hasPriceFilter,
    required this.currencySign,
    required this.manufacturers,
    required this.features,
  });

  factory StoreFacets.empty() => const StoreFacets(
        totalProducts: 0,
        totalFiltered: 0,
        priceMin: 0,
        priceMax: 0,
        hasPriceFilter: false,
        currencySign: 'TND',
        manufacturers: [],
        features: [],
      );

  factory StoreFacets.fromJson(Map<String, dynamic> data) {
    final priceData = data['price'];
    double pmin = 0.0;
    double pmax = 0.0;
    bool hasPrice = false;
    if (priceData is Map) {
      pmin = double.tryParse(priceData['min'].toString()) ?? 0.0;
      pmax = double.tryParse(priceData['max'].toString()) ?? 0.0;
      hasPrice = pmax > pmin;
    }

    final manuRaw = (data['manufacturers'] as List?) ?? const [];
    final manufacturers = manuRaw
        .whereType<Map>()
        .map((m) => FacetOption(
              id: int.tryParse(m['id'].toString()) ?? 0,
              name: (m['name'] ?? '').toString(),
              count: int.tryParse(m['count'].toString()) ?? 0,
            ))
        .where((o) => o.id > 0)
        .toList();

    final featRaw = (data['features'] as List?) ?? const [];
    final features = featRaw.whereType<Map>().map((f) {
      final valuesRaw = (f['values'] as List?) ?? const [];
      return FacetGroup(
        id: int.tryParse(f['id_feature'].toString()) ?? 0,
        name: (f['name'] ?? '').toString(),
        values: valuesRaw
            .whereType<Map>()
            .map((v) => FacetOption(
                  id: int.tryParse(v['id_feature_value'].toString()) ?? 0,
                  name: (v['name'] ?? '').toString(),
                  count: int.tryParse(v['count'].toString()) ?? 0,
                ))
            .where((o) => o.id > 0)
            .toList(),
      );
    }).where((g) => g.id > 0 && g.values.isNotEmpty).toList();

    final sign = (data['currency_sign'] ?? '').toString();
    final total = int.tryParse(data['total_products'].toString()) ?? 0;
    final filtered = int.tryParse(data['total_filtered'].toString()) ?? total;

    return StoreFacets(
      totalProducts: total,
      totalFiltered: filtered,
      priceMin: pmin,
      priceMax: pmax,
      hasPriceFilter: hasPrice,
      currencySign: sign.isNotEmpty ? sign : 'TND',
      manufacturers: manufacturers,
      features: features,
    );
  }
}

class FacetOption {
  final int id;
  final String name;
  final int count;
  const FacetOption({required this.id, required this.name, required this.count});
}

class FacetGroup {
  final int id;
  final String name;
  final List<FacetOption> values;
  const FacetGroup({required this.id, required this.name, required this.values});
}
