import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ark_flutter/theme.dart';

/// Widget to display a spinning animation with three bouncing dots
Widget dotProgress(BuildContext context, {Color? color, double? size}) {
  return Center(
    child: SpinKitThreeBounce(
      color: color ?? Theme.of(context).colorScheme.primary,
      size: size ?? 20.0,
    ),
  );
}
