import 'package:ark_flutter/src/services/settings_controller.dart';
import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/services/timezone_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ark_flutter/app_theme.dart';

class ChangeTimezoneScreen extends StatefulWidget {
  const ChangeTimezoneScreen({super.key});

  @override
  State<ChangeTimezoneScreen> createState() => _ChangeTimezoneScreenState();
}

class _ChangeTimezoneScreenState extends State<ChangeTimezoneScreen> {
  String _searchQuery = '';
  String? _selectedTimezone;

  @override
  void initState() {
    super.initState();
    final timezoneService = context.read<TimezoneService>();
    _selectedTimezone = timezoneService.currentTimezone;
  }

  void _applyTimezone() async {
    if (_selectedTimezone == null) return;

    final timezoneService = context.read<TimezoneService>();
    final settingsController = context.read<SettingsController>();
    await timezoneService.setTimezone(_selectedTimezone!);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(AppLocalizations.of(context)!.timezoneUpdatedSuccessfully),
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
    final timezoneService = context.watch<TimezoneService>();
    final allTimezones = TimezoneService.allTimezones;

    final filteredTimezones = _searchQuery.isEmpty
        ? allTimezones
        : allTimezones
            .where(
                (tz) => tz.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

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
          AppLocalizations.of(context)!.changeTimezone,
          style: TextStyle(
            color: theme.primaryWhite,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.searchTimezone,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredTimezones.length,
              itemBuilder: (context, index) {
                final timezone = filteredTimezones[index];
                final displayName =
                    timezoneService.getTimezoneDisplayName(timezone);

                return RadioListTile<String>(
                  title: Text(displayName),
                  subtitle: Text(timezone),
                  value: timezone,
                  groupValue: _selectedTimezone,
                  onChanged: (String? value) {
                    setState(() {
                      _selectedTimezone = value;
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
                onPressed: _applyTimezone,
                child: Text(AppLocalizations.of(context)!.apply),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
