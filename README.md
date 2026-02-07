# decorated_tab_bar

A drop-in replacement for Flutter's `TabBar` that supports **selected and unselected tab decorations** with smooth animated transitions.

## Problem

Flutter's built-in `TabBar` only lets you style the **selected tab indicator** (the underline). There's no way to decorate unselected tabs — for example, giving them a white background, a border, or a different shape. Wrapping tab children in `Container` widgets leads to inconsistent sizing and no animation between states.

## Solution

`DecoratedTabBar` adds five new properties on top of every standard `TabBar` property:

| Property | Description |
|---|---|
| `tabDecoration` | `Decoration` painted behind the **selected** tab |
| `unselectedTabDecoration` | `Decoration` painted behind **unselected** tabs |
| `tabDecorationPadding` | Inner padding inside the decoration container |
| `tabDecorationMargin` | Outer margin around the decoration container |
| `tabDecorationConstraints` | Optional `BoxConstraints` for the decoration container |

The decoration **animates** smoothly when tabs change — both on tap and during swipe — using `Decoration.lerp`, the same approach Flutter uses internally for other animated properties.

## Getting started

```yaml
dependencies:
  decorated_tab_bar: ^0.1.0
```

## Usage

### Basic — white unselected / blue selected

```dart
DecoratedTabBar(
  tabDecoration: BoxDecoration(
    color: Colors.blue,
    borderRadius: BorderRadius.circular(8),
  ),
  unselectedTabDecoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: Colors.grey.shade300),
  ),
  tabDecorationMargin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
  // Hide the default underline indicator.
  indicator: const BoxDecoration(),
  dividerHeight: 0,
  tabs: const [
    Tab(text: 'Tab 1'),
    Tab(text: 'Tab 2'),
    Tab(text: 'Tab 3'),
  ],
)
```

### Pill-style tabs

```dart
DecoratedTabBar(
  tabDecoration: BoxDecoration(
    color: colorScheme.primary,
    borderRadius: BorderRadius.circular(24),
  ),
  unselectedTabDecoration: BoxDecoration(
    color: Colors.transparent,
    borderRadius: BorderRadius.circular(24),
  ),
  labelColor: colorScheme.onPrimary,
  unselectedLabelColor: colorScheme.onSurfaceVariant,
  tabDecorationMargin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
  indicator: const BoxDecoration(),
  dividerHeight: 0,
  tabs: const [
    Tab(text: 'All'),
    Tab(text: 'Unread'),
    Tab(text: 'Groups'),
  ],
)
```

### Keeping the underline indicator

You don't have to hide the indicator. The decorations layer sits behind the default indicator:

```dart
DecoratedTabBar(
  unselectedTabDecoration: BoxDecoration(
    color: Colors.grey.shade100,
    borderRadius: BorderRadius.circular(4),
  ),
  tabDecorationMargin: const EdgeInsets.only(bottom: 2, left: 2, right: 2),
  tabs: const [
    Tab(text: 'Home'),
    Tab(text: 'Profile'),
  ],
)
```

### Secondary tab bar

```dart
DecoratedTabBar.secondary(
  tabDecoration: BoxDecoration(
    color: colorScheme.secondaryContainer,
    borderRadius: BorderRadius.circular(8),
  ),
  unselectedTabDecoration: const BoxDecoration(),
  tabDecorationMargin: const EdgeInsets.all(4),
  indicator: const BoxDecoration(),
  dividerHeight: 0,
  tabs: const [
    Tab(text: 'Overview'),
    Tab(text: 'Details'),
  ],
)
```

### Theming

Use `DecoratedTabBarTheme` to apply decoration defaults across a subtree:

```dart
DecoratedTabBarTheme(
  data: DecoratedTabBarThemeData(
    tabDecoration: BoxDecoration(
      color: Colors.blue,
      borderRadius: BorderRadius.circular(8),
    ),
    unselectedTabDecoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
    ),
    tabDecorationMargin: const EdgeInsets.all(4),
  ),
  child: // ...
)
```

## API compatibility

`DecoratedTabBar` accepts **every property** that the standard `TabBar` does — `controller`, `isScrollable`, `indicator`, `indicatorSize`, `labelColor`, `overlayColor`, `physics`, `tabAlignment`, and so on. You can swap `TabBar` → `DecoratedTabBar` without changing any other code.

## License

BSD-3-Clause — same as Flutter.