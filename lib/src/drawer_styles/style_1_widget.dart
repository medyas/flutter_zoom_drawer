import 'package:flutter/material.dart';

class Style1Widget extends StatelessWidget {
  const Style1Widget({
    Key? key,
    required this.animationValue,
    required this.mainScreenWidget,
    required this.menuScreenWidget,
    required this.slideDirection,
    required this.slideWidth,
    required this.mainScreenScale,
    required this.isRtl,
    this.menuBackgroundColor,
  }) : super(key: key);

  final double animationValue;
  final int slideDirection;
  final double slideWidth;
  final double mainScreenScale;
  final bool isRtl;
  final Widget mainScreenWidget;
  final Widget menuScreenWidget;
  final Color? menuBackgroundColor;

  @override
  Widget build(BuildContext context) {
    final xOffset = (1 - animationValue) * slideWidth * slideDirection;

    return Stack(
      children: [
        mainScreenWidget,
        Transform.translate(
          offset: Offset(-xOffset, 0),
          child: Container(
            width: slideWidth,
            color: menuBackgroundColor,
            child: menuScreenWidget,
          ),
        ),
      ],
    );
  }
}
