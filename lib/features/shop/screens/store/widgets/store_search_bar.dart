import 'dart:async';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../controllers/store_controller.dart';

/// Search bar widget with autocomplete suggestions
/// Displays debounced search suggestions in an overlay
class StoreSearchBar extends StatefulWidget {
  final VoidCallback onSearchSubmitted;
  final VoidCallback onClose;

  const StoreSearchBar({
    super.key,
    required this.onSearchSubmitted,
    required this.onClose,
  });

  @override
  State<StoreSearchBar> createState() => _StoreSearchBarState();
}

class _StoreSearchBarState extends State<StoreSearchBar> {
  final TextEditingController _textController = TextEditingController();
  Timer? _debounceTimer;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onSearchTextChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _textController.removeListener(_onSearchTextChanged);
    _textController.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onSearchTextChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    if (_textController.text.isEmpty) {
      _removeOverlay();
      context.read<StoreController>().clearSearchSuggestions();
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      context.read<StoreController>().fetchSearchSuggestions(_textController.text);
      _showSuggestionsOverlay();
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showSuggestionsOverlay() {
    _removeOverlay();

    final controller = context.read<StoreController>();
    if (controller.searchSuggestions.isEmpty) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + kToolbarHeight + 70,
        left: 12,
        right: 12,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 300),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: controller.searchSuggestions.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                return ListTile(
                  dense: true,
                  leading: const Icon(Iconsax.search_normal, size: 18, color: Colors.grey),
                  title: Text(
                    controller.searchSuggestions[index],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14),
                  ),
                  onTap: () {
                    final selectedText = controller.searchSuggestions[index];
                    // Update text without triggering listener
                    _textController.removeListener(_onSearchTextChanged);
                    _textController.text = selectedText;
                    _textController.addListener(_onSearchTextChanged);

                    _removeOverlay();
                    _performSearch(selectedText);
                  },
                );
              },
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) return;
    context.read<StoreController>().searchProducts(query);
    _removeOverlay();
    widget.onSearchSubmitted();
  }

  void _handleClear() {
    final controller = context.read<StoreController>();
    if (controller.isSearching) {
      controller.clearSearch();
      widget.onClose();
    } else {
      _textController.clear();
      _removeOverlay();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
      child: TextField(
        controller: _textController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Recherche',
          prefixIcon: const Icon(Iconsax.search_normal),
          suffixIcon: _textController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: _handleClear,
                  tooltip: 'Effacer',
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        onSubmitted: _performSearch,
        onChanged: (value) {
          setState(() {}); // Trigger rebuild to show/hide clear button
        },
      ),
    );
  }
}
