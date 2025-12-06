import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/models/app_theme_model.dart';
import 'package:ark_flutter/src/providers/theme_provider.dart';
import 'package:ark_flutter/src/services/settings_controller.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_app_bar.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_scaffold.dart';
import 'package:ark_flutter/theme.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsStyleView extends StatefulWidget {
  const SettingsStyleView({super.key});

  @override
  State<SettingsStyleView> createState() => _SettingsStyleViewState();
}

class _SettingsStyleViewState extends State<SettingsStyleView> {
  ThemeMode _selectedThemeMode = ThemeMode.dark;
  Color _selectedCustomColor = const Color(0xFF2196F3);

  // Preset colors matching original BitNet
  final List<Color?> _customColors = [
    Colors.white, // System theme indicator
    const Color(0xFFF7931A), // Bitcoin orange
    Colors.blue,
    Colors.purple,
    Colors.green,
    Colors.red,
    Colors.pink,
    Colors.teal,
    null, // Custom color picker
  ];

  @override
  void initState() {
    super.initState();
    final themeProvider = context.read<ThemeProvider>();
    // Set initial theme mode based on current theme type
    switch (themeProvider.currentThemeType) {
      case ThemeType.light:
        _selectedThemeMode = ThemeMode.light;
        break;
      case ThemeType.dark:
      case ThemeType.custom:
        _selectedThemeMode = ThemeMode.dark;
        break;
    }
    if (themeProvider.customColor != null) {
      _selectedCustomColor = themeProvider.customColor!;
    }
  }

  void _setColor(Color? color) {
    if (color == null) {
      // Show color picker
      _showColorPicker();
    } else if (color == Colors.white) {
      // System theme - no custom color
      final themeProvider = context.read<ThemeProvider>();
      themeProvider.setDarkTheme(); // Default to dark
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.themeAppliedSuccessfully),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      // Set custom color
      final themeProvider = context.read<ThemeProvider>();
      themeProvider.setCustomTheme(color);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.themeAppliedSuccessfully),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _showColorPicker() async {
    final Color? pickedColor = await showDialog<Color>(
      context: context,
      builder: (BuildContext context) {
        Color tempColor = _selectedCustomColor;

        return AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? BitNetTheme.black90
              : Colors.white,
          title: Text(
            AppLocalizations.of(context)!.chooseYourColor,
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? BitNetTheme.white90
                  : BitNetTheme.black90,
            ),
          ),
          content: SingleChildScrollView(
            child: ColorPicker(
              color: tempColor,
              onColorChanged: (Color color) {
                tempColor = color;
              },
              width: 40,
              height: 40,
              borderRadius: 8,
              heading: Text(AppLocalizations.of(context)!.selectColor),
              subheading: Text(AppLocalizations.of(context)!.selectColorShade),
              pickersEnabled: const <ColorPickerType, bool>{
                ColorPickerType.both: false,
                ColorPickerType.primary: true,
                ColorPickerType.accent: false,
                ColorPickerType.bw: false,
                ColorPickerType.custom: false,
                ColorPickerType.wheel: true,
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                AppLocalizations.of(context)!.cancel,
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? BitNetTheme.white60
                      : BitNetTheme.black60,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(tempColor),
              child: Text(
                AppLocalizations.of(context)!.select,
                style: const TextStyle(color: Colors.amber),
              ),
            ),
          ],
        );
      },
    );

