// Copyright 2025 The decorated_tab_bar Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter/material.dart';
library;

import 'dart:math' as math;
import 'dart:ui' show SemanticsRole, lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'decorated_tab_bar_theme.dart';

const double _kTabHeight = 46.0;
const double _kTextAndIconTabHeight = 72.0;
const double _kStartOffset = 52.0;

// ---------------------------------------------------------------------------
// _TabStyle
// ---------------------------------------------------------------------------

class _TabStyle extends AnimatedWidget {
  const _TabStyle({
    required Animation<double> animation,
    required this.isSelected,
    required this.isPrimary,
    required this.labelColor,
    required this.unselectedLabelColor,
    required this.labelStyle,
    required this.unselectedLabelStyle,
    required this.defaults,
    required this.child,
  }) : super(listenable: animation);

  final TextStyle? labelStyle;
  final TextStyle? unselectedLabelStyle;
  final bool isSelected;
  final bool isPrimary;
  final Color? labelColor;
  final Color? unselectedLabelColor;
  final TabBarThemeData defaults;
  final Widget child;

  WidgetStateColor _resolveWithLabelColor(
    BuildContext context, {
    IconThemeData? iconTheme,
  }) {
    final ThemeData themeData = Theme.of(context);
    final TabBarThemeData tabBarTheme = TabBarTheme.of(context);
    final Animation<double> animation = listenable as Animation<double>;

    Color selectedColor =
        labelColor ??
        tabBarTheme.labelColor ??
        labelStyle?.color ??
        tabBarTheme.labelStyle?.color ??
        defaults.labelColor!;

    final Color unselectedColor;

    if (selectedColor is WidgetStateColor) {
      unselectedColor = selectedColor.resolve(const <WidgetState>{});
      selectedColor = selectedColor.resolve(const <WidgetState>{
        WidgetState.selected,
      });
    } else {
      unselectedColor =
          unselectedLabelColor ??
          tabBarTheme.unselectedLabelColor ??
          unselectedLabelStyle?.color ??
          tabBarTheme.unselectedLabelStyle?.color ??
          iconTheme?.color ??
          (themeData.useMaterial3
              ? defaults.unselectedLabelColor!
              : selectedColor.withAlpha(0xB2));
    }

    return WidgetStateColor.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.selected)) {
        return Color.lerp(selectedColor, unselectedColor, animation.value)!;
      }
      return Color.lerp(unselectedColor, selectedColor, animation.value)!;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TabBarThemeData tabBarTheme = TabBarTheme.of(context);
    final Animation<double> animation = listenable as Animation<double>;

    final Set<WidgetState> states = isSelected
        ? const <WidgetState>{WidgetState.selected}
        : const <WidgetState>{};

    final TextStyle selectedStyle = defaults.labelStyle!
        .merge(labelStyle ?? tabBarTheme.labelStyle)
        .copyWith(inherit: true);
    final TextStyle unselectedStyle = defaults.unselectedLabelStyle!
        .merge(
          unselectedLabelStyle ??
              tabBarTheme.unselectedLabelStyle ??
              labelStyle,
        )
        .copyWith(inherit: true);
    final TextStyle textStyle = isSelected
        ? TextStyle.lerp(selectedStyle, unselectedStyle, animation.value)!
        : TextStyle.lerp(unselectedStyle, selectedStyle, animation.value)!;
    final Color defaultIconColor = switch (theme.colorScheme.brightness) {
      Brightness.light => Colors.black87,
      Brightness.dark => Colors.white,
    };
    final IconThemeData? customIconTheme = switch (IconTheme.of(context)) {
      final IconThemeData iconTheme when iconTheme.color != defaultIconColor =>
        iconTheme,
      _ => null,
    };
    final Color iconColor = _resolveWithLabelColor(
      context,
      iconTheme: customIconTheme,
    ).resolve(states);
    final Color resolvedLabelColor = _resolveWithLabelColor(
      context,
    ).resolve(states);

    return DefaultTextStyle(
      style: textStyle.copyWith(color: resolvedLabelColor),
      child: IconTheme.merge(
        data: IconThemeData(
          size: customIconTheme?.size ?? 24.0,
          color: iconColor,
        ),
        child: child,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _TabDecorationWrapper
// ---------------------------------------------------------------------------

/// Wraps a tab child with an animated decoration that transitions between
/// selected and unselected states.
class _TabDecorationWrapper extends AnimatedWidget {
  const _TabDecorationWrapper({
    required Animation<double> animation,
    required this.isSelected,
    required this.tabDecoration,
    required this.unselectedTabDecoration,
    this.tabDecorationPadding,
    this.tabDecorationMargin,
    this.tabDecorationConstraints,
    required this.child,
  }) : super(listenable: animation);

  final bool isSelected;
  final Decoration? tabDecoration;
  final Decoration? unselectedTabDecoration;
  final EdgeInsetsGeometry? tabDecorationPadding;
  final EdgeInsetsGeometry? tabDecorationMargin;
  final BoxConstraints? tabDecorationConstraints;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final Animation<double> animation = listenable as Animation<double>;

    // If neither decoration is provided, just return the child.
    if (tabDecoration == null && unselectedTabDecoration == null) {
      return child;
    }

    // Use empty BoxDecoration as fallback for null decorations to enable
    // smooth lerp transitions.
    final Decoration selected = tabDecoration ?? const BoxDecoration();
    final Decoration unselected =
        unselectedTabDecoration ?? const BoxDecoration();

    final Decoration decoration;
    if (isSelected) {
      decoration = Decoration.lerp(selected, unselected, animation.value)!;
    } else {
      decoration = Decoration.lerp(unselected, selected, animation.value)!;
    }

    Widget result = child;

    if (tabDecorationPadding != null) {
      result = Padding(padding: tabDecorationPadding!, child: result);
    }

    result = DecoratedBox(decoration: decoration, child: result);

    if (tabDecorationConstraints != null) {
      result = ConstrainedBox(
        constraints: tabDecorationConstraints!,
        child: result,
      );
    }

    if (tabDecorationMargin != null) {
      result = Padding(padding: tabDecorationMargin!, child: result);
    }

    return result;
  }
}

// ---------------------------------------------------------------------------
// Layout helpers
// ---------------------------------------------------------------------------

typedef _LayoutCallback =
    void Function(
      List<double> xOffsets,
      TextDirection textDirection,
      double width,
    );

class _TabLabelBarRenderer extends RenderFlex {
  _TabLabelBarRenderer({
    required super.direction,
    required super.mainAxisSize,
    required super.mainAxisAlignment,
    required super.crossAxisAlignment,
    required TextDirection super.textDirection,
    required super.verticalDirection,
    required this.onPerformLayout,
  });

  _LayoutCallback onPerformLayout;

  @override
  void performLayout() {
    super.performLayout();
    RenderBox? child = firstChild;
    final List<double> xOffsets = <double>[];
    while (child != null) {
      final FlexParentData childParentData =
          child.parentData! as FlexParentData;
      xOffsets.add(childParentData.offset.dx);
      assert(child.parentData == childParentData);
      child = childParentData.nextSibling;
    }
    assert(textDirection != null);
    switch (textDirection!) {
      case TextDirection.rtl:
        xOffsets.insert(0, size.width);
      case TextDirection.ltr:
        xOffsets.add(size.width);
    }
    onPerformLayout(xOffsets, textDirection!, size.width);
  }
}

class _TabLabelBar extends Flex {
  const _TabLabelBar({
    super.children,
    required this.onPerformLayout,
    required super.mainAxisSize,
  }) : super(
         direction: Axis.horizontal,
         mainAxisAlignment: MainAxisAlignment.start,
         crossAxisAlignment: CrossAxisAlignment.center,
         verticalDirection: VerticalDirection.down,
       );

  final _LayoutCallback onPerformLayout;

  @override
  RenderFlex createRenderObject(BuildContext context) {
    return _TabLabelBarRenderer(
      direction: direction,
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: mainAxisSize,
      crossAxisAlignment: crossAxisAlignment,
      textDirection: getEffectiveTextDirection(context)!,
      verticalDirection: verticalDirection,
      onPerformLayout: onPerformLayout,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _TabLabelBarRenderer renderObject,
  ) {
    super.updateRenderObject(context, renderObject);
    renderObject.onPerformLayout = onPerformLayout;
  }
}

// ---------------------------------------------------------------------------
// Animation helpers
// ---------------------------------------------------------------------------

double _indexChangeProgress(TabController controller) {
  final double controllerValue = controller.animation!.value;
  final double previousIndex = controller.previousIndex.toDouble();
  final double currentIndex = controller.index.toDouble();

  if (!controller.indexIsChanging) {
    return clampDouble((currentIndex - controllerValue).abs(), 0.0, 1.0);
  }

  return (controllerValue - currentIndex).abs() /
      (currentIndex - previousIndex).abs();
}

class _ChangeAnimation extends Animation<double>
    with AnimationWithParentMixin<double> {
  _ChangeAnimation(this.controller);

  final TabController controller;

  @override
  Animation<double> get parent => controller.animation!;

  @override
  void removeStatusListener(AnimationStatusListener listener) {
    if (controller.animation != null) {
      super.removeStatusListener(listener);
    }
  }

  @override
  void removeListener(VoidCallback listener) {
    if (controller.animation != null) {
      super.removeListener(listener);
    }
  }

  @override
  double get value => _indexChangeProgress(controller);
}

class _DragAnimation extends Animation<double>
    with AnimationWithParentMixin<double> {
  _DragAnimation(this.controller, this.index);

  final TabController controller;
  final int index;

  @override
  Animation<double> get parent => controller.animation!;

  @override
  void removeStatusListener(AnimationStatusListener listener) {
    if (controller.animation != null) {
      super.removeStatusListener(listener);
    }
  }

  @override
  void removeListener(VoidCallback listener) {
    if (controller.animation != null) {
      super.removeListener(listener);
    }
  }

  @override
  double get value {
    assert(!controller.indexIsChanging);
    final double controllerMaxValue = (controller.length - 1).toDouble();
    final double controllerValue = clampDouble(
      controller.animation!.value,
      0.0,
      controllerMaxValue,
    );
    return clampDouble((controllerValue - index.toDouble()).abs(), 0.0, 1.0);
  }
}

// ---------------------------------------------------------------------------
// Painters
// ---------------------------------------------------------------------------

class _DividerPainter extends CustomPainter {
  _DividerPainter({required this.dividerColor, required this.dividerHeight});

  final Color dividerColor;
  final double dividerHeight;

  @override
  void paint(Canvas canvas, Size size) {
    if (dividerHeight <= 0.0) {
      return;
    }
    final Paint paint = Paint()
      ..color = dividerColor
      ..strokeWidth = dividerHeight;
    canvas.drawLine(
      Offset(0, size.height - (paint.strokeWidth / 2)),
      Offset(size.width, size.height - (paint.strokeWidth / 2)),
      paint,
    );
  }

  @override
  bool shouldRepaint(_DividerPainter oldDelegate) {
    return oldDelegate.dividerColor != dividerColor ||
        oldDelegate.dividerHeight != dividerHeight;
  }
}

class _IndicatorPainter extends CustomPainter {
  _IndicatorPainter({
    required this.controller,
    required this.indicator,
    required this.indicatorSize,
    required this.tabKeys,
    required _IndicatorPainter? old,
    required this.indicatorPadding,
    required this.labelPaddings,
    this.dividerColor,
    this.dividerHeight,
    required this.showDivider,
    this.devicePixelRatio,
    required this.indicatorAnimation,
    required this.textDirection,
  }) : super(repaint: controller.animation) {
    if (old != null) {
      saveTabOffsets(old._currentTabOffsets, old._currentTextDirection);
    }
  }

  final TabController controller;
  final Decoration indicator;
  final TabBarIndicatorSize indicatorSize;
  final EdgeInsetsGeometry indicatorPadding;
  final List<GlobalKey> tabKeys;
  final List<EdgeInsetsGeometry> labelPaddings;
  final Color? dividerColor;
  final double? dividerHeight;
  final bool showDivider;
  final double? devicePixelRatio;
  final TabIndicatorAnimation indicatorAnimation;
  final TextDirection textDirection;

  List<double>? _currentTabOffsets;
  TextDirection? _currentTextDirection;

  Rect? _currentRect;
  BoxPainter? _painter;
  bool _needsPaint = false;

  void markNeedsPaint() {
    _needsPaint = true;
  }

  void dispose() {
    _painter?.dispose();
  }

  void saveTabOffsets(List<double>? tabOffsets, TextDirection? textDirection) {
    _currentTabOffsets = tabOffsets;
    _currentTextDirection = textDirection;
  }

  int get maxTabIndex => _currentTabOffsets!.length - 2;

  double centerOf(int tabIndex) {
    assert(_currentTabOffsets != null);
    assert(_currentTabOffsets!.isNotEmpty);
    assert(tabIndex >= 0);
    assert(tabIndex <= maxTabIndex);
    return (_currentTabOffsets![tabIndex] + _currentTabOffsets![tabIndex + 1]) /
        2.0;
  }

  Rect indicatorRect(Size tabBarSize, int tabIndex) {
    assert(_currentTabOffsets != null);
    assert(_currentTextDirection != null);
    assert(_currentTabOffsets!.isNotEmpty);
    assert(tabIndex >= 0);
    assert(tabIndex <= maxTabIndex);
    double tabLeft, tabRight;
    (tabLeft, tabRight) = switch (_currentTextDirection!) {
      TextDirection.rtl => (
        _currentTabOffsets![tabIndex + 1],
        _currentTabOffsets![tabIndex],
      ),
      TextDirection.ltr => (
        _currentTabOffsets![tabIndex],
        _currentTabOffsets![tabIndex + 1],
      ),
    };

    if (indicatorSize == TabBarIndicatorSize.label) {
      final double tabWidth = tabKeys[tabIndex].currentContext!.size!.width;
      final EdgeInsetsGeometry labelPadding = labelPaddings[tabIndex];
      final EdgeInsets insets = labelPadding.resolve(_currentTextDirection);
      final double delta =
          ((tabRight - tabLeft) - (tabWidth + insets.horizontal)) / 2.0;
      tabLeft += delta + insets.left;
      tabRight = tabLeft + tabWidth;
    }

    final EdgeInsets insets = indicatorPadding.resolve(_currentTextDirection);
    final Rect rect = Rect.fromLTWH(
      tabLeft,
      0.0,
      tabRight - tabLeft,
      tabBarSize.height,
    );

    if (!(rect.size >= insets.collapsedSize)) {
      throw FlutterError(
        'indicatorPadding insets should be less than Tab Size\n'
        'Rect Size : ${rect.size}, Insets: $insets',
      );
    }
    return insets.deflateRect(rect);
  }

  @override
  void paint(Canvas canvas, Size size) {
    _needsPaint = false;
    _painter ??= indicator.createBoxPainter(markNeedsPaint);

    final double value = controller.animation!.value;

    _currentRect = switch (indicatorAnimation) {
      TabIndicatorAnimation.linear => _applyLinearEffect(
        size: size,
        value: value,
      ),
      TabIndicatorAnimation.elastic => _applyElasticEffect(
        size: size,
        value: value,
      ),
    };

    assert(_currentRect != null);

    final ImageConfiguration configuration = ImageConfiguration(
      size: _currentRect!.size,
      textDirection: _currentTextDirection,
      devicePixelRatio: devicePixelRatio,
    );
    if (showDivider && dividerHeight! > 0) {
      final Paint dividerPaint = Paint()
        ..color = dividerColor!
        ..strokeWidth = dividerHeight!;
      final Offset dividerP1 = Offset(
        0,
        size.height - (dividerPaint.strokeWidth / 2),
      );
      final Offset dividerP2 = Offset(
        size.width,
        size.height - (dividerPaint.strokeWidth / 2),
      );
      canvas.drawLine(dividerP1, dividerP2, dividerPaint);
    }
    _painter!.paint(canvas, _currentRect!.topLeft, configuration);
  }

  Rect? _applyLinearEffect({required Size size, required double value}) {
    final double index = controller.index.toDouble();
    final bool ltr = index > value;
    final int from = (ltr ? value.floor() : value.ceil()).clamp(0, maxTabIndex);
    final int to = (ltr ? from + 1 : from - 1).clamp(0, maxTabIndex);
    final Rect fromRect = indicatorRect(size, from);
    final Rect toRect = indicatorRect(size, to);
    return Rect.lerp(fromRect, toRect, (value - from).abs());
  }

  double decelerateInterpolation(double fraction) {
    return math.sin((fraction * math.pi) / 2.0);
  }

  double accelerateInterpolation(double fraction) {
    return 1.0 - math.cos((fraction * math.pi) / 2.0);
  }

  Rect? _applyElasticEffect({required Size size, required double value}) {
    final double index = controller.index.toDouble();
    double progressLeft = (index - value).abs();

    final int to = progressLeft == 0.0 || !controller.indexIsChanging
        ? switch (textDirection) {
            TextDirection.ltr => value.ceil(),
            TextDirection.rtl => value.floor(),
          }.clamp(0, maxTabIndex)
        : controller.index;
    final int from = progressLeft == 0.0 || !controller.indexIsChanging
        ? switch (textDirection) {
            TextDirection.ltr => (to - 1),
            TextDirection.rtl => (to + 1),
          }.clamp(0, maxTabIndex)
        : controller.previousIndex;
    final Rect toRect = indicatorRect(size, to);
    final Rect fromRect = indicatorRect(size, from);
    final Rect rect = Rect.lerp(fromRect, toRect, (value - from).abs())!;

    if (controller.animation!.isCompleted) {
      return rect;
    }

    final double tabChangeProgress;

    if (controller.indexIsChanging) {
      final int tabsDelta = (controller.index - controller.previousIndex).abs();
      if (tabsDelta != 0) {
        progressLeft /= tabsDelta;
      }
      tabChangeProgress = 1 - clampDouble(progressLeft, 0.0, 1.0);
    } else {
      tabChangeProgress = (index - value).abs();
    }

    if (tabChangeProgress == 1.0) {
      return rect;
    }

    final double leftFraction;
    final double rightFraction;
    final bool isMovingRight = switch (textDirection) {
      TextDirection.ltr =>
        controller.indexIsChanging ? index > value : value > index,
      TextDirection.rtl =>
        controller.indexIsChanging ? value > index : index > value,
    };
    if (isMovingRight) {
      leftFraction = accelerateInterpolation(tabChangeProgress);
      rightFraction = decelerateInterpolation(tabChangeProgress);
    } else {
      leftFraction = decelerateInterpolation(tabChangeProgress);
      rightFraction = accelerateInterpolation(tabChangeProgress);
    }

    final double lerpRectLeft;
    final double lerpRectRight;

    if (controller.indexIsChanging) {
      lerpRectLeft = lerpDouble(fromRect.left, toRect.left, leftFraction)!;
      lerpRectRight = lerpDouble(fromRect.right, toRect.right, rightFraction)!;
    } else {
      lerpRectLeft = switch (isMovingRight) {
        true => lerpDouble(fromRect.left, toRect.left, leftFraction)!,
        false => lerpDouble(toRect.left, fromRect.left, leftFraction)!,
      };
      lerpRectRight = switch (isMovingRight) {
        true => lerpDouble(fromRect.right, toRect.right, rightFraction)!,
        false => lerpDouble(toRect.right, fromRect.right, rightFraction)!,
      };
    }

    return Rect.fromLTRB(lerpRectLeft, rect.top, lerpRectRight, rect.bottom);
  }

  @override
  bool shouldRepaint(_IndicatorPainter old) {
    return _needsPaint ||
        controller != old.controller ||
        indicator != old.indicator ||
        tabKeys.length != old.tabKeys.length ||
        (!listEquals(_currentTabOffsets, old._currentTabOffsets)) ||
        _currentTextDirection != old._currentTextDirection;
  }
}

// ---------------------------------------------------------------------------
// Scroll position / controller helpers
// ---------------------------------------------------------------------------

class _TabBarScrollPosition extends ScrollPositionWithSingleContext {
  _TabBarScrollPosition({
    required super.physics,
    required super.context,
    required super.oldPosition,
    required this.tabBar,
  }) : super(initialPixels: null);

  final _DecoratedTabBarState tabBar;

  bool _viewportDimensionWasNonZero = false;
  bool _needsPixelsCorrection = true;

  @override
  bool applyContentDimensions(double minScrollExtent, double maxScrollExtent) {
    bool result = true;
    if (!_viewportDimensionWasNonZero) {
      _viewportDimensionWasNonZero = viewportDimension != 0.0;
    }
    if (!_viewportDimensionWasNonZero || _needsPixelsCorrection) {
      _needsPixelsCorrection = false;
      correctPixels(
        tabBar._initialScrollOffset(
          viewportDimension,
          minScrollExtent,
          maxScrollExtent,
        ),
      );
      result = false;
    }
    return super.applyContentDimensions(minScrollExtent, maxScrollExtent) &&
        result;
  }

  void markNeedsPixelsCorrection() {
    _needsPixelsCorrection = true;
  }
}

class _TabBarScrollController extends ScrollController {
  _TabBarScrollController(this.tabBar);

  final _DecoratedTabBarState tabBar;

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) {
    return _TabBarScrollPosition(
      physics: physics,
      context: context,
      oldPosition: oldPosition,
      tabBar: tabBar,
    );
  }
}

// ---------------------------------------------------------------------------
// DecoratedTabBar
// ---------------------------------------------------------------------------

/// A Material Design [TabBar] that supports decorating both selected and
/// unselected tabs with animated transitions.
///
/// This is a drop-in replacement for Flutter's [TabBar] with additional
/// properties for tab decoration:
///
///  * [tabDecoration] — the decoration painted behind the **selected** tab.
///  * [unselectedTabDecoration] — the decoration painted behind **unselected**
///    tabs.
///  * [tabDecorationPadding] — inner padding inside the decoration container.
///  * [tabDecorationMargin] — outer margin around the decoration container.
///  * [tabDecorationConstraints] — optional box constraints for the decoration
///    container.
///
/// When the selected tab changes, the decoration animates smoothly between the
/// selected and unselected states using the same animation infrastructure as
/// the label color and text style transitions.
///
/// {@tool snippet}
/// A simple example of a [DecoratedTabBar] with a white background for
/// unselected tabs and a blue background for the selected tab:
///
/// ```dart
/// DecoratedTabBar(
///   tabDecoration: BoxDecoration(
///     color: Colors.blue,
///     borderRadius: BorderRadius.circular(8),
///   ),
///   unselectedTabDecoration: BoxDecoration(
///     color: Colors.white,
///     borderRadius: BorderRadius.circular(8),
///   ),
///   tabDecorationMargin: const EdgeInsets.symmetric(
///     horizontal: 4,
///     vertical: 6,
///   ),
///   tabs: const [
///     Tab(text: 'Tab 1'),
///     Tab(text: 'Tab 2'),
///     Tab(text: 'Tab 3'),
///   ],
/// )
/// ```
/// {@end-tool}
///
/// If a [TabController] is not provided, then a [DefaultTabController]
/// ancestor must be provided instead.
///
/// See also:
///
///  * [TabBar], the standard Material Design tab bar.
///  * [DecoratedTabBarTheme], for theming the decoration properties.
///  * [TabBarView], which displays a widget for the currently selected tab.
class DecoratedTabBar extends StatefulWidget implements PreferredSizeWidget {
  /// Creates a Material Design primary tab bar with decoration support.
  ///
  /// The length of the [tabs] argument must match the [controller]'s
  /// [TabController.length].
  ///
  /// If a [TabController] is not provided, then there must be a
  /// [DefaultTabController] ancestor.
  const DecoratedTabBar({
    super.key,
    required this.tabs,
    this.controller,
    this.isScrollable = false,
    this.padding,
    this.indicatorColor,
    this.automaticIndicatorColorAdjustment = true,
    this.indicatorWeight = 2.0,
    this.indicatorPadding = EdgeInsets.zero,
    this.indicator,
    this.indicatorSize,
    this.dividerColor,
    this.dividerHeight,
    this.labelColor,
    this.labelStyle,
    this.labelPadding,
    this.unselectedLabelColor,
    this.unselectedLabelStyle,
    this.dragStartBehavior = DragStartBehavior.start,
    this.overlayColor,
    this.mouseCursor,
    this.enableFeedback,
    this.onTap,
    this.onHover,
    this.onFocusChange,
    this.physics,
    this.splashFactory,
    this.splashBorderRadius,
    this.tabAlignment,
    this.textScaler,
    this.indicatorAnimation,
    // --- Decoration properties ---
    this.tabDecoration,
    this.unselectedTabDecoration,
    this.tabDecorationPadding,
    this.tabDecorationMargin,
    this.tabDecorationConstraints,
  }) : _isPrimary = true,
       assert(indicator != null || (indicatorWeight > 0.0));

  /// Creates a Material Design secondary tab bar with decoration support.
  ///
  /// Secondary tabs are used within a content area to further separate
  /// related content and establish hierarchy.
  const DecoratedTabBar.secondary({
    super.key,
    required this.tabs,
    this.controller,
    this.isScrollable = false,
    this.padding,
    this.indicatorColor,
    this.automaticIndicatorColorAdjustment = true,
    this.indicatorWeight = 2.0,
    this.indicatorPadding = EdgeInsets.zero,
    this.indicator,
    this.indicatorSize,
    this.dividerColor,
    this.dividerHeight,
    this.labelColor,
    this.labelStyle,
    this.labelPadding,
    this.unselectedLabelColor,
    this.unselectedLabelStyle,
    this.dragStartBehavior = DragStartBehavior.start,
    this.overlayColor,
    this.mouseCursor,
    this.enableFeedback,
    this.onTap,
    this.onHover,
    this.onFocusChange,
    this.physics,
    this.splashFactory,
    this.splashBorderRadius,
    this.tabAlignment,
    this.textScaler,
    this.indicatorAnimation,
    // --- Decoration properties ---
    this.tabDecoration,
    this.unselectedTabDecoration,
    this.tabDecorationPadding,
    this.tabDecorationMargin,
    this.tabDecorationConstraints,
  }) : _isPrimary = false,
       assert(indicator != null || (indicatorWeight > 0.0));

  // -------------------------------------------------------------------------
  // Standard TabBar properties
  // -------------------------------------------------------------------------

  /// {@macro flutter.material.tabs.tabs}
  final List<Widget> tabs;

  /// This widget's selection and animation state.
  final TabController? controller;

  /// Whether this tab bar can be scrolled horizontally.
  final bool isScrollable;

  /// The amount of space by which to inset the tab bar.
  final EdgeInsetsGeometry? padding;

  /// The color of the line that appears below the selected tab.
  final Color? indicatorColor;

  /// Whether this tab bar should automatically adjust the [indicatorColor].
  final bool automaticIndicatorColorAdjustment;

  /// The thickness of the line that appears below the selected tab.
  final double indicatorWeight;

  /// The padding for the indicator.
  final EdgeInsetsGeometry indicatorPadding;

  /// Defines the appearance of the selected tab indicator.
  final Decoration? indicator;

  /// Defines how the selected tab indicator's size is computed.
  final TabBarIndicatorSize? indicatorSize;

  /// The color of the divider.
  final Color? dividerColor;

  /// The height of the divider.
  final double? dividerHeight;

  /// The color of selected tab labels.
  final Color? labelColor;

  /// The text style of the selected tab labels.
  final TextStyle? labelStyle;

  /// The padding added to each of the tab labels.
  final EdgeInsetsGeometry? labelPadding;

  /// The color of unselected tab labels.
  final Color? unselectedLabelColor;

  /// The text style of the unselected tab labels.
  final TextStyle? unselectedLabelStyle;

  /// {@macro flutter.widgets.scrollable.dragStartBehavior}
  final DragStartBehavior dragStartBehavior;

  /// Defines the ink response focus, hover, and splash colors.
  final WidgetStateProperty<Color?>? overlayColor;

  /// {@macro flutter.material.tabs.mouseCursor}
  final MouseCursor? mouseCursor;

  /// Whether detected gestures should provide acoustic and/or haptic feedback.
  final bool? enableFeedback;

  /// An optional callback that's called when the [TabBar] is tapped.
  final ValueChanged<int>? onTap;

  /// An optional callback for hover state changes.
  final TabValueChanged<bool>? onHover;

  /// An optional callback for focus state changes.
  final TabValueChanged<bool>? onFocusChange;

  /// How the scroll view should respond to user input.
  final ScrollPhysics? physics;

  /// Creates the tab bar's [InkWell] splash factory.
  final InteractiveInkFeatureFactory? splashFactory;

  /// Defines the clipping radius of splashes.
  final BorderRadius? splashBorderRadius;

  /// Specifies the horizontal alignment of the tabs within a [TabBar].
  final TabAlignment? tabAlignment;

  /// Specifies the text scaling behavior for the [Tab] label.
  final TextScaler? textScaler;

  /// Specifies the animation behavior of the tab indicator.
  final TabIndicatorAnimation? indicatorAnimation;

  // -------------------------------------------------------------------------
  // Decoration properties
  // -------------------------------------------------------------------------

  /// The decoration to paint behind the **selected** tab.
  ///
  /// When a tab becomes selected, its decoration animates from
  /// [unselectedTabDecoration] to this value.
  ///
  /// If null, then the value of [DecoratedTabBarThemeData.tabDecoration] is
  /// used. If that is also null, no decoration is painted for the selected tab.
  ///
  /// {@tool snippet}
  /// A tab bar where the selected tab has a blue rounded background:
  ///
  /// ```dart
  /// DecoratedTabBar(
  ///   tabDecoration: BoxDecoration(
  ///     color: Colors.blue,
  ///     borderRadius: BorderRadius.circular(8),
  ///   ),
  ///   tabs: const [Tab(text: 'First'), Tab(text: 'Second')],
  /// )
  /// ```
  /// {@end-tool}
  final Decoration? tabDecoration;

  /// The decoration to paint behind **unselected** tabs.
  ///
  /// When a tab becomes unselected, its decoration animates from
  /// [tabDecoration] to this value.
  ///
  /// If null, then the value of
  /// [DecoratedTabBarThemeData.unselectedTabDecoration] is used. If that is
  /// also null, no decoration is painted for unselected tabs.
  ///
  /// {@tool snippet}
  /// A tab bar where unselected tabs have a white background with a border:
  ///
  /// ```dart
  /// DecoratedTabBar(
  ///   unselectedTabDecoration: BoxDecoration(
  ///     color: Colors.white,
  ///     borderRadius: BorderRadius.circular(8),
  ///     border: Border.all(color: Colors.grey.shade300),
  ///   ),
  ///   tabs: const [Tab(text: 'First'), Tab(text: 'Second')],
  /// )
  /// ```
  /// {@end-tool}
  final Decoration? unselectedTabDecoration;

  /// The padding inside the tab decoration container.
  ///
  /// This is applied inside the [tabDecoration] / [unselectedTabDecoration]
  /// container, adding space between the decoration edge and the tab content.
  ///
  /// If null, then the value of [DecoratedTabBarThemeData.tabDecorationPadding]
  /// is used. If that is also null, no additional padding is applied.
  final EdgeInsetsGeometry? tabDecorationPadding;

  /// The margin around the tab decoration container.
  ///
  /// This is applied outside the [tabDecoration] / [unselectedTabDecoration]
  /// container, adding space between adjacent tab decorations.
  ///
  /// If null, then the value of [DecoratedTabBarThemeData.tabDecorationMargin]
  /// is used. If that is also null, no margin is applied.
  final EdgeInsetsGeometry? tabDecorationMargin;

  /// Optional constraints for the tab decoration container.
  ///
  /// If null, then the value of
  /// [DecoratedTabBarThemeData.tabDecorationConstraints] is used. If that is
  /// also null, no additional constraints are applied.
  final BoxConstraints? tabDecorationConstraints;

  /// Whether this tab bar is a primary tab bar.
  final bool _isPrimary;

  @override
  Size get preferredSize {
    double maxHeight = _kTabHeight;
    for (final Widget item in tabs) {
      if (item is PreferredSizeWidget) {
        final double itemHeight = item.preferredSize.height;
        maxHeight = math.max(itemHeight, maxHeight);
      }
    }
    return Size.fromHeight(maxHeight + indicatorWeight);
  }

  /// Returns whether the [TabBar] contains a tab with both text and icon.
  bool get tabHasTextAndIcon {
    for (final Widget item in tabs) {
      if (item is PreferredSizeWidget) {
        if (item.preferredSize.height == _kTextAndIconTabHeight) {
          return true;
        }
      }
    }
    return false;
  }

  @override
  State<DecoratedTabBar> createState() => _DecoratedTabBarState();
}

// ---------------------------------------------------------------------------
// _DecoratedTabBarState
// ---------------------------------------------------------------------------

class _DecoratedTabBarState extends State<DecoratedTabBar> {
  ScrollController? _scrollController;
  TabController? _controller;
  _IndicatorPainter? _indicatorPainter;
  int? _currentIndex;
  late double _tabStripWidth;
  late List<GlobalKey> _tabKeys;
  late List<EdgeInsetsGeometry> _labelPaddings;
  bool _debugHasScheduledValidTabsCountCheck = false;

  @override
  void initState() {
    super.initState();
    _tabKeys = widget.tabs.map((Widget tab) => GlobalKey()).toList();
    _labelPaddings = List<EdgeInsetsGeometry>.filled(
      widget.tabs.length,
      EdgeInsets.zero,
      growable: true,
    );
  }

  // -----------------------------------------------------------------------
  // Defaults
  // -----------------------------------------------------------------------

  TabBarThemeData get _defaults {
    if (Theme.of(context).useMaterial3) {
      return widget._isPrimary
          ? _TabsPrimaryDefaultsM3(context, widget.isScrollable)
          : _TabsSecondaryDefaultsM3(context, widget.isScrollable);
    } else {
      return _TabsDefaultsM2(context, widget.isScrollable);
    }
  }

  // -----------------------------------------------------------------------
  // Indicator
  // -----------------------------------------------------------------------

  Decoration _getIndicator(TabBarIndicatorSize indicatorSize) {
    final ThemeData theme = Theme.of(context);
    final TabBarThemeData tabBarTheme = TabBarTheme.of(context);

    if (widget.indicator != null) {
      return widget.indicator!;
    }
    if (tabBarTheme.indicator != null) {
      return tabBarTheme.indicator!;
    }

    Color color =
        widget.indicatorColor ??
        tabBarTheme.indicatorColor ??
        _defaults.indicatorColor!;

    if (widget.automaticIndicatorColorAdjustment &&
        color.value == Material.maybeOf(context)?.color?.value) {
      color = Colors.white;
    }

    final double effectiveIndicatorWeight = theme.useMaterial3
        ? math.max(widget.indicatorWeight, switch (widget._isPrimary) {
            true => _TabsPrimaryDefaultsM3.indicatorWeight(indicatorSize),
            false => _TabsSecondaryDefaultsM3.indicatorWeight,
          })
        : widget.indicatorWeight;

    final bool primaryWithLabelIndicator = switch (indicatorSize) {
      TabBarIndicatorSize.label => widget._isPrimary,
      TabBarIndicatorSize.tab => false,
    };
    final BorderRadius? effectiveBorderRadius =
        theme.useMaterial3 && primaryWithLabelIndicator
        ? BorderRadius.only(
            topLeft: Radius.circular(effectiveIndicatorWeight),
            topRight: Radius.circular(effectiveIndicatorWeight),
          )
        : null;
    return UnderlineTabIndicator(
      borderRadius: effectiveBorderRadius,
      borderSide: BorderSide(width: effectiveIndicatorWeight, color: color),
    );
  }

  // -----------------------------------------------------------------------
  // Controller
  // -----------------------------------------------------------------------

  bool get _controllerIsValid => _controller?.animation != null;

  void _updateTabController() {
    final TabController? newController =
        widget.controller ?? DefaultTabController.maybeOf(context);
    assert(() {
      if (newController == null) {
        throw FlutterError(
          'No TabController for ${widget.runtimeType}.\n'
          'When creating a ${widget.runtimeType}, you must either provide an '
          'explicit TabController using the "controller" property, or you must '
          'ensure that there is a DefaultTabController above the '
          '${widget.runtimeType}.\n'
          'In this case, there was neither an explicit controller nor a '
          'default controller.',
        );
      }
      return true;
    }());

    if (newController == _controller) {
      return;
    }

    if (_controllerIsValid) {
      _controller!.animation!.removeListener(_handleTabControllerAnimationTick);
      _controller!.removeListener(_handleTabControllerTick);
    }
    _controller = newController;
    if (_controller != null) {
      _controller!.animation!.addListener(_handleTabControllerAnimationTick);
      _controller!.addListener(_handleTabControllerTick);
      _currentIndex = _controller!.index;
    }
  }

  // -----------------------------------------------------------------------
  // Indicator painter
  // -----------------------------------------------------------------------

  void _initIndicatorPainter() {
    final ThemeData theme = Theme.of(context);
    final TabBarThemeData tabBarTheme = TabBarTheme.of(context);
    final TabBarIndicatorSize indicatorSize =
        widget.indicatorSize ??
        tabBarTheme.indicatorSize ??
        _defaults.indicatorSize!;

    final _IndicatorPainter? oldPainter = _indicatorPainter;

    final TabIndicatorAnimation defaultTabIndicatorAnimation =
        switch (indicatorSize) {
          TabBarIndicatorSize.label => TabIndicatorAnimation.elastic,
          TabBarIndicatorSize.tab => TabIndicatorAnimation.linear,
        };

    _indicatorPainter = !_controllerIsValid
        ? null
        : _IndicatorPainter(
            controller: _controller!,
            indicator: _getIndicator(indicatorSize),
            indicatorSize: indicatorSize,
            indicatorPadding: widget.indicatorPadding,
            tabKeys: _tabKeys,
            old: oldPainter,
            labelPaddings: _labelPaddings,
            dividerColor:
                widget.dividerColor ??
                tabBarTheme.dividerColor ??
                _defaults.dividerColor,
            dividerHeight:
                widget.dividerHeight ??
                tabBarTheme.dividerHeight ??
                _defaults.dividerHeight,
            showDivider: theme.useMaterial3 && !widget.isScrollable,
            devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
            indicatorAnimation:
                widget.indicatorAnimation ??
                tabBarTheme.indicatorAnimation ??
                defaultTabIndicatorAnimation,
            textDirection: Directionality.of(context),
          );

    oldPainter?.dispose();
  }

  // -----------------------------------------------------------------------
  // Lifecycle
  // -----------------------------------------------------------------------

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    assert(debugCheckHasMaterial(context));
    _updateTabController();
    _initIndicatorPainter();
  }

  @override
  void didUpdateWidget(DecoratedTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _updateTabController();
      _initIndicatorPainter();
      if (_scrollController != null && _scrollController!.hasClients) {
        final ScrollPosition position = _scrollController!.position;
        if (position is _TabBarScrollPosition) {
          position.markNeedsPixelsCorrection();
        }
      }
    } else if (widget.indicatorColor != oldWidget.indicatorColor ||
        widget.indicatorWeight != oldWidget.indicatorWeight ||
        widget.indicatorSize != oldWidget.indicatorSize ||
        widget.indicatorPadding != oldWidget.indicatorPadding ||
        widget.indicator != oldWidget.indicator ||
        widget.dividerColor != oldWidget.dividerColor ||
        widget.dividerHeight != oldWidget.dividerHeight ||
        widget.indicatorAnimation != oldWidget.indicatorAnimation) {
      _initIndicatorPainter();
    }

    if (widget.tabs.length > _tabKeys.length) {
      final int delta = widget.tabs.length - _tabKeys.length;
      _tabKeys.addAll(List<GlobalKey>.generate(delta, (int n) => GlobalKey()));
      _labelPaddings.addAll(
        List<EdgeInsetsGeometry>.filled(delta, EdgeInsets.zero),
      );
    } else if (widget.tabs.length < _tabKeys.length) {
      _tabKeys.removeRange(widget.tabs.length, _tabKeys.length);
      _labelPaddings.removeRange(widget.tabs.length, _labelPaddings.length);
    }
  }

  @override
  void dispose() {
    _indicatorPainter!.dispose();
    if (_controllerIsValid) {
      _controller!.animation!.removeListener(_handleTabControllerAnimationTick);
      _controller!.removeListener(_handleTabControllerTick);
    }
    _controller = null;
    _scrollController?.dispose();
    super.dispose();
  }

  // -----------------------------------------------------------------------
  // Scroll helpers
  // -----------------------------------------------------------------------

  int get maxTabIndex => _indicatorPainter!.maxTabIndex;

  double _tabScrollOffset(
    int index,
    double viewportWidth,
    double minExtent,
    double maxExtent,
  ) {
    if (!widget.isScrollable) {
      return 0.0;
    }
    double tabCenter = _indicatorPainter!.centerOf(index);
    double paddingStart;
    switch (Directionality.of(context)) {
      case TextDirection.rtl:
        paddingStart = widget.padding?.resolve(TextDirection.rtl).right ?? 0;
        tabCenter = _tabStripWidth - tabCenter;
      case TextDirection.ltr:
        paddingStart = widget.padding?.resolve(TextDirection.ltr).left ?? 0;
    }
    return clampDouble(
      tabCenter + paddingStart - viewportWidth / 2.0,
      minExtent,
      maxExtent,
    );
  }

  double _tabCenteredScrollOffset(int index) {
    final ScrollPosition position = _scrollController!.position;
    return _tabScrollOffset(
      index,
      position.viewportDimension,
      position.minScrollExtent,
      position.maxScrollExtent,
    );
  }

  double _initialScrollOffset(
    double viewportWidth,
    double minExtent,
    double maxExtent,
  ) {
    return _tabScrollOffset(
      _currentIndex!,
      viewportWidth,
      minExtent,
      maxExtent,
    );
  }

  void _scrollToCurrentIndex() {
    final double offset = _tabCenteredScrollOffset(_currentIndex!);
    _scrollController!.animateTo(
      offset,
      duration: kTabScrollDuration,
      curve: Curves.ease,
    );
  }

  void _scrollToControllerValue() {
    final double? leadingPosition = _currentIndex! > 0
        ? _tabCenteredScrollOffset(_currentIndex! - 1)
        : null;
    final double middlePosition = _tabCenteredScrollOffset(_currentIndex!);
    final double? trailingPosition = _currentIndex! < maxTabIndex
        ? _tabCenteredScrollOffset(_currentIndex! + 1)
        : null;

    final double index = _controller!.index.toDouble();
    final double value = _controller!.animation!.value;
    final double offset = switch (value - index) {
      -1.0 => leadingPosition ?? middlePosition,
      1.0 => trailingPosition ?? middlePosition,
      0 => middlePosition,
      < 0 =>
        leadingPosition == null
            ? middlePosition
            : lerpDouble(middlePosition, leadingPosition, index - value)!,
      _ =>
        trailingPosition == null
            ? middlePosition
            : lerpDouble(middlePosition, trailingPosition, value - index)!,
    };

    _scrollController!.jumpTo(offset);
  }

  // -----------------------------------------------------------------------
  // Controller listeners
  // -----------------------------------------------------------------------

  void _handleTabControllerAnimationTick() {
    assert(mounted);
    if (!_controller!.indexIsChanging && widget.isScrollable) {
      _currentIndex = _controller!.index;
      _scrollToControllerValue();
    }
  }

  void _handleTabControllerTick() {
    if (_controller!.index != _currentIndex) {
      _currentIndex = _controller!.index;
      if (widget.isScrollable) {
        _scrollToCurrentIndex();
      }
    }
    setState(() {});
  }

  void _saveTabOffsets(
    List<double> tabOffsets,
    TextDirection textDirection,
    double width,
  ) {
    _tabStripWidth = width;
    _indicatorPainter?.saveTabOffsets(tabOffsets, textDirection);
  }

  void _handleTap(int index) {
    assert(index >= 0 && index < widget.tabs.length);
    _controller!.animateTo(index);
    widget.onTap?.call(index);
  }

  // -----------------------------------------------------------------------
  // Build helpers
  // -----------------------------------------------------------------------

  Widget _buildStyledTab(
    Widget child,
    bool isSelected,
    Animation<double> animation,
    TabBarThemeData defaults,
  ) {
    return _TabStyle(
      animation: animation,
      isSelected: isSelected,
      isPrimary: widget._isPrimary,
      labelColor: widget.labelColor,
      unselectedLabelColor: widget.unselectedLabelColor,
      labelStyle: widget.labelStyle,
      unselectedLabelStyle: widget.unselectedLabelStyle,
      defaults: defaults,
      child: child,
    );
  }

  Widget _buildDecoratedTab(
    Widget child,
    bool isSelected,
    Animation<double> animation,
  ) {
    final DecoratedTabBarThemeData decorationTheme = DecoratedTabBarTheme.of(
      context,
    );

    final Decoration? effectiveTabDecoration =
        widget.tabDecoration ?? decorationTheme.tabDecoration;
    final Decoration? effectiveUnselectedTabDecoration =
        widget.unselectedTabDecoration ??
        decorationTheme.unselectedTabDecoration;

    // Short-circuit: if no decoration is set at all, skip the wrapper.
    if (effectiveTabDecoration == null &&
        effectiveUnselectedTabDecoration == null) {
      return child;
    }

    return _TabDecorationWrapper(
      animation: animation,
      isSelected: isSelected,
      tabDecoration: effectiveTabDecoration,
      unselectedTabDecoration: effectiveUnselectedTabDecoration,
      tabDecorationPadding:
          widget.tabDecorationPadding ?? decorationTheme.tabDecorationPadding,
      tabDecorationMargin:
          widget.tabDecorationMargin ?? decorationTheme.tabDecorationMargin,
      tabDecorationConstraints:
          widget.tabDecorationConstraints ??
          decorationTheme.tabDecorationConstraints,
      child: child,
    );
  }

  // -----------------------------------------------------------------------
  // Debug
  // -----------------------------------------------------------------------

  bool _debugScheduleCheckHasValidTabsCount() {
    if (_debugHasScheduledValidTabsCountCheck) {
      return true;
    }
    WidgetsBinding.instance.addPostFrameCallback((Duration duration) {
      _debugHasScheduledValidTabsCountCheck = false;
      if (!mounted) {
        return;
      }
      assert(() {
        if (_controller!.length != widget.tabs.length) {
          throw FlutterError(
            "Controller's length property (${_controller!.length}) does not "
            "match the number of tabs (${widget.tabs.length}) present in "
            "DecoratedTabBar's tabs property.",
          );
        }
        return true;
      }());
    }, debugLabel: 'DecoratedTabBar.tabsCountCheck');
    _debugHasScheduledValidTabsCountCheck = true;
    return true;
  }

  bool _debugTabAlignmentIsValid(TabAlignment tabAlignment) {
    assert(() {
      if (widget.isScrollable && tabAlignment == TabAlignment.fill) {
        throw FlutterError(
          '$tabAlignment is only valid for non-scrollable tab bars.',
        );
      }
      if (!widget.isScrollable &&
          (tabAlignment == TabAlignment.start ||
              tabAlignment == TabAlignment.startOffset)) {
        throw FlutterError(
          '$tabAlignment is only valid for scrollable tab bars.',
        );
      }
      return true;
    }());
    return true;
  }

  // -----------------------------------------------------------------------
  // Build
  // -----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterialLocalizations(context));
    assert(_debugScheduleCheckHasValidTabsCount());
    final ThemeData theme = Theme.of(context);
    final TabBarThemeData tabBarTheme = TabBarTheme.of(context);
    final TabAlignment effectiveTabAlignment =
        widget.tabAlignment ??
        tabBarTheme.tabAlignment ??
        _defaults.tabAlignment!;
    assert(_debugTabAlignmentIsValid(effectiveTabAlignment));

    final MaterialLocalizations localizations = MaterialLocalizations.of(
      context,
    );
    if (_controller!.length == 0) {
      return LimitedBox(
        maxWidth: 0.0,
        child: SizedBox(
          width: double.infinity,
          height: _kTabHeight + widget.indicatorWeight,
        ),
      );
    }

    // --- Wrap tabs with padding and keyed subtree ---
    final List<Widget> wrappedTabs = List<Widget>.generate(widget.tabs.length, (
      int index,
    ) {
      EdgeInsetsGeometry padding =
          widget.labelPadding ?? tabBarTheme.labelPadding ?? kTabLabelPadding;
      const double verticalAdjustment =
          (_kTextAndIconTabHeight - _kTabHeight) / 2.0;

      final Widget tab = widget.tabs[index];
      if (tab is PreferredSizeWidget &&
          tab.preferredSize.height == _kTabHeight &&
          widget.tabHasTextAndIcon) {
        padding = padding.add(
          const EdgeInsets.symmetric(vertical: verticalAdjustment),
        );
      }
      _labelPaddings[index] = padding;

      return Center(
        heightFactor: 1.0,
        child: Padding(
          padding: _labelPaddings[index],
          child: KeyedSubtree(key: _tabKeys[index], child: widget.tabs[index]),
        ),
      );
    });

    // --- Apply text style and decoration animations ---
    if (_controller != null) {
      final int previousIndex = _controller!.previousIndex;

      if (_controller!.indexIsChanging) {
        assert(_currentIndex != previousIndex);
        final Animation<double> animation = _ChangeAnimation(_controller!);

        wrappedTabs[_currentIndex!] = _buildDecoratedTab(
          _buildStyledTab(
            wrappedTabs[_currentIndex!],
            true,
            animation,
            _defaults,
          ),
          true,
          animation,
        );
        wrappedTabs[previousIndex] = _buildDecoratedTab(
          _buildStyledTab(
            wrappedTabs[previousIndex],
            false,
            animation,
            _defaults,
          ),
          false,
          animation,
        );
      } else {
        final int tabIndex = _currentIndex!;
        final Animation<double> centerAnimation = _DragAnimation(
          _controller!,
          tabIndex,
        );

        wrappedTabs[tabIndex] = _buildDecoratedTab(
          _buildStyledTab(
            wrappedTabs[tabIndex],
            true,
            centerAnimation,
            _defaults,
          ),
          true,
          centerAnimation,
        );

        if (_currentIndex! > 0) {
          final int prevTabIndex = _currentIndex! - 1;
          final Animation<double> previousAnimation = ReverseAnimation(
            _DragAnimation(_controller!, prevTabIndex),
          );
          wrappedTabs[prevTabIndex] = _buildDecoratedTab(
            _buildStyledTab(
              wrappedTabs[prevTabIndex],
              false,
              previousAnimation,
              _defaults,
            ),
            false,
            previousAnimation,
          );
        }
        if (_currentIndex! < widget.tabs.length - 1) {
          final int nextTabIndex = _currentIndex! + 1;
          final Animation<double> nextAnimation = ReverseAnimation(
            _DragAnimation(_controller!, nextTabIndex),
          );
          wrappedTabs[nextTabIndex] = _buildDecoratedTab(
            _buildStyledTab(
              wrappedTabs[nextTabIndex],
              false,
              nextAnimation,
              _defaults,
            ),
            false,
            nextAnimation,
          );
        }
      }
    }

    // --- Wrap with InkWell, semantics, and Expanded ---
    final int tabCount = widget.tabs.length;
    for (int index = 0; index < tabCount; index += 1) {
      final Set<WidgetState> selectedState = <WidgetState>{
        if (index == _currentIndex) WidgetState.selected,
      };

      final MouseCursor effectiveMouseCursor =
          WidgetStateProperty.resolveAs<MouseCursor?>(
            widget.mouseCursor,
            selectedState,
          ) ??
          tabBarTheme.mouseCursor?.resolve(selectedState) ??
          WidgetStateMouseCursor.clickable.resolve(selectedState);

      final WidgetStateProperty<Color?> defaultOverlay =
          WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
            final Set<WidgetState> effectiveStates = selectedState.toSet()
              ..addAll(states);
            return _defaults.overlayColor?.resolve(effectiveStates);
          });

      wrappedTabs[index] = InkWell(
        mouseCursor: effectiveMouseCursor,
        onTap: () {
          _handleTap(index);
        },
        onHover: (bool value) {
          widget.onHover?.call(value, index);
        },
        onFocusChange: (bool value) {
          widget.onFocusChange?.call(value, index);
        },
        enableFeedback: widget.enableFeedback ?? true,
        overlayColor:
            widget.overlayColor ?? tabBarTheme.overlayColor ?? defaultOverlay,
        splashFactory:
            widget.splashFactory ??
            tabBarTheme.splashFactory ??
            _defaults.splashFactory,
        borderRadius:
            widget.splashBorderRadius ??
            tabBarTheme.splashBorderRadius ??
            _defaults.splashBorderRadius,
        child: Padding(
          padding: EdgeInsets.only(bottom: widget.indicatorWeight),
          child: Stack(
            children: <Widget>[
              wrappedTabs[index],
              Semantics(
                role: SemanticsRole.tab,
                selected: index == _currentIndex,
                label: kIsWeb
                    ? null
                    : localizations.tabLabel(
                        tabIndex: index + 1,
                        tabCount: tabCount,
                      ),
              ),
            ],
          ),
        ),
      );
      wrappedTabs[index] = MergeSemantics(child: wrappedTabs[index]);
      if (!widget.isScrollable && effectiveTabAlignment == TabAlignment.fill) {
        wrappedTabs[index] = Expanded(child: wrappedTabs[index]);
      }
    }

    // --- Compose the final tab bar ---
    Widget tabBar = Semantics(
      role: SemanticsRole.tabBar,
      container: true,
      explicitChildNodes: true,
      child: CustomPaint(
        painter: _indicatorPainter,
        child: _TabStyle(
          animation: kAlwaysDismissedAnimation,
          isSelected: false,
          isPrimary: widget._isPrimary,
          labelColor: widget.labelColor,
          unselectedLabelColor: widget.unselectedLabelColor,
          labelStyle: widget.labelStyle,
          unselectedLabelStyle: widget.unselectedLabelStyle,
          defaults: _defaults,
          child: _TabLabelBar(
            onPerformLayout: _saveTabOffsets,
            mainAxisSize: effectiveTabAlignment == TabAlignment.fill
                ? MainAxisSize.max
                : MainAxisSize.min,
            children: wrappedTabs,
          ),
        ),
      ),
    );

    if (widget.isScrollable) {
      final EdgeInsetsGeometry? effectivePadding =
          effectiveTabAlignment == TabAlignment.startOffset
          ? const EdgeInsetsDirectional.only(
              start: _kStartOffset,
            ).add(widget.padding ?? EdgeInsets.zero)
          : widget.padding;
      _scrollController ??= _TabBarScrollController(this);
      tabBar = ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
        child: SingleChildScrollView(
          dragStartBehavior: widget.dragStartBehavior,
          scrollDirection: Axis.horizontal,
          controller: _scrollController,
          padding: effectivePadding,
          physics: widget.physics,
          child: tabBar,
        ),
      );
      if (theme.useMaterial3) {
        final AlignmentGeometry effectiveAlignment =
            switch (effectiveTabAlignment) {
              TabAlignment.center => Alignment.center,
              TabAlignment.start ||
              TabAlignment.startOffset ||
              TabAlignment.fill => AlignmentDirectional.centerStart,
            };

        final Color dividerColor =
            widget.dividerColor ??
            tabBarTheme.dividerColor ??
            _defaults.dividerColor!;
        final double dividerHeight =
            widget.dividerHeight ??
            tabBarTheme.dividerHeight ??
            _defaults.dividerHeight!;

        tabBar = Align(
          heightFactor: 1.0,
          widthFactor: dividerHeight > 0 ? null : 1.0,
          alignment: effectiveAlignment,
          child: tabBar,
        );

        if (dividerColor != Colors.transparent && dividerHeight > 0) {
          tabBar = CustomPaint(
            painter: _DividerPainter(
              dividerColor: dividerColor,
              dividerHeight: dividerHeight,
            ),
            child: tabBar,
          );
        }
      }
    } else if (widget.padding != null) {
      tabBar = Padding(padding: widget.padding!, child: tabBar);
    }

    return MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: widget.textScaler ?? tabBarTheme.textScaler),
      child: tabBar,
    );
  }
}

