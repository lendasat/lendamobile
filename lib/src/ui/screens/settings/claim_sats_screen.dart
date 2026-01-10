import 'dart:convert';
import 'dart:math';

import 'package:ark_flutter/src/logger/logger.dart';
import 'package:ark_flutter/src/services/overlay_service.dart';
import 'package:ark_flutter/src/services/settings_controller.dart';
import 'package:ark_flutter/src/services/settings_service.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/button_types.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/long_button_widget.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/bitnet_app_bar.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_scaffold.dart';
import 'package:ark_flutter/theme.dart';
import 'package:cloudflare_turnstile/cloudflare_turnstile.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class ClaimSatsScreen extends StatefulWidget {
  const ClaimSatsScreen({super.key});

  @override
  State<ClaimSatsScreen> createState() => _ClaimSatsScreenState();
}

class _ClaimSatsScreenState extends State<ClaimSatsScreen> {
  final SettingsService _settingsService = SettingsService();

  String? _userEmail;
  String? _deviceId;
  bool _isLoading = true;
  bool _hasAlreadyClaimed = false;

  // Eligibility state
  bool _isEligible = false;
  bool _isCheckingEligibility = true;
  String? _eligibilityError;

  // Turnstile state
  String? _turnstileToken;
  bool _turnstileCompleted = false;

  // Turnstile config from environment (injected via --dart-define)
  static const String _siteKey = String.fromEnvironment('TURNSTILE_SITE_KEY');
  static const String _baseUrl = String.fromEnvironment('TURNSTILE_BASE_URL');

  // Waitlist API base URL
  static const String _waitlistApiUrl = 'https://waitinglist.lendasat.com';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      // Get user email
      final email = await _settingsService.getUserEmail();

      // Get device ID
      final deviceInfo = DeviceInfoPlugin();
      String deviceId = 'unknown';

      try {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
      } catch (_) {
        try {
          final iosInfo = await deviceInfo.iosInfo;
          deviceId = iosInfo.identifierForVendor ?? 'unknown-ios';
        } catch (_) {
          // Fallback for other platforms
          deviceId = 'unknown-platform';
        }
      }

      // Check if device has already claimed
      final prefs = await SharedPreferences.getInstance();
      final claimedDevices = prefs.getStringList('claimed_device_ids') ?? [];
      final hasClaimed = claimedDevices.contains(deviceId);

      if (mounted) {
        setState(() {
          _userEmail = email;
          _deviceId = deviceId;
          _hasAlreadyClaimed = hasClaimed;
          _isLoading = false;
        });
      }