    if (pickedColor != null) {
      setState(() {
        _selectedCustomColor = pickedColor;
      });
      _setColor(pickedColor);
    }
  }

  void _switchTheme(ThemeMode themeMode) {
    final themeProvider = context.read<ThemeProvider>();

    switch (themeMode) {
      case ThemeMode.dark:
        themeProvider.setDarkTheme();
        break;
      case ThemeMode.light:
        themeProvider.setLightTheme();
        break;
      case ThemeMode.system:
        // For system, we default to dark but could detect system preference
        themeProvider.setDarkTheme();
        break;
    }

    setState(() {
      _selectedThemeMode = themeMode;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.themeAppliedSuccessfully),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<SettingsController>();
    const colorPickerSize = BitNetTheme.cardPadding * 1.5;

    return ArkScaffold(
      extendBodyBehindAppBar: true,
      context: context,
      appBar: ArkAppBar(
        text: AppLocalizations.of(context)!.theme,
        context: context,
        hasBackButton: true,
        onTap: () => controller.switchTab('main'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: BitNetTheme.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: BitNetTheme.cardPadding * 3),
              Text(
                "Color",
                textAlign: TextAlign.start,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: BitNetTheme.elementSpacing),
              SizedBox(
                height: colorPickerSize + 24,
                child: ListView(
                  shrinkWrap: true,
                  scrollDirection: Axis.horizontal,
                  children: _customColors
                      .map(
                        (color) => Padding(
                          padding: const EdgeInsets.all(
                            BitNetTheme.elementSpacing,
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(colorPickerSize),
                            onTap: () => _setColor(color),
                            child: color == null
                                ? _buildColorPickerButton(colorPickerSize)
                                : color == Colors.white
                                    ? _buildSystemThemeCircle(colorPickerSize)
                                    : _buildColorCircle(color, colorPickerSize),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: BitNetTheme.cardPadding),
              Text(
                "System Theme",
                textAlign: TextAlign.start,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: BitNetTheme.elementSpacing),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildThemeOption(
                    label: "System",
                    icon: Icons.settings_suggest,
                    isActive: _selectedThemeMode == ThemeMode.system,
                    onTap: () => _switchTheme(ThemeMode.system),
                  ),
                  const SizedBox(width: BitNetTheme.cardPadding),
                  _buildThemeOption(
                    label: AppLocalizations.of(context)!.light,
                    icon: Icons.light_mode,
                    isActive: _selectedThemeMode == ThemeMode.light,
                    onTap: () => _switchTheme(ThemeMode.light),
                  ),
                  const SizedBox(width: BitNetTheme.cardPadding),
                  _buildThemeOption(
                    label: AppLocalizations.of(context)!.dark,
                    icon: Icons.dark_mode,
                    isActive: _selectedThemeMode == ThemeMode.dark,
                    onTap: () => _switchTheme(ThemeMode.dark),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorPickerButton(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size),
        gradient: const SweepGradient(
          colors: [
            Colors.red,
            Colors.orange,
            Colors.yellow,
            Colors.green,
            Colors.blue,
            Colors.purple,
            Colors.red,
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.colorize,
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }

  Widget _buildSystemThemeCircle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size),
      ),
      child: CustomPaint(
        painter: _CirclePainter(),
      ),
    );
  }

  Widget _buildColorCircle(Color color, double size) {
    final themeProvider = context.watch<ThemeProvider>();
    final isSelected = themeProvider.customColor == color;

    return Material(
      color: color,
      elevation: 6,
      borderRadius: BorderRadius.circular(size),
      child: SizedBox(
        width: size,
        height: size,
        child: isSelected
            ? const Center(
                child: Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildThemeOption({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: BitNetTheme.cardPadding * 4,
        height: BitNetTheme.cardPadding * 5.25,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? BitNetTheme.black60.withValues(alpha: 0.3)
              : BitNetTheme.white90,
          borderRadius: BorderRadius.circular(BitNetTheme.cardPadding),
          border: Border.all(
            color: isActive ? Colors.amber : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: isActive
                  ? Colors.amber
                  : Theme.of(context).brightness == Brightness.dark
                      ? BitNetTheme.white60
                      : BitNetTheme.black60,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: isActive
                    ? Colors.amber
                    : Theme.of(context).brightness == Brightness.dark
                        ? BitNetTheme.white60
                        : BitNetTheme.black60,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset center = Offset(radius, radius);

    final Paint paint = Paint();

    // Draw white slice
    paint.color = Colors.white;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      2 * 3.14 / 3,
      true,
      paint,
    );

    // Draw black slice
    paint.color = Colors.black;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      2 * 3.14 / 3,
      2 * 3.14 / 3,
      true,
      paint,
    );

    // Draw bitcoin orange slice
    paint.color = BitNetTheme.colorBitcoin;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      4 * 3.14 / 3,
      2 * 3.14 / 3,
      true,
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
