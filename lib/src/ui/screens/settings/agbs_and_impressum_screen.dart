import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/services/settings_controller.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/bitnet_app_bar.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_scaffold.dart';
import 'package:ark_flutter/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AgbsAndImpressumScreen extends StatefulWidget {
  const AgbsAndImpressumScreen({super.key, this.onBackButton});

  /// Optional callback for back button. If null, uses Navigator.pop() when
  /// opened standalone, or SettingsController.resetToMain() when opened from settings.
  final VoidCallback? onBackButton;

  @override
  State<AgbsAndImpressumScreen> createState() => _AgbsAndImpressumScreenState();
}

class _AgbsAndImpressumScreenState extends State<AgbsAndImpressumScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleBack() {
    if (widget.onBackButton != null) {
      widget.onBackButton!();
    } else {
      // Check if we have a SettingsController available (opened from settings)
      try {
        final controller = context.read<SettingsController>();
        controller.resetToMain();
      } catch (_) {
        // No SettingsController, just pop (opened standalone e.g. from onboarding)
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ArkScaffold(
      context: context,
      appBar: BitNetAppBar(
        text: AppLocalizations.of(context)!.legalInformation,
        context: context,
        onTap: _handleBack,
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            _buildAGBSection(context),
            const SizedBox(height: AppTheme.cardPadding * 2),
            _buildImpressumSection(context),
            const SizedBox(height: AppTheme.cardPadding * 2),
          ],
        ),
      ),
    );
  }

  Widget _buildAGBSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.cardPadding),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  AppTheme.colorPrimaryGradient.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: AppTheme.cardRadiusBig,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.termsAndConditionsTitle1,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                Text(
                  AppLocalizations.of(context)!.termsAndConditionsTitle2,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                ),
                const SizedBox(height: AppTheme.elementSpacing),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    borderRadius: AppTheme.cardRadiusSmall,
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.lastUpdated,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.cardPadding),

          // Warning Card
          Container(
            padding: const EdgeInsets.all(AppTheme.cardPaddingSmall),
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withOpacity(0.1),
              borderRadius: AppTheme.cardRadiusMid,
              boxShadow: [AppTheme.boxShadowSuperSmall],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: AppTheme.errorColor,
                  size: 24,
                ),
                const SizedBox(width: AppTheme.elementSpacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.alphaVersion,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppTheme.errorColor,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      Text(
                        AppLocalizations.of(context)!.alphaVersionWarning,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.errorColor,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.cardPadding),

          // Content Sections
          _buildSection(
            context,
            icon: Icons.check_circle_outline,
            title: AppLocalizations.of(context)!.agbScopeTitle,
            content: AppLocalizations.of(context)!.agbScopeContent,
          ),
          _buildSection(
            context,
            icon: Icons.account_balance_wallet_outlined,
            title: AppLocalizations.of(context)!.agbFunctionalityTitle,
            content: AppLocalizations.of(context)!.agbFunctionalityContent,
          ),
          _buildSection(
            context,
            icon: Icons.security_outlined,
            title: AppLocalizations.of(context)!.agbUserResponsibilityTitle,
            content: AppLocalizations.of(context)!.agbUserResponsibilityContent,
          ),
          _buildSection(
            context,
            icon: Icons.payment_outlined,
            title: AppLocalizations.of(context)!.agbFeesTitle,
            content: AppLocalizations.of(context)!.agbFeesContent,
          ),
          _buildSection(
            context,
            icon: Icons.gavel_outlined,
            title: AppLocalizations.of(context)!.agbLiabilityTitle,
            content: AppLocalizations.of(context)!.agbLiabilityContent,
          ),
          _buildSection(
            context,
            icon: Icons.update_outlined,
            title: AppLocalizations.of(context)!.agbChangesTitle,
            content: AppLocalizations.of(context)!.agbChangesContent,
          ),
          _buildSection(
            context,
            icon: Icons.article_outlined,
            title: AppLocalizations.of(context)!.agbFinalProvisionsTitle,
            content: AppLocalizations.of(context)!.agbFinalProvisionsContent,
          ),
        ],
      ),
    );
  }

  Widget _buildImpressumSection(BuildContext context) {
    return Column(
      children: [
        // Section divider
        Container(
          margin: const EdgeInsets.symmetric(horizontal: AppTheme.cardPadding),
          height: 1,
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        ),
        const SizedBox(height: AppTheme.cardPadding * 2),
        Padding(
          padding: const EdgeInsets.all(AppTheme.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                // Contact Cards
              _buildContactCard(
                context,
                icon: Icons.location_on_outlined,
                title: AppLocalizations.of(context)!.address,
                content: const [
                  "COBLOX PTY LTD",
                  "ABN 86 624 756 467",
                  "NSW 2487",
                  "Australia",
                ],
              ),
              _buildContactCard(
                context,
                icon: Icons.contact_phone_outlined,
                title: AppLocalizations.of(context)!.contact,
                content: const [
                  "+61 492 921 166",
                  "contact@lendasat.com",
                ],
              ),
              _buildContactCard(
                context,
                icon: Icons.business_outlined,
                title: AppLocalizations.of(context)!.responsibleForContent,
                content: const [
                  "COBLOX PTY LTD",
                  "Australian Private Company",
                ],
              ),

              // Legal Notice
              const SizedBox(height: AppTheme.cardPadding),
              Container(
                padding: const EdgeInsets.all(AppTheme.cardPaddingSmall),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: AppTheme.cardRadiusMid,
                  boxShadow: [AppTheme.boxShadowSuperSmall],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.disclaimer,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.elementSpacing),
                    Text(
                      AppLocalizations.of(context)!.disclaimerContent,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.color
                                ?.withOpacity(0.8),
                          ),
                    ),
                  ],
                ),
              ),

              // Footer
              const SizedBox(height: AppTheme.cardPadding * 2),
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.copyright,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "\u00a9 ${DateTime.now().year} COBLOX PTY LTD",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      AppLocalizations.of(context)!.allRightsReserved,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.color
                                ?.withOpacity(0.6),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.cardPaddingSmall),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppTheme.cardRadiusMid,
        boxShadow: [AppTheme.boxShadowSuperSmall],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.cardPaddingSmall),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: AppTheme.cardRadiusSmall,
                  ),
                  child: Icon(
                    icon,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppTheme.elementSpacing),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.elementSpacing),
            Text(
              content,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    height: 1.5,
                    color: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.color
                        ?.withOpacity(0.8),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required List<String> content,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.cardPaddingSmall),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppTheme.cardRadiusMid,
        boxShadow: [AppTheme.boxShadowSuperSmall],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.cardPaddingSmall),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    AppTheme.colorPrimaryGradient,
                  ],
                ),
                borderRadius: AppTheme.cardRadiusSmall,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: AppTheme.elementSpacing),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.color
                              ?.withOpacity(0.6),
                        ),
                  ),
                  const SizedBox(height: 4),
                  ...content.map((line) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          line,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
