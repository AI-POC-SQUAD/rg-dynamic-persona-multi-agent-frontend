import 'package:flutter/material.dart';

/// A custom page route that provides a fade transition animation
/// for all page navigations in the app.
class FadePageRoute<T> extends PageRouteBuilder<T> {
  /// The widget to navigate to
  final Widget child;

  /// The duration of the fade in animation
  final Duration duration;

  /// The duration of the fade out animation when going back
  final Duration reverseDuration;

  FadePageRoute({
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.reverseDuration = const Duration(milliseconds: 200),
    RouteSettings? settings,
  }) : super(
          settings: settings,
          transitionDuration: duration,
          reverseTransitionDuration: reverseDuration,
          pageBuilder: (context, animation, secondaryAnimation) => child,
        );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Fade in animation for the new page
    final fadeInAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOut,
      ),
    );

    // Fade out animation for the old page when going back
    final fadeOutAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: secondaryAnimation,
        curve: Curves.easeInOut,
      ),
    );

    return FadeTransition(
      opacity: animation.status == AnimationStatus.reverse
          ? fadeOutAnimation
          : fadeInAnimation,
      child: child,
    );
  }
}

/// Extension to make it easier to use fade transitions with Navigator
extension FadeNavigation on NavigatorState {
  /// Push a new route with fade transition
  Future<T?> pushWithFade<T extends Object?>(
    Widget page, {
    Duration duration = const Duration(milliseconds: 300),
    Duration reverseDuration = const Duration(milliseconds: 200),
    RouteSettings? settings,
  }) {
    return push<T>(
      FadePageRoute<T>(
        child: page,
        duration: duration,
        reverseDuration: reverseDuration,
        settings: settings,
      ),
    );
  }

  /// Push replacement with fade transition
  Future<T?> pushReplacementWithFade<T extends Object?, TO extends Object?>(
    Widget page, {
    TO? result,
    Duration duration = const Duration(milliseconds: 300),
    Duration reverseDuration = const Duration(milliseconds: 200),
    RouteSettings? settings,
  }) {
    return pushReplacement<T, TO>(
      FadePageRoute<T>(
        child: page,
        duration: duration,
        reverseDuration: reverseDuration,
        settings: settings,
      ),
      result: result,
    );
  }
}

/// Extension to make it easier to use fade transitions with Navigator context
extension FadeNavigationContext on BuildContext {
  /// Push a new route with fade transition
  Future<T?> pushWithFade<T extends Object?>(
    Widget page, {
    Duration duration = const Duration(milliseconds: 300),
    Duration reverseDuration = const Duration(milliseconds: 200),
    RouteSettings? settings,
  }) {
    return Navigator.of(this).pushWithFade<T>(
      page,
      duration: duration,
      reverseDuration: reverseDuration,
      settings: settings,
    );
  }

  /// Push replacement with fade transition
  Future<T?> pushReplacementWithFade<T extends Object?, TO extends Object?>(
    Widget page, {
    TO? result,
    Duration duration = const Duration(milliseconds: 300),
    Duration reverseDuration = const Duration(milliseconds: 200),
    RouteSettings? settings,
  }) {
    return Navigator.of(this).pushReplacementWithFade<T, TO>(
      page,
      result: result,
      duration: duration,
      reverseDuration: reverseDuration,
      settings: settings,
    );
  }
}
