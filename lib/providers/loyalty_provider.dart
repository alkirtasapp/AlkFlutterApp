import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../utils/backendData/userData.dart';

/// Model class for loyalty program data
class LoyaltyProgram {
  final String programName;
  final double points;
  final String pointName;
  final String? lastUpdated;

  LoyaltyProgram({
    required this.programName,
    required this.points,
    required this.pointName,
    this.lastUpdated,
  });

  factory LoyaltyProgram.fromJson(Map<String, dynamic> json) {
    return LoyaltyProgram(
      programName: json['program_name'] ?? 'Loyalty',
      points: (json['points'] ?? 0).toDouble(),
      pointName: json['point_name'] ?? 'Points',
      lastUpdated: json['last_updated'],
    );
  }
}

/// Model class for customer loyalty data
class LoyaltyData {
  final double totalPoints;
  final double walletBalance;
  final String? barcode;
  final List<LoyaltyProgram> programs;
  final DateTime? lastFetched;

  LoyaltyData({
    required this.totalPoints,
    required this.walletBalance,
    this.barcode,
    required this.programs,
    this.lastFetched,
  });

  factory LoyaltyData.fromJson(Map<String, dynamic> json) {
    final loyaltyData = json['loyalty'] ?? {};
    final programsList = (loyaltyData['programs'] as List? ?? [])
        .map((p) => LoyaltyProgram.fromJson(p))
        .toList();

    return LoyaltyData(
      totalPoints: (loyaltyData['total_points'] ?? 0).toDouble(),
      walletBalance: (loyaltyData['wallet_balance'] ?? 0).toDouble(),
      barcode: loyaltyData['barcode'],
      programs: programsList,
      lastFetched: DateTime.now(),
    );
  }

  factory LoyaltyData.empty() {
    return LoyaltyData(
      totalPoints: 0,
      walletBalance: 0,
      barcode: null,
      programs: [],
      lastFetched: null,
    );
  }
}

/// Provider for managing customer loyalty points
/// Fetches loyalty data from PrestaShop mobile_cart_api module
class LoyaltyProvider extends ChangeNotifier {
  LoyaltyData _loyaltyData = LoyaltyData.empty();
  bool _isLoading = false;
  String? _error;

  LoyaltyData get loyaltyData => _loyaltyData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get totalPoints => _loyaltyData.totalPoints;
  double get walletBalance => _loyaltyData.walletBalance;
  String? get barcode => _loyaltyData.barcode;
  List<LoyaltyProgram> get programs => _loyaltyData.programs;
  bool get hasPoints => _loyaltyData.totalPoints > 0;
  bool get hasBalance => _loyaltyData.walletBalance > 0;
  bool get hasBarcode => _loyaltyData.barcode != null && _loyaltyData.barcode!.isNotEmpty;

  /// Fetch loyalty points from PrestaShop
  Future<void> fetchLoyaltyPoints() async {
    // Check if user is logged in
    if (UserData.id.isEmpty) {
      _error = 'User not logged in';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final customerId = UserData.id;
      final url = 'https://www.alkirtas.com/module/mobile_cart_api/loyalty?customer_id=$customerId&ws_key=${AppConfig.prestashopApiKey}';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        if (data['success'] == true) {
          _loyaltyData = LoyaltyData.fromJson(data);
          _error = null;
        } else {
          _error = data['error']?['message'] ?? 'Failed to fetch loyalty points';
        }
      } else if (response.statusCode == 404) {
        _loyaltyData = LoyaltyData.empty();
        _error = null;
      } else {
        _error = 'Failed to fetch loyalty points (${response.statusCode})';
      }
    } catch (e) {
      _error = 'Network error: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Clear loyalty data (on logout)
  void clear() {
    _loyaltyData = LoyaltyData.empty();
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  /// Refresh loyalty points if needed (e.g., older than 5 minutes)
  Future<void> refreshIfNeeded() async {
    final lastFetched = _loyaltyData.lastFetched;
    if (lastFetched == null ||
        DateTime.now().difference(lastFetched).inMinutes > 5) {
      await fetchLoyaltyPoints();
    }
  }
}