// ---------------------------------------------------------------------------
// Default theme data (M2 & M3)
// ---------------------------------------------------------------------------

class _TabsDefaultsM2 extends TabBarThemeData {
  _TabsDefaultsM2(this.context, this.isScrollable)
    : super(indicatorSize: TabBarIndicatorSize.tab);

  final BuildContext context;
  final bool isScrollable;

  static const EdgeInsetsGeometry iconMargin = EdgeInsets.only(bottom: 10.0);

  late final ColorScheme _colors = Theme.of(context).colorScheme;
  late final TextTheme _textTheme = Theme.of(context).textTheme;

  @override
  Color? get indicatorColor => Theme.of(context).indicatorColor;

  @override
  Color? get labelColor => _textTheme.bodyLarge?.color;

  @override
  TextStyle? get labelStyle => _textTheme.bodyLarge;

  @override
  Color? get unselectedLabelColor => null;

  @override
  TextStyle? get unselectedLabelStyle => _textTheme.bodyLarge;

  @override
  InteractiveInkFeatureFactory? get splashFactory =>
      Theme.of(context).splashFactory;

  @override
  TabAlignment? get tabAlignment =>
      isScrollable ? TabAlignment.center : TabAlignment.fill;

  @override
  Color? get dividerColor => null;

  @override
  double? get dividerHeight => null;

