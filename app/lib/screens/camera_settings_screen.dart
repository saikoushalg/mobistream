import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Screen for setting camera name
class CameraSettingsScreen extends StatefulWidget {
  const CameraSettingsScreen({super.key});

  @override
  State<CameraSettingsScreen> createState() => _CameraSettingsScreenState();
}

class _CameraSettingsScreenState extends State<CameraSettingsScreen> {
  final _nameController = TextEditingController();
  String? _currentName;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCameraName();
  }

  Future<void> _loadCameraName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('camera_name') ?? 'Camera';
    setState(() {
      _currentName = name;
      _nameController.text = name;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Camera Settings'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              const Icon(
                Icons.videocam,
                color: Colors.purple,
                size: 48,
              ),
              const SizedBox(height: 16),

              // Title
              const Text(
                'Camera Name',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Description
              const Text(
                'This name will appear in OBS when you connect. Choose a unique name for this camera.',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),

              // Current name display
              if (_currentName != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Colors.white54,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Current name: $_currentName',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              // Input field
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Camera Name',
                  labelStyle: const TextStyle(color: Colors.white60),
                  hintText: 'e.g., Main, Wide, Close',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.38),
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Colors.purple,
                      width: 2,
                    ),
                  ),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),

              // Suggestions
              const Text(
                'Suggestions:',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildSuggestionChip('Main'),
                  _buildSuggestionChip('Wide'),
                  _buildSuggestionChip('Close'),
                  _buildSuggestionChip('Top'),
                  _buildSuggestionChip('Side'),
                  _buildSuggestionChip('Audience'),
                ],
              ),
              const SizedBox(height: 32),

              // Save button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _saveCameraName,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save Camera Name',
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

  Widget _buildSuggestionChip(String label) {
    return ActionChip(
      label: Text(label),
      labelStyle: const TextStyle(
        color: Colors.white70,
        fontSize: 12,
      ),
      backgroundColor: Colors.white.withValues(alpha: 0.1),
      onPressed: () {
        _nameController.text = label;
      },
    );
  }

  Future<void> _saveCameraName() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      _showSnackBar('Please enter a camera name', Colors.red);
      return;
    }

    if (name.length < 2) {
      _showSnackBar('Camera name must be at least 2 characters', Colors.orange);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('camera_name', name);

      if (mounted) {
        _showSnackBar('Camera name saved!', Colors.green);

        // Update display
        setState(() {
          _currentName = name;
        });

        // Go back after a short delay
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to save camera name', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
