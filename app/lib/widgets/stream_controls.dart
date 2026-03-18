import 'package:flutter/material.dart';
import '../config/stream_config.dart';
import '../config/app_constants.dart';

/// Stream configuration selected by the user.
class StreamSelection {
  final int cameraNumber;
  final StreamConfig quality;

  const StreamSelection({
    required this.cameraNumber,
    required this.quality,
  });

  StreamSelection copyWith({
    int? cameraNumber,
    StreamConfig? quality,
  }) {
    return StreamSelection(
      cameraNumber: cameraNumber ?? this.cameraNumber,
      quality: quality ?? this.quality,
    );
  }
}

/// Controls for starting/stopping the stream and selecting quality.
class StreamControlsWidget extends StatelessWidget {
  final StreamSelection selection;
  final Function(int cameraNumber) onCameraNumberChanged;
  final Function(StreamConfig quality) onQualityChanged;
  final VoidCallback onStartStream;
  final VoidCallback onStopStream;
  final bool isStreaming;

  const StreamControlsWidget({
    super.key,
    required this.selection,
    required this.onCameraNumberChanged,
    required this.onQualityChanged,
    required this.onStartStream,
    required this.onStopStream,
    required this.isStreaming,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.7),
          ],
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Camera number selector
            _buildSectionTitle('Camera Number', theme),
            const SizedBox(height: 8),
            _buildCameraNumberSelector(),
            const SizedBox(height: 16),

            // Quality selector
            _buildSectionTitle('Quality', theme),
            const SizedBox(height: 8),
            _buildQualitySelector(theme),
            const SizedBox(height: 24),

            // Start/Stop button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: isStreaming ? onStopStream : onStartStream,
                style: FilledButton.styleFrom(
                  backgroundColor: isStreaming
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  isStreaming ? 'Stop Streaming' : 'Start Streaming',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCameraNumberSelector() {
    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: AppConstants.maxCameras,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cameraNumber = index + 1;
          final isSelected = cameraNumber == selection.cameraNumber;

          return _buildCameraNumberButton(
            cameraNumber: cameraNumber,
            isSelected: isSelected,
            onTap: () => onCameraNumberChanged(cameraNumber),
          );
        },
      ),
    );
  }

  Widget _buildCameraNumberButton({
    required int cameraNumber,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            '$cameraNumber',
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQualitySelector(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<StreamConfig>(
          value: selection.quality,
          dropdownColor: Colors.grey[900],
          iconEnabledColor: Colors.white,
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white,
          ),
          items: StreamConfig.all.map((config) {
            return DropdownMenuItem<StreamConfig>(
              value: config,
              child: Text(config.name),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              onQualityChanged(value);
            }
          },
        ),
      ),
    );
  }
}
