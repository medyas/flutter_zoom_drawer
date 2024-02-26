import 'dart:math' show pi;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';

import 'drawer_styles/drawer_styles.dart';

/// Build custom style with (context, animationValue, slideWidth, menuScreen, mainScreen) {}
typedef DrawerStyleBuilder = Widget Function(
  BuildContext context,
  double animationValue,
  double slideWidth,
  Widget menuScreen,
  Widget mainScreen,
);

class ZoomDrawer extends StatefulWidget {
  const ZoomDrawer({
    required this.menuScreen,
    required this.mainScreen,
    this.style = DrawerStyle.defaultStyle,
    this.controller,
    this.mainScreenScale = 0.3,
    this.slideWidth = 275.0,
    this.slideHeight = 0,
    this.menuScreenWidth,
    this.borderRadius = 16.0,
    this.angle = -12.0,
    this.dragOffset = 60.0,
    this.openDragSensitivity = 425,
    this.closeDragSensitivity = 425,
    this.drawerShadowsBackgroundColor = const Color(0xffffffff),
    this.menuBackgroundColor = Colors.transparent,
    this.mainScreenOverlayColor,
    this.menuScreenOverlayColor,
    this.overlayBlend = BlendMode.srcATop,
    this.overlayBlur,
    this.shadowLayer1Color,
    this.shadowLayer2Color,
    this.showShadow = false,
    this.openCurve = const Interval(0.0, 1.0, curve: Curves.easeOut),
    this.closeCurve = const Interval(0.0, 1.0, curve: Curves.easeOut),
    this.duration = const Duration(milliseconds: 250),
    this.reverseDuration = const Duration(milliseconds: 250),
    this.androidCloseOnBackTap = false,
    this.moveMenuScreen = true,
    this.disableDragGesture = false,
    this.isRtl = false,
    this.clipMainScreen = true,
    this.mainScreenTapClose = false,
    this.menuScreenTapClose = false,
    this.mainScreenAbsorbPointer = true,
    this.shrinkMainScreen = false,
    this.boxShadow,
    this.drawerStyleBuilder,
  });

  /// Layout style
  final DrawerStyle style;

  /// controller to have access to the open/close/toggle function of the drawer
  final ZoomDrawerController? controller;

  /// Screen containing the menu/bottom screen
  final Widget menuScreen;

  /// Screen containing the main content to display
  final Widget mainScreen;

  /// MainScreen scale factor
  final double mainScreenScale;

  /// Sliding width of the drawer
  final double slideWidth;

  /// Sliding height of the drawer
  final double slideHeight;

  /// menuScreen Width
  /// Set it to double.infinity to make it take screen width
  final double? menuScreenWidth;

  /// Border radius of the slide content
  final double borderRadius;

  /// Rotation angle of the drawer
  final double angle;

  /// Background color of the menuScreen
  final Color menuBackgroundColor;

  /// Background color of the drawer shadows
  final Color drawerShadowsBackgroundColor;

  /// First shadow background color
  final Color? shadowLayer1Color;

  /// Second shadow background color
  final Color? shadowLayer2Color;

  /// Boolean, whether to show the drawer shadows - Applies to defaultStyle only
  final bool showShadow;

  /// Close drawer on android back button
  /// Note: This won't work if you are using PopScope in mainScreen,
  /// If that is the case, you have to manually close the drawer from there
  /// By using ZoomDrawer.of(context)?.close()
  final bool androidCloseOnBackTap;

  /// Make menuScreen slide along with mainScreen animation
  /// Has no effects to style1
  final bool moveMenuScreen;

  /// Drawer slide out curve
  final Curve openCurve;

  /// Drawer slide in curve
  final Curve closeCurve;

  /// Drawer forward Duration
  final Duration duration;

  /// Drawer reverse Duration
  final Duration reverseDuration;

  /// Disable swipe gesture
  final bool disableDragGesture;

  /// display the drawer in RTL
  final bool isRtl;

  /// Depreciated: Set [borderRadius] to 0 instead
  final bool clipMainScreen;

  /// The offset to trigger drawer drag
  final double dragOffset;

  /// How fast the opening drawer drag in response to a touch, the lower the more sensitive
  final double openDragSensitivity;

