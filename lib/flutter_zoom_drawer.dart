library flutter_zoom_drawer;

import 'dart:math' show pi;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_zoom_drawer/config.dart';

extension ZoomDrawerContext on BuildContext {
  DrawerLastAction? get drawerLastAction =>
      ZoomDrawer.of(this)?.drawerLastAction;
  DrawerState? get drawerState => ZoomDrawer.of(this)?.stateNotifier.value;
  _ZoomDrawerState? get drawer => ZoomDrawer.of(this);
}

class ZoomDrawer extends StatefulWidget {
  const ZoomDrawer({
    this.style = DrawerStyle.defaultStyle,
    this.controller,
    required this.menuScreen,
    required this.mainScreen,
    this.mainScreenScale = 0.3,
    this.slideWidth = 275.0,
    this.borderRadius = 16.0,
    this.angle = -12.0,
    this.drawerShadowsBackgroundColor = const Color(0xffffffff),
    this.mainBackgroundColor = Colors.blue,
    this.menuBackgroundColor = Colors.blueGrey,
    this.shadowLayer1Color,
    this.shadowLayer2Color,
    this.showShadow = false,
    this.androidCloseOnBackTap = true,
    this.openCurve,
    this.closeCurve,
    this.duration,
    this.disableDragGesture = false,
    this.isRtl = false,
    this.clipMainScreen = true,
    this.dragOffset = 60.0,
    this.openDragSensitivity = 425,
    this.closeDragSensitivity = 425,
    this.mainScreenOverlayColor,
    this.menuScreenOverlayColor,
    this.overlayBlend,
    this.overlayBlur,
    this.mainScreenTapClose = false,
    this.menuScreenTapClose = false,
    this.mainScreenAbsorbPointer = true,
    this.boxShadow,
    this.shrinkMainScreen = false,
    this.drawerStyleBuilder,
  }) : assert(angle <= 0.0 && angle >= -30.0);

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

  /// Sliding width of the drawer - defaults to 275.0
  final double slideWidth;

  /// Border radius of the slide content - defaults to 16.0
  final double borderRadius;

  /// Rotation angle of the drawer - defaults to -12.0
  final double angle;

  /// Background color of the parent widget (mainScreen and menuScreen together) - defaults to blue
  final Color mainBackgroundColor;

  /// Background color of the menuScreen - defaults to blueGrey
  final Color menuBackgroundColor;

  /// Background color of the drawer shadows - defaults to white
  final Color drawerShadowsBackgroundColor;

  /// First shadow background color
  final Color? shadowLayer1Color;

  /// Second shadow background color
  final Color? shadowLayer2Color;

  /// Depreciated: Set [boxShadow] to show shadow on [mainScreen]
  /// Boolean, whether to show the drawer shadows - Applies to Style1
  final bool showShadow;

  /// Close drawer on android back button
  /// Note: This won't work if you are using WillPopScope in mainScreen,
  /// If that is the case, you have to manually close the drawer from there
  /// By using ZoomDrawer.of(context)?.close()
  final bool androidCloseOnBackTap;

  /// Drawer slide out curve
  final Curve? openCurve;

  /// Drawer slide in curve
  final Curve? closeCurve;

  /// Drawer Duration
  final Duration? duration;

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

  /// The BlendMode of the [mainScreenOverlayColor] and [menuScreenOverlayColor] filter (default BlendMode.screen)
  final BlendMode? overlayBlend;

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

  /// Shrinks the mainScreen by [slideWidth], good for use on desktop with Style2
  final bool shrinkMainScreen;

  /// Build custom animated style to override [DrawerStyle]
  /// ```dart
  /// drawerStyleBuilder: (context, percentOpen, slideWidth, menuScreen, mainScreen) {
  ///     double slide = slideWidth * percentOpen;
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
  _ZoomDrawerState createState() => _ZoomDrawerState();

  /// static function to provide the drawer state
  static _ZoomDrawerState? of(BuildContext context) {
    return context.findAncestorStateOfType<State<ZoomDrawer>>()
        as _ZoomDrawerState?;
  }
}

