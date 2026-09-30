import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:alkirtas/models/home_section.dart';
import 'package:alkirtas/navigation_menu.dart';
import 'package:alkirtas/utils/constants/colors.dart';
import 'package:alkirtas/utils/backendData/userData.dart';
import 'package:alkirtas/features/authentication/screens/login/log_in.dart';
import 'package:alkirtas/features/authentication/screens/splash_wrapper.dart';
import 'package:alkirtas/common/widgets/custom_shapes/containers/searchContainer.dart';
import 'package:alkirtas/common/widgets/products/cart/cart_menu_icon.dart';
import '../widgets/home_search_overlay.dart';
import 'editorial_repository.dart';
import 'editorial_product.dart';
import 'editorial_widgets.dart';
import 'editorial_department.dart';

class EditorialHomeScreen extends StatefulWidget {
  const EditorialHomeScreen(
      {super.key,
      this.repository,
      this.onCategory,
      this.onMenu,
      this.onCart,
      this.showCartCounter = true});
  final EditorialRepository? repository;
  final void Function(int, String)? onCategory;
  final VoidCallback? onMenu, onCart;
  final bool showCartCounter;
  @override
  State<EditorialHomeScreen> createState() => _EditorialHomeScreenState();
}

class _EditorialHomeScreenState extends State<EditorialHomeScreen> {
  late final EditorialRepository _repository;
  late Future<List<HomeSection>> _sections;
  late Future<List<EditorialProduct>> _deals;
  bool _searching = false;
  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? EditorialRepository();
    _sections = _repository.sections();
    _deals = _repository.deals();
  }

  void _category(int id, String name) {
    if (widget.onCategory != null) {
      widget.onCategory!(id, name);
      return;
    }
    Get.find<NavigationController>()
        .navigateToStoreDrawer(categoryId: id, categoryName: name);
  }

  void _menu() => widget.onMenu != null
      ? widget.onMenu!()
      : Get.find<NavigationController>().navigateToMenu();
  void _cart() {
    if (widget.onCart != null) {
      widget.onCart!();
      return;
    }
    if (UserData.id.isEmpty) {
      Get.to(() => LoginScreen());
      return;
    }
    Get.find<NavigationController>().navigateToCart();
  }

  Future<void> _refresh() async {
    _repository.clear();
    setState(() {
      _sections = _repository.sections();
      _deals = _repository.deals();
    });
    await Future.wait([_sections, _deals]);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF191919)
            : const Color(0xFFFFFEFC),
        body: SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                key: const PageStorageKey('editorial-home'),
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  Center(
                      child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 760),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Expanded(
                                        child: Text('ALKIRTAS',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 27,
                                                letterSpacing: -0.8,
                                                color:
                                                    AlkColors.AppFirstColor))),
                                    IconButton(
                                        onPressed: _menu,
                                        tooltip: 'Explorer les catégories',
                                        icon: const Icon(
                                            Icons.grid_view_rounded,
                                            size: 23)),
                                    if (widget.showCartCounter)
                                      AlkCartCounterIcon(
                                          onPressed: _cart,
                                          iconColor: editorialInk(context))
                                    else
                                      IconButton(
                                          onPressed: _cart,
                                          tooltip: 'Panier',
                                          icon: const Icon(
                                              Icons.shopping_bag_outlined)),
                                  ]),
                                  const SizedBox(height: 12),
                                  if (_searching)
                                    HomeSearchBar(
                                        onClose: () =>
                                            setState(() => _searching = false))
                                  else
                                    AlkSearchContainer(
                                      text: 'Une envie, un produit…',
                                      icon: Icons.search,
                                      showQrButton: true,
                                      padding: EdgeInsets.zero,
                                      showBorder: false,
                                      onPressed: () =>
                                          setState(() => _searching = true),
                                    ),
                                  const SizedBox(height: 20),
                                  _EditorialHero(onExplore: _menu),
                                  FutureBuilder<List<EditorialProduct>>(
                                    future: _deals,
                                    builder: (context, snapshot) {
                                      final products = snapshot.data ?? [];
                                      if (products.isEmpty) {
                                        return const SizedBox.shrink();
                                      }
                                      return Padding(
                                          padding: const EdgeInsets.only(
                                              top: 24, bottom: 28),
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text('À saisir',
                                                    style: editorialTitle(
                                                        context)),
                                                const SizedBox(height: 4),
                                                Text(
                                                    'Notre sélection du moment',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall),
                                                const SizedBox(height: 14),
                                                EditorialProductShelf(
                                                    products: products
                                                        .take(5)
                                                        .toList()),
                                              ]));
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  FutureBuilder<List<HomeSection>>(
                                    future: _sections,
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState !=
                                          ConnectionState.done) {
                                        return const SizedBox(
                                            height: 260,
                                            child: Center(
                                                child:
                                                    CircularProgressIndicator()));
                                      }
                                      final sections = snapshot.data ?? [];
                                      if (sections.isEmpty) {
                                        return Padding(
                                            padding: const EdgeInsets.all(24),
                                            child: Column(children: [
                                              const Text(
                                                  'Les univers sont momentanément indisponibles.'),
                                              TextButton(
                                                  onPressed: _refresh,
                                                  child:
                                                      const Text('Réessayer')),
                                              TextButton(
                                                  onPressed: _menu,
                                                  child: const Text(
                                                      'Explorer la boutique')),
                                            ]));
                                      }
                                      return Column(children: [
                                        for (var i = 0;
                                            i < sections.length;
                                            i++)
                                          EditorialDepartment(
                                            key: ValueKey(
                                                '${sections[i].title}:${sections[i].tabs.map((t) => t.categoryId).join(',')}:$i'),
                                            section: sections[i],
                                            index: i,
                                            repository: _repository,
                                            onCategory: _category,
                                          ),
                                      ]);
                                    },
                                  ),
                                  Center(
                                      child: TextButton.icon(
                                          onPressed: _menu,
                                          icon: const Icon(
                                              Icons.grid_view_rounded,
                                              size: 18),
                                          label: const Text(
                                              'Explorer toute la boutique'))),
                                ]),
                          ))),
                ],
              ),
            )),
      );
}

