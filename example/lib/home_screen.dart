import 'package:easy_localization/easy_localization.dart';
import 'package:example/menu_page.dart';
import 'package:example/page_structure.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  static List<MenuItem> mainMenu = [
    MenuItem(tr("payment"), Icons.payment, 0),
    MenuItem(tr("promos"), Icons.card_giftcard, 1),
    MenuItem(tr("notifications"), Icons.notifications, 2),
    MenuItem(tr("help"), Icons.help, 3),
    MenuItem(tr("about_us"), Icons.info_outline, 4),
    MenuItem(tr("rate_us"), Icons.star_border, 5),
  ];

  @override
  _HomeScreenState createState() => new _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _drawerController = ZoomDrawerController();

  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return ZoomDrawer(
      controller: _drawerController,
      menuScreen: MenuScreen(
        HomeScreen.mainMenu,
        callback: _updatePage,
        current: _currentPage,
      ),
      mainScreen: MainScreen(),
      borderRadius: 24.0,
      showShadow: true,
      angle: -12.0,
      slideWidth:
          MediaQuery.of(context).size.width * (ZoomDrawer.isRTL() ? .45 : 0.65),
    );
  }

  void _updatePage(index) {
    Provider.of<MenuProvider>(context, listen: false).updateCurrentPage(index);
    _drawerController.toggle();
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  Widget build(BuildContext context) {
    return Selector<MenuProvider, int>(
      selector: (_, provider) => provider.currentPage,
      builder: (_, index, __) => PageStructure(
        title: "${HomeScreen.mainMenu[index].title} ${tr("page")}",
        backgroundColor: Colors.white,
        child: Container(
          color: Colors.grey[300],
          child: Center(
            child: Text(
                "${tr("current")}: ${HomeScreen.mainMenu[index].title}"),
          ),
        ),
      ),
    );
  }
}

class MenuProvider extends ChangeNotifier {
  int _currentPage = 0;

  int get currentPage => _currentPage;

  void updateCurrentPage(int index) {
    if (index != currentPage) {
      _currentPage = index;
      notifyListeners();
    }
  }
}