class _ZoomDrawerState extends State<ZoomDrawer>
    with SingleTickerProviderStateMixin {
  final Curve _scaleDownCurve = const Interval(0.0, 0.3, curve: Curves.easeOut);
  final Curve _scaleUpCurve = const Interval(0.0, 1.0, curve: Curves.easeOut);
  final Curve _slideOutCurve = const Interval(0.0, 1.0, curve: Curves.easeOut);
  final Curve _slideInCurve = const Interval(0.0, 1.0, curve: Curves.easeOut);
  ColorTween _overlayColor =
      ColorTween(begin: Colors.transparent, end: Colors.black38);

  static bool _shouldDrag = false;

  /// Check the slide direction
  late int _rtlSlide;

  late final AnimationController _animationController;
  double get _animationValue => _animationController.value;

  DrawerLastAction drawerLastAction = DrawerLastAction.closed;

  /// Drawer state
  final ValueNotifier<DrawerState> stateNotifier =
      ValueNotifier(DrawerState.closed);

  /// Absorbing value
  late final ValueNotifier<bool> _absorbingMainScreen;

  /// Triggers drag animation
  void _onDragStart(DragStartDetails startDetails) {
    // Offset decided by user to open drawer
    final _maxDragSlide = widget.isRtl
        ? MediaQuery.of(context).size.width - widget.dragOffset
        : widget.dragOffset;

    // Will help us to set the offset according to RTL value
    // Without this user can open the drawer without respecing initial offset required
    final _toggleValue = widget.isRtl
        ? _animationController.isCompleted
        : _animationController.isDismissed;

    final _isDraggingFromLeft =
        _toggleValue && startDetails.globalPosition.dx < _maxDragSlide;

    final _isDraggingFromRight =
        !_toggleValue && startDetails.globalPosition.dx > _maxDragSlide;

    _shouldDrag = _isDraggingFromLeft || _isDraggingFromRight;
  }

  /// Update animation value continuesly upon draging
  void _onDragUpdate(DragUpdateDetails updateDetails) {
    if (_shouldDrag == false) {
      return;
    }

    final _dragSensitivity = drawerLastAction == DrawerLastAction.opened
        ? widget.closeDragSensitivity
        : widget.openDragSensitivity;

    final _delta = updateDetails.primaryDelta ?? 0 / widget.dragOffset;

    if (widget.isRtl) {
      _animationController.value -= _delta / _dragSensitivity;
    } else {
      _animationController.value += _delta / _dragSensitivity;
    }
  }

  /// Case _onDragUpdate didn't complete its full drawer animation
  /// _onDragEnd will decide where the drawer should go
  /// Whether continue to its destination or return to initial position
  void _onDragEnd(DragEndDetails dragEndDetails) {
    if (_animationController.isDismissed || _animationController.isCompleted) {
      return;
    }

    /// Min swipe strength
    const _minFlingVelocity = 350.0;

    /// Actual swipe strength
    final _dragVelocity = dragEndDetails.velocity.pixelsPerSecond.dx.abs();

    // Shall continue to its direction?
    final _willFling = _dragVelocity > _minFlingVelocity;

    if (_willFling) {
      // Strong swipe will cause the animation continue to its destination
      final _visualVelocityInPx = dragEndDetails.velocity.pixelsPerSecond.dx /
          (MediaQuery.of(context).size.width * 50);

      final _visualVelocityInPxRTL = -_visualVelocityInPx;

      _animationController.fling(
        velocity: widget.isRtl ? _visualVelocityInPxRTL : _visualVelocityInPx,
        animationBehavior: AnimationBehavior.normal,
      );
    }

    /// We use DrawerLastAction instead of DrawerState,
    /// because on draging, Drawer state is always equal to DrawerState.opening
    else if (drawerLastAction == DrawerLastAction.opened &&
        _animationController.value < 0.6) {
      // Continue animation to close the drawer
      close();
    } else if (drawerLastAction == DrawerLastAction.closed &&
        _animationController.value > 0.15) {
      // Continue animation to open the drawer
      open();
    } else if (drawerLastAction == DrawerLastAction.opened) {
      // Return back to initial position
      open();
    } else if (drawerLastAction == DrawerLastAction.closed) {
      // Return back to initial position
      close();
    }
  }

  // Whether to close drawer on Tap
  void _onTap() {
    if (widget.mainScreenTapClose && stateNotifier.value == DrawerState.open) {
      return close();
    }
  }

  /// Check whether drawer is open
  bool isOpen() => stateNotifier.value == DrawerState.open;

  /// Open drawer
  void open() {
    _animationController.forward();
  }

  /// Close drawer
  void close() {
    _animationController.reverse();
  }

  /// Toggle drawer,
  /// forceToggle: Will toggle even if it's currently animating - defaults to false
  void toggle({
    bool forceToggle = false,
  }) {
    /// We use DrawerLastAction instead of DrawerState,
    /// because on draging, Drawer state is always equal to DrawerState.opening
    if (stateNotifier.value == DrawerState.open ||
        (forceToggle && drawerLastAction == DrawerLastAction.opened)) {
      close();
    } else if (stateNotifier.value == DrawerState.closed ||
        (forceToggle && drawerLastAction == DrawerLastAction.closed)) {
      open();
    }
  }

  /// Assign controller function to the widget methods
  void _assignToController() {
    if (widget.controller == null) return;

    widget.controller!.open = open;
    widget.controller!.close = close;
    widget.controller!.toggle = toggle;
    widget.controller!.isOpen = isOpen;
    widget.controller!.stateNotifier = stateNotifier;
  }

  @override
  void initState() {
    super.initState();
    _absorbingMainScreen = ValueNotifier(widget.mainScreenAbsorbPointer);

    /// Initialize the animation controller
    /// add status listener to update the menuStatus
    _animationController = AnimationController(
      vsync: this,
      duration: widget.duration ?? const Duration(milliseconds: 250),
    )..addStatusListener((status) {
        switch (status) {
          case AnimationStatus.forward:
            stateNotifier.value = DrawerState.opening;
            break;
          case AnimationStatus.reverse:
            stateNotifier.value = DrawerState.closing;
            break;
          case AnimationStatus.completed:
            stateNotifier.value = DrawerState.open;
            drawerLastAction = DrawerLastAction.opened;
            _absorbingMainScreen.value = widget.mainScreenAbsorbPointer;
            break;
          case AnimationStatus.dismissed:
            stateNotifier.value = DrawerState.closed;
            drawerLastAction = DrawerLastAction.closed;
            _absorbingMainScreen.value = false;
            break;
        }
      });
    _assignToController();
    _rtlSlide = widget.isRtl ? -1 : 1;
  }

  @override
  void didUpdateWidget(covariant ZoomDrawer oldWidget) {
    if (oldWidget.isRtl != widget.isRtl) {
      _rtlSlide = widget.isRtl ? -1 : 1;
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    stateNotifier.dispose();
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
  Widget _zoomAndSlideContent(
    Widget? container, {
    double? angle,
    double? scale,
    double slide = 0,
    bool isMain = false,
  }) {
    double _slidePercent;
    double _scalePercent;

    /// determine current slide percent based on the MenuStatus
    switch (stateNotifier.value) {
      case DrawerState.closed:
        _slidePercent = 0.0;
        _scalePercent = 0.0;
        break;
      case DrawerState.open:
        _slidePercent = 1.0;
        _scalePercent = 1.0;
        break;
      case DrawerState.opening:
        _slidePercent =
            (widget.openCurve ?? _slideOutCurve).transform(_animationValue);
        _scalePercent = _scaleDownCurve.transform(_animationValue);
        break;
      case DrawerState.closing:
        _slidePercent =
            (widget.closeCurve ?? _slideInCurve).transform(_animationValue);
        _scalePercent = _scaleUpCurve.transform(_animationValue);
        break;
    }

    /// calculated sliding amount based on the RTL and animation value
    final _slideAmount =
        (widget.slideWidth - slide) * _slidePercent * _rtlSlide;

    /// calculated scale amount based on the provided scale and animation value
    final _contentScale =
        (scale ?? 1.0) - (widget.mainScreenScale * _scalePercent);

    /// calculated radius based on the provided radius and animation value
    final _cornerRadius = widget.borderRadius * _animationValue;

    /// calculated rotation amount based on the provided angle and animation value
    final _rotationAngle =
        (((angle ?? widget.angle) * pi * _rtlSlide) / 180) * _animationValue;

    return Transform(
      transform: Matrix4.translationValues(_slideAmount, 0.0, 0.0)
        ..rotateZ(_rotationAngle)
        ..scale(_contentScale, _contentScale),
      alignment: Alignment.centerLeft,
      child: isMain
          ? container
          : ClipRRect(
              borderRadius: BorderRadius.circular(_cornerRadius),
              child: container,
            ),
    );
  }

  /// Builds the layers of menuScreen
  Widget get menuScreenWidget {
    Widget _menuScreen = Material(
      color: widget.menuBackgroundColor,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (widget.menuScreenTapClose &&
              context.drawer?.stateNotifier.value == DrawerState.open) {
            return context.drawer?.close();
          }
        },
        child: widget.menuScreen,
      ),
    );

    // Add layer - Overlay color
    if (widget.menuScreenOverlayColor != null) {
      _overlayColor = ColorTween(
        begin: widget.menuScreenOverlayColor,
        end: widget.menuScreenOverlayColor!.withOpacity(0.0),
      );
      _menuScreen = ColorFiltered(
        colorFilter: ColorFilter.mode(
          _overlayColor.lerp(_animationValue)!,
          widget.overlayBlend ?? BlendMode.screen,
        ),
        child: _menuScreen,
      );
    }

    return _menuScreen;
  }

  /// Builds the layers of mainScreen
  Widget get mainScreenWidget {
    Widget _mainScreen = widget.mainScreen;

    // Add layer - Shrink Screen
    if (widget.shrinkMainScreen) {
      final _mainSize = MediaQuery.of(context).size.width -
          (widget.slideWidth * _animationValue);
      _mainScreen = SizedBox(
        width: _mainSize,
        child: _mainScreen,
      );
    }

    // Add layer - Overlay color
    if (widget.mainScreenOverlayColor != null) {
      _overlayColor = ColorTween(
        begin: widget.mainScreenOverlayColor!.withOpacity(0.0),
        end: widget.mainScreenOverlayColor,
      );
      _mainScreen = ColorFiltered(
        colorFilter: ColorFilter.mode(
          _overlayColor.lerp(_animationValue)!,
          widget.overlayBlend ?? BlendMode.screen,
        ),
        child: _mainScreen,
      );
    }

    // Add layer - Border radius
    if (widget.borderRadius != 0) {
      final _cornerRadius = widget.borderRadius * _animationValue;
      _mainScreen = ClipRRect(
        borderRadius: BorderRadius.circular(_cornerRadius),
        child: _mainScreen,
      );
    }

    // Add layer - Box shadow
    if (widget.boxShadow != null) {
      final _cornerRadius = widget.borderRadius * _animationValue;

      _mainScreen = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_cornerRadius),
          boxShadow: widget.boxShadow ??
              [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 5,
                )
              ],
        ),
        child: _mainScreen,
      );
    }

    // Add layer - Angle
    // Works on Style 1 only
    if (widget.angle != 0 && widget.style != DrawerStyle.style1) {
      final _rotationAngle =
          (((widget.angle) * pi * _rtlSlide) / 180) * _animationValue;
      _mainScreen = Transform.rotate(
        angle: _rotationAngle,
        alignment: widget.isRtl
            ? AlignmentDirectional.topEnd
            : AlignmentDirectional.topStart,
        child: _mainScreen,
      );
    }

    // Add layer - Overlay blur
    if (widget.overlayBlur != null) {
      final _blurAmount = widget.overlayBlur! * _animationValue;
      _mainScreen = ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: _blurAmount, sigmaY: _blurAmount),
        child: _mainScreen,
      );
    }

    // Add layer - AbsorbPointer
    /// Prevents touches to mainScreen while drawer is open
    if (widget.mainScreenAbsorbPointer) {
      _mainScreen = Stack(
        children: [
          _mainScreen,
          ValueListenableBuilder(
            valueListenable: _absorbingMainScreen,
            builder: (_, bool _valueNotifier, ___) {
              if (_valueNotifier && stateNotifier.value == DrawerState.open) {
                return AbsorbPointer(
                  child: Container(
                    color: Colors.transparent,
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      );
    }

    return _mainScreen;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: renderLayout(),
    );
  }

  Widget renderLayout() {
    Widget _parentWidget = renderDefault();

    switch (widget.style) {
      case DrawerStyle.style1:
        _parentWidget = renderStyle1();
        break;
      case DrawerStyle.style2:
        _parentWidget = renderStyle2();
        break;
      case DrawerStyle.style3:
        _parentWidget = renderStyle3();
        break;
      case DrawerStyle.style4:
        _parentWidget = renderStyle4();
        break;
      case DrawerStyle.style5:
        _parentWidget = renderStyle5();
        break;
      case DrawerStyle.style6:
        _parentWidget = renderStyle6();
        break;
      case DrawerStyle.style7:
        _parentWidget = renderStyle7();
        break;
      case DrawerStyle.style8:
        _parentWidget = renderStyle8();
        break;
      default:
        _parentWidget = renderDefault();
    }

    if (widget.drawerStyleBuilder != null) _parentWidget = renderCustomStyle();

    return WillPopScope(
      onWillPop: () async {
        // Case drawer is opened or will open, either way will close
        if (widget.androidCloseOnBackTap &&
            [DrawerState.open, DrawerState.opening]
                .contains(stateNotifier.value)) {
          close();
        }
        return false;
      },
      child: Material(
        color: widget.mainBackgroundColor,
        child: widget.disableDragGesture
            ? _parentWidget
            : GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragStart: _onDragStart,
                onHorizontalDragUpdate: _onDragUpdate,
                onHorizontalDragEnd: _onDragEnd,
                child: _parentWidget,
              ),
      ),
    );
  }

  Widget renderCustomStyle() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, _) {
        return widget.drawerStyleBuilder!(
          context,
          _animationValue,
          widget.slideWidth,
          menuScreenWidget,
          mainScreenWidget,
        );
      },
    );
  }

  Widget renderDefault() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (_, __) {
        final _slide = widget.slideWidth * _animationValue * _rtlSlide;
        final _scale = 1 - (_animationValue * widget.mainScreenScale);

        return Stack(
          children: [
            menuScreenWidget,
            Transform(
              transform: Matrix4.identity()
                ..translate(_slide)
                ..scale(_scale),
              alignment: Alignment.center,
              child: mainScreenWidget,
            )
          ],
        );
      },
    );
  }

  Widget renderStyle1() {
    final _slidePercent =
        widget.isRtl ? MediaQuery.of(context).size.width * .1 : 15.0;
    return Stack(
      children: [
        /// Displaying Menu screen
        AnimatedBuilder(
          animation: _animationController,
          builder: (_, __) => menuScreenWidget,
        ),

        if (widget.showShadow) ...[
          /// Displaying the first shadow
          AnimatedBuilder(
            animation: _animationController,
            builder: (_, w) => _zoomAndSlideContent(
              w,
              angle: (widget.angle == 0.0) ? 0.0 : widget.angle - 8,
              scale: .9,
              slide: _slidePercent * 2,
            ),
            child: Container(
              color: widget.shadowLayer1Color ??
                  widget.drawerShadowsBackgroundColor.withAlpha(60),
            ),
          ),

          /// Displaying the second shadow
          AnimatedBuilder(
            animation: _animationController,
            builder: (_, w) => _zoomAndSlideContent(
              w,
              angle: (widget.angle == 0.0) ? 0.0 : widget.angle - 4.0,
              scale: .95,
              slide: _slidePercent,
            ),
            child: Container(
              color: widget.shadowLayer2Color ??
                  widget.drawerShadowsBackgroundColor.withAlpha(180),
            ),
          )
        ],

        /// Displaying the Main screen
        AnimatedBuilder(
          animation: _animationController,
          builder: (_, __) => _zoomAndSlideContent(
            mainScreenWidget,
            isMain: true,
          ),
        ),
      ],
    );
  }

  Widget renderStyle2() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (_, __) {
        final _slide = widget.slideWidth * _rtlSlide * _animationValue;

        return Stack(
          children: [
            menuScreenWidget,
            Transform(
              transform: Matrix4.identity()..translate(_slide),
              alignment: Alignment.center,
              child: mainScreenWidget,
            ),
          ],
        );
      },
    );
  }

  Widget renderStyle3() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (_, __) {
        final _slide = widget.slideWidth * _animationValue * _rtlSlide;
        final _left = (1 - _animationValue) * widget.slideWidth * _rtlSlide;

        return Stack(
          children: [
            Transform(
              transform: Matrix4.identity()..translate(_slide),
              alignment: Alignment.center,
              child: mainScreenWidget,
            ),
            Transform.translate(
              offset: Offset(-_left, 0),
              child: SizedBox(
                width: widget.slideWidth,
                child: menuScreenWidget,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget renderStyle4() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (_, __) {
        final _left = (1 - _animationValue) * widget.slideWidth * _rtlSlide;

        return Stack(
          children: [
            mainScreenWidget,
            Transform.translate(
              offset: Offset(-_left, 0),
              child: SizedBox(
                width: widget.slideWidth,
                child: menuScreenWidget,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget renderStyle5() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (_, __) {
        final _slide = widget.slideWidth * _rtlSlide * _animationValue;
        final _scale = 1 - (_animationValue * widget.mainScreenScale);
        final _top = _animationValue * widget.slideWidth;

        return Stack(
          children: [
            menuScreenWidget,
            Transform(
              transform: Matrix4.identity()
                ..translate(_slide, _top)
                ..scale(_scale),
              alignment: Alignment.center,
              child: mainScreenWidget,
            ),
          ],
        );
      },
    );
  }

  Widget renderStyle6() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (_, __) {
        final slideWidth =
            widget.isRtl ? widget.slideWidth : widget.slideWidth / 2;
        final _x = _animationValue * slideWidth * _rtlSlide;
        final _scale = 1 - (_animationValue * widget.mainScreenScale);
        final _rotate = _animationValue * (pi / 4);

        return Stack(
          children: [
            menuScreenWidget,
            Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0009)
                ..translate(_x)
                ..scale(_scale)
                ..rotateY(_rotate * _rtlSlide),
              alignment: Alignment.centerRight,
              child: mainScreenWidget,
            ),
          ],
        );
      },
    );
  }

  Widget renderStyle7() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (_, __) {
        final _slideWidth =
            widget.isRtl ? widget.slideWidth * 1.2 : widget.slideWidth / 2;
        final _x = _animationValue * _slideWidth * _rtlSlide;
        final _scale = 1 - (_animationValue * widget.mainScreenScale);
        final _rotate = _animationValue * (pi / 4);

        return Stack(
          children: [
            menuScreenWidget,
            Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0009)
                ..translate(_x)
                ..scale(_scale)
                ..rotateY(-_rotate * _rtlSlide),
              alignment: Alignment.centerRight,
              child: mainScreenWidget,
            ),
          ],
        );
      },
    );
  }

  Widget renderStyle8() {
    final _width = MediaQuery.of(context).size.width;
    final _rightSlide = _width *
        ((_width < 500)
            ? .6
            : (_width > 500 && (_width < 1000))
                ? .4
                : .2);
    return AnimatedBuilder(
      animation: _animationController,
      builder: (_, __) {
        final _slide = _rightSlide * _animationController.value * _rtlSlide;
        final _left =
            (1 - _animationController.value) * _rightSlide * _rtlSlide;
        return Stack(
          children: [
            Transform(
              transform: Matrix4.identity()..translate(_slide),
              alignment: Alignment.center,
              child: mainScreenWidget,
            ),
            Transform.translate(
              offset: Offset(-_left, 0),
              child: SizedBox(
                width: _rightSlide,
                child: menuScreenWidget,
              ),
            ),
          ],
        );
      },
    );
  }
}
