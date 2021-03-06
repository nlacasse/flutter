// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/widgets.dart';

import 'constants.dart';
import 'divider.dart';
import 'icon.dart';
import 'icons.dart';
import 'icon_button.dart';
import 'icon_theme.dart';
import 'icon_theme_data.dart';
import 'ink_well.dart';
import 'list_item.dart';
import 'material.dart';
import 'theme.dart';

const Duration _kMenuDuration = const Duration(milliseconds: 300);
const double _kBaselineOffsetFromBottom = 20.0;
const double _kMenuCloseIntervalEnd = 2.0 / 3.0;
const double _kMenuHorizontalPadding = 16.0;
const double _kMenuItemHeight = 48.0;
const double _kMenuMaxWidth = 5.0 * _kMenuWidthStep;
const double _kMenuMinWidth = 2.0 * _kMenuWidthStep;
const double _kMenuVerticalPadding = 8.0;
const double _kMenuWidthStep = 56.0;
const double _kMenuScreenPadding = 8.0;

abstract class PopupMenuEntry<T> extends StatefulWidget {
  PopupMenuEntry({ Key key }) : super(key: key);

  double get height;
  T get value => null;
  bool get enabled => true;
}

class PopupMenuDivider extends PopupMenuEntry<dynamic> {
  PopupMenuDivider({ Key key, this.height: 16.0 }) : super(key: key);

  @override
  final double height;

  @override
  _PopupMenuDividerState createState() => new _PopupMenuDividerState();
}

class _PopupMenuDividerState extends State<PopupMenuDivider> {
  @override
  Widget build(BuildContext context) => new Divider(height: config.height);
}

class PopupMenuItem<T> extends PopupMenuEntry<T> {
  PopupMenuItem({
    Key key,
    this.value,
    this.enabled: true,
    this.child
  }) : super(key: key);

  @override
  final T value;

  @override
  final bool enabled;

  /// The widget below this widget in the tree.
  final Widget child;

  @override
  double get height => _kMenuItemHeight;

  @override
  _PopupMenuItemState<PopupMenuItem<T>> createState() => new _PopupMenuItemState<PopupMenuItem<T>>();
}

class _PopupMenuItemState<T extends PopupMenuItem<dynamic>> extends State<T> {
  // Override this to put something else in the menu entry.
  Widget buildChild() => config.child;

  void onTap() {
    Navigator.pop(context, config.value);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    TextStyle style = theme.textTheme.subhead;
    if (!config.enabled)
      style = style.copyWith(color: theme.disabledColor);

    Widget item = new AnimatedDefaultTextStyle(
      style: style,
      duration: kThemeChangeDuration,
      child: new Baseline(
        baseline: config.height - _kBaselineOffsetFromBottom,
        child: buildChild()
      )
    );
    if (!config.enabled) {
      final bool isDark = theme.brightness == ThemeBrightness.dark;
      item = new IconTheme(
        data: new IconThemeData(opacity: isDark ? 0.5 : 0.38),
        child: item
      );
    }

    return new InkWell(
      onTap: config.enabled ? onTap : null,
      child: new MergeSemantics(
        child: new Container(
          height: config.height,
          padding: const EdgeInsets.symmetric(horizontal: _kMenuHorizontalPadding),
          child: item
        )
      )
    );
  }
}

class CheckedPopupMenuItem<T> extends PopupMenuItem<T> {
  CheckedPopupMenuItem({
    Key key,
    T value,
    this.checked: false,
    bool enabled: true,
    Widget child
  }) : super(
    key: key,
    value: value,
    enabled: enabled,
    child: child
  );

  final bool checked;

  @override
  _CheckedPopupMenuItemState<T> createState() => new _CheckedPopupMenuItemState<T>();
}

class _CheckedPopupMenuItemState<T> extends _PopupMenuItemState<CheckedPopupMenuItem<T>> {
  static const Duration _kFadeDuration = const Duration(milliseconds: 150);
  AnimationController _controller;
  Animation<double> get _opacity => _controller.view;

  @override
  void initState() {
    super.initState();
    _controller = new AnimationController(duration: _kFadeDuration)
      ..value = config.checked ? 1.0 : 0.0
      ..addListener(() => setState(() { /* animation changed */ }));
  }

  @override
  void onTap() {
    // This fades the checkmark in or out when tapped.
    if (config.checked)
      _controller.reverse();
    else
      _controller.forward();
    super.onTap();
  }

