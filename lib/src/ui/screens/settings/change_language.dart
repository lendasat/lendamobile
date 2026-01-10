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
  String _searchText = '';

  @override
  Widget build(BuildContext context) {
    final languageService = context.watch<LanguageService>();
    final selectedLanguage = languageService.currentLocale;
    const languages = LanguageService.languageNames;
    final languageCodes = languages.keys.toList();

    return ArkScaffoldUnsafe(
      context: context,
      resizeToAvoidBottomInset: false,
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.elementSpacing,
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: AppTheme.elementSpacing),
              SearchFieldWidget(
                hintText: AppLocalizations.of(context)!.search,
                isSearchEnabled: true,
                onChanged: (val) {
                  setState(() {
                    _searchText = val;
                  });
                },
                handleSearch: (dynamic) {},
              ),
              _buildLanguageList(languageCodes, languages, selectedLanguage),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageList(
    List<String> languageCodes,
    Map<String, String> languages,
    Locale selectedLanguage,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ListView.builder(
        itemCount: languageCodes.length,
        shrinkWrap: true,
        scrollDirection: Axis.vertical,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final languageCode = languageCodes[index];
          final languageName = languages[languageCode]!;

          if (_searchText.isNotEmpty &&
              !languageName
                  .toLowerCase()
                  .startsWith(_searchText.toLowerCase())) {
            return const SizedBox.shrink();
          }

          return _buildLanguageTile(
            languageCode,
            languageName,
            selectedLanguage,
          );
        },
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
