library flutter_zoom_drawer;

import 'dart:io';
import 'dart:math' show pi;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_zoom_drawer/config.dart';

extension ZoomDrawerContext on BuildContext {
  _ZoomDrawerState? get drawer => ZoomDrawer.of(this);

  DrawerLastAction? get drawerLastAction =>
      ZoomDrawer.of(this)?.drawerLastAction;

  DrawerState? get drawerState => ZoomDrawer.of(this)?.stateNotifier.value;

  ValueNotifier<DrawerState>? get drawerStateNotifier =>
      ZoomDrawer.of(this)?.stateNotifier;

  double get _screenWidth => MediaQuery.of(this).size.width;
  double get _screenHeight => MediaQuery.of(this).size.height;
}

class ZoomDrawer extends StatefulWidget {
  const ZoomDrawer({
    required this.menuScreen,
    required this.mainScreen,
    this.style = DrawerStyle.defaultStyle,
    this.controller,
    this.mainScreenScale = 0.3,
    this.slideWidth = 275.0,
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
    this.overlayBlend,
    this.overlayBlur,
    this.shadowLayer1Color,
    this.shadowLayer2Color,
    this.showShadow = false,
    this.openCurve = const Interval(0.0, 1.0, curve: Curves.easeOut),
    this.closeCurve = const Interval(0.0, 1.0, curve: Curves.easeOut),
    this.duration = const Duration(milliseconds: 250),
    this.reverseDuration = const Duration(milliseconds: 250),
    this.androidCloseOnBackTap = true,
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

  /// menuScreen Width
  final double? menuScreenWidth;

  /// Border radius of the slide content - defaults to 16.0
  final double borderRadius;

  /// Rotation angle of the drawer - defaults to -12.0
  final double angle;

  /// Background color of the menuScreen - defaults to transparent
  final Color menuBackgroundColor;

  /// Background color of the drawer shadows - defaults to white
  final Color drawerShadowsBackgroundColor;

  /// First shadow background color
  final Color? shadowLayer1Color;

  /// Second shadow background color
  final Color? shadowLayer2Color;

  /// Depreciated: Set [boxShadow] to show shadow on [mainScreen]
  /// Boolean, whether to show the drawer shadows - Applies to defaultStyle
  final bool showShadow;

  /// Close drawer on android back button
  /// Note: This won't work if you are using WillPopScope in mainScreen,
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
  _ZoomDrawerState createState() => _ZoomDrawerState();

  /// static function to provide the drawer state
  static _ZoomDrawerState? of(BuildContext context) {
    return context.findAncestorStateOfType<State<ZoomDrawer>>()
        as _ZoomDrawerState?;
  }
}

class _ZoomDrawerState extends State<ZoomDrawer>
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

  late final AnimationController _animationController;
  double get animationValue => _animationController.value;

  /// Is similar to DrawerState but with only (open, closed) values
  /// Very useful case you want to know the drawer is either open or closed
  DrawerLastAction _drawerLastAction = DrawerLastAction.closed;
  DrawerLastAction get drawerLastAction => _drawerLastAction;

  /// Check whether drawer is open
  bool isOpen() => stateNotifier.value == DrawerState.open;

  /// Decides if drag animation should start
  void _onHorizontalDragStart(DragStartDetails startDetails) {
    // Offset decided by user to open drawer
    final _maxDragSlide = widget.isRtl
        ? context._screenWidth - widget.dragOffset
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

  /// If drag animation is triggered, this will
  /// update animation value continuesly upon draging
  void _onHorizontalDragUpdate(DragUpdateDetails updateDetails) {
    if (_shouldDrag == false) return;

    final _dragSensitivity = drawerLastAction == DrawerLastAction.open
        ? widget.closeDragSensitivity
        : widget.openDragSensitivity;

    final _delta = updateDetails.primaryDelta ?? 0 / widget.dragOffset;

    if (widget.isRtl) {
      _animationController.value -= _delta / _dragSensitivity;
    } else {
      _animationController.value += _delta / _dragSensitivity;
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
    const _minFlingVelocity = 350.0;

    /// Actual swipe strength
    final _dragVelocity = dragEndDetails.velocity.pixelsPerSecond.dx.abs();

    // Shall drawer continue to its destination?
    final _willFling = _dragVelocity > _minFlingVelocity;

    if (_willFling) {
      // Strong swipe will cause the animation continue to its destination
      final _visualVelocityInPx = dragEndDetails.velocity.pixelsPerSecond.dx /
          (context._screenWidth * 50);

      final _visualVelocityInPxRTL = -_visualVelocityInPx;

      _animationController.fling(
        velocity: widget.isRtl ? _visualVelocityInPxRTL : _visualVelocityInPx,
        animationBehavior: AnimationBehavior.normal,
      );
    }

    /// We use DrawerLastAction instead of DrawerState,
    /// because on draging, Drawer state is always equal to DrawerState.opening
    else if (drawerLastAction == DrawerLastAction.open &&
        _animationController.value < 0.6) {
      // Continue animation to close the drawer
      close();
    } else if (drawerLastAction == DrawerLastAction.closed &&
        _animationController.value > 0.15) {
      // Continue animation to open the drawer
      open();
    } else if (drawerLastAction == DrawerLastAction.open) {
      // Return back to initial position
      open();
    } else if (drawerLastAction == DrawerLastAction.closed) {
      // Return back to initial position
      close();
    }
  }

  /// Close drawer on Tap
  void _onTap() {
    if (widget.mainScreenTapClose && stateNotifier.value == DrawerState.open) {
      return close();
    }
  }

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
  void toggle({bool forceToggle = false}) {
    /// We use DrawerLastAction instead of DrawerState,
    /// because on draging, Drawer state is always equal to DrawerState.opening
    if (stateNotifier.value == DrawerState.open ||
        (forceToggle && drawerLastAction == DrawerLastAction.open)) {
      close();
    } else if (stateNotifier.value == DrawerState.closed ||
        (forceToggle && drawerLastAction == DrawerLastAction.closed)) {
      open();
    }
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
      case AnimationStatus.forward:
        stateNotifier.value = DrawerState.opening;
        break;
      case AnimationStatus.reverse:
        stateNotifier.value = DrawerState.closing;
        break;
      case AnimationStatus.completed:
        stateNotifier.value = DrawerState.open;
        _drawerLastAction = DrawerLastAction.open;
        _absorbingMainScreen.value = widget.mainScreenAbsorbPointer;
        break;
      case AnimationStatus.dismissed:
        stateNotifier.value = DrawerState.closed;
        _drawerLastAction = DrawerLastAction.closed;
        _absorbingMainScreen.value = false;
        break;
    }
  }

  @override
  void initState() {
    super.initState();

    _absorbingMainScreen = ValueNotifier(widget.mainScreenAbsorbPointer);

    _animationController = AnimationController(
      vsync: this,
      duration: widget.duration,
      reverseDuration: widget.duration,
    )..addStatusListener(_animationStatusListener);

    _assignToController();

    _slideDirection = widget.isRtl ? -1 : 1;
  }

  @override
  void didUpdateWidget(covariant ZoomDrawer oldWidget) {
    if (oldWidget.isRtl != widget.isRtl) {
      _slideDirection = widget.isRtl ? -1 : 1;
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
    double scale = 1,
    double slide = 0,
  }) {
    double _slidePercent;
    double _scalePercent;

    /// Determine current slide percent based on the MenuStatus
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
        _slidePercent = (widget.openCurve).transform(animationValue);
        _scalePercent = Interval(0.0, 0.3, curve: widget.openCurve)
            .transform(animationValue);
        break;
      case DrawerState.closing:
        _slidePercent = (widget.closeCurve).transform(animationValue);
        _scalePercent = Interval(0.0, 1.0, curve: widget.closeCurve)
            .transform(animationValue);
        break;
    }

    /// calculated sliding amount based on the RTL and animation value
    final _slidePercentage =
        ((widget.slideWidth - slide) * animationValue * _slideDirection) *
            _slidePercent;

    /// calculated scale amount based on the provided scale and animation value
    final _scalePercentage = scale - (widget.mainScreenScale * _scalePercent);

    /// calculated radius based on the provided radius and animation value
    final _cornerRadius = widget.borderRadius * animationValue;

    /// calculated rotation amount based on the provided angle and animation value
    final _rotationAngle =
        ((((angle ?? widget.angle) * pi) / 180) * animationValue) *
            _slideDirection;

    return Transform(
      transform: Matrix4.translationValues(_slidePercentage, 0.0, 0.0)
        ..rotateZ(_rotationAngle)
        ..scale(_scalePercentage, _scalePercentage),
      alignment: widget.isRtl ? Alignment.centerRight : Alignment.centerLeft,
      child: ClipRRect(
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
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Align(
            alignment: widget.isRtl ? Alignment.topRight : Alignment.topLeft,
            child: SizedBox(
              width: widget.menuScreenWidth ??
                  widget.slideWidth -
                      (context._screenWidth / widget.slideWidth) -
                      50,
              child: widget.menuScreen,
            ),
          ),
        ),
      ),
    );

    // Add layer - Transform
    if (widget.moveMenuScreen && widget.style != DrawerStyle.style1) {
      final _left = (1 - animationValue) * widget.slideWidth * _slideDirection;
      _menuScreen = Transform.translate(
        offset: Offset(-_left, 0),
        child: _menuScreen,
      );
    }

    // Add layer - Overlay color
    if (widget.menuScreenOverlayColor != null) {
      final _overlayColor = ColorTween(
        begin: widget.menuScreenOverlayColor,
        end: widget.menuScreenOverlayColor!.withOpacity(0.0),
      );

      _menuScreen = ColorFiltered(
        colorFilter: ColorFilter.mode(
          _overlayColor.lerp(animationValue)!,
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
      final _mainSize =
          context._screenWidth - (widget.slideWidth * animationValue);
      _mainScreen = SizedBox(
        width: _mainSize,
        child: _mainScreen,
      );
    }

    // Add layer - Overlay color
    if (widget.mainScreenOverlayColor != null) {
      final _overlayColor = ColorTween(
        begin: widget.mainScreenOverlayColor!.withOpacity(0.0),
        end: widget.mainScreenOverlayColor,
      );
      _mainScreen = ColorFiltered(
        colorFilter: ColorFilter.mode(
          _overlayColor.lerp(animationValue)!,
          widget.overlayBlend ?? BlendMode.screen,
        ),
        child: _mainScreen,
      );
    }

    // Add layer - Border radius
    if (widget.borderRadius != 0) {
      final _cornerRadius = widget.borderRadius * animationValue;
      _mainScreen = ClipRRect(
        borderRadius: BorderRadius.circular(_cornerRadius),
        child: _mainScreen,
      );
    }

    // Add layer - Box shadow
    if (widget.boxShadow != null) {
      final _cornerRadius = widget.borderRadius * animationValue;

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
    if (widget.angle != 0 && widget.style != DrawerStyle.defaultStyle) {
      final _rotationAngle =
          (((widget.angle) * pi * _slideDirection) / 180) * animationValue;
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
      final _blurAmount = widget.overlayBlur! * animationValue;
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
                    width: context._screenWidth,
                    height: context._screenHeight,
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
      _mainScreen = GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _onTap,
        child: _mainScreen,
      );
    }

    return _mainScreen;
  }

  @override
  Widget build(BuildContext context) => renderLayout();

  Widget renderLayout() {
    Widget? _parentWidget;

    if (widget.drawerStyleBuilder != null) {
      _parentWidget = renderCustomStyle();
    } else {
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
        default:
          _parentWidget = renderDefault();
      }
    }

    // Add layer - WillPopScope
    if (!kIsWeb && Platform.isAndroid) {
      _parentWidget = WillPopScope(
        onWillPop: () async {
          // Case drawer is opened or will open, either way will close
          if (widget.androidCloseOnBackTap &&
              [DrawerState.open, DrawerState.opening]
                  .contains(stateNotifier.value)) {
            close();
          }
          return false;
        },
        child: _parentWidget,
      );
    }

    // Add layer - GestureDetector
    if (!widget.disableDragGesture) {
      _parentWidget = GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragStart: _onHorizontalDragStart,
        onHorizontalDragUpdate: _onHorizontalDragUpdate,
        onHorizontalDragEnd: _onHorizontalDragEnd,
        child: _parentWidget,
      );
    }

    return Material(
      color: widget.menuBackgroundColor,
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _animationController,
            builder: (_, __) => menuScreenWidget,
          ),
          _parentWidget,
        ],
      ),
    );
  }

  Widget renderCustomStyle() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, _) {
        return widget.drawerStyleBuilder!(
          context,
          animationValue,
          widget.slideWidth,
          menuScreenWidget,
          mainScreenWidget,
        );
      },
    );
  }

  Widget renderDefault() {
    const _slidePercent = 15.0;
    return Stack(
      children: [
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
          ),
        ),
      ],
    );
  }

  Widget renderStyle1() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (_, __) {
        final _left =
            (1 - animationValue) * widget.slideWidth * _slideDirection;

        return Stack(
          children: [
            mainScreenWidget,
            Transform.translate(
              offset: Offset(-_left, 0),
              child: Container(
                width: widget.slideWidth,
                color: widget.menuBackgroundColor,
                child: menuScreenWidget,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget renderStyle2() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (_, __) {
        final _slide = widget.slideWidth * _slideDirection * animationValue;
        final _scale = 1 - (animationValue * widget.mainScreenScale);
        final _top = animationValue * widget.slideWidth;

        return Transform(
          transform: Matrix4.identity()
            ..translate(_slide, _top)
            ..scale(_scale),
          alignment: Alignment.center,
          child: mainScreenWidget,
        );
      },
    );
  }

  Widget renderStyle3() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (_, __) {
        final slideWidth =
            widget.isRtl ? widget.slideWidth : widget.slideWidth / 2;
        final _x = animationValue * slideWidth * _slideDirection;
        final _scale = 1 - (animationValue * widget.mainScreenScale);
        final _rotate = animationValue * (pi / 4);

        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0009)
            ..translate(_x)
            ..scale(_scale)
            ..rotateY(_rotate * _slideDirection),
          alignment: Alignment.centerRight,
          child: mainScreenWidget,
        );
      },
    );
  }

  Widget renderStyle4() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (_, __) {
        final _slideWidth =
            (widget.slideWidth * 1.2) * animationValue * _slideDirection;
        final _scale = 1 - (animationValue * widget.mainScreenScale);
        final _rotate = animationValue * (pi / 4);

        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0009)
            ..translate(_slideWidth)
            ..scale(_scale)
            ..rotateY(-_rotate * _slideDirection),
          alignment:
              widget.isRtl ? Alignment.centerRight : Alignment.centerLeft,
          child: mainScreenWidget,
        );
      },
    );
  }
}
