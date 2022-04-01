import 'package:easy_localization/easy_localization.dart';
import 'package:example/menu_page.dart';
import 'package:example/page_structure.dart';
import 'package:flutter/material.dart';
import 'package:flutter_zoom_drawer/config.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  static List<MenuItem> mainMenu = [
    MenuItem(tr("payment"), Icons.payment, 0),
    MenuItem(tr("promos"), Icons.card_giftcard, 1),
    MenuItem(tr("notifications"), Icons.notifications, 2),
    MenuItem(tr("help"), Icons.help, 3),
    MenuItem(tr("about_us"), Icons.info_outline, 4),
  ];

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _drawerController = ZoomDrawerController();

  @override
  Widget build(BuildContext context) {
    final _isRtl = context.locale.languageCode == "ar";
    return ZoomDrawer(
      controller: _drawerController,
      menuScreen: MenuScreen(
        HomeScreen.mainMenu,
        callback: _updatePage,
        current: 0,
      ),
      mainScreen: MainScreen(),
      openCurve: Curves.fastOutSlowIn,
      borderRadius: 32.0,
      style: DrawerStyle.style8,
      showShadow: true,
      angle: 0.0,
      slideWidth: MediaQuery.of(context).size.width * (_isRtl ? .55 : 0.65),
      isRtl: _isRtl,
      mainScreenTapClose: true,
      overlayColor: Colors.brown.withOpacity(0.5),
      boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 12)],
    );
  }

  void _updatePage(int index) {
    context.read<MenuProvider>().updateCurrentPage(index);
    _drawerController.toggle?.call();
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  Widget build(BuildContext context) {
    final rtl = context.locale.languageCode == "ar";
    return ValueListenableBuilder<DrawerState>(
      valueListenable: ZoomDrawer.of(context)!.stateNotifier,
      builder: (context, state, child) {
        return AbsorbPointer(
          absorbing: state != DrawerState.closed,
          child: child,
        );
      },
      child: GestureDetector(
        child: const PageStructure(),
        onPanUpdate: (details) {
          if (details.delta.dx < 6 && !rtl || details.delta.dx < -6 && rtl) {
            ZoomDrawer.of(context)?.toggle.call();
          }
        },
      ),
    );
  }
}

class MenuProvider extends ChangeNotifier {
  int _currentPage = 0;

  int get currentPage => _currentPage;

  void updateCurrentPage(int index) {
    if (index == currentPage) return;
    _currentPage = index;
    notifyListeners();
  }
}
