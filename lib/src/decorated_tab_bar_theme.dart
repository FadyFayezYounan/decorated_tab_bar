// Copyright 2025 The decorated_tab_bar Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Defines the visual properties for [DecoratedTabBar] tab decorations.
///
/// Used by [DecoratedTabBarTheme] to control the appearance of tab
/// decorations in a widget subtree.
///
/// To obtain the current [DecoratedTabBarThemeData], use
/// [DecoratedTabBarTheme.of] to access the closest ancestor
/// [DecoratedTabBarTheme], which provides this data.
///
/// See also:
///
///  * [DecoratedTabBarTheme], an [InheritedWidget] that propagates the theme
///    down the widget tree.
@immutable
class DecoratedTabBarThemeData with Diagnosticable {
  /// Creates a theme data object for [DecoratedTabBar].
  const DecoratedTabBarThemeData({
    this.tabDecoration,
    this.unselectedTabDecoration,
    this.tabDecorationPadding,
    this.tabDecorationMargin,
    this.tabDecorationAnimationDuration,
    this.tabDecorationConstraints,
  });

  /// The decoration to paint behind the selected tab.
  ///
  /// If null, no decoration is painted for the selected tab.
  final Decoration? tabDecoration;

  /// The decoration to paint behind unselected tabs.
  ///
  /// If null, no decoration is painted for unselected tabs.
  final Decoration? unselectedTabDecoration;

  /// The padding inside the tab decoration container.
  ///
  /// If null, no additional padding is applied.
  final EdgeInsetsGeometry? tabDecorationPadding;

  /// The margin around the tab decoration container.
  ///
  /// If null, no margin is applied.
  final EdgeInsetsGeometry? tabDecorationMargin;

  /// The duration of the tab decoration transition animation.
  ///
  /// If null, defaults to [kTabScrollDuration].
  final Duration? tabDecorationAnimationDuration;

  /// Optional constraints for the tab decoration container.
  ///
  /// If null, no additional constraints are applied.
  final BoxConstraints? tabDecorationConstraints;

  /// Creates a copy of this object with the given fields replaced with the new
  /// values.
  DecoratedTabBarThemeData copyWith({
    Decoration? tabDecoration,
    Decoration? unselectedTabDecoration,
    EdgeInsetsGeometry? tabDecorationPadding,
    EdgeInsetsGeometry? tabDecorationMargin,
    Duration? tabDecorationAnimationDuration,
    BoxConstraints? tabDecorationConstraints,
  }) {
    return DecoratedTabBarThemeData(
      tabDecoration: tabDecoration ?? this.tabDecoration,
      unselectedTabDecoration:
          unselectedTabDecoration ?? this.unselectedTabDecoration,
      tabDecorationPadding: tabDecorationPadding ?? this.tabDecorationPadding,
      tabDecorationMargin: tabDecorationMargin ?? this.tabDecorationMargin,
      tabDecorationAnimationDuration:
          tabDecorationAnimationDuration ?? this.tabDecorationAnimationDuration,
      tabDecorationConstraints:
          tabDecorationConstraints ?? this.tabDecorationConstraints,
    );
  }

  /// Linearly interpolates between two [DecoratedTabBarThemeData] objects.
  static DecoratedTabBarThemeData? lerp(
    DecoratedTabBarThemeData? a,
    DecoratedTabBarThemeData? b,
    double t,
  ) {
    if (identical(a, b)) {
      return a;
    }
    return DecoratedTabBarThemeData(
      tabDecoration: Decoration.lerp(a?.tabDecoration, b?.tabDecoration, t),
      unselectedTabDecoration: Decoration.lerp(
        a?.unselectedTabDecoration,
        b?.unselectedTabDecoration,
        t,
      ),
      tabDecorationPadding: EdgeInsetsGeometry.lerp(
        a?.tabDecorationPadding,
        b?.tabDecorationPadding,
        t,
      ),
      tabDecorationMargin: EdgeInsetsGeometry.lerp(
        a?.tabDecorationMargin,
        b?.tabDecorationMargin,
        t,
      ),
    );
  }

  @override
  int get hashCode => Object.hash(
    tabDecoration,
    unselectedTabDecoration,
    tabDecorationPadding,
    tabDecorationMargin,
    tabDecorationAnimationDuration,
    tabDecorationConstraints,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is DecoratedTabBarThemeData &&
        other.tabDecoration == tabDecoration &&
        other.unselectedTabDecoration == unselectedTabDecoration &&
        other.tabDecorationPadding == tabDecorationPadding &&
        other.tabDecorationMargin == tabDecorationMargin &&
        other.tabDecorationAnimationDuration ==
            tabDecorationAnimationDuration &&
        other.tabDecorationConstraints == tabDecorationConstraints;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<Decoration>(
        'tabDecoration',
        tabDecoration,
        defaultValue: null,
      ),
    );
    properties.add(
      DiagnosticsProperty<Decoration>(
        'unselectedTabDecoration',
        unselectedTabDecoration,
        defaultValue: null,
      ),
    );
    properties.add(
      DiagnosticsProperty<EdgeInsetsGeometry>(
        'tabDecorationPadding',
        tabDecorationPadding,
        defaultValue: null,
      ),
    );
    properties.add(
      DiagnosticsProperty<EdgeInsetsGeometry>(
        'tabDecorationMargin',
        tabDecorationMargin,
        defaultValue: null,
      ),
    );
    properties.add(
      DiagnosticsProperty<Duration>(
        'tabDecorationAnimationDuration',
        tabDecorationAnimationDuration,
        defaultValue: null,
      ),
    );
    properties.add(
      DiagnosticsProperty<BoxConstraints>(
        'tabDecorationConstraints',
        tabDecorationConstraints,
        defaultValue: null,
      ),
    );
  }
}

/// An [InheritedWidget] that defines the visual properties for
/// [DecoratedTabBar] widgets in this widget's subtree.
///
/// Values specified here are used for [DecoratedTabBar] properties that are not
/// given an explicit non-null value.
class DecoratedTabBarTheme extends InheritedTheme {
  /// Creates a theme that defines the visual properties for
  /// [DecoratedTabBar] widgets.
  const DecoratedTabBarTheme({
    super.key,
    required this.data,
    required super.child,
  });

  /// The properties for descendant [DecoratedTabBar] widgets.
  final DecoratedTabBarThemeData data;

  /// The closest instance of this class that encloses the given context.
  ///
  /// If there is no enclosing [DecoratedTabBarTheme] widget, then
  /// [DecoratedTabBarThemeData] with all null values is returned.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// final DecoratedTabBarThemeData theme = DecoratedTabBarTheme.of(context);
  /// ```
  static DecoratedTabBarThemeData of(BuildContext context) {
    final DecoratedTabBarTheme? decoratedTabBarTheme = context
        .dependOnInheritedWidgetOfExactType<DecoratedTabBarTheme>();
    return decoratedTabBarTheme?.data ?? const DecoratedTabBarThemeData();
  }

  @override
  Widget wrap(BuildContext context, Widget child) {
    return DecoratedTabBarTheme(data: data, child: child);
  }

  @override
  bool updateShouldNotify(DecoratedTabBarTheme oldWidget) =>
      data != oldWidget.data;
}