class _EditorialHero extends StatefulWidget {
  const _EditorialHero({required this.onExplore});
  final VoidCallback onExplore;
  @override
  State<_EditorialHero> createState() => _EditorialHeroState();
}

class _EditorialHeroState extends State<_EditorialHero> {
  int _page = 0;
  @override
  Widget build(BuildContext context) {
    final banners = SplashWrapper.preloadedBannerUrls;
    if (banners.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            color: editorialPaper(context),
            borderRadius: BorderRadius.circular(18)),
        child: Row(children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Les belles\ntrouvailles',
                    style: editorialTitle(context).copyWith(fontSize: 30)),
                const SizedBox(height: 8),
                const Text('De nouvelles envies, chaque jour.'),
                TextButton(
                    onPressed: widget.onExplore,
                    child: const Text('Explorer →')),
              ])),
          Icon(Icons.auto_awesome_outlined,
              size: 56, color: AlkColors.AppFirstColor.withOpacity(0.4)),
        ]),
      );
    }
    return Column(children: [
      ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: AspectRatio(
            aspectRatio: 2.4,
            child: PageView.builder(
              itemCount: banners.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (_, i) => InkWell(
                  onTap: widget.onExplore,
                  child: EditorialImage(url: banners[i], fit: BoxFit.contain)),
            ),
          )),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(
            child: Text('Les belles trouvailles',
                style: editorialTitle(context).copyWith(fontSize: 19))),
        for (var i = 0; i < banners.length; i++)
          Container(
              width: i == _page ? 18 : 5,
              height: 5,
              margin: const EdgeInsets.only(left: 5),
              decoration: BoxDecoration(
                  color: i == _page
                      ? AlkColors.AppFirstColor
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(6))),
      ]),
    ]);
  }
}