  @override
  WidgetStateProperty<Color?>? get overlayColor => null;

  @override
  BorderRadius? get splashBorderRadius => null;
}

class _TabsPrimaryDefaultsM3 extends TabBarThemeData {
  _TabsPrimaryDefaultsM3(this.context, this.isScrollable)
    : super(indicatorSize: TabBarIndicatorSize.label);

  final BuildContext context;
  final bool isScrollable;

  static const EdgeInsetsGeometry iconMargin = EdgeInsets.only(bottom: 2.0);

  static double indicatorWeight(TabBarIndicatorSize indicatorSize) {
    return switch (indicatorSize) {
      TabBarIndicatorSize.label => 3.0,
      TabBarIndicatorSize.tab => 2.0,
    };
  }

  late final ColorScheme _colors = Theme.of(context).colorScheme;
  late final TextTheme _textTheme = Theme.of(context).textTheme;

  @override
  Color? get indicatorColor => _colors.primary;

  @override
  Color? get labelColor => _colors.primary;

  @override
  TextStyle? get labelStyle => _textTheme.titleSmall;

  @override
  Color? get unselectedLabelColor => _colors.onSurfaceVariant;

  @override
  TextStyle? get unselectedLabelStyle => _textTheme.titleSmall;

  @override
  InteractiveInkFeatureFactory? get splashFactory =>
      Theme.of(context).splashFactory;

