import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:audioplayers/audioplayers.dart';
import 'package:excellencecoachinghub/config/api_config.dart';
import 'package:http_parser/http_parser.dart';

/// Voice Chat Recording Widget
class VoiceChatWidget extends StatefulWidget {
  final String conversationId;
  final Map<String, dynamic>? context;
  final Function(String text)? onVoiceMessageReceived;
  final Function(String text)? onTextMessageReceived;

  const VoiceChatWidget({
    super.key,
    required this.conversationId,
    this.context,
    this.onVoiceMessageReceived,
    this.onTextMessageReceived,
  });

  @override
  State<VoiceChatWidget> createState() => _VoiceChatWidgetState();
}

class _VoiceChatWidgetState extends State<VoiceChatWidget> {
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _isProcessing = false;
  String? _recordingText;
  String? _responseText;
  String? _audioResponseUrl;
  final TextEditingController _textController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _tempAudioPath;

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        _isPlaying = false;
      });
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    setState(() {
      _isRecording = true;
      _recordingText = null;
      _responseText = null;
      _audioResponseUrl = null;
    });

    // TODO: Implement actual recording functionality with correct API
    // For now, simulate recording completion
    await Future.delayed(Duration(milliseconds: 500));
    
    // Simulate a temporary audio file path for demonstration
    final tempDir = await Directory.systemTemp.createTemp();
    final fileName = 'recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
    _tempAudioPath = path.join(tempDir.path, fileName);
    
    // Create a dummy file for testing purposes
    File(_tempAudioPath!).createSync();
    
    setState(() {
      _isRecording = false;
    });
    
    await _sendVoiceMessage();
  }

  Future<void> _stopRecording() async {
    // Stop recording simulation
    if (_tempAudioPath != null && File(_tempAudioPath!).existsSync()) {
      await _sendVoiceMessage();
    }
    
    setState(() {
      _isRecording = false;
    });
  }

  Future<void> _sendVoiceMessage() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // Create multipart request to send audio file
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.voiceBaseUrl}/send'), // Use centralized API config
      );
      
      request.fields['conversationId'] = widget.conversationId;
      if (widget.context != null) {
        request.fields['context'] = jsonEncode(widget.context);
      }
      
      if (_tempAudioPath != null && File(_tempAudioPath!).existsSync()) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'audio',
            _tempAudioPath!,
            contentType: MediaType('audio', 'm4a'), // Using m4a for audio file
          ),
        );
      }
      
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        var responseData = jsonDecode(responseBody);
        
        setState(() {
          _recordingText = responseData['transcription'] ?? 'Audio received';
          _responseText = responseData['textResponse'];
          _audioResponseUrl = responseData['audioResponse'];
          _isProcessing = false;
        });

        if (widget.onVoiceMessageReceived != null) {
          widget.onVoiceMessageReceived!(responseData['textResponse'] ?? '');
        }
      } else {
        throw Exception('Failed to send voice message: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending voice message: $e');
      setState(() {
        _isProcessing = false;
      });
      _showError('Failed to send voice message');
    } finally {
      // Clean up temporary file
      if (_tempAudioPath != null) {
        File(_tempAudioPath!).delete();
        _tempAudioPath = null;
      }
    }
  }

  Future<void> _playAudioResponse() async {
    if (_audioResponseUrl == null) return;

    setState(() {
      _isPlaying = true;
    });

    try {
      await _audioPlayer.play(UrlSource(_audioResponseUrl!));
    } catch (e) {
      print('Error playing audio: $e');
      setState(() {
        _isPlaying = false;
      });
    }
  }

  void _sendTextMessage() async {
    if (_textController.text.trim().isEmpty) return;

    final message = _textController.text.trim();
    _textController.clear();

    setState(() {
      _isProcessing = true;
    });

    try {
      // Send text message to backend as if it were a transcribed voice message
      final response = await http.post(
        Uri.parse('${ApiConfig.aiBaseUrl}/chat/send'), // Use centralized API config
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'conversationId': widget.conversationId,
          'message': message,
          'context': widget.context,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _responseText = data['message'];
          _isProcessing = false;
        });

        if (widget.onTextMessageReceived != null) {
          widget.onTextMessageReceived!(data['message']);
        }
      } else {
        throw Exception('Failed to send message');
      }
    } catch (e) {
      print('Error sending text message: $e');
      setState(() {
        _isProcessing = false;
      });
      _showError('Failed to send message');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderGrey),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Voice recording controls
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Text(
                    _recordingText ?? 'Press and hold to speak...',
                    style: const TextStyle(
                      color: Color(0xFF8E8E93),
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTapDown: (_) => _startRecording(),
                onTapUp: (_) => _stopRecording(),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _isRecording ? Colors.red : AppTheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isRecording ? Icons.mic_off : Icons.mic,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),

          if (_isProcessing)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: LinearProgressIndicator(),
            ),

          if (_responseText != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AI Response:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _responseText!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  if (_audioResponseUrl != null) ...[
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _isPlaying ? null : _playAudioResponse,
                      icon: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        size: 16,
                      ),
                      label: Text(_isPlaying ? 'Playing...' : 'Play Response'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Text input alternative
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: TextField(
                    controller: _textController,
                    onSubmitted: (_) => _sendTextMessage(),
                    decoration: const InputDecoration(
                      hintText: 'Type your message...',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: IconButton(
                  onPressed: _sendTextMessage,
                  icon: const Icon(
                    Icons.send,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
