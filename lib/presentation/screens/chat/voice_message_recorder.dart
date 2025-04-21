import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceMessageRecorder extends StatefulWidget {
  final Function(File audioFile) onStop;
  final VoidCallback onCancel;

  const VoiceMessageRecorder({
    super.key,
    required this.onStop,
    required this.onCancel,
  });

  @override
  State<VoiceMessageRecorder> createState() => _VoiceMessageRecorderState();
}

class _VoiceMessageRecorderState extends State<VoiceMessageRecorder> {
  final _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String _path = '';
  Timer? _timer;
  int _recordDuration = 0;
  bool _isInitializing = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkPermissionAndStartRecording();
  }

  Future<void> _checkPermissionAndStartRecording() async {
    try {
      final hasPermission = await _requestPermission(Permission.microphone);

      if (hasPermission) {
        await _startRecording();
      } else {
        setState(() {
          _errorMessage = 'Microphone permission denied';
          _isInitializing = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error initializing: $e';
        _isInitializing = false;
      });
    }
  }

  Future<bool> _requestPermission(Permission permission) async {
    final status = await permission.request();
    return status.isGranted;
  }

  Future<void> _startRecording() async {
    try {
      final dir = await getTemporaryDirectory();
      _path =
          '${dir.path}/voice_message_${DateTime.now().millisecondsSinceEpoch}.m4a';

      // Check if recording is already initialized and if microphone is available
      if (await _audioRecorder.hasPermission()) {
        // Configure recorder with the updated API
        await _audioRecorder.start(
          RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: _path,
        );

        setState(() {
          _isRecording = true;
          _isInitializing = false;
          _recordDuration = 0;
        });

        _startTimer();
      } else {
        setState(() {
          _errorMessage = 'Microphone permission denied';
          _isInitializing = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to start recording: $e';
        _isInitializing = false;
      });
    }
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();

    try {
      final path = await _audioRecorder.stop();

      setState(() {
        _isRecording = false;
      });

      if (path != null) {
        final file = File(path);
        if (await file.exists()) {
          widget.onStop(file);
        } else {
          throw Exception('Recording file does not exist');
        }
      } else {
        throw Exception('Recording failed, no path returned');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error stopping recording: $e')),
      );
      widget.onCancel();
    }
  }

  void _cancelRecording() async {
    _timer?.cancel();

    try {
      await _audioRecorder.stop();

      // Delete the recording file if it exists
      if (_path.isNotEmpty) {
        final file = File(_path);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (e) {
      debugPrint('Error canceling recording: $e');
    } finally {
      widget.onCancel();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      setState(() => _recordDuration++);

      // Auto-stop after 2 minutes to avoid very large files
      if (_recordDuration >= 120) {
        _stopRecording();
      }
    });
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              offset: const Offset(0, -1),
              blurRadius: 3,
            ),
          ],
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 8),
              Text('Initializing microphone...'),
            ],
          ),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              offset: const Offset(0, -1),
              blurRadius: 3,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _errorMessage,
              style: const TextStyle(color: Colors.red),
            ),
            TextButton(
              onPressed: widget.onCancel,
              child: const Text('CLOSE'),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            offset: const Offset(0, -1),
            blurRadius: 3,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.mic, color: Colors.red),
              const SizedBox(width: 10),
              Text(
                _formatDuration(_recordDuration),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 10),
              const Text('Recording...'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.delete),
                label: const Text('Cancel'),
                onPressed: _cancelRecording,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.send),
                label: const Text('Send'),
                onPressed: _stopRecording,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
