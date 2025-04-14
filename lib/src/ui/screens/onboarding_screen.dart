import 'package:ark_flutter/src/rust/api/ark_api.dart';
import 'package:flutter/material.dart';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:ark_flutter/src/ui/screens/dashboard_screen.dart';
import 'package:path_provider/path_provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  String? _selectedOption;
  final TextEditingController _secretKeyController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _secretKeyController.dispose();
    super.dispose();
  }

  void _handleOptionSelect(String option) {
    setState(() {
      _selectedOption = option;

      if (option == 'new') {
        _secretKeyController.clear();
      }
    });
  }

  void _handleContinue() async {
    // Show loading indicator
    setState(() {
      _isLoading = true;
    });

    final dataDir = await getApplicationSupportDirectory();

    try {
      if (_selectedOption == 'new') {
        logger.i('Creating new wallet');

        try {
          var aspId = await setupNewWallet(dataDir: dataDir.path);
          logger.i("Received id $aspId");

          // Navigate to dashboard
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                  builder: (context) => DashboardScreen(aspId: aspId)),
            );
          }
        } catch (e) {
          logger.e("Failed to create new wallet: $e");
          _showErrorDialog("Failed to create wallet",
              "There was an error creating your new wallet. Please try again.\n\nError: ${e.toString()}");
        }
      } else if (_selectedOption == 'existing' &&
          _secretKeyController.text.isNotEmpty) {
        logger.i('Restoring wallet with key');

        try {
          var aspId = await restoreWallet(nsec: _secretKeyController.text, dataDir: dataDir.path);
          logger.i("Received id $aspId");

          // Navigate to dashboard
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                  builder: (context) => DashboardScreen(aspId: aspId)),
            );
          }
        } catch (e) {
          logger.e("Failed to restore wallet: $e");
          _showErrorDialog("Failed to restore wallet",
              "There was an error restoring your wallet. Please check your nsec and try again.\n\nError: ${e.toString()}");
        }
      }
    } finally {
      // Hide loading indicator if we're still mounted
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: Text(
          title,
          style: const TextStyle(color: Colors.red),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.amber,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo and Header
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'WTFark',
                      style: TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber[500],
                      ),
                    ),
                    const SizedBox(height: 16),
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[300],
                        ),
                        children: const [
                          TextSpan(
                            text: 'W',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(text: 'allet '),
                          TextSpan(
                            text: 'T',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(text: 'hat '),
                          TextSpan(
                            text: 'F',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(text: 'lies on Ark'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Option Selection
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Choose an option:',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // New Wallet Option
                    _buildOptionCard(
                      title: 'Create New Wallet',
                      subtitle: 'Generate a new secure wallet',
                      option: 'new',
                    ),
                    const SizedBox(height: 16),

                    // Existing Wallet Option
                    _buildOptionCard(
                      title: 'Restore Existing Wallet',
                      subtitle: 'Use your secret key to access your wallet',
                      option: 'existing',
                    ),
                    const SizedBox(height: 24),

                    // Secret Key Input (shown only when "Existing Wallet" is selected)
                    if (_selectedOption == 'existing') ...[
                      const Text(
                        'Enter your nsec:',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[850],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: _secretKeyController,
                          style: const TextStyle(color: Colors.white),
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'Paste your recovery nsec...',
                            hintStyle: TextStyle(color: Colors.grey),
                            contentPadding: EdgeInsets.all(16),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Continue Button
              SizedBox(
                height: 56,
                child: ElevatedButton(

                  onPressed: _isLoading
                      ? null
                      : (_selectedOption == 'new' || _selectedOption == 'existing'
                      ? _handleContinue
                      : null),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[500],
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.black),
                            strokeWidth: 3,
                          ),
                        )
                      : const Text(
                          'CONTINUE',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String subtitle,
    required String option,
  }) {
    final bool isSelected = _selectedOption == option;

    return InkWell(
      onTap: () => _handleOptionSelect(option),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber[500] : Colors.grey[850],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.black : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected
                          ? Colors.black.withOpacity(0.7)
                          : Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Colors.black,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
