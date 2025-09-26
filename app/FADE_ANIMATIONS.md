# Fade Animation Usage Guide

This project uses custom fade animations for all page transitions. Here's how to use them:

## Basic Usage

### Push with Fade
```dart
// Instead of:
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => NewPage()),
);

// Use:
context.pushWithFade(NewPage());
```

### Push Replacement with Fade
```dart
// Instead of:
Navigator.pushReplacement(
  context,
  MaterialPageRoute(builder: (context) => NewPage()),
);

// Use:
context.pushReplacementWithFade(NewPage());
```

## Customizing Animation Duration

```dart
// Custom fade duration
context.pushWithFade(
  NewPage(),
  duration: Duration(milliseconds: 500),        // Fade in duration
  reverseDuration: Duration(milliseconds: 300), // Fade out duration when going back
);
```

## With Route Settings

```dart
context.pushWithFade(
  NewPage(),
  settings: RouteSettings(name: '/new-page'),
);
```

## Direct Route Usage

If you need more control, you can use the FadePageRoute directly:

```dart
Navigator.push(
  context,
  FadePageRoute(
    child: NewPage(),
    duration: Duration(milliseconds: 400),
    settings: RouteSettings(name: '/new-page'),
  ),
);
```

## Animation Details

- **Default fade in duration**: 300ms
- **Default fade out duration**: 200ms
- **Animation curve**: Curves.easeInOut
- **Works for both**: Forward navigation and back navigation
- **Smooth transitions**: Optimized for both mobile and web

## Benefits

1. **Consistent UX**: All pages have the same smooth fade transition
2. **Performance**: Lightweight animation that works well on all devices
3. **Customizable**: Easy to adjust timing and curves if needed
4. **Clean code**: Simple API that's easy to use and maintain

## Updated Files

The following files have been updated to use fade animations:
- `home_page.dart`
- `selection_page.dart`
- `persona_selection_page.dart`
- `focus_persona_selection_page.dart`

All new pages should use the fade animation utilities for consistency.