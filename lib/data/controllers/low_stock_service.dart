import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:alkirtas/config/app_config.dart';
import 'package:alkirtas/utils/logging/logger.dart';

/// A resolved low-stock badge for one product, exactly as the PrestaShop
/// back office configured it. Nothing here is decided by the app.
class LowStockBadge {
  final int quantity;
  final String message;
  final Color background;
  final Color foreground;

  const LowStockBadge({
    required this.quantity,
    required this.message,
    required this.background,
    required this.foreground,
  });

  static LowStockBadge? fromJson(Map<String, dynamic> json) {
    final message = json['message']?.toString() ?? '';
    if (message.isEmpty) return null;
    return LowStockBadge(
      quantity: int.tryParse(json['quantity'].toString()) ?? 0,
      message: message,
      background: _parseHex(json['bg']?.toString()) ?? const Color(0xFF0802A3),
      foreground: _parseHex(json['fg']?.toString()) ?? Colors.white,
    );
  }

  static Color? _parseHex(String? hex) {
    if (hex == null) return null;
    var value = hex.trim().replaceFirst('#', '');
    if (value.length == 3) {
      value = value.split('').map((c) => '$c$c').join();
    }
    if (value.length != 6) return null;
    final parsed = int.tryParse(value, radix: 16);
    return parsed == null ? null : Color(0xFF000000 | parsed);
  }
}

/// Client for the `alkproductlowstock` PrestaShop module.
///
/// The badge rules (threshold, colour, wording, which categories/brands) live
/// in the back office. This service never decides what "low stock" means — it
/// only asks the server, so the app and the website always agree.
///
/// Per-product lookups from many product cards are coalesced into a single
/// batched HTTP request, so a full grid costs one call rather than twenty.
class LowStockService {
  LowStockService._();

  /// Controls low-stock badge rendering and server requests.
  static const bool enabled = true;

  static const String _moduleBase =
      'https://www.alkirtas.com/module/alkproductlowstock/api';

  /// How long a fetched badge (or a known "no badge") stays trusted.
  static const Duration _cacheTtl = Duration(minutes: 5);

  /// Window over which individual card requests are merged into one call.
  static const Duration _batchWindow = Duration(milliseconds: 60);

  /// The server caps a single request; stay under it.
  static const int _maxIdsPerRequest = 200;

  static final Map<int, LowStockBadge?> _cache = {};
  static DateTime? _cacheStampedAt;

  static final Map<int, List<Completer<LowStockBadge?>>> _pending = {};
  static Timer? _batchTimer;

  static int? _maxThreshold;
  static DateTime? _maxThresholdAt;
  static Future<int>? _maxThresholdRequest;

  /// Highest threshold across all *active* badge rules, straight from the
  /// back office. Products stocked above it can skip the network entirely.
  /// Returns 0 when no rule is active, or when the module is unreachable.
  static Future<int> maxThreshold() {
    if (!enabled) return Future.value(0);
    final stamped = _maxThresholdAt;
    if (_maxThreshold != null &&
        stamped != null &&
        DateTime.now().difference(stamped) < _cacheTtl) {
      return Future.value(_maxThreshold);
    }
    return _maxThresholdRequest ??= _fetchMaxThreshold().whenComplete(() {
      _maxThresholdRequest = null;
    });
  }