  @override
  TabAlignment? get tabAlignment =>
      isScrollable ? TabAlignment.startOffset : TabAlignment.fill;

  @override
  Color? get dividerColor => _colors.outlineVariant;

  @override
  double? get dividerHeight => 1.0;

  @override
  WidgetStateProperty<Color?>? get overlayColor {
    return WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.selected)) {
        if (states.contains(WidgetState.pressed)) {
          return _colors.primary.withOpacity(0.1);
        }
        if (states.contains(WidgetState.hovered)) {
          return _colors.primary.withOpacity(0.08);
        }
        if (states.contains(WidgetState.focused)) {
          return _colors.primary.withOpacity(0.1);
        }
        return null;
      }
      if (states.contains(WidgetState.pressed)) {
        return _colors.primary.withOpacity(0.1);
      }
      if (states.contains(WidgetState.hovered)) {
        return _colors.onSurface.withOpacity(0.08);
      }
      if (states.contains(WidgetState.focused)) {
        return _colors.onSurface.withOpacity(0.1);
      }
      return null;
    });
  }

  @override
  BorderRadius? get splashBorderRadius => null;
}

class _TabsSecondaryDefaultsM3 extends TabBarThemeData {
  _TabsSecondaryDefaultsM3(this.context, this.isScrollable)
    : super(indicatorSize: TabBarIndicatorSize.tab);

