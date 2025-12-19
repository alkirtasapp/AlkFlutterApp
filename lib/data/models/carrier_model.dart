class Carrier {
  final int id;
  final String name;
  final bool isActive;
  final bool isFree;
  final String delay;
  final double shippingCost;

  Carrier({
    required this.id,
    required this.name,
    required this.isActive,
    required this.isFree,
    required this.delay,
    this.shippingCost = 0.0,
  });

  factory Carrier.fromJson(Map<String, dynamic> json, {double? cost}) {
    final name = json['name']?.toString() ?? '';
    final isFreeField = json['is_free']?.toString() == '1';
    // Also check if name contains "gratuit" (French for free)
    final nameIndicatesFree = name.toLowerCase().contains('gratuit');

    return Carrier(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: name.trim(),
      isActive: json['active']?.toString() == '1',
      isFree: isFreeField || nameIndicatesFree,
      delay: json['delay']?.toString() ?? '',
      shippingCost: (isFreeField || nameIndicatesFree) ? 0.0 : (cost ?? 0.0),
    );
  }

  @override
  String toString() {
    return 'Carrier(id: $id, name: $name, isFree: $isFree, cost: $shippingCost)';
  }
}
