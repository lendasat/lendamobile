import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/services/settings_controller.dart';
import 'package:ark_flutter/src/services/timezone_service.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_app_bar.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_list_tile.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_scaffold.dart';
import 'package:ark_flutter/src/ui/widgets/utility/search_field_widget.dart';
import 'package:ark_flutter/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timezone/standalone.dart';

class ChangeTimezone extends StatefulWidget {
  const ChangeTimezone({super.key});

  @override
  State<ChangeTimezone> createState() => _ChangeTimezoneState();
}

class _ChangeTimezoneState extends State<ChangeTimezone> {
  @override
  Widget build(BuildContext context) {
    final controller = context.read<SettingsController>();
    return ArkScaffold(
      extendBodyBehindAppBar: true,
      context: context,
      appBar: ArkAppBar(
        text: AppLocalizations.of(context)!.timezone,
        context: context,
        hasBackButton: true,
        onTap: () => controller.switchTab('main'),
      ),
      body: const _TimezonePickerBody(),
    );
  }
}

class _TimezonePickerBody extends StatefulWidget {
  const _TimezonePickerBody();

  @override
  State<_TimezonePickerBody> createState() => _TimezonePickerBodyState();
}

class _TimezonePickerBodyState extends State<_TimezonePickerBody> {
  String _searchText = '';
  bool _isLoading = true;
  late List<Location> _locations;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _locations = timeZoneDatabase.locations.values.toList();
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
        ),
      );
    }

    return ArkScaffold(
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
              _TimezoneList(
                timezones: _locations,
                searchText: _searchText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimezoneList extends StatelessWidget {
  const _TimezoneList({
    required this.timezones,
    required this.searchText,
  });

  final List<Location> timezones;
  final String searchText;

  @override
  Widget build(BuildContext context) {
    final timezoneService = context.watch<TimezoneService>();
    final selectedTimezone = timezoneService.currentTimezone;

    return SizedBox(
      width: double.infinity,
      child: ListView.builder(
        itemCount: timezones.length,
        shrinkWrap: true,
        scrollDirection: Axis.vertical,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (ctx, i) {
          final timezone = timezones[i];

          // Filter by search
          if (searchText.isNotEmpty) {
            final matchesAbbr = timezone.currentTimeZone.abbreviation
                .toLowerCase()
                .startsWith(searchText.toLowerCase());
            final matchesName =
                timezone.name.toLowerCase().startsWith(searchText.toLowerCase());
            if (!matchesAbbr && !matchesName) {
              return const SizedBox.shrink();
            }
          }

          return _TimezoneTile(
            timezone: timezone,
            isSelected: timezone.name == selectedTimezone,
          );
        },
      ),
    );
  }
}

class _TimezoneTile extends StatelessWidget {
  final Location timezone;
  final bool isSelected;

  const _TimezoneTile({
    required this.timezone,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final timezoneService = context.read<TimezoneService>();

    return ArkListTile(
      customTitle: Text(
        _processTimezoneIdentifier(timezone.name),
        style: Theme.of(context).textTheme.titleSmall,
      ),
      subtitle: Text(
        "${_formatDurationOffset(Duration(milliseconds: timezone.currentTimeZone.offset))} ${timezone.currentTimeZone.abbreviation}",
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelMedium,
      ),
      selected: isSelected,
      onTap: () async {
        await timezoneService.setTimezone(timezone.name);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  AppLocalizations.of(context)!.timezoneUpdatedSuccessfully),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
    );
  }

  String _formatDurationOffset(Duration duration) {
    int hours = duration.inHours;
    int minutes = duration.inMinutes.remainder(60);

    String sign = hours >= 0 ? "+" : "-";
    hours = hours.abs();
    minutes = minutes.abs();

    return "$sign${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}";
  }

  String _processTimezoneIdentifier(String timezone) {
    return timezone.replaceAll("/", ", ").replaceAll("_", " ");
  }
}