  static Future<int> _fetchMaxThreshold() async {
    try {
      final url = '$_moduleBase?action=getRules'
          '&ws_key=${AppConfig.prestashopApiKey}';
      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        AlkLoggerHelper.warning(
            'LowStockService.getRules HTTP ${response.statusCode}');
        return _rememberMaxThreshold(0);
      }

      final data = json.decode(utf8.decode(response.bodyBytes));
      if (data is! Map || data['success'] != true) {
        return _rememberMaxThreshold(0);
      }

      final rules = data['data']?['rules'] as List<dynamic>? ?? const [];
      var max = 0;
      for (final rule in rules) {
        if (rule is! Map) continue;
        final threshold = int.tryParse(rule['threshold'].toString()) ?? 0;
        if (threshold > max) max = threshold;
      }
      AlkLoggerHelper.debug(
          'Low-stock rules loaded: ${rules.length} active, max threshold $max');
      return _rememberMaxThreshold(max);
    } catch (e) {
      AlkLoggerHelper.warning('LowStockService.getRules unavailable: $e');
      // Cache the failure briefly so every card does not retry at once.
      return _rememberMaxThreshold(0);
    }
  }

  static int _rememberMaxThreshold(int value) {
    _maxThreshold = value;
    _maxThresholdAt = DateTime.now();
    return value;
  }

  /// The badge for [productId], or null when the product earns none.
  ///
  /// Callers should pass [stock] when they already know it: a product that is
  /// out of stock, or stocked above every active threshold, is answered
  /// locally without touching the network.
  static Future<LowStockBadge?> badgeFor(int productId, {int? stock}) async {
    if (!enabled || productId <= 0) return null;
    if (stock != null && stock <= 0) return null;

    if (stock != null) {
      final max = await maxThreshold();
      if (max <= 0 || stock > max) return null;
    }

    if (_isCacheFresh() && _cache.containsKey(productId)) {
      return _cache[productId];
    }

    final completer = Completer<LowStockBadge?>();
    _pending.putIfAbsent(productId, () => []).add(completer);
    _batchTimer ??= Timer(_batchWindow, _flushBatch);
    return completer.future;
  }

  static bool _isCacheFresh() {
    final stamped = _cacheStampedAt;
    return stamped != null && DateTime.now().difference(stamped) < _cacheTtl;
  }

  static Future<void> _flushBatch() async {
    _batchTimer = null;
    if (_pending.isEmpty) return;

    final batch = Map<int, List<Completer<LowStockBadge?>>>.from(_pending);
    _pending.clear();

    final ids = batch.keys.take(_maxIdsPerRequest).toList();

    // null means the request failed, which is different from "nothing matched".
    Map<int, LowStockBadge?>? resolved;
    try {
      resolved = await _fetchBadges(ids);
    } catch (e) {
      AlkLoggerHelper.warning('LowStockService.getBadges failed: $e');
    }

    if (resolved != null) {
      if (!_isCacheFresh()) {
        _cache.clear();
        _cacheStampedAt = DateTime.now();
      }
      // Every id we asked about is now known: either it has a badge, or it
      // explicitly does not. Cache both so the grid stops asking.
      for (final id in ids) {
        _cache[id] = resolved[id];
      }
    }
    // On failure nothing is cached, so the next render retries rather than
    // hiding badges for the whole TTL.

    batch.forEach((id, waiters) {
      final badge = resolved?[id];
      for (final waiter in waiters) {
        if (!waiter.isCompleted) waiter.complete(badge);
      }
    });
  }

  /// Returns null when the request itself failed; an empty map means the
  /// server answered and none of these products earn a badge.
  static Future<Map<int, LowStockBadge?>?> _fetchBadges(List<int> ids) async {
    if (ids.isEmpty) return {};

    final url = '$_moduleBase?action=getBadges'
        '&ids=${ids.join('|')}'
        '&ws_key=${AppConfig.prestashopApiKey}';

    final response =
        await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) {
      AlkLoggerHelper.warning(
          'LowStockService.getBadges HTTP ${response.statusCode}');
      return null;
    }

    final data = json.decode(utf8.decode(response.bodyBytes));
    if (data is! Map || data['success'] != true) return null;

    final badges = data['data']?['badges'];
    // An empty result is encoded as {} by the server, so a non-map here means
    // a malformed response rather than "no badges".
    if (badges is! Map) return null;

    final result = <int, LowStockBadge?>{};
    badges.forEach((key, value) {
      final id = int.tryParse(key.toString()) ?? 0;
      if (id > 0 && value is Map) {
        result[id] = LowStockBadge.fromJson(Map<String, dynamic>.from(value));
      }
    });
    return result;
  }

  /// Drops every cached badge and rule. Call after an action that can change
  /// stock (placing an order), so the next render re-reads the server.
  static void invalidate() {
    _cache.clear();
    _cacheStampedAt = null;
    _maxThreshold = null;
    _maxThresholdAt = null;
  }
}
