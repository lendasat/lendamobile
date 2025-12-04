import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/services/language_service.dart';
import 'package:ark_flutter/src/services/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ark_flutter/app_theme.dart';

class ChangeLanguageScreen extends StatefulWidget {
  const ChangeLanguageScreen({super.key});

  @override
  State<ChangeLanguageScreen> createState() => _ChangeLanguageScreenState();
}

class _ChangeLanguageScreenState extends State<ChangeLanguageScreen> {
  String? _selectedLanguageCode;

  @override
  void initState() {
    super.initState();
    final languageService = context.read<LanguageService>();
    _selectedLanguageCode = languageService.currentLocale.languageCode;
  }

  void _applyLanguage() async {
    if (_selectedLanguageCode == null) return;

    final languageService = context.read<LanguageService>();
    final settingsController = context.read<SettingsController>();
    await languageService.setLanguage(_selectedLanguageCode!);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(AppLocalizations.of(context)!.languageUpdatedSuccessfully),
          duration: const Duration(seconds: 2),
        ),
      );
      settingsController.resetToMain();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final settingsController = context.read<SettingsController>();
    final languageService = context.watch<LanguageService>();
    const languages = LanguageService.languageNames;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.primaryWhite),
          onPressed: () => settingsController.resetToMain(),
        ),
        title: Text(
          AppLocalizations.of(context)!.changeLanguage,
          style: TextStyle(
            color: theme.primaryWhite,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: languages.length,
              itemBuilder: (context, index) {
                final languageCode = languages.keys.elementAt(index);
                final languageName = languages[languageCode]!;
                final flag = languageService.getLanguageFlag(languageCode);

                return RadioListTile<String>(
                  title: Text('$flag $languageName'),
                  value: languageCode,
                  groupValue: _selectedLanguageCode,
                  onChanged: (String? value) {
                    setState(() {
                      _selectedLanguageCode = value;
                    });
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _applyLanguage,
                child: Text(AppLocalizations.of(context)!.apply),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