  /// How fast the closing drawer drag in response to a touch, the lower the more sensitive
  final double closeDragSensitivity;

  /// Color of the main screen's cover overlay
  final Color? mainScreenOverlayColor;

  /// Color of the menu screen's cover overlay
  final Color? menuScreenOverlayColor;

  /// The BlendMode of the [mainScreenOverlayColor] and [menuScreenOverlayColor] filter
  final BlendMode overlayBlend;

  /// Apply a Blur amount to the mainScreen
  final double? overlayBlur;

  /// The Shadow of the mainScreenWidget
  final List<BoxShadow>? boxShadow;

  /// Close drawer when tapping menuScreen
  final bool menuScreenTapClose;

  /// Close drawer when tapping mainScreen
  final bool mainScreenTapClose;

  /// Prevent touches to mainScreen while drawer is open
  final bool mainScreenAbsorbPointer;

  /// Shrinks the mainScreen by [slideWidth]
  final bool shrinkMainScreen;

  /// Build custom animated style to override [DrawerStyle]
  /// ```dart
  /// drawerStyleBuilder: (context, animationValue, slideWidth, menuScreen, mainScreen) {
  ///     double slide = slideWidth * animationValue;
  ///     return Stack(
  ///       children: [
  ///         menuScreen,
  ///         Transform(
  ///           transform: Matrix4.identity()..translate(slide),
  ///           alignment: Alignment.center,
  ///           child: mainScreen,
  ///         )]);
  ///   },
  /// ```
  final DrawerStyleBuilder? drawerStyleBuilder;

  @override
  ZoomDrawerState createState() => ZoomDrawerState();

  /// static function to provide the drawer state
  static ZoomDrawerState? of(BuildContext context) =>
      context.findAncestorStateOfType<ZoomDrawerState>();
}

