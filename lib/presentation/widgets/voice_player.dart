import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';

class VoicePlayer extends StatefulWidget {
  final String audioPath;
  final bool isMe;
  final int? duration;

  const VoicePlayer({
    Key? key,
    required this.audioPath,
    required this.isMe,
    this.duration,
  }) : super(key: key);

  @override
  State<VoicePlayer> createState() => _VoicePlayerState();
}

class _VoicePlayerState extends State<VoicePlayer> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isLoading = false;
  double _playbackProgress = 0.0;
  String? _localFilePath;
  Duration? _totalDuration;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _prepareAudio();

    _audioPlayer.playerStateStream.listen((playerState) {
      final isPlaying = playerState.playing;
      setState(() {
        _isPlaying = isPlaying;
      });
    });

    _audioPlayer.positionStream.listen((position) {
      setState(() {
        _position = position;
        if (_audioPlayer.duration != null) {
          _playbackProgress =
              position.inMilliseconds / _audioPlayer.duration!.inMilliseconds;
        }
      });
    });

    _audioPlayer.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        setState(() {
          _isPlaying = false;
          _playbackProgress = 0.0;
          _position = Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _prepareAudio() async {
    final content = widget.audioPath;

    try {
      setState(() {
        _isLoading = true;
      });

      // Kiểm tra nếu content là base64
      if (content.startsWith('base64audio:')) {
        // Trích xuất chuỗi base64
        String base64Data = content.substring('base64audio:'.length);

        // Tạo file tạm để phát
        final tempDir = await getTemporaryDirectory();
        final tempFilePath =
            '${tempDir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

        // Giải mã và lưu vào file tạm
        try {
          final bytes = base64Decode(base64Data);
          await File(tempFilePath).writeAsBytes(bytes);
          print('Created temp file from base64 data: $tempFilePath');
          _localFilePath = tempFilePath;
        } catch (e) {
          print('Error decoding base64 audio: $e');
          throw Exception('Could not decode audio data');
        }
      } else {
        // Đây là đường dẫn file thông thường
        _localFilePath = content;
      }

      // Cố gắng chuẩn bị audio từ file path
      if (_localFilePath != null) {
        final file = File(_localFilePath!);
        if (await file.exists()) {
          try {
            await _audioPlayer.setFilePath(_localFilePath!);
            _totalDuration = _audioPlayer.duration;
          } catch (e) {
            print('Error setting audio file: $e');
          }
        } else {
          print('Audio file not found: $_localFilePath');
        }
      }

      // Nếu không có thông tin về thời lượng từ file, sử dụng giá trị được cung cấp
      if (_totalDuration == null && widget.duration != null) {
        _totalDuration = Duration(seconds: widget.duration!);
      }
    } catch (e) {
      print('Error preparing voice message: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _togglePlayPause() async {
    if (_isLoading || _localFilePath == null) return;

    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        if (_audioPlayer.playing) {
          await _audioPlayer.play();
        } else {
          setState(() {
            _isLoading = true;
          });

          try {
            // Kiểm tra file và phát
            final file = File(_localFilePath!);
            if (await file.exists()) {
              await _audioPlayer.setFilePath(_localFilePath!);
              await _audioPlayer.play();
            } else {
              print('Audio file does not exist: $_localFilePath');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Audio file not found')),
              );
            }
          } catch (e) {
            print('Error playing audio: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error playing audio: $e')),
            );
          } finally {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          }
        }
      }
    } catch (e) {
      print('Error toggling playback: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    // Tính toán thời lượng hiển thị
    final Duration displayDuration =
        _totalDuration ?? Duration(seconds: widget.duration ?? 5);

    final String durationText = _isPlaying
        ? '${_formatDuration(_position)} / ${_formatDuration(displayDuration)}'
        : _formatDuration(displayDuration);

    return Container(
      constraints: BoxConstraints(
        minWidth: 100,
        maxWidth: MediaQuery.of(context).size.width * 0.6,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Biểu tượng mic
          Icon(
            Icons.mic,
            color: widget.isMe ? Colors.white : Colors.black54,
            size: 20,
          ),
          const SizedBox(width: 8),

          // Thanh tiến trình phát nhạc
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: widget.isMe
                        ? Colors.white.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _playbackProgress.isNaN
                        ? 0.0
                        : (_playbackProgress < 0
                            ? 0.0
                            : (_playbackProgress > 1.0
                                ? 1.0
                                : _playbackProgress)),
                    child: Container(
                      decoration: BoxDecoration(
                        color: widget.isMe
                            ? Colors.white
                            : Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  durationText,
                  style: TextStyle(
                    fontSize: 10,
                    color: widget.isMe ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Nút phát/dừng
          _isLoading
              ? SizedBox(
                  width: 36,
                  height: 36,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        widget.isMe
                            ? Colors.white
                            : Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                )
              : IconButton(
                  icon: Icon(
                    _isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    color: widget.isMe
                        ? Colors.white
                        : Theme.of(context).primaryColor,
                  ),
                  iconSize: 36,
                  onPressed: _togglePlayPause,
                  splashRadius: 24,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(), // Loại bỏ padding mặc định
                ),
        ],
      ),
    );
  }
}
