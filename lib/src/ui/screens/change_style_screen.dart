import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:ark_flutter/app_theme.dart';
import '../../../models/app_theme_model.dart';
import '../../../providers/theme_provider.dart';

class ChangeStyleScreen extends StatefulWidget {
  const ChangeStyleScreen({super.key});

  @override
  State<ChangeStyleScreen> createState() => _ChangeStyleScreenState();
}

class _ChangeStyleScreenState extends State<ChangeStyleScreen> {
  late ThemeType _selectedThemeType;
  Color _selectedCustomColor = const Color(0xFF2196F3);

  @override
  void initState() {
    super.initState();
    final themeProvider = context.read<ThemeProvider>();
    _selectedThemeType = themeProvider.currentThemeType;
    if (themeProvider.customColor != null) {
      _selectedCustomColor = themeProvider.customColor!;
    }
  }

  void _applyTheme() {
    final themeProvider = context.read<ThemeProvider>();

    switch (_selectedThemeType) {
      case ThemeType.dark:
        themeProvider.setDarkTheme();
        break;
      case ThemeType.light:
        themeProvider.setLightTheme();
        break;
      case ThemeType.custom:
        themeProvider.setCustomTheme(_selectedCustomColor);
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.themeAppliedSuccessfully),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showColorPicker() async {
    final Color? pickedColor = await showDialog<Color>(
      context: context,
      builder: (BuildContext context) {
        Color tempColor = _selectedCustomColor;

        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.chooseYourColor),
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
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(tempColor),
              child: Text(AppLocalizations.of(context)!.select),
            ),
          ],
        );
      },
    );

    if (pickedColor != null) {
      setState(() {
        _selectedCustomColor = pickedColor;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Scaffold(
      backgroundColor: theme.primaryBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(AppLocalizations.of(context)!.changeYourStyle,
            style: TextStyle(color: theme.primaryWhite)),
        iconTheme: IconThemeData(color: theme.primaryWhite),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.chooseYourPreferredTheme,
                style: TextStyle(color: theme.mutedText)),
            const SizedBox(height: 24),
            _buildThemeOption(
              theme: theme,
              themeType: ThemeType.dark,
              title: AppLocalizations.of(context)!.dark,
              subtitle: AppLocalizations.of(context)!.originalDarkTheme,
            ),
            const SizedBox(height: 16),
            _buildThemeOption(
              theme: theme,
              themeType: ThemeType.light,
              title: AppLocalizations.of(context)!.light,
              subtitle: AppLocalizations.of(context)!.cleanLightTheme,
            ),
            const SizedBox(height: 16),
            _buildCustomThemeOption(theme),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _applyTheme,
                child: Text(AppLocalizations.of(context)!.applyTheme),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required AppTheme theme,
    required ThemeType themeType,
    required String title,
    required String subtitle,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedThemeType = themeType;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.secondaryBlack,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedThemeType == themeType
                ? Colors.amber
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Radio<ThemeType>(
              value: themeType,
              groupValue: _selectedThemeType,
              onChanged: (ThemeType? value) {
                if (value != null) {
                  setState(() {
                    _selectedThemeType = value;
                  });
                }
              },
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                        color: theme.primaryWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.w600),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: theme.mutedText, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomThemeOption(AppTheme theme) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedThemeType = ThemeType.custom;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.secondaryBlack,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedThemeType == ThemeType.custom
                ? Colors.amber
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Radio<ThemeType>(
              value: ThemeType.custom,
              groupValue: _selectedThemeType,
              onChanged: (ThemeType? value) {
                if (value != null) {
                  setState(() {
                    _selectedThemeType = value;
                  });
                }
              },
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.custom,
                    style: TextStyle(
                        color: theme.primaryWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.w600),
                  ),
                  Text(
                    AppLocalizations.of(context)!.createYourOwnTheme,
                    style: TextStyle(color: theme.mutedText, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: _showColorPicker,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _selectedCustomColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.palette, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
