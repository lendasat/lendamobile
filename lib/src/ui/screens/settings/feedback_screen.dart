import 'dart:io';
import 'package:ark_flutter/src/services/feedback_service.dart';
import 'package:ark_flutter/src/services/settings_controller.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/button_types.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/long_button_widget.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_app_bar.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_scaffold.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:ark_flutter/theme.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FeedbackService _feedbackService = FeedbackService();
  final ImagePicker _imagePicker = ImagePicker();

  String _selectedType = 'Bug Report';
  final List<String> _feedbackTypes = [
    'Bug Report',
    'Feature Request',
    'General Feedback',
    'Other',
  ];

  final List<File> _attachedImages = [];
  bool _isLoading = false;
  bool _includeDeviceInfo = true;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _attachedImages.add(File(image.path));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to pick image')),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _attachedImages.removeAt(index);
    });
  }

  Future<void> _submitFeedback() async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your feedback message')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final deviceInfo =
          _includeDeviceInfo ? _feedbackService.getDeviceInfo() : null;

      final success = await _feedbackService.sendFeedbackViaEmail(
        feedbackType: _selectedType,
        message: _messageController.text,
        deviceInfo: deviceInfo,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (success) {
          if (_attachedImages.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Email app opened. Please attach your images manually.',
                ),
                duration: Duration(seconds: 4),
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Could not open email app. Please email support@lendasat.com directly.',
              ),
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<SettingsController>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ArkScaffold(
      extendBodyBehindAppBar: true,
      context: context,
      appBar: ArkAppBar(
        text: 'Feedback',
        context: context,
        hasBackButton: true,
        onTap: () => controller.switchTab('main'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppTheme.cardPadding),

            // Feedback Type Selector
            Text(
              'Feedback Type',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppTheme.elementSpacing),
            GlassContainer(
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMid),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.cardPadding,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedType,
                    isExpanded: true,
                    dropdownColor: isDarkMode ? AppTheme.black90 : Colors.white,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                      fontSize: 16,
                    ),
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                    ),
                    items: _feedbackTypes.map((type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Row(
                          children: [
                            Icon(
                              _getTypeIcon(type),
                              size: 20,
                              color: _getTypeColor(type),
                            ),
                            const SizedBox(width: 12),
                            Text(type),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedType = value;
                        });
                      }
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppTheme.cardPadding),

            // Message Input
            Text(
              'Your Message',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppTheme.elementSpacing),
            GlassContainer(
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMid),
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.elementSpacing),
                child: TextField(
                  controller: _messageController,
                  maxLines: 6,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    hintText:
                        'Describe your feedback, bug, or suggestion in detail...',
                    hintStyle: TextStyle(
                      color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppTheme.cardPadding),

            // Images Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Images (Optional)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (_attachedImages.length < 5)
                  TextButton.icon(
                    onPressed: _pickImageFromGallery,
                    icon: const Icon(Icons.add_photo_alternate_rounded, size: 20),
                    label: const Text('Add'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.colorBitcoin,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppTheme.elementSpacing),

            if (_attachedImages.isEmpty)
              GlassContainer(
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusMid),
                child: InkWell(
                  onTap: _pickImageFromGallery,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMid),
                  child: Container(
                    height: 100,
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppTheme.cardPadding),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 32,
                          color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to add images from gallery',
                          style: TextStyle(
                            color:
                                isDarkMode ? AppTheme.white60 : AppTheme.black60,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  itemCount: _attachedImages.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ClipRRect(
                            borderRadius:
                                BorderRadius.circular(AppTheme.borderRadiusMid),
                            child: Image.file(
                              _attachedImages[index],
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: -8,
                            right: -8,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Theme.of(context).scaffoldBackgroundColor,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: AppTheme.cardPadding),

            // Device Info Toggle
            GlassContainer(
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMid),
              child: Theme(
                data: Theme.of(context).copyWith(
                  switchTheme: SwitchThemeData(
                    thumbColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return AppTheme.colorBitcoin;
                      }
                      return null;
                    }),
                    trackColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return AppTheme.colorBitcoin.withValues(alpha: 0.5);
                      }
                      return null;
                    }),
                  ),
                ),
                child: SwitchListTile(
                  title: const Text('Include Device Info'),
                  subtitle: Text(
                    'Helps us diagnose issues faster',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                    ),
                  ),
                  value: _includeDeviceInfo,
                  onChanged: (value) {
                    setState(() {
                      _includeDeviceInfo = value;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: AppTheme.cardPadding),

            // Info Text
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your feedback will be sent to support@lendasat.com. If you added images, please attach them manually in your email app.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              isDarkMode ? AppTheme.white60 : AppTheme.black60,
                        ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppTheme.cardPadding * 2),

            // Submit Button
            LongButtonWidget(
              title: 'Send Feedback',
              customWidth: double.infinity,
              state: _isLoading ? ButtonState.loading : ButtonState.idle,
              onTap: _isLoading ? null : _submitFeedback,
            ),

            const SizedBox(height: AppTheme.cardPadding),
          ],
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'Bug Report':
        return Icons.bug_report_rounded;
      case 'Feature Request':
        return Icons.lightbulb_outline_rounded;
      case 'General Feedback':
        return Icons.feedback_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Bug Report':
        return Colors.red;
      case 'Feature Request':
        return Colors.blue;
      case 'General Feedback':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }
}
