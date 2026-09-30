import 'dart:math' as math;

import 'package:alkirtas/features/shop/services/delivered_order_review_prompt_service.dart';
import 'package:alkirtas/features/shop/services/product_review_service.dart';
import 'package:alkirtas/utils/constants/colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class DeliveredOrderReviewDialog extends StatefulWidget {
  final Map<String, dynamic> order;
  final Set<String> reviewedProductIds;

  const DeliveredOrderReviewDialog({
    super.key,
    required this.order,
    this.reviewedProductIds = const {},
  });

  @override
  State<DeliveredOrderReviewDialog> createState() =>
      _DeliveredOrderReviewDialogState();
}

class _DeliveredOrderReviewDialogState
    extends State<DeliveredOrderReviewDialog> {
  final _commentController = TextEditingController();
  late final List<Map<String, dynamic>> _items;
  int _currentIndex = 0;
  int _rating = 0;
  bool _isSubmitting = false;
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    final rawItems = (widget.order['items'] as List?) ?? const [];
    _items = rawItems
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .where((item) {
      final productId = item['productId']?.toString() ?? '';
      return productId.isNotEmpty &&
          !widget.reviewedProductIds.contains(productId);
    }).toList();
    _isComplete = _items.isEmpty;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final availableHeight =
        mediaQuery.size.height - mediaQuery.viewInsets.bottom;
    final sheetHeight = math.min(680.0, availableHeight * 0.9);

    return Padding(
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      child: Material(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: sheetHeight,
          child: SafeArea(
            top: false,
            child: _isComplete ? _buildThankYou() : _buildReview(),
          ),
        ),
      ),
    );
  }

  Widget _buildReview() {
    final item = _items[_currentIndex];
    final productName = item['productName']?.toString().trim();
    final imageUrl = item['productImage']?.toString() ?? '';
    final orderReference =
        widget.order['prestashopOrderRef']?.toString().trim() ?? '';

    return Column(
      children: [
        const SizedBox(height: 10),
        Container(
          width: 42,
          height: 4,
          decoration: BoxDecoration(
            color: AlkColors.grey,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Votre avis compte',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      orderReference.isEmpty
                          ? 'Commande livrée'
                          : 'Commande $orderReference · livrée',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AlkColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Fermer',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        if (_items.length > 1)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: (_currentIndex + 1) / _items.length,
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(2),
                    backgroundColor: AlkColors.grey,
                    color: AlkColors.AppFirstColor,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${_currentIndex + 1}/${_items.length}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AlkColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
            child: Column(
              children: [
                _ProductImage(
                  productId: item['productId']?.toString() ?? '',
                  imageUrl: imageUrl,
                ),
                const SizedBox(height: 16),
                Text(
                  productName?.isNotEmpty == true ? productName! : 'Produit',
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Quelle note lui donnez-vous ?',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Semantics(
                  label: 'Note du produit',
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final value = index + 1;
                      return IconButton(
                        tooltip: '$value étoile${value > 1 ? 's' : ''}',
                        constraints: const BoxConstraints.tightFor(
                            width: 48, height: 48),
                        onPressed: _isSubmitting
                            ? null
                            : () => setState(() => _rating = value),
                        iconSize: 40,
                        icon: Icon(
                          value <= _rating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: value <= _rating
                              ? const Color(0xFFFFB000)
                              : AlkColors.borderPrimary,
                        ),
                      );
                    }),
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: _rating == 0
                      ? const SizedBox(height: 24)
                      : Text(
                          _ratingLabel,
                          key: ValueKey(_rating),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AlkColors.AppFirstColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _commentController,
                  enabled: !_isSubmitting,
                  minLines: 2,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Un détail à partager ? (optionnel)',
                    filled: true,
                    fillColor: AlkColors.softGrey,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: AlkColors.borderSecondary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AlkColors.AppFirstColor,
                    foregroundColor: AlkColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _rating == 0 || _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AlkColors.white,
                          ),
                        )
                      : const Text(
                          'Publier mon avis',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
              TextButton(
                onPressed:
                    _isSubmitting ? null : () => Navigator.of(context).pop(),
                child: const Text('Pas maintenant'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThankYou() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: Color(0xFFE7F7EC),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 42,
              color: AlkColors.success,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Merci pour votre avis',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Il aidera les autres clients à faire leur choix.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AlkColors.textSecondary,
                ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AlkColors.AppFirstColor,
                foregroundColor: AlkColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Terminer',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String get _ratingLabel {
    switch (_rating) {
      case 1:
        return 'Décevant';
      case 2:
        return 'Moyen';
      case 3:
        return 'Bien';
      case 4:
        return 'Très bien';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }

  Future<void> _submit() async {
    final item = _items[_currentIndex];
    final productId = item['productId']?.toString() ?? '';

    setState(() => _isSubmitting = true);
    try {
      final comment = _commentController.text.trim();
      final success = await ProductReviewService().submitReview(
        ProductReviewSubmission(
          orderId: widget.order['orderId']?.toString() ?? '',
          productId: productId,
          rating: _rating,
          title: 'Avis client',
          comment:
              comment.isEmpty ? 'Note donnée depuis l’application.' : comment,
        ),
      );

      if (!mounted) return;
      if (!success) {
        _showSubmitError();
        return;
      }

      await DeliveredOrderReviewPromptService.markProductReviewed(productId);
      if (!mounted) return;

      if (_currentIndex == _items.length - 1) {
        await DeliveredOrderReviewPromptService.dismissOrder(widget.order);
        if (mounted) setState(() => _isComplete = true);
      } else {
        setState(() {
          _currentIndex += 1;
          _rating = 0;
          _commentController.clear();
        });
      }
    } on ProductReviewException catch (error) {
      if (mounted) _showSubmitError(error.message);
    } catch (_) {
      if (mounted) _showSubmitError();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSubmitError([String? message]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(message ?? 'Impossible d’envoyer votre avis pour le moment.'),
      ),
    );
  }
}

class _ProductImage extends StatefulWidget {
  final String productId;
  final String imageUrl;

  const _ProductImage({required this.productId, required this.imageUrl});

  @override
  State<_ProductImage> createState() => _ProductImageState();
}

class _ProductImageState extends State<_ProductImage> {
  late Future<String> _imageFuture;

  @override
  void initState() {
    super.initState();
    _imageFuture = _loadImage();
  }

  @override
  void didUpdateWidget(covariant _ProductImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.productId != widget.productId ||
        oldWidget.imageUrl != widget.imageUrl) {
      _imageFuture = _loadImage();
    }
  }

  Future<String> _loadImage() {
    if (widget.imageUrl.isNotEmpty) return Future.value(widget.imageUrl);
    return ProductReviewService().fetchProductImageUrl(widget.productId);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 142,
      height: 176,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AlkColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AlkColors.borderSecondary),
      ),
      child: FutureBuilder<String>(
        future: _imageFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _loading();
          }

          final imageUrl = snapshot.data ?? '';
          if (imageUrl.isEmpty) return _fallback();

          return CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            placeholder: (_, __) => _loading(),
            errorWidget: (_, __, ___) => _fallback(),
          );
        },
      ),
    );
  }

  Widget _loading() => Container(
        color: AlkColors.softGrey,
        alignment: Alignment.center,
        child: const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );

  Widget _fallback() => Container(
        color: AlkColors.softGrey,
        alignment: Alignment.center,
        child: const Icon(
          Icons.menu_book_rounded,
          size: 52,
          color: AlkColors.textSecondary,
        ),
      );
}
