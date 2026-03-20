import 'package:flutter/material.dart';
import '../config/stream_config.dart';
import '../config/app_constants.dart';

/// Stream configuration selected by the user.
class StreamSelection {
  final int cameraNumber;
  final StreamConfig quality;
  final String mediaMtxIp;
  final String streamName;

  const StreamSelection({
    required this.cameraNumber,
    required this.quality,
    this.mediaMtxIp = '',
    this.streamName = '',
  });

  StreamSelection copyWith({
    int? cameraNumber,
    StreamConfig? quality,
    String? mediaMtxIp,
    String? streamName,
  }) {
    return StreamSelection(
      cameraNumber: cameraNumber ?? this.cameraNumber,
      quality: quality ?? this.quality,
      mediaMtxIp: mediaMtxIp ?? this.mediaMtxIp,
      streamName: streamName ?? this.streamName,
    );
  }
}

/// Controls for starting/stopping the stream and selecting quality.
class StreamControlsWidget extends StatelessWidget {
  final StreamSelection selection;
  final Function(int cameraNumber) onCameraNumberChanged;
  final Function(StreamConfig quality) onQualityChanged;
  final Function(String ip) onMediaMtxIpChanged;
  final Function(String name) onStreamNameChanged;
  final VoidCallback onStartStream;
  final VoidCallback onStopStream;
  final VoidCallback onDiscover;
  final bool isStreaming;

  const StreamControlsWidget({
    super.key,
    required this.selection,
    required this.onCameraNumberChanged,
    required this.onQualityChanged,
    required this.onMediaMtxIpChanged,
    required this.onStreamNameChanged,
    required this.onStartStream,
    required this.onStopStream,
    required this.onDiscover,
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
            // MediaMTX IP
            _buildSectionTitle('MediaMTX IP', theme),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    initialValue: selection.mediaMtxIp,
                    onChanged: onMediaMtxIpChanged,
                    hint: 'e.g. 192.168.1.5',
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: isStreaming ? null : onDiscover,
                  icon: const Icon(Icons.search),
                  tooltip: 'Discover MediaMTX',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Stream Name
            _buildSectionTitle('Stream Name', theme),
            const SizedBox(height: 8),
            _buildTextField(
              initialValue: selection.streamName,
              onChanged: onStreamNameChanged,
              hint: 'e.g. cam1',
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Camera', theme),
                      const SizedBox(height: 8),
                      _buildCameraNumberSelector(),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Quality', theme),
                      const SizedBox(height: 8),
                      _buildQualitySelector(theme),
                    ],
                  ),
                ),
              ],
            ),
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

  Widget _buildTextField({
    required String initialValue,
    required Function(String) onChanged,
    required String hint,
  }) {
    return TextFormField(
      initialValue: initialValue,
      onChanged: onChanged,
      enabled: !isStreaming,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
