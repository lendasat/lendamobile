import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/services/settings_controller.dart';
import 'package:ark_flutter/src/services/settings_service.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/button_types.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/rounded_button_widget.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_app_bar.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_list_tile.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_scaffold.dart';
import 'package:ark_flutter/theme.dart';
import 'package:flutter/material.dart';
import 'package:linear_progress_bar/linear_progress_bar.dart';
import 'package:provider/provider.dart';

/// Emergency Recovery View - displays recovery options with progress indicator
/// Similar to BitNet's emergency recovery UI pattern
class EmergencyRecoveryView extends StatefulWidget {
  const EmergencyRecoveryView({super.key});

  @override
  State<EmergencyRecoveryView> createState() => _EmergencyRecoveryViewState();
}

class _EmergencyRecoveryViewState extends State<EmergencyRecoveryView> {
  // Recovery status flags
  // Word recovery = user has viewed/backed up their recovery phrase
  bool wordRecoverySet = false;

  @override
  void initState() {
    super.initState();
    _loadRecoveryStatus();
  }

  Future<void> _loadRecoveryStatus() async {
    final isWordSet = await SettingsService().isWordRecoverySet();
    if (mounted) {
      setState(() {
        wordRecoverySet = isWordSet;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<SettingsController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Calculate completed steps (only count word recovery since email is disabled)
    final int completedSteps = wordRecoverySet ? 1 : 0;

    // Total possible recovery options (only 1 now since email is disabled)
    const int totalSteps = 1;

    // Determine progress bar color based on completion
    Color progressColor;
    if (completedSteps >= 1) {
      progressColor = AppTheme.successColor;
    } else {
      progressColor = AppTheme.errorColor;
    }

    return ArkScaffold(
      extendBodyBehindAppBar: true,
      context: context,
      appBar: ArkAppBar(
        text: AppLocalizations.of(context)!.recoveryOptions,
        context: context,
        hasBackButton: true,
        onTap: () => controller.resetToMain(),
      ),
      body: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppTheme.elementSpacing * 0.25,
        ),
        child: ListView(
          children: [
            // Progress Section
            Container(
              margin: const EdgeInsets.symmetric(
                horizontal: AppTheme.cardPadding * 0.5,
                vertical: AppTheme.elementSpacing,
              ),
              padding: const EdgeInsets.all(AppTheme.cardPadding),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.03),
                borderRadius: AppTheme.cardRadiusSmall,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and progress indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.securityStatus,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppTheme.white90 : AppTheme.black90,
                        ),
                      ),
                      Text(
                        '$completedSteps / $totalSteps',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: progressColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.elementSpacing),

                  // Linear Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: LinearProgressBar(
                      maxSteps: totalSteps,
                      progressType: LinearProgressBar.progressTypeLinear,
                      currentStep: completedSteps,
                      progressColor: progressColor,
                      backgroundColor: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.1),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: AppTheme.elementSpacing),

                  // Warning message if not all recovery options are set
                  if (completedSteps < totalSteps)
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: AppTheme.errorColor,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)!.setupRecoveryWarning,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.errorColor,
                            ),
                          ),
                        ),
                      ],
                    ),

                  // Success message if all recovery options are set
                  if (completedSteps == totalSteps)
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: AppTheme.successColor,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)!.recoveryFullySetup,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.successColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.elementSpacing),

            // Section Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.cardPadding * 0.75,
              ),
              child: Text(
                AppLocalizations.of(context)!.recoveryMethods,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.white60 : AppTheme.black60,
                ),
              ),
            ),

            const SizedBox(height: AppTheme.elementSpacing * 0.5),

            // Word Recovery Option
            _buildRecoveryOptionTile(
              context: context,
              icon: Icons.article_rounded,
              title: AppLocalizations.of(context)!.wordRecovery,
              subtitle: AppLocalizations.of(context)!.wordRecoveryDescription,
              isSetUp: wordRecoverySet,
              onTap: () async {
                // Navigate to view recovery key and refresh status on return
                controller.switchTab('recovery');
                // Refresh status after a short delay to allow navigation
                Future.delayed(const Duration(milliseconds: 500), () {
                  _loadRecoveryStatus();
                });
              },
            ),

            // Email Recovery Option (Coming Soon - disabled)
            _buildRecoveryOptionTile(
              context: context,
              icon: Icons.email_rounded,
              title: AppLocalizations.of(context)!.emailRecovery,
              subtitle: AppLocalizations.of(context)!.comingSoon,
              isSetUp: false,
              isDisabled: true,
              onTap: () {
                // Disabled - Coming Soon
              },
            ),

            const SizedBox(height: AppTheme.cardPadding * 2),
          ],
        ),
      ),
    );
  }

  /// Builds a recovery option list tile with status indicator dot
  Widget _buildRecoveryOptionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSetUp,
    required VoidCallback onTap,
    bool isDisabled = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: ArkListTile(
        leading: Stack(
          children: [
            RoundedButtonWidget(
              iconData: icon,
              onTap: isDisabled ? () {} : onTap,
              size: AppTheme.iconSize * 1.5,
              buttonType: ButtonType.transparent,
            ),
            // Status indicator dot
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDisabled
                      ? (isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.3))
                      : (isSetUp ? AppTheme.successColor : AppTheme.errorColor),
                  border: Border.all(
                    color: isDark ? Colors.black : Colors.white,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
        text: title,
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppTheme.white60 : AppTheme.black60,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDisabled
                    ? (isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.1))
                    : (isSetUp
                        ? AppTheme.successColor.withOpacity(0.15)
                        : AppTheme.errorColor.withOpacity(0.15)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isDisabled
                    ? AppLocalizations.of(context)!.comingSoon
                    : (isSetUp
                        ? AppLocalizations.of(context)!.enabled
                        : AppLocalizations.of(context)!.notSetUp),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDisabled
                      ? (isDark ? AppTheme.white60 : AppTheme.black60)
                      : (isSetUp ? AppTheme.successColor : AppTheme.errorColor),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: AppTheme.iconSize * 0.75,
              color: isDark ? AppTheme.white60 : AppTheme.black60,
            ),
          ],
        ),
        onTap: isDisabled ? null : onTap,
      ),
    );
  }

}
