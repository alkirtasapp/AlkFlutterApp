import 'package:flutter/material.dart';
import '../models/audiobook_model.dart';

/// Beautiful synchronized text display with smooth animations
class SyncedTextDisplay extends StatefulWidget {
  final AudioTranscript? transcript;
  final Duration currentPosition;
  final Function(Duration)? onSegmentTap;

  const SyncedTextDisplay({
    super.key,
    required this.transcript,
    required this.currentPosition,
    this.onSegmentTap,
  });

  @override
  State<SyncedTextDisplay> createState() => _SyncedTextDisplayState();
}

class _SyncedTextDisplayState extends State<SyncedTextDisplay> {
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _itemKeys = {};
  int? _lastActiveIndex;

  @override
  void initState() {
    super.initState();
    // Initialize keys for each segment
    if (widget.transcript != null) {
      for (int i = 0; i < widget.transcript!.segments.length; i++) {
        _itemKeys[i] = GlobalKey();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(SyncedTextDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToActiveSegment();
    });
  }

  void _scrollToActiveSegment() {
    if (widget.transcript == null || !_scrollController.hasClients) return;

    final activeIndex =
        widget.transcript!.findActiveSegmentIndex(widget.currentPosition);

    if (activeIndex != null && activeIndex != _lastActiveIndex) {
      _lastActiveIndex = activeIndex;

      // Get the RenderBox of the active item
      final keyContext = _itemKeys[activeIndex]?.currentContext;
      if (keyContext != null) {
        final box = keyContext.findRenderObject() as RenderBox?;
        if (box != null) {
          // Calculate position to center the item
          final itemPosition = box.localToGlobal(Offset.zero, ancestor: context.findRenderObject());
          final itemHeight = box.size.height;
          final scrollViewHeight = _scrollController.position.viewportDimension;

          // Calculate the offset needed to center the item
          final targetOffset = _scrollController.offset +
                              itemPosition.dy -
                              (scrollViewHeight / 2) +
                              (itemHeight / 2);

          _scrollController.animateTo(
            targetOffset.clamp(
              _scrollController.position.minScrollExtent,
              _scrollController.position.maxScrollExtent,
            ),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOutCubic,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    if (widget.transcript == null || widget.transcript!.segments.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primaryColor.withOpacity(0.1),
              primaryColor.withOpacity(0.03),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.text_snippet_outlined,
                size: 48,
                color: primaryColor.withOpacity(0.4),
              ),
              const SizedBox(height: 12),
              Text(
                'Aucun texte disponible',
                style: TextStyle(
                  color: primaryColor.withOpacity(0.6),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final activeIndex =
        widget.transcript!.findActiveSegmentIndex(widget.currentPosition);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            primaryColor.withOpacity(0.08),
            primaryColor.withOpacity(0.02),
            theme.scaffoldBackgroundColor,
          ],
          stops: const [0.0, 0.4, 1.0],
        ),
      ),
      child: ShaderMask(
        shaderCallback: (Rect bounds) {
          return LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.white,
              Colors.white,
              Colors.transparent,
            ],
            stops: const [0.0, 0.06, 0.94, 1.0],
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstIn,
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
          itemCount: widget.transcript!.segments.length,
          itemBuilder: (context, index) {
            final segment = widget.transcript!.segments[index];
            final isActive = index == activeIndex;
            final isPast = activeIndex != null && index < activeIndex;

            return _SegmentTile(
              key: _itemKeys[index],
              segment: segment,
              isActive: isActive,
              isPast: isPast,
              primaryColor: primaryColor,
              onTap: widget.onSegmentTap != null
                  ? () => widget.onSegmentTap!(
                      Duration(milliseconds: (segment.startTime * 1000).toInt()))
                  : null,
            );
          },
        ),
      ),
    );
  }
}

class _SegmentTile extends StatelessWidget {
  final TextSegment segment;
  final bool isActive;
  final bool isPast;
  final Color primaryColor;
  final VoidCallback? onTap;

  const _SegmentTile({
    super.key,
    required this.segment,
    required this.isActive,
    required this.isPast,
    required this.primaryColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: isActive ? 1.0 : 0.0),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Container(
            margin: EdgeInsets.symmetric(
              vertical: 6 + (value * 4),
              horizontal: 4 - (value * 4),
            ),
            padding: EdgeInsets.all(14 + (value * 4)),
            decoration: BoxDecoration(
              color: Color.lerp(
                Colors.transparent,
                primaryColor.withOpacity(0.12),
                value,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: primaryColor.withOpacity(0.3 * value),
                width: 1.5,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Indicator bar
                Container(
                  width: 4,
                  height: 24 + (value * 16),
                  margin: const EdgeInsets.only(right: 14),
                  decoration: BoxDecoration(
                    color: isActive
                        ? primaryColor
                        : isPast
                            ? primaryColor.withOpacity(0.25)
                            : primaryColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Text with proper RTL support
                Expanded(
                  child: Text(
                    segment.text,
                    textDirection: _detectTextDirection(segment.text),
                    style: TextStyle(
                      fontSize: 15 + (value * 2),
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive
                          ? primaryColor
                          : isPast
                              ? Colors.grey.shade500
                              : Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Detect if text is RTL (Arabic, Hebrew, etc.)
  TextDirection _detectTextDirection(String text) {
    if (text.isEmpty) return TextDirection.ltr;

    // Check for Arabic characters (U+0600 to U+06FF)
    final arabicRegex = RegExp(r'[\u0600-\u06FF]');
    // Check for Hebrew characters (U+0590 to U+05FF)
    final hebrewRegex = RegExp(r'[\u0590-\u05FF]');

    if (arabicRegex.hasMatch(text) || hebrewRegex.hasMatch(text)) {
      return TextDirection.rtl;
    }

    return TextDirection.ltr;
  }
}

/// Compact version showing current segment only
class CompactSyncedText extends StatelessWidget {
  final AudioTranscript? transcript;
  final Duration currentPosition;

  const CompactSyncedText({
    super.key,
    required this.transcript,
    required this.currentPosition,
  });

  @override
  Widget build(BuildContext context) {
    if (transcript == null || transcript!.segments.isEmpty) {
      return const SizedBox.shrink();
    }

    final activeIndex = transcript!.findActiveSegmentIndex(currentPosition);
    if (activeIndex == null) return const SizedBox.shrink();

    final segment = transcript!.segments[activeIndex];
    final primaryColor = Theme.of(context).primaryColor;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.15),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            )),
            child: child,
          ),
        );
      },
      child: Container(
        key: ValueKey(activeIndex),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: primaryColor.withOpacity(0.15),
          ),
        ),
        child: Text(
          segment.text,
          textAlign: TextAlign.center,
          textDirection: _detectTextDirection(segment.text),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: primaryColor.withOpacity(0.85),
            height: 1.4,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  /// Detect if text is RTL (Arabic, Hebrew, etc.)
  TextDirection _detectTextDirection(String text) {
    if (text.isEmpty) return TextDirection.ltr;

    final arabicRegex = RegExp(r'[\u0600-\u06FF]');
    final hebrewRegex = RegExp(r'[\u0590-\u05FF]');

    if (arabicRegex.hasMatch(text) || hebrewRegex.hasMatch(text)) {
      return TextDirection.rtl;
    }

    return TextDirection.ltr;
  }
}
