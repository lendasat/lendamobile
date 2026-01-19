import 'package:ark_flutter/src/services/biometric_service.dart';
import 'package:ark_flutter/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Lock screen that requires biometric authentication to access the app
class LockScreen extends StatefulWidget {
  final Widget child;

  const LockScreen({
    super.key,
    required this.child,
  });

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> with WidgetsBindingObserver {
  bool _isAuthenticating = false;
  bool _authFailed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Trigger authentication on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attemptAuthentication();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final biometricService = context.read<BiometricService>();

    if (state == AppLifecycleState.paused) {
      // Record when app went to background (grace period starts)
      biometricService.onAppBackgrounded();
    } else if (state == AppLifecycleState.resumed) {
      // Check if grace period expired and re-authentication is needed
      final needsAuth = biometricService.onAppResumed();
      if (needsAuth) {
        _attemptAuthentication();
      }
    }
  }

  Future<void> _attemptAuthentication() async {
    final biometricService = context.read<BiometricService>();

    if (!biometricService.shouldShowLockScreen) return;
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
      _authFailed = false;
    });

    try {
      final success = await biometricService.authenticate();

      if (mounted) {
        setState(() {
          _isAuthenticating = false;
          _authFailed = !success;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
          _authFailed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BiometricService>(
      builder: (context, biometricService, _) {
        // If no lock needed, show the child directly
        if (!biometricService.shouldShowLockScreen) {
          return widget.child;
        }

        // Show lock screen
        return _buildLockScreen(context, biometricService);
      },
    );
  }

  Widget _buildLockScreen(BuildContext context, BiometricService biometricService) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final biometricName = biometricService.getBiometricTypeName();

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey.shade100,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.cardPadding * 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App icon or logo
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.lock_rounded,
                    size: 40,
                    color: AppTheme.primaryColor,
                  ),
                ),

                const SizedBox(height: AppTheme.cardPadding * 2),

                // Title
                Text(
                  'Wallet Locked',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),

                const SizedBox(height: AppTheme.elementSpacing),

                // Subtitle
                Text(
                  _authFailed
                      ? 'Authentication failed. Please try again.'
                      : 'Use $biometricName to unlock your wallet',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _authFailed
                            ? AppTheme.errorColor
                            : (isDark ? AppTheme.white60 : AppTheme.black60),
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppTheme.cardPadding * 2),

                // Fingerprint button
                GestureDetector(
                  onTap: _isAuthenticating ? null : _attemptAuthentication,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: _isAuthenticating
                          ? AppTheme.primaryColor.withValues(alpha: 0.1)
                          : AppTheme.primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(36),
                      border: Border.all(
                        color: _authFailed
                            ? AppTheme.errorColor.withValues(alpha: 0.5)
                            : AppTheme.primaryColor.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: _isAuthenticating
                        ? Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.primaryColor,
                                ),
                              ),
                            ),
                          )
                        : Icon(
                            Icons.fingerprint_rounded,
                            size: 36,
                            color: _authFailed
                                ? AppTheme.errorColor
                                : AppTheme.primaryColor,
                          ),
                  ),
                ),

                const SizedBox(height: AppTheme.elementSpacing),

                // Tap to unlock hint
                if (!_isAuthenticating)
                  Text(
                    'Tap to unlock',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark ? AppTheme.white60 : AppTheme.black60,
                        ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
