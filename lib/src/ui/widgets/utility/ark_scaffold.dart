import 'package:ark_flutter/theme.dart';
import 'package:flutter/material.dart';

/// Ark scaffold with gradient background support
/// Provides consistent styling across the app with light/dark mode support
class ArkScaffold extends StatelessWidget {
  final Widget body;
  final Color? gradientColor;
  final PreferredSizeWidget? appBar;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? margin;
  final BuildContext context;
  final bool extendBodyBehindAppBar;
  final bool extendBodyBehindBottomNav;
  final Widget? floatingActionButton;
  final bool removeGradientColor;
  final FloatingActionButtonLocation floatingActionButtonLocation;
  final bool resizeToAvoidBottomInset;
  final Widget? bottomSheet;

  const ArkScaffold({
    super.key,
    required this.body,
    required this.context,
    this.margin,
    this.appBar,
    this.backgroundColor,
    this.gradientColor,
    this.extendBodyBehindAppBar = false,
    this.extendBodyBehindBottomNav = false,
    this.removeGradientColor = false,
    this.floatingActionButton,
    this.floatingActionButtonLocation =
        FloatingActionButtonLocation.centerDocked,
    this.resizeToAvoidBottomInset = true,
    this.bottomSheet,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return SafeArea(
      child: Scaffold(
        bottomNavigationBar: bottomSheet,
        backgroundColor: backgroundColor,
        extendBodyBehindAppBar: extendBodyBehindAppBar,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        body: Stack(
          children: [
            // Background container - pure black/white based on theme
            Container(
              width: double.infinity,
              height: double.infinity,
              color: isLight ? Colors.white : Colors.black,
              child: Padding(
                padding: extendBodyBehindBottomNav
                    ? const EdgeInsets.only(bottom: AppTheme.cardPadding * 3)
                    : EdgeInsets.zero,
                child: Container(margin: margin, child: body),
              ),
            ),
            // Gradient fade overlay - shows when extendBodyBehindAppBar is true
            extendBodyBehindAppBar
                ? removeGradientColor
                    ? Container()
                    : Container(
                        width: double.infinity,
                        height: AppTheme.cardPadding * 3,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                            colors: _buildGradientColors(context, isLight),
                          ),
                        ),
                      )
                : Container(),
          ],
        ),
        appBar: appBar,
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.cardPadding),
          child: floatingActionButton,
        ),
        floatingActionButtonLocation: floatingActionButtonLocation,
      ),
    );
  }

  List<Color> _buildGradientColors(BuildContext context, bool isLight) {
    final baseColor = isLight ? Colors.white : Colors.black;

    return [
      baseColor,
      baseColor.withOpacity(0.9),
      baseColor.withOpacity(0.7),
      baseColor.withOpacity(0.4),
      baseColor.withOpacity(0.0),
    ];
  }
}

/// Ark scaffold without SafeArea wrapper
/// Use when you need to control SafeArea yourself
class ArkScaffoldUnsafe extends StatelessWidget {
  final Widget body;
  final Color? gradientColor;
  final PreferredSizeWidget? appBar;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? margin;
  final BuildContext context;
  final bool extendBodyBehindAppBar;
  final bool extendBodyBehindBottomNav;
  final Widget? floatingActionButton;
  final bool removeGradientColor;
  final FloatingActionButtonLocation floatingActionButtonLocation;
  final bool resizeToAvoidBottomInset;
  final Widget? bottomSheet;
  final double? height;

  const ArkScaffoldUnsafe({
    super.key,
    required this.body,
    required this.context,
    this.margin,
    this.appBar,
    this.backgroundColor,
    this.gradientColor,
    this.extendBodyBehindAppBar = false,
    this.extendBodyBehindBottomNav = false,
    this.removeGradientColor = false,
    this.floatingActionButton,
    this.floatingActionButtonLocation =
        FloatingActionButtonLocation.centerDocked,
    this.resizeToAvoidBottomInset = true,
    this.bottomSheet,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      bottomNavigationBar: bottomSheet,
      backgroundColor: backgroundColor,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: Stack(
        children: [
          // Background container - pure black/white based on theme
          Container(
            width: double.infinity,
            height: height ?? double.infinity,
            color: isLight ? Colors.white : Colors.black,
            child: Padding(
              padding: extendBodyBehindBottomNav
                  ? const EdgeInsets.only(bottom: AppTheme.cardPadding * 3)
                  : EdgeInsets.zero,
              child: Container(margin: margin, child: body),
            ),
          ),
          // Gradient fade overlay - shows when extendBodyBehindAppBar is true
          // Includes topPadding to extend into status bar/notch area
          extendBodyBehindAppBar
              ? removeGradientColor
                  ? Container()
                  : Container(
                      width: double.infinity,
                      height: AppTheme.cardPadding * 3 + topPadding,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                          colors: _buildGradientColors(context, isLight),
                        ),
                      ),
                    )
              : Container(),
        ],
      ),
      appBar: appBar,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: AppTheme.cardPadding),
        child: floatingActionButton,
      ),
      floatingActionButtonLocation: floatingActionButtonLocation,
    );
  }

  List<Color> _buildGradientColors(BuildContext context, bool isLight) {
    final baseColor = isLight ? Colors.white : Colors.black;

    return [
      baseColor,
      baseColor.withOpacity(0.9),
      baseColor.withOpacity(0.7),
      baseColor.withOpacity(0.4),
      baseColor.withOpacity(0.0),
    ];
  }
}