  @override
  Widget buildChild() {
    return new ListItem(
      enabled: config.enabled,
      leading: new FadeTransition(
        opacity: _opacity,
        child: new Icon(icon: _controller.isDismissed ? null : Icons.done)
      ),
      title: config.child
    );
  }
}

class _PopupMenu<T> extends StatelessWidget {
  _PopupMenu({
    Key key,
    this.route
  }) : super(key: key);

  final _PopupMenuRoute<T> route;

  @override
  Widget build(BuildContext context) {
    double unit = 1.0 / (route.items.length + 1.5); // 1.0 for the width and 0.5 for the last item's fade.
    List<Widget> children = <Widget>[];

    for (int i = 0; i < route.items.length; ++i) {
      final double start = (i + 1) * unit;
      final double end = (start + 1.5 * unit).clamp(0.0, 1.0);
      CurvedAnimation opacity = new CurvedAnimation(
        parent: route.animation,
        curve: new Interval(start, end)
      );
      Widget item = route.items[i];
      if (route.initialValue != null && route.initialValue == route.items[i].value) {
        item = new Container(
          decoration: new BoxDecoration(backgroundColor: Theme.of(context).highlightColor),
          child: item
        );
      }
      children.add(new FadeTransition(
        opacity: opacity,
        child: item
      ));
    }

    final CurveTween opacity = new CurveTween(curve: new Interval(0.0, 1.0 / 3.0));
    final CurveTween width = new CurveTween(curve: new Interval(0.0, unit));
    final CurveTween height = new CurveTween(curve: new Interval(0.0, unit * route.items.length));

    Widget child = new ConstrainedBox(
      constraints: new BoxConstraints(
        minWidth: _kMenuMinWidth,
        maxWidth: _kMenuMaxWidth
      ),
      child: new IntrinsicWidth(
        stepWidth: _kMenuWidthStep,
        child: new Block(
          children: children,
          padding: const EdgeInsets.symmetric(
            vertical: _kMenuVerticalPadding
          )
        )
      )
    );

    return new AnimatedBuilder(
      animation: route.animation,
      builder: (BuildContext context, Widget child) {
        return new Opacity(
          opacity: opacity.evaluate(route.animation),
          child: new Material(
            type: MaterialType.card,
            elevation: route.elevation,
            child: new Align(
              alignment: FractionalOffset.topRight,
              widthFactor: width.evaluate(route.animation),
              heightFactor: height.evaluate(route.animation),
              child: child
            )
          )
        );
      },
      child: child
    );
  }
}

class _PopupMenuRouteLayout extends SingleChildLayoutDelegate {
  _PopupMenuRouteLayout(this.position, this.selectedItemOffset);

  final ModalPosition position;
  final double selectedItemOffset;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return new BoxConstraints(
      minWidth: 0.0,
      maxWidth: constraints.maxWidth,
      minHeight: 0.0,
      maxHeight: constraints.maxHeight
    );
  }

  // Put the child wherever position specifies, so long as it will fit within the
  // specified parent size padded (inset) by 8. If necessary, adjust the child's
  // position so that it fits.
  @override
  Offset getPositionForChild(Size size, Size childSize) {
    double x = position?.left
      ?? (position?.right != null ? size.width - (position.right + childSize.width) : _kMenuScreenPadding);
    double y = position?.top
      ?? (position?.bottom != null ? size.height - (position.bottom - childSize.height) : _kMenuScreenPadding);

    if (selectedItemOffset != null)
      y -= selectedItemOffset + _kMenuVerticalPadding + _kMenuItemHeight / 2.0;

    if (x < _kMenuScreenPadding)
      x = _kMenuScreenPadding;
    else if (x + childSize.width > size.width - 2 * _kMenuScreenPadding)
      x = size.width - childSize.width - _kMenuScreenPadding;
    if (y < _kMenuScreenPadding)
      y = _kMenuScreenPadding;
    else if (y + childSize.height > size.height - 2 * _kMenuScreenPadding)
      y = size.height - childSize.height - _kMenuScreenPadding;
    return new Offset(x, y);
  }

  @override
  bool shouldRelayout(_PopupMenuRouteLayout oldDelegate) {
    return position != oldDelegate.position;
  }
}

class _PopupMenuRoute<T> extends PopupRoute<T> {
  _PopupMenuRoute({
    Completer<T> completer,
    this.position,
    this.items,
    this.initialValue,
    this.elevation
  }) : super(completer: completer);

  final ModalPosition position;
  final List<PopupMenuEntry<T>> items;
  final dynamic initialValue;
  final int elevation;

