import 'package:example/menu_page.dart';
import 'package:example/page_structure.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {

  static const List<MenuItem> MAIN_MENU = [
    MenuItem("Payment", Icons.payment, 0),
    MenuItem("Promos", Icons.card_giftcard, 1),
    MenuItem("Notification", Icons.notifications, 2),
    MenuItem("Help", Icons.help, 3),
    MenuItem("About Us", Icons.info_outline, 4),
    MenuItem("Rate Us", Icons.star_border, 5),
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
        HomeScreen.MAIN_MENU,
        callback: _updatePage,
        current: _currentPage,
      ),
      mainScreen: MainScreen(),
      borderRadius: 24.0,
      showShadow: false,
      angle: 0.0,
      backgroundColor: Colors.grey[300],
      slideWidth: MediaQuery.of(context).size.width*.65,
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
        title: "${HomeScreen.MAIN_MENU[index].title} Page",
        backgroundColor: Colors.white,
        child: Container(
          color: Colors.grey[300],
          child: Center(
            child: Text("Current Page: ${HomeScreen.MAIN_MENU[index].title}"),
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
