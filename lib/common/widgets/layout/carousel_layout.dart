import 'dart:async';
import 'package:flutter/material.dart';

import '../../../utils/constants/size.dart';
import '../products/product_cards/product_card_vertical.dart';

class AlkCarouselLayout extends StatefulWidget {
  const AlkCarouselLayout({
    super.key,
    required this.itemCount,
    required this.productsPerPage,
    this.horizontalPadding = AlkSize.gridViewSpacing,
    this.verticalPadding = AlkSize.gridViewSpacing,
    this.autoSwipeDuration = const Duration(seconds: 3),
  });

  final int itemCount;
  final int productsPerPage;
  final double horizontalPadding;
  final double verticalPadding;
  final Duration autoSwipeDuration;

  @override
  _AlkCarouselLayoutState createState() => _AlkCarouselLayoutState();
}

class _AlkCarouselLayoutState extends State<AlkCarouselLayout> {
  final ScrollController _scrollController = ScrollController();
  late Timer _autoSwipeTimer;
  int _currentIndex = 0;

  int get maxScrollIndex {
    return (widget.itemCount / widget.productsPerPage).floor() - 1;
  }

  @override
  void initState() {
    super.initState();

    _autoSwipeTimer = Timer.periodic(widget.autoSwipeDuration, (timer) {
      final double fullItemWidth = _calculateItemWidth() + widget.horizontalPadding;

      if (_currentIndex < maxScrollIndex) {
        _currentIndex++;
      } else {
        _currentIndex = 0;
      }

      _scrollController.animateTo(
        _currentIndex * fullItemWidth,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoSwipeTimer.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  double _calculateItemWidth() {
    final screenWidth = MediaQuery.of(context).size.width;

    if (widget.productsPerPage == 1) {
      // For a single product per page, use 90% of the screen width
      return screenWidth * 0.77;
    } else {
      // For multiple products per page, divide the screen width by the number of products
      return (screenWidth - (widget.horizontalPadding * (widget.productsPerPage + 1))) /
          widget.productsPerPage;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double itemWidth = _calculateItemWidth();
    final double itemHeight = 240.0; // Height of product cards

    return SizedBox(
      height: itemHeight + (2 * widget.verticalPadding),
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: widget.itemCount,
        itemBuilder: (_, index) {
          return Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? widget.horizontalPadding : widget.horizontalPadding / 2,
              right: index == widget.itemCount - 1 ? widget.horizontalPadding : widget.horizontalPadding / 2,
            ),
            child: SizedBox(
              width: itemWidth,
              height: itemHeight,
              child: AlkProductCardVertical(productIndex: index),
            ),
          );
        },
      ),
    );
  }
}
