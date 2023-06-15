import 'package:flutter/material.dart';

class StyleDefaultWidget extends StatelessWidget {
  const StyleDefaultWidget({
    super.key,
    required this.animationController,
    required this.showShadow,
    required this.angle,
    required this.menuScreenWidget,
    required this.mainScreenWidget,
    this.shadowLayer1Color,
    this.shadowLayer2Color,
    required this.drawerShadowsBackgroundColor,
    required this.applyDefaultStyle,
  });

  final AnimationController animationController;
  final bool showShadow;
  final double angle;
  final Widget menuScreenWidget;
  final Widget mainScreenWidget;
  final Color? shadowLayer1Color;
  final Color? shadowLayer2Color;
  final Color drawerShadowsBackgroundColor;
  final Widget Function(
    Widget?, {
    double? angle,
    double scale,
    double slide,
  }) applyDefaultStyle;

  @override
  Widget build(BuildContext context) {
    const slidePercent = 15.0;

    return Stack(
      children: [
        menuScreenWidget,
        if (showShadow) ...[
          /// Displaying the first shadow
          applyDefaultStyle(
            Container(
              color: shadowLayer1Color ??
                  drawerShadowsBackgroundColor.withAlpha(60),
            ),
            angle: (angle == 0.0) ? 0.0 : angle - 8,
            scale: .9,
            slide: slidePercent * 2,
          ),

          /// Displaying the second shadow
          applyDefaultStyle(
            Container(
              color: shadowLayer2Color ??
                  drawerShadowsBackgroundColor.withAlpha(180),
            ),
            angle: (angle == 0.0) ? 0.0 : angle - 4.0,
            scale: .95,
            slide: slidePercent,
          )
        ],

        /// Displaying the Main screen
        applyDefaultStyle(
          mainScreenWidget,
        ),
      ],
    );
  }
}
