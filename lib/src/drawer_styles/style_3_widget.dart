import 'dart:math';

import 'package:flutter/material.dart';

class Style3Widget extends StatelessWidget {
  const Style3Widget({
    Key? key,
    required this.animationValue,
    required this.slideDirection,
    required this.menuScreenWidget,
    required this.mainScreenWidget,
    required this.slideWidth,
    required this.mainScreenScale,
    required this.isRtl,
  }) : super(key: key);

  final double animationValue;
  final int slideDirection;
  final double slideWidth;
  final double mainScreenScale;
  final bool isRtl;
  final Widget menuScreenWidget;
  final Widget mainScreenWidget;

  @override
  Widget build(BuildContext context) {
    final xPosition = (slideWidth / 2) * animationValue * slideDirection;
    final scalePercentage = 1 - (animationValue * mainScreenScale);
    final yAngle = animationValue * (pi / 4) * slideDirection;

    return Stack(
      children: [
        menuScreenWidget,
        Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0009)
            ..translate(xPosition)
            ..scale(scalePercentage)
            ..rotateY(yAngle),
          alignment: isRtl ? Alignment.centerLeft : Alignment.centerRight,
          child: mainScreenWidget,
        ),
      ],
    );
  }
}