      // Check eligibility from waitlist
      if (email != null && email.isNotEmpty) {
        await _checkWaitlistEligibility(email);
      } else {
        if (mounted) {
          setState(() {
            _isCheckingEligibility = false;
            _isEligible = false;
            _eligibilityError = 'No email found. Please sign up first.';
          });
        }
      }
    } catch (e) {
      logger.e('Error loading user data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isCheckingEligibility = false;
        });
      }
    }
  }

  Future<void> _checkWaitlistEligibility(String email) async {
    try {
      logger.i('Checking waitlist eligibility for: $email');

      final response = await http.post(
        Uri.parse('$_waitlistApiUrl/check-waitlist'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final isOnWaitlist = data['isOnWaitlist'] == true;

        logger.i('Waitlist check result: isOnWaitlist=$isOnWaitlist');

        if (mounted) {
          setState(() {
            _isEligible = isOnWaitlist;
            _isCheckingEligibility = false;
          });
        }
      } else {
        logger.e('Waitlist check failed: ${response.statusCode}');
        if (mounted) {
          setState(() {
            _isCheckingEligibility = false;
            _isEligible = false;
            _eligibilityError =
                'Could not verify eligibility. Please try again.';
          });
        }
      }
    } catch (e) {
      logger.e('Error checking waitlist eligibility: $e');
      if (mounted) {
        setState(() {
          _isCheckingEligibility = false;
          _isEligible = false;
          _eligibilityError = 'Network error. Please check your connection.';
        });
      }
    }
  }

  Future<void> _openTwitter() async {
    final uri = Uri.parse('https://x.com/lendasat');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _onTurnstileToken(String token) {
    logger.i('Turnstile token received');
    setState(() {
      _turnstileToken = token;
      _turnstileCompleted = true;
    });
  }

  Future<void> _claimSats() async {
    if (!_turnstileCompleted || _hasAlreadyClaimed || _turnstileToken == null) {
      return;
    }

    // TODO: Send _turnstileToken to backend for server-side verification
    // The backend should verify the token with Cloudflare's API:
    // POST https://challenges.cloudflare.com/turnstile/v0/siteverify
    // with secret key and token

    // Mark device as claimed
    final prefs = await SharedPreferences.getInstance();
    final claimedDevices = prefs.getStringList('claimed_device_ids') ?? [];
    claimedDevices.add(_deviceId!);
    await prefs.setStringList('claimed_device_ids', claimedDevices);

    setState(() {
      _hasAlreadyClaimed = true;
    });

    if (mounted) {
      OverlayService()
          .showSuccess('Claim submitted! 500 sats will be added soon.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<SettingsController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ArkScaffoldUnsafe(
      extendBodyBehindAppBar: true,
      context: context,
      appBar: BitNetAppBar(
        text: 'Claim 500 SATS',
        context: context,
        onTap: () => controller.resetToMain(),
      ),
      body: _isLoading || _isCheckingEligibility
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppTheme.cardPadding * 2),

                  // Show different UI based on eligibility
                  if (!_isEligible) ...[
                    // NOT ELIGIBLE UI
                    _buildNotEligibleUI(isDark),
                  ] else ...[
                    // ELIGIBLE UI (existing flow)
                    // Gift Icon
                    const Icon(
                      Icons.card_giftcard_rounded,
                      size: 80,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: AppTheme.cardPadding),

                    // Title
                    Text(
                      'You are eligible for a gift!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.white90 : AppTheme.black90,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.elementSpacing),

                    // Already claimed message
                    if (_hasAlreadyClaimed) ...[
                      Container(
                        padding: const EdgeInsets.all(AppTheme.cardPadding),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Colors.orange,
                              size: 48,
                            ),
                            const SizedBox(height: AppTheme.elementSpacing),
                            Text(
                              'You have already claimed your gift on this device.',
                              style: TextStyle(
                                fontSize: 16,
                                color: isDark
                                    ? AppTheme.white90
                                    : AppTheme.black90,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Cloudflare Turnstile Verification
                      Text(
                        'Complete verification to claim:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppTheme.white90 : AppTheme.black90,
                        ),
                      ),
                      const SizedBox(height: AppTheme.cardPadding),

                      // Turnstile Widget
                      _buildTurnstileCard(isDark),

                      const SizedBox(height: AppTheme.cardPadding * 1.5),

                      // Claim Button
                      SizedBox(
                        width: double.infinity,
                        child: LongButtonWidget(
                          title: 'Claim 500 sats',
                          onTap: _turnstileCompleted ? _claimSats : null,
                          buttonType: _turnstileCompleted
                              ? ButtonType.primary
                              : ButtonType.disabled,
                          backgroundColor:
                              _turnstileCompleted ? Colors.orange : null,
                          customWidth: double.infinity,
                        ),
                      ),

                      if (!_turnstileCompleted)
                        Padding(
                          padding: const EdgeInsets.only(
                              top: AppTheme.elementSpacing),
                          child: Text(
                            'Complete the verification above to claim',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.4)
                                  : Colors.black.withValues(alpha: 0.4),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],

                    const SizedBox(height: AppTheme.cardPadding * 2),

                    // Device ID (for transparency)
                    if (_deviceId != null)
                      Text(
                        'Device ID: ${_deviceId!.substring(0, min(12, _deviceId!.length))}...',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.2)
                              : Colors.black.withValues(alpha: 0.2),
                        ),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildTurnstileCard(bool isDark) {
    // Check if Turnstile is configured
    if (_siteKey.isEmpty || _siteKey.startsWith('0x4XXXX')) {
      return Container(
        padding: const EdgeInsets.all(AppTheme.cardPadding),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red),
        ),
        child: Column(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Colors.red, size: 32),
            const SizedBox(height: AppTheme.elementSpacing),
            Text(
              'Turnstile not configured',
              style: TextStyle(
                color: isDark ? AppTheme.white90 : AppTheme.black90,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Please add TURNSTILE_SITE_KEY to .env',
              style: TextStyle(
                color: isDark ? AppTheme.white60 : AppTheme.black60,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppTheme.cardPadding),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _turnstileCompleted
              ? Colors.green
              : (isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.1)),
          width: _turnstileCompleted ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _turnstileCompleted ? Colors.green : Colors.orange,
                ),
                child: Center(
                  child: _turnstileCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : const Icon(Icons.shield_outlined,
                          color: Colors.white, size: 16),
                ),
              ),
              const SizedBox(width: AppTheme.elementSpacing),
              Text(
                _turnstileCompleted
                    ? 'Verification complete'
                    : 'Verify you\'re human',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.white90 : AppTheme.black90,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.cardPadding),
          if (!_turnstileCompleted)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CloudFlareTurnstile(
                siteKey: _siteKey,
                mode: TurnstileMode.managed,
                baseUrl: _baseUrl,
                options: TurnstileOptions(
                  size: TurnstileSize.normal,
                  theme: isDark ? TurnstileTheme.dark : TurnstileTheme.light,
                  language: 'auto',
                  refreshExpired: TurnstileRefreshExpired.auto,
                ),
                onTokenRecived: _onTurnstileToken,
                errorBuilder: (context, error) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Error: ${error.message}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                },
              ),
            )
          else
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified_user, color: Colors.green, size: 24),
                SizedBox(width: 8),
                Text(
                  'Verified!',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildNotEligibleUI(bool isDark) {
    return Column(
      children: [
        // Sad/Info Icon
        Icon(
          Icons.sentiment_dissatisfied_rounded,
          size: 80,
          color: isDark ? AppTheme.white60 : AppTheme.black60,
        ),
        const SizedBox(height: AppTheme.cardPadding),

        // Title
        Text(
          'Not Eligible',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? AppTheme.white90 : AppTheme.black90,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.elementSpacing),

        // Explanation
        Container(
          padding: const EdgeInsets.all(AppTheme.cardPadding),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            children: [
              Text(
                'Unfortunately, you are not eligible to claim any gifts at this time.',
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? AppTheme.white90 : AppTheme.black90,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.elementSpacing),
              Text(
                'Only users who joined our early waitlist are eligible for this reward.',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppTheme.white60 : AppTheme.black60,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        const SizedBox(height: AppTheme.cardPadding * 1.5),

        // Follow us section
        Text(
          'Stay updated for upcoming gifts!',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? AppTheme.white90 : AppTheme.black90,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.cardPadding),

        // X/Twitter Follow Button
        SizedBox(
          width: double.infinity,
          child: LongButtonWidget(
            title: 'Follow us on X',
            onTap: _openTwitter,
            buttonType: ButtonType.primary,
            customWidth: double.infinity,
            trailingIcon: const Icon(Icons.open_in_new, size: 18),
          ),
        ),

        const SizedBox(height: AppTheme.elementSpacing),

        // X handle
        Text(
          '@lendasat',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppTheme.white60 : AppTheme.black60,
          ),
          textAlign: TextAlign.center,
        ),

        // Show error if any
        if (_eligibilityError != null) ...[
          const SizedBox(height: AppTheme.cardPadding),
          Text(
            _eligibilityError!,
            style: TextStyle(
              fontSize: 12,
              color: Colors.orange.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
