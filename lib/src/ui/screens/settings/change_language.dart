import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/services/language_service.dart';
import 'package:ark_flutter/src/services/overlay_service.dart';
import 'package:ark_flutter/src/services/settings_controller.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/bitnet_app_bar.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_list_tile.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_scaffold.dart';
import 'package:ark_flutter/src/ui/widgets/utility/search_field_widget.dart';
import 'package:ark_flutter/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChangeLanguage extends StatefulWidget {
  const ChangeLanguage({super.key});

  @override
  State<ChangeLanguage> createState() => _ChangeLanguageState();
}

class _ChangeLanguageState extends State<ChangeLanguage> {
  @override
  Widget build(BuildContext context) {
    final controller = context.read<SettingsController>();
    return ArkScaffoldUnsafe(
      context: context,
      appBar: BitNetAppBar(
        text: AppLocalizations.of(context)!.language,
        context: context,
        hasBackButton: true,
        transparent: false,
        onTap: () => controller.switchTab('main'),
      ),
      body: const _LanguagePickerBody(),
    );
  }
}

class _LanguagePickerBody extends StatefulWidget {
  const _LanguagePickerBody();

  @override
  State<_LanguagePickerBody> createState() => _LanguagePickerBodyState();
}

class _LanguagePickerBodyState extends State<_LanguagePickerBody> {
  static const _languages = LanguageService.languageNames;
  late List<String> _allLanguageCodes;
  List<String> _filteredLanguageCodes = [];

  @override
  void initState() {
    super.initState();
    _allLanguageCodes = _languages.keys.toList();
    _filteredLanguageCodes = _allLanguageCodes;
  }

  void _filterLanguages(String searchText) {
    setState(() {
      if (searchText.isEmpty) {
        _filteredLanguageCodes = _allLanguageCodes;
      } else {
        final searchLower = searchText.toLowerCase();
        _filteredLanguageCodes = _allLanguageCodes.where((code) {
          final name = _languages[code]!.toLowerCase();
          return name.contains(searchLower) || code.startsWith(searchLower);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final languageService = context.watch<LanguageService>();
    final selectedLanguage = languageService.currentLocale;

    return ArkScaffoldUnsafe(
      context: context,
      resizeToAvoidBottomInset: false,
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.elementSpacing,
        ),
        child: Column(
          children: [
            const SizedBox(height: AppTheme.elementSpacing),
            // Fixed search bar at top
            SearchFieldWidget(
              hintText: AppLocalizations.of(context)!.search,
              isSearchEnabled: true,
              onChanged: _filterLanguages,
              handleSearch: (dynamic) {},
            ),
            const SizedBox(height: AppTheme.elementSpacing),
            // Scrollable list
            Expanded(
              child: ListView.builder(
                itemCount: _filteredLanguageCodes.length,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  final languageCode = _filteredLanguageCodes[index];
                  final languageName = _languages[languageCode]!;
                  return _buildLanguageTile(
                    languageCode,
                    languageName,
                    selectedLanguage,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageTile(
    String languageCode,
    String languageName,
    Locale selectedLanguage,
  ) {
    final languageService = context.read<LanguageService>();
    final locale = Locale.fromSubtags(languageCode: languageCode);
    final flag = languageService.getLanguageFlag(languageCode);

    return ArkListTile(
      leading: Text(
        flag,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      text: languageName,
      selected: locale.languageCode == selectedLanguage.languageCode,
      onTap: () async {
        await languageService.setLanguage(languageCode);
        if (mounted) {
          OverlayService().showSuccess(
            AppLocalizations.of(context)!.languageUpdatedSuccessfully,
          );
        }
      },
    );
  }
}
