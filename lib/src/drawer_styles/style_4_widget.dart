import 'dart:math';

import 'package:flutter/material.dart';

class Style4Widget extends StatelessWidget {
  const Style4Widget({
    Key? key,
    required this.animationValue,
    required this.slideDirection,
    required this.menuScreenWidget,
    required this.mainScreenWidget,
    required this.mainScreenScale,
    required this.slideWidth,
    required this.isRtl,
  }) : super(key: key);

  final double animationValue;
  final double slideWidth;
  final double mainScreenScale;
  final bool isRtl;
  final int slideDirection;
  final Widget menuScreenWidget;
  final Widget mainScreenWidget;

  @override
  Widget build(BuildContext context) {
    final xPosition = (slideWidth * 1.2) * animationValue * slideDirection;
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
            ..rotateY(-yAngle),
          alignment: isRtl ? Alignment.centerRight : Alignment.centerLeft,
          child: mainScreenWidget,
        ),
      ],
    );
  }
}