  @override
  ModalPosition getPosition(BuildContext context) => null;

  @override
  Animation<double> createAnimation() {
    return new CurvedAnimation(
      parent: super.createAnimation(),
      reverseCurve: new Interval(0.0, _kMenuCloseIntervalEnd)
    );
  }

  @override
  Duration get transitionDuration => _kMenuDuration;

  @override
  bool get barrierDismissable => true;

  @override
  Color get barrierColor => null;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> forwardAnimation) {
    double selectedItemOffset;
    if (initialValue != null) {
      selectedItemOffset = 0.0;
      for (int i = 0; i < items.length; i++) {
        if (initialValue == items[i].value)
          break;
        selectedItemOffset += items[i].height;
      }
    }
    final Size screenSize = MediaQuery.of(context).size;
    return new ConstrainedBox(
      constraints: new BoxConstraints(maxWidth: screenSize.width, maxHeight: screenSize.height),
      child: new CustomSingleChildLayout(
        delegate: new _PopupMenuRouteLayout(position, selectedItemOffset),
        child: new _PopupMenu<T>(route: this)
      )
    );
  }
}

/// Show a popup menu that contains the [items] at [position]. If [initialValue]
/// is specified then the first item with a matching value will be highlighted
/// and the value of [position] implies where the left, center point of the
/// highlighted item should appear. If [initialValue] is not specified then position
/// implies the menu's origin.
Future<dynamic/*=T*/> showMenu/*<T>*/({
  BuildContext context,
  ModalPosition position,
  List<PopupMenuEntry<dynamic/*=T*/>> items,
  dynamic/*=T*/ initialValue,
  int elevation: 8
}) {
  assert(context != null);
  assert(items != null && items.length > 0);
  Completer<dynamic/*=T*/> completer = new Completer<dynamic/*=T*/>();
  Navigator.push(context, new _PopupMenuRoute<dynamic/*=T*/>(
    completer: completer,
    position: position,
    items: items,
    initialValue: initialValue,
    elevation: elevation
  ));
  return completer.future;
}

/// A callback that is passed the value of the PopupMenuItem that caused
/// its menu to be dismissed.
typedef void PopupMenuItemSelected<T>(T value);

/// Signature used by [PopupMenuButton] to lazily construct the items shown when the button is pressed.
typedef List<PopupMenuEntry<T>> PopupMenuItemBuilder<T>(BuildContext context);

/// Displays a menu when pressed and calls [onSelected] when the menu is dismissed
/// because an item was selected. The value passed to [onSelected] is the value of
/// the selected menu item. If child is null then a standard 'navigation/more_vert'
/// icon is created.
class PopupMenuButton<T> extends StatefulWidget {
  PopupMenuButton({
    Key key,
    this.itemBuilder,
    this.initialValue,
    this.onSelected,
    this.tooltip: 'Show menu',
    this.elevation: 8,
    this.child
  }) : super(key: key) {
    assert(itemBuilder != null);
  }

  /// Called when the button is pressed to create the items to show in the menu.
  final PopupMenuItemBuilder<T> itemBuilder;

  final T initialValue;

  final PopupMenuItemSelected<T> onSelected;

  /// Text that describes the action that will occur when the button is pressed.
  ///
  /// This text is displayed when the user long-presses on the button and is
  /// used for accessibility.
  final String tooltip;

  /// The z-coordinate at which to place the menu when open.
  final int elevation;

  /// The widget below this widget in the tree.
  final Widget child;

  @override
  _PopupMenuButtonState<T> createState() => new _PopupMenuButtonState<T>();
}

class _PopupMenuButtonState<T> extends State<PopupMenuButton<T>> {
  void showButtonMenu(BuildContext context) {
    final RenderBox renderBox = context.findRenderObject();
    final Point topLeft = renderBox.localToGlobal(Point.origin);
    showMenu/*<T>*/(
      context: context,
      elevation: config.elevation,
      items: config.itemBuilder(context),
      initialValue: config.initialValue,
      position: new ModalPosition(
        left: topLeft.x,
        top: topLeft.y + (config.initialValue != null ? renderBox.size.height / 2.0 : 0.0)
      )
    )
    .then((T value) {
      if (value != null && config.onSelected != null)
        config.onSelected(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (config.child == null) {
      return new IconButton(
        icon: Icons.more_vert,
        tooltip: config.tooltip,
        onPressed: () { showButtonMenu(context); }
      );
    }
    return new InkWell(
      onTap: () { showButtonMenu(context); },
      child: config.child
    );
  }
}
