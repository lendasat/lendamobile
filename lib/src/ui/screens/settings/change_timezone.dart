import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/services/overlay_service.dart';
import 'package:ark_flutter/src/ui/widgets/loaders/loaders.dart';
import 'package:ark_flutter/src/services/settings_controller.dart';
import 'package:ark_flutter/src/services/timezone_service.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/bitnet_app_bar.dart';
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
    return ArkScaffoldUnsafe(
      context: context,
      appBar: BitNetAppBar(
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
  late List<Location> _allLocations;
  List<Location> _filteredLocations = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final locations = timeZoneDatabase.locations.values.toList();
      // Sort alphabetically by name
      locations.sort((a, b) => a.name.compareTo(b.name));
      setState(() {
        _allLocations = locations;
        _filteredLocations = locations;
        _isLoading = false;
      });
    });
  }

  void _filterTimezones(String searchText) {
    setState(() {
      _searchText = searchText;
      if (searchText.isEmpty) {
        _filteredLocations = _allLocations;
      } else {
        final searchLower = searchText.toLowerCase();
        _filteredLocations = _allLocations.where((tz) {
          final matchesAbbr = tz.currentTimeZone.abbreviation
              .toLowerCase()
              .startsWith(searchLower);
          final matchesName = tz.name.toLowerCase().contains(searchLower);
          return matchesAbbr || matchesName;
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return dotProgress(context);
    }

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
            SearchFieldWidget(
              hintText: AppLocalizations.of(context)!.search,
              isSearchEnabled: true,
              onChanged: _filterTimezones,
              handleSearch: (dynamic) {},
            ),
            const SizedBox(height: AppTheme.elementSpacing),
            Expanded(
              child: _TimezoneList(
                timezones: _filteredLocations,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimezoneList extends StatelessWidget {
  const _TimezoneList({
    required this.timezones,
  });

  final List<Location> timezones;

  @override
  Widget build(BuildContext context) {
    final timezoneService = context.watch<TimezoneService>();
    final selectedTimezone = timezoneService.currentTimezone;

    return ListView.builder(
      itemCount: timezones.length,
      // No shrinkWrap - let the Expanded parent handle sizing
      // This enables proper virtualization (only visible items are built)
      physics: const BouncingScrollPhysics(),
      itemBuilder: (ctx, i) {
        final timezone = timezones[i];
        return _TimezoneTile(
          timezone: timezone,
          isSelected: timezone.name == selectedTimezone,
        );
      },
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
          OverlayService().showSuccess(
            AppLocalizations.of(context)!.timezoneUpdatedSuccessfully,
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
