import 'package:ark_flutter/src/providers/theme_provider.dart';
import 'package:ark_flutter/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<T?> arkBottomSheet<T>({
  required BuildContext context,
  double borderRadius = 20.0,
  required Widget child,
  double? height,
  double? width,
  Color backgroundColor = Colors.transparent,
  bool isDismissible = true,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet(
    context: context,
    elevation: 0.0,
    backgroundColor: Colors.transparent,
    isDismissible: isDismissible,
    isScrollControlled: isScrollControlled,
    constraints: BoxConstraints(
      maxHeight: height ?? MediaQuery.of(context).size.height * 0.9,
      maxWidth: width ?? MediaQuery.of(context).size.width,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(borderRadius),
        topRight: Radius.circular(borderRadius),
      ),
    ),
    builder: (context) {
      return Consumer<ThemeProvider>(
        builder: (context, value, chid) => Material(
          color: Colors.transparent,
          child: ArkBottomSheetWidget(
            height: height,
            width: width,
            borderRadius: borderRadius,
            backgroundColor: backgroundColor,
            child: child,
          ),
        ),
      );
    },
  );
}

class ArkBottomSheetWidget extends StatelessWidget {
  const ArkBottomSheetWidget({
    super.key,
    this.height,
    this.width,
    this.borderRadius = 20.0,
    this.backgroundColor = Colors.transparent,
    required this.child,
  });

  final double borderRadius;
  final double? height;
  final double? width;
  final Color backgroundColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: AppTheme.elementSpacing),
        // Drag handle
        Container(
          height: AppTheme.elementSpacing / 1.375,
          width: AppTheme.cardPadding * 2.25,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.grey.shade300
                : Colors.grey.shade700,
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusCircular),
          ),
        ),
        const SizedBox(height: AppTheme.elementSpacing * 0.75),
        Flexible(
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: backgroundColor != Colors.transparent
                  ? backgroundColor
                  : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(borderRadius),
                topRight: Radius.circular(borderRadius),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(borderRadius),
                topRight: Radius.circular(borderRadius),
              ),
              child: child,
            ),
          ),
        ),
      ],
    );
  }
}
