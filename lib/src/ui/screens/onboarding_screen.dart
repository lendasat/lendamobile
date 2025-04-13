import 'package:ark_flutter/src/rust/api/ark_api.dart';
import 'package:flutter/material.dart';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:ark_flutter/src/ui/screens/dashboard_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  String? _selectedOption;
  final TextEditingController _secretKeyController = TextEditingController();

  @override
  void dispose() {
    _secretKeyController.dispose();
    super.dispose();
  }

  void _handleOptionSelect(String option) {
    setState(() {
      _selectedOption = option;
    });
  }

  void _handleContinue() async {
    if (_selectedOption == 'new') {
      logger.i('Creating new wallet');
      // Call your Rust backend to create a new wallet
      var aspId = await setupArkClient();
      logger.i("Received id $aspId");

      // Navigate to dashboard
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
              builder: (context) => DashboardScreen(aspId: aspId)),
        );
      }
    } else if (_selectedOption == 'existing' &&
        _secretKeyController.text.isNotEmpty) {
      logger.i('Restoring wallet with key: ${_secretKeyController.text}');
      // Call your Rust backend to restore wallet with the provided secret key
      var aspId =
          await setupArkClient(); // You might need a different function for restoration
      logger.i("Received id $aspId");

      // Navigate to dashboard
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
              builder: (context) => DashboardScreen(aspId: aspId)),
        );
      }
    }
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
                    Text(
                      'Bitcoin Wallet for Ark L2',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[300],
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
                        'Enter your secret key:',
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
                            hintText: 'Paste your secret recovery phrase...',
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
                  onPressed: _selectedOption != null
                      ? (_selectedOption == 'existing' &&
                              _secretKeyController.text.isEmpty
                          ? null // Disable if existing wallet is selected but no key provided
                          : _handleContinue)
                      : null, // Disable if no option is selected
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[500],
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
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
