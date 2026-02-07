import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../../../../../utils/constants/colors.dart';
import '../controllers/store_controller.dart';

/// Custom AppBar for store screen with search, filter, and QR scanner
class StoreAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onSearchToggle;
  final VoidCallback onQrScannerPressed;
  final bool isSearchVisible;

  const StoreAppBar({
    super.key,
    required this.onSearchToggle,
    required this.onQrScannerPressed,
    required this.isSearchVisible,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 4);

  @override
  Widget build(BuildContext context) {
    return Consumer<StoreController>(
      builder: (context, controller, child) {
        return AppBar(
          leading: _buildLeading(context, controller),
          title: _buildTitle(controller),
          actions: [
            _buildSearchAction(context, controller),
            IconButton(
              icon: const Icon(Iconsax.scan),
              onPressed: onQrScannerPressed,
              tooltip: 'Scanner QR Code',
            ),
            _buildFilterMenu(context, controller),
          ],
        );
      },
    );
  }

  Widget _buildTitle(StoreController controller) {
    if (controller.isSearching) {
      return const Text('Recherche');
    }

    final hasNavigation = controller.navigationStack.isNotEmpty;
    final categoryName = controller.selectedCategory.isNotEmpty
        ? controller.selectedCategory
        : "Chargement...";

    if (!hasNavigation) {
      return Text(
        categoryName,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      );
    }

    // Build breadcrumb: Parent > ... > Current
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          categoryName,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        _buildBreadcrumb(controller),
      ],
    );
  }

  Widget _buildBreadcrumb(StoreController controller) {
    // Build path: "Parent › Child › ..."
    final pathParts = controller.navigationStack.join(' › ');

    return Text(
      pathParts,
      style: TextStyle(
        fontSize: 10,
        color: AlkColors.AppSecColor.withOpacity(0.7),
        fontWeight: FontWeight.w400,
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }

  Widget? _buildLeading(BuildContext context, StoreController controller) {
    // Only show back button when there's navigation history
    if (controller.navigationStack.isNotEmpty) {
      return IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
        onPressed: () => controller.navigateBack(),
      );
    }
    // No leading button at root level (drawer removed, categories in Menu tab)
    return null;
  }

  Widget _buildSearchAction(BuildContext context, StoreController controller) {
    return IconButton(
      icon: Icon(controller.isSearching ? Icons.search_off : Icons.search),
      tooltip: controller.isSearching ? 'Effacer la recherche' : 'Rechercher',
      onPressed: () {
        if (controller.isSearching) {
          controller.clearSearch();
        }
        onSearchToggle();
      },
    );
  }

  Widget _buildFilterMenu(BuildContext context, StoreController controller) {
    return PopupMenuButton<String>(
      icon: Icon(
        Iconsax.filter,
        color: controller.selectedSortOption != "None" ? Colors.purple : null,
      ),
      tooltip: controller.selectedSortOption != "None"
          ? 'Filtre actif: ${controller.getSortOptionLabel(controller.selectedSortOption)}'
          : 'Filtrer',
      onSelected: (String value) => controller.updateSortOption(value),
      itemBuilder: (BuildContext context) => [
        _buildFilterMenuItem(
          "None",
          "Par défaut",
          controller.selectedSortOption,
          showDivider: true,
        ),
        _buildFilterMenuItem("Price Asc", "Prix Croissant", controller.selectedSortOption),
        _buildFilterMenuItem("Price Desc", "Prix Décroissant", controller.selectedSortOption),
        _buildFilterMenuItem("Name Asc", "Nom A-Z", controller.selectedSortOption),
        _buildFilterMenuItem("Name Desc", "Nom Z-A", controller.selectedSortOption),
        _buildFilterMenuItem("Référence Asc", "Référence A-Z", controller.selectedSortOption),
        _buildFilterMenuItem("Référence Desc", "Référence Z-A", controller.selectedSortOption),
      ],
    );
  }

  PopupMenuEntry<String> _buildFilterMenuItem(
    String value,
    String label,
    String selectedOption, {
    bool showDivider = false,
  }) {
    final isSelected = selectedOption == value;
    final items = <PopupMenuEntry<String>>[
      PopupMenuItem(
        value: value,
        child: Row(
          children: [
            if (value == "None")
              Icon(
                isSelected ? Iconsax.tick_circle5 : Iconsax.close_circle,
                size: 18,
                color: isSelected ? Colors.purple : Colors.grey,
              )
            else if (isSelected)
              const Icon(Iconsax.tick_circle5, size: 18, color: Colors.purple)
            else
              const SizedBox(width: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: value == "None" && isSelected ? Colors.purple : null,
              ),
            ),
          ],
        ),
      ),
    ];

    if (showDivider) {
      items.add(const PopupMenuDivider());
    }

    return items.length == 1 ? items[0] : items[0];
  }
}
