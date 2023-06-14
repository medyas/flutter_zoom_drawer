import 'package:flutter/material.dart';

class Style2Widget extends StatelessWidget {
  const Style2Widget({
    Key? key,
    required this.animationValue,
    required this.menuScreenWidget,
    required this.mainScreenWidget,
    required this.slideDirection,
    required this.slideWidth,
    required this.mainScreenScale,
    required this.isRtl,
  }) : super(key: key);

  final int slideDirection;
  final double slideWidth;
  final double mainScreenScale;
  final bool isRtl;
  final double animationValue;
  final Widget menuScreenWidget;
  final Widget mainScreenWidget;

  @override
  Widget build(BuildContext context) {
    final xPosition = slideWidth * slideDirection * animationValue;
    final yPosition = animationValue * slideWidth;
    final scalePercentage = 1 - (animationValue * mainScreenScale);

    return Stack(
      children: [
        menuScreenWidget,
        Transform(
          transform: Matrix4.identity()
            ..translate(xPosition, yPosition)
            ..scale(scalePercentage),
          alignment: Alignment.center,
          child: mainScreenWidget,
        ),
      ],
    );
  }
}