  final BuildContext context;
  final bool isScrollable;

  static const double indicatorWeight = 2.0;

  late final ColorScheme _colors = Theme.of(context).colorScheme;
  late final TextTheme _textTheme = Theme.of(context).textTheme;

  @override
  Color? get indicatorColor => _colors.primary;

  @override
  Color? get labelColor => _colors.onSurface;

  @override
  TextStyle? get labelStyle => _textTheme.titleSmall;

  @override
  Color? get unselectedLabelColor => _colors.onSurfaceVariant;

  @override
  TextStyle? get unselectedLabelStyle => _textTheme.titleSmall;

  @override
  InteractiveInkFeatureFactory? get splashFactory =>
      Theme.of(context).splashFactory;

  @override
  TabAlignment? get tabAlignment =>
      isScrollable ? TabAlignment.startOffset : TabAlignment.fill;

  @override
  Color? get dividerColor => _colors.outlineVariant;

  @override
  double? get dividerHeight => 1.0;

  @override
  WidgetStateProperty<Color?>? get overlayColor {
    return WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.selected)) {
        if (states.contains(WidgetState.pressed)) {
          return _colors.onSurface.withOpacity(0.1);
        }
        if (states.contains(WidgetState.hovered)) {
          return _colors.onSurface.withOpacity(0.08);
        }
        if (states.contains(WidgetState.focused)) {
          return _colors.onSurface.withOpacity(0.1);
        }
        return null;
      }
      if (states.contains(WidgetState.pressed)) {
        return _colors.onSurface.withOpacity(0.1);
      }
      if (states.contains(WidgetState.hovered)) {
        return _colors.onSurface.withOpacity(0.08);
      }
      if (states.contains(WidgetState.focused)) {
        return _colors.onSurface.withOpacity(0.1);
      }
      return null;
    });
  }

  @override
  BorderRadius? get splashBorderRadius => null;
}
