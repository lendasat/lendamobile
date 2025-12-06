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
    final useGradient = gradientColor != null;
    final defaultBgColor = isLight
        ? Theme.of(context).colorScheme.surface
        : Theme.of(context).colorScheme.surface;

    return SafeArea(
      child: Scaffold(
        bottomNavigationBar: bottomSheet,
        backgroundColor: backgroundColor ?? defaultBgColor,
        extendBodyBehindAppBar: extendBodyBehindAppBar,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        body: Stack(
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: useGradient
                  ? BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          isLight
                              ? lighten(
                                  Theme.of(context)
                                      .colorScheme
                                      .primaryContainer,
                                  50,
                                )
                              : darken(
                                  Theme.of(context)
                                      .colorScheme
                                      .primaryContainer,
                                  80,
                                ),
                          isLight
                              ? lighten(
                                  Theme.of(context)
                                      .colorScheme
                                      .tertiaryContainer,
                                  50,
                                )
                              : darken(
                                  Theme.of(context)
                                      .colorScheme
                                      .tertiaryContainer,
                                  80,
                                ),
                        ],
                      ),
                    )
                  : null,
              child: Padding(
                padding: extendBodyBehindBottomNav
                    ? const EdgeInsets.only(bottom: BitNetTheme.cardPadding * 3)
                    : EdgeInsets.zero,
                child: Container(margin: margin, child: body),
              ),
            ),
            if (extendBodyBehindAppBar && !removeGradientColor && useGradient)
              Container(
                width: double.infinity,
                height: BitNetTheme.cardPadding * 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                    colors: _buildGradientColors(context, isLight),
                  ),
                ),
              ),
          ],
        ),
        appBar: appBar,
        floatingActionButton: floatingActionButton != null
            ? Padding(
                padding: const EdgeInsets.only(bottom: BitNetTheme.cardPadding),
                child: floatingActionButton,
              )
            : null,
        floatingActionButtonLocation: floatingActionButtonLocation,
      ),
    );
  }

  List<Color> _buildGradientColors(BuildContext context, bool isLight) {
    final baseColor = isLight
        ? lighten(Theme.of(context).colorScheme.primaryContainer, 50)
        : darken(Theme.of(context).colorScheme.primaryContainer, 80);

    return [
      baseColor,
      baseColor.withValues(alpha: 0.9),
      baseColor.withValues(alpha: 0.7),
      baseColor.withValues(alpha: 0.4),
      baseColor.withValues(alpha: 0.0001),
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
    final useGradient = gradientColor != null;
    final defaultBgColor =
        isLight ? BitNetTheme.colorBackground : BitNetTheme.colorBackground;

    return Scaffold(
      bottomNavigationBar: bottomSheet,
      backgroundColor: backgroundColor ?? defaultBgColor,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: height ?? double.infinity,
            decoration: useGradient
                ? BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        isLight
                            ? lighten(
                                Theme.of(context).colorScheme.primaryContainer,
                                50,
                              )
                            : darken(
                                Theme.of(context).colorScheme.primaryContainer,
                                80,
                              ),
                        isLight
                            ? lighten(
                                Theme.of(context).colorScheme.tertiaryContainer,
                                50,
                              )
                            : darken(
                                Theme.of(context).colorScheme.tertiaryContainer,
                                80,
                              ),
                      ],
                    ),
                  )
                : null,
            child: Padding(
              padding: extendBodyBehindBottomNav
                  ? const EdgeInsets.only(bottom: BitNetTheme.cardPadding * 3)
                  : EdgeInsets.zero,
              child: Container(margin: margin, child: body),
            ),
          ),
          if (extendBodyBehindAppBar && !removeGradientColor && useGradient)
            Container(
              width: double.infinity,
              height: BitNetTheme.cardPadding * 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                  colors: _buildGradientColors(context, isLight),
                ),
              ),
            ),
        ],
      ),
      appBar: appBar,
      floatingActionButton: floatingActionButton != null
          ? Padding(
              padding: const EdgeInsets.only(bottom: BitNetTheme.cardPadding),
              child: floatingActionButton,
            )
          : null,
      floatingActionButtonLocation: floatingActionButtonLocation,
    );
  }

  List<Color> _buildGradientColors(BuildContext context, bool isLight) {
    final baseColor = isLight
        ? lighten(Theme.of(context).colorScheme.primaryContainer, 50)
        : darken(Theme.of(context).colorScheme.primaryContainer, 80);

    return [
      baseColor,
      baseColor.withValues(alpha: 0.9),
      baseColor.withValues(alpha: 0.7),
      baseColor.withValues(alpha: 0.4),
      baseColor.withValues(alpha: 0.0001),
    ];
  }
}