class ZoomDrawerState extends State<ZoomDrawer>
    with SingleTickerProviderStateMixin {
  /// Triggers drag animation
  bool _shouldDrag = false;

  /// Decides where the drawer will reside in screen
  late int _slideDirection;

  /// Once drawer is open, _absorbingMainScreen will absorb any pointer to avoid
  /// mainScreen interactions
  late final ValueNotifier<bool> _absorbingMainScreen;

  /// Drawer state
  final ValueNotifier<DrawerState> _stateNotifier =
      ValueNotifier(DrawerState.closed);

  ValueNotifier<DrawerState> get stateNotifier => _stateNotifier;

  late final AnimationController _animationController = AnimationController(
    vsync: this,
    duration: widget.duration,
    reverseDuration: widget.duration,
  )..addStatusListener(_animationStatusListener);

  double get _animationValue => _animationController.value;

  /// Is similar to DrawerState but with only (open, closed) values
  /// Very useful case you want to know the drawer is either open or closed
  DrawerLastAction _drawerLastAction = DrawerLastAction.closed;

  DrawerLastAction get drawerLastAction => _drawerLastAction;

  /// Check whether drawer is open
  bool isOpen() => stateNotifier.value == DrawerState.open;

  /// Decides if drag animation should start according to dragOffset
  void _onHorizontalDragStart(DragStartDetails startDetails) {
    // Offset required to to open drawer
    final maxDragSlide = widget.isRtl
        ? context.screenWidth - widget.dragOffset
        : widget.dragOffset;

    // Will help us to set the offset according to RTL value
    // Without this user can open the drawer without respecing initial offset required
    final toggleValue = widget.isRtl
        ? _animationController.isCompleted
        : _animationController.isDismissed;

    final isDraggingFromLeft =
        toggleValue && startDetails.globalPosition.dx < maxDragSlide;

    final isDraggingFromRight =
        !toggleValue && startDetails.globalPosition.dx > maxDragSlide;

    _shouldDrag = isDraggingFromLeft || isDraggingFromRight;
  }

  /// Update animation value continuesly upon draging.
  void _onHorizontalDragUpdate(DragUpdateDetails updateDetails) {
    /// Drag animation can be triggered when _shouldDrag is true,
    /// or when DrawerState is opening or closing
    if (_shouldDrag == false &&
        ![DrawerState.opening, DrawerState.closing]
            .contains(_stateNotifier.value)) {
      return;
    }

    final dragSensitivity = drawerLastAction == DrawerLastAction.open
        ? widget.closeDragSensitivity
        : widget.openDragSensitivity;

    final delta = updateDetails.primaryDelta ?? 0 / widget.dragOffset;

    if (widget.isRtl) {
      _animationController.value -= delta / dragSensitivity;
    } else {
      _animationController.value += delta / dragSensitivity;
    }
  }

  /// Case _onHorizontalDragUpdate didn't complete its full drawer animation
  /// _onHorizontalDragEnd will decide where the drawer reside
  /// Whether continue to its destination or return to initial position
  void _onHorizontalDragEnd(DragEndDetails dragEndDetails) {
    if (_animationController.isDismissed || _animationController.isCompleted) {
      return;
    }

    /// Min swipe strength
    const minFlingVelocity = 350.0;

    /// Actual swipe strength
    final dragVelocity = dragEndDetails.velocity.pixelsPerSecond.dx.abs();

    // Shall drawer continue to its destination?
    final willFling = dragVelocity > minFlingVelocity;

    if (willFling) {
      // Strong swipe will cause the animation continue to its destination
      final visualVelocityInPx = dragEndDetails.velocity.pixelsPerSecond.dx /
          (context.screenWidth * 50);

      final visualVelocityInPxRTL = -visualVelocityInPx;

      _animationController.fling(
        velocity: widget.isRtl ? visualVelocityInPxRTL : visualVelocityInPx,
        animationBehavior: AnimationBehavior.preserve,
      );
    }

    /// We use DrawerLastAction instead of DrawerState,
    /// because on draging, Drawer state is always equal to DrawerState.opening.
    /// User must pass 35% of animation value to proceed the full animation,
    /// Otherwise, it will return to initial position
    else if (drawerLastAction == DrawerLastAction.open) {
      // Because drawer is open, Animation value starts from 1.0 to 0
      if (_animationController.value > 0.65) {
        // User have not passed 35% of animation value
        // Return back to initial position
        open();
        return;
      }
      // Continue animation to close the drawer
      close();
    } else if (drawerLastAction == DrawerLastAction.closed) {
      // Because drawer is closed, Animation value starts from 0 to 1.0
      if (_animationController.value < 0.35) {
        // User have not passed 35% of animation value
        // Return back to initial position
        close();
        return;
      }
      // Continue animation to open the drawer
      open();
    }
  }

  /// Close drawer on Tap
  void _mainScreenTapHandler() {
    if (widget.mainScreenTapClose && stateNotifier.value == DrawerState.open) {
      close();
    }
  }

  void _menuScreenTapHandler() {
    if (widget.menuScreenTapClose && stateNotifier.value == DrawerState.open) {
      close();
    }
  }

  /// Open drawer
  TickerFuture? open() {
    if (mounted) {
      return _animationController.forward();
    }
    return null;
  }

  /// Close drawer
  TickerFuture? close() {
    if (mounted) {
      return _animationController.reverse();
    }
    return null;
  }

  /// Toggle drawer,
  /// forceToggle: Will toggle even if it's currently animating - defaults to false
  TickerFuture? toggle({bool forceToggle = false}) {
    /// We use DrawerLastAction instead of DrawerState,
    /// because on draging, Drawer state is always equal to DrawerState.opening
    if (stateNotifier.value == DrawerState.open ||
        (forceToggle && drawerLastAction == DrawerLastAction.open)) {
      return close();
    } else if (stateNotifier.value == DrawerState.closed ||
        (forceToggle && drawerLastAction == DrawerLastAction.closed)) {
      return open();
    }
    return null;
  }

  /// Assign widget methods to controller
  void _assignToController() {
    if (widget.controller == null) return;

    widget.controller!.open = open;
    widget.controller!.close = close;
    widget.controller!.toggle = toggle;
    widget.controller!.isOpen = isOpen;
    widget.controller!.stateNotifier = stateNotifier;
  }

  /// Updates stateNotifier, drawerLastAction, and _absorbingMainScreen
  void _animationStatusListener(AnimationStatus status) {
    switch (status) {
      /// The to animation.fling causes the AnimationStatus to be
      /// emitted with forward & reverse for the same action
      /// Adding a check to determine if the drawer is in the process of opening or closing
      case AnimationStatus.forward:
        if (drawerLastAction == DrawerLastAction.open &&
            _animationController.value < 1) {
          _stateNotifier.value = DrawerState.closing;
        } else {
          _stateNotifier.value = DrawerState.opening;
        }
        break;
      case AnimationStatus.reverse:
        if (drawerLastAction == DrawerLastAction.closed &&
            _animationController.value > 0) {
          _stateNotifier.value = DrawerState.opening;
        } else {
          _stateNotifier.value = DrawerState.closing;
        }
        break;
      case AnimationStatus.completed:
        _stateNotifier.value = DrawerState.open;
        _drawerLastAction = DrawerLastAction.open;
        _absorbingMainScreen.value = widget.mainScreenAbsorbPointer;
        break;
      case AnimationStatus.dismissed:
        _stateNotifier.value = DrawerState.closed;
        _drawerLastAction = DrawerLastAction.closed;
        _absorbingMainScreen.value = false;
        break;
    }
  }

  @override
  void initState() {
    super.initState();

    _absorbingMainScreen = ValueNotifier(widget.mainScreenAbsorbPointer);

    _assignToController();

    _slideDirection = widget.isRtl ? -1 : 1;
  }

  @override
  void didUpdateWidget(covariant ZoomDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isRtl != widget.isRtl) {
      _slideDirection = widget.isRtl ? -1 : 1;
    }
  }

  @override
  void dispose() {
    _stateNotifier.dispose();
    _absorbingMainScreen.dispose();
    _animationController.dispose();
    super.dispose();
  }

  /// Build the widget based on the animation value
  ///
  /// * [container] is the widget to be displayed
  ///
  /// * [angle] is the the Z rotation angle
  ///
  /// * [scale] is a string to help identify this animation during
  ///   debugging (used by [toString]).
  ///
  /// * [slide] is the sliding amount of the drawer
  ///
  Widget _applyDefaultStyle(
    Widget? child, {
    double? angle,
    double scale = 1,
    double slide = 0,
  }) {
    double slidePercent;
    double scalePercent;

    /// Determine current slide percent based on the MenuStatus
    switch (stateNotifier.value) {
      case DrawerState.closed:
        slidePercent = 0.0;
        scalePercent = 0.0;
        break;
      case DrawerState.open:
        slidePercent = 1.0;
        scalePercent = 1.0;
        break;
      case DrawerState.opening:
        slidePercent = (widget.openCurve).transform(_animationValue);
        scalePercent = Interval(0.0, 0.3, curve: widget.openCurve)
            .transform(_animationValue);
        break;
      case DrawerState.closing:
        slidePercent = (widget.closeCurve).transform(_animationValue);
        scalePercent = Interval(0.0, 1.0, curve: widget.closeCurve)
            .transform(_animationValue);
        break;
    }

    /// Sliding X
    final xPosition =
        ((widget.slideWidth - slide) * _animationValue * _slideDirection) *
            slidePercent;

    /// Sliding Y
    final yPosition =
        ((widget.slideHeight - slide) * _animationValue * _slideDirection) *
            slidePercent;

    /// Scale
    final scalePercentage = scale - (widget.mainScreenScale * scalePercent);

    /// BorderRadius
    final radius = widget.borderRadius * _animationValue;

    /// Rotation
    final rotationAngle =
        ((((angle ?? widget.angle) * pi) / 180) * _animationValue) *
            _slideDirection;

    return Transform(
      transform: Matrix4.translationValues(xPosition, yPosition, 0.0)
        ..rotateZ(rotationAngle)
        ..scale(scalePercentage, scalePercentage),
      alignment: widget.isRtl ? Alignment.centerRight : Alignment.centerLeft,

      // We exclude mainScreen from ClipRRect because it already has borderRadius applied
      // Only mainScreen has Scale of 1 while others has < 1
      // We apply borderRadius to shadowLayer1Color and shadowLayer2Color
      child: scale == 1
          ? child
          : ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: child,
            ),
    );
  }

  /// Builds the layers of menuScreen
  Widget get menuScreenWidget {
    // Add layer - GestureDetector
    Widget menuScreen = GestureDetector(
      behavior: HitTestBehavior.translucent,
      // onTap shouldn't be null to avoid loosing state
      onTap: _menuScreenTapHandler,
      // Full width and hight to make menuScreen behind mainScreen
      child: SizedBox.expand(
        // Without Align, SizedBox won't work
        child: Align(
          alignment: widget.isRtl ? Alignment.topRight : Alignment.topLeft,
          // By default menuScreen width is calculated based on slideWidth
          // Unless user set menuScreenWidth
          child: SizedBox(
            width: widget.menuScreenWidth ??
                widget.slideWidth -
                    (context.screenWidth / widget.slideWidth) -
                    50,
            child: widget.menuScreen,
          ),
        ),
      ),
    );

    // Add layer - Transform
    if (widget.moveMenuScreen && widget.style != DrawerStyle.style1) {
      final left = (1 - _animationValue) * widget.slideWidth * _slideDirection;
      menuScreen = Transform.translate(
        offset: Offset(-left, 0),
        child: menuScreen,
      );
    }
    // Add layer - Overlay color
    // Material widget needs to be set after ColorFilter,
    // Storing Material widget in variable will make
    // ColorFiltered renders only 50% of the width
    if (widget.menuScreenOverlayColor != null) {
      final overlayColor = ColorTween(
        begin: widget.menuScreenOverlayColor,
        end: widget.menuScreenOverlayColor!.withOpacity(0.0),
      );

      menuScreen = ColorFiltered(
        colorFilter: ColorFilter.mode(
          overlayColor.lerp(_animationValue)!,
          widget.overlayBlend,
        ),
        child: ColoredBox(
          color: widget.menuBackgroundColor,
          child: menuScreen,
        ),
      );
    } else {
      menuScreen = ColoredBox(
        color: widget.menuBackgroundColor,
        child: menuScreen,
      );
    }

    return menuScreen;
  }

  /// Builds the layers of mainScreen
  Widget get mainScreenWidget {
    Widget mainScreen = widget.mainScreen;

    // Add layer - Shrink Screen
    if (widget.shrinkMainScreen) {
      final mainSize =
          context.screenWidth - (widget.slideWidth * _animationValue);
      mainScreen = SizedBox(
        width: mainSize,
        child: mainScreen,
      );
    }

    // Add layer - Overlay color
    if (widget.mainScreenOverlayColor != null) {
      final overlayColor = ColorTween(
        begin: widget.mainScreenOverlayColor!.withOpacity(0.0),
        end: widget.mainScreenOverlayColor,
      );
      mainScreen = ColorFiltered(
        colorFilter: ColorFilter.mode(
          overlayColor.lerp(_animationValue)!,
          widget.overlayBlend,
        ),
        child: mainScreen,
      );
    }

    // Add layer - Border radius
    if (widget.borderRadius != 0) {
      final borderRadius = widget.borderRadius * _animationValue;
      mainScreen = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: mainScreen,
      );
    }

    // Add layer - Box shadow
    if (widget.boxShadow != null) {
      final radius = widget.borderRadius * _animationValue;

      mainScreen = Container(
        margin: EdgeInsets.all(8.0 * _animationValue),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: widget.boxShadow ??
              [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 5,
                )
              ],
        ),
        child: mainScreen,
      );
    }

    // Add layer - Angle
    if (widget.angle != 0 && widget.style != DrawerStyle.defaultStyle) {
      final rotationAngle =
          (((widget.angle) * pi * _slideDirection) / 180) * _animationValue;
      mainScreen = Transform.rotate(
        angle: rotationAngle,
        alignment: widget.isRtl
            ? AlignmentDirectional.topEnd
            : AlignmentDirectional.topStart,
        child: mainScreen,
      );
    }

    // Add layer - Overlay blur
    if (widget.overlayBlur != null) {
      final blurAmount = widget.overlayBlur! * _animationValue;
      mainScreen = ImageFiltered(
        imageFilter: ImageFilter.blur(
          sigmaX: blurAmount,
          sigmaY: blurAmount,
        ),
        child: mainScreen,
      );
    }

    // Add layer - AbsorbPointer
    /// Prevents touches to mainScreen while drawer is open
    if (widget.mainScreenAbsorbPointer) {
      mainScreen = Stack(
        children: [
          mainScreen,
          ValueListenableBuilder(
            valueListenable: _absorbingMainScreen,
            builder: (_, bool valueNotifier, ___) {
              if (valueNotifier && stateNotifier.value == DrawerState.open) {
                return AbsorbPointer(
                  child: Container(
                    color: Colors.transparent,
                    width: context.screenWidth,
                    height: context.screenHeight,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      );
    }

    // Add layer - GestureDetector
    if (widget.mainScreenTapClose) {
      mainScreen = GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _mainScreenTapHandler,
        child: mainScreen,
      );
    }

    return mainScreen;
  }

  @override
  Widget build(BuildContext context) => _renderLayout();

  Widget _renderLayout() {
    Widget parentWidget;

    if (widget.drawerStyleBuilder != null) {
      parentWidget = AnimatedBuilder(
        animation: _animationController,
        builder: (context, _) => widget.drawerStyleBuilder!(
          context,
          _animationValue,
          widget.slideWidth,
          menuScreenWidget,
          mainScreenWidget,
        ),
      );
    } else {
      switch (widget.style) {
        case DrawerStyle.style1:
          parentWidget = AnimatedBuilder(
            animation: _animationController,
            builder: (context, _) => Style1Widget(
              animationValue: _animationValue,
              isRtl: widget.isRtl,
              mainScreenScale: widget.mainScreenScale,
              slideWidth: widget.slideWidth,
              menuBackgroundColor: widget.menuBackgroundColor,
              slideDirection: _slideDirection,
              mainScreenWidget: mainScreenWidget,
              menuScreenWidget: menuScreenWidget,
            ),
          );
          break;
        case DrawerStyle.style2:
          parentWidget = AnimatedBuilder(
            animation: _animationController,
            builder: (context, _) => Style2Widget(
              isRtl: widget.isRtl,
              mainScreenScale: widget.mainScreenScale,
              slideWidth: widget.slideWidth,
              slideDirection: _slideDirection,
              animationValue: _animationValue,
              menuScreenWidget: menuScreenWidget,
              mainScreenWidget: mainScreenWidget,
            ),
          );
          break;
        case DrawerStyle.style3:
          parentWidget = AnimatedBuilder(
            animation: _animationController,
            builder: (context, _) => Style3Widget(
              isRtl: widget.isRtl,
              mainScreenScale: widget.mainScreenScale,
              slideWidth: widget.slideWidth,
              animationValue: _animationValue,
              slideDirection: _slideDirection,
              menuScreenWidget: menuScreenWidget,
              mainScreenWidget: mainScreenWidget,
            ),
          );
          break;
        case DrawerStyle.style4:
          parentWidget = AnimatedBuilder(
            animation: _animationController,
            builder: (context, _) => Style4Widget(
              isRtl: widget.isRtl,
              mainScreenScale: widget.mainScreenScale,
              slideWidth: widget.slideWidth,
              animationValue: _animationValue,
              slideDirection: _slideDirection,
              menuScreenWidget: menuScreenWidget,
              mainScreenWidget: mainScreenWidget,
            ),
          );
          break;
        default:
          parentWidget = AnimatedBuilder(
            animation: _animationController,
            builder: (_, __) => StyleDefaultWidget(
              animationController: _animationController,
              mainScreenWidget: mainScreenWidget,
              menuScreenWidget: menuScreenWidget,
              angle: widget.angle,
              showShadow: widget.showShadow,
              shadowLayer1Color: widget.shadowLayer1Color,
              shadowLayer2Color: widget.shadowLayer2Color,
              drawerShadowsBackgroundColor: widget.drawerShadowsBackgroundColor,
              applyDefaultStyle: _applyDefaultStyle,
            ),
          );
      }
    }

    // Add layer - GestureDetector
    if (!widget.disableDragGesture) {
      parentWidget = GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragStart: _onHorizontalDragStart,
        onHorizontalDragUpdate: _onHorizontalDragUpdate,
        onHorizontalDragEnd: _onHorizontalDragEnd,
        child: parentWidget,
      );
    }

    // Add layer - PopScope
    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        widget.androidCloseOnBackTap) {
      parentWidget = PopScope(
        canPop: _canPop(),
        child: parentWidget,
      );
    }

    return parentWidget;
  }

  bool _canPop() {
    if ([DrawerState.open, DrawerState.opening].contains(stateNotifier.value)) {
      close();
      return false;
    }
    return true;
  }
}
