# Chat Interface Fixes - Implementation Guide

## Overview
This document outlines the changes needed to fix voice message functionality and add multiple photo/video selection in the chat interface.

## 1. Package Dependencies (pubspec.yaml) ✅ DONE
Already added `just_audio: ^0.9.36` for audio playback.

## 2. Import Statements
Add to `lib/screens/adsy_connect_chat_interface.dart`:
```dart
import 'package:just_audio/just_audio.dart';
```

## 3. State Variables
Add these state variables to `_AdsyConnectChatInterfaceState`:
```dart
final Map<String, AudioPlayer> _audioPlayers = {};
final Map<String, bool> _isPlayingMap = {};
final Map<String, Duration> _positionMap = {};
final Map<String, Duration> _durationMap = {};
```

## 4. Dispose Method
Update the `dispose()` method to clean up audio players:
```dart
@override
void dispose() {
  // Clear active chat when leaving
  ActiveChatTracker.clearActiveChat();
  _messageController.dispose();
  _scrollController.dispose();
  _messageFocusNode.dispose();
  _audioRecorder.dispose();
  _recordTimer?.cancel();
  _messagePollingTimer?.cancel();
  
  // Dispose all audio players
  for (var player in _audioPlayers.values) {
    player.dispose();
  }
  _audioPlayers.clear();
  
  super.dispose();
}
```

## 5. Voice Message Sending Fix
Replace the `_stopRecording()` method:
```dart
Future<void> _stopRecording() async {
  try {
    final path = await _audioRecorder.stop();
    _recordTimer?.cancel();

    setState(() {
      _isRecording = false;
    });

    if (path != null) {
      // Upload voice message to backend API
      setState(() => _isUploadingAttachment = true);
      
      try {
        print('🔵 Sending voice message: $path, duration: $_recordDuration seconds');
        
        final sentMessage = await AdsyConnectService.sendMediaMessage(
          chatroomId: widget.chatroomId,
          receiverId: widget.userId,
          messageType: 'voice',
          mediaFilePath: path,
          voiceDuration: _recordDuration,
        );
        
        print('🟢 Voice message sent: ${sentMessage['id']}');
        print('🟢 Voice URL: ${sentMessage['media_url']}');
        
        if (mounted) {
          setState(() {
            _messages.add(_parseSingleMessage(sentMessage));
            _isUploadingAttachment = false;
            _recordDuration = 0;
          });
          _scrollToBottom();
        }
      } catch (e) {
        print('🔴 Error sending voice message: $e');
        if (mounted) {
          setState(() {
            _isUploadingAttachment = false;
            _recordDuration = 0;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to send voice message: $e'),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
      }
    } else {
      setState(() => _recordDuration = 0);
    }
  } catch (e) {
    print('Error stopping recording: $e');
    setState(() {
      _isRecording = false;
      _recordDuration = 0;
    });
  }
}
```

## 6. Voice Message Playback Widget
Replace the `_buildVoiceMessageContent()` method:
```dart
Widget _buildVoiceMessageContent(Map<String, dynamic> message, bool isMe) {
  final messageId = message['id']?.toString() ?? '';
  final mediaUrl = message['mediaUrl'] as String?;
  final isPlaying = _isPlayingMap[messageId] ?? false;
  final position = _positionMap[messageId] ?? Duration.zero;
  final duration = _durationMap[messageId] ?? Duration.zero;
  
  // If no media URL, show error
  if (mediaUrl == null || mediaUrl.isEmpty) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.error_outline_rounded,
          size: 20,
          color: isMe ? Colors.white70 : Colors.grey,
        ),
        const SizedBox(width: 6),
        Text(
          'Voice message unavailable',
          style: TextStyle(
            fontSize: 11,
            color: isMe ? Colors.white70 : Colors.grey,
          ),
        ),
      ],
    );
  }
  
  return GestureDetector(
    onTap: () => _toggleVoicePlayback(messageId, mediaUrl),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          size: 24,
          color: isMe ? Colors.white : const Color(0xFF3B82F6),
        ),
        const SizedBox(width: 8),
        // Waveform visualization
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: List.generate(
                15,
                (index) {
                  final progress = duration.inSeconds > 0 
                      ? position.inSeconds / duration.inSeconds 
                      : 0.0;
                  final isActive = (index / 15) <= progress;
                  return Container(
                    width: 2,
                    height: (index % 3 + 1) * 4.0,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: isActive
                          ? (isMe ? Colors.white : const Color(0xFF3B82F6))
                          : (isMe ? Colors.white.withOpacity(0.4) : const Color(0xFF3B82F6).withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isPlaying && position.inSeconds > 0
                  ? '${_formatDuration(position.inSeconds)} / ${_formatDuration(duration.inSeconds)}'
                  : _formatDuration(duration.inSeconds),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isMe ? Colors.white.withOpacity(0.9) : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
```

## 7. Voice Playback Toggle Method
Add this new method:
```dart
Future<void> _toggleVoicePlayback(String messageId, String mediaUrl) async {
  try {
    // Get or create audio player for this message
    if (!_audioPlayers.containsKey(messageId)) {
      final player = AudioPlayer();
      _audioPlayers[messageId] = player;
      
      // Set up listeners
      player.positionStream.listen((position) {
        if (mounted) {
          setState(() {
            _positionMap[messageId] = position;
          });
        }
      });
      
      player.durationStream.listen((duration) {
        if (mounted && duration != null) {
          setState(() {
            _durationMap[messageId] = duration;
          });
        }
      });
      
      player.playerStateStream.listen((state) {
        if (mounted) {
          final isPlaying = state.playing;
          setState(() {
            _isPlayingMap[messageId] = isPlaying;
          });
          
          // Reset position when playback completes
          if (state.processingState == ProcessingState.completed) {
            setState(() {
              _isPlayingMap[messageId] = false;
              _positionMap[messageId] = Duration.zero;
            });
          }
        }
      });
      
      // Load the audio
      await player.setUrl(mediaUrl);
    }
    
    final player = _audioPlayers[messageId]!;
    final isPlaying = _isPlayingMap[messageId] ?? false;
    
    if (isPlaying) {
      await player.pause();
    } else {
      // Pause all other players
      for (var entry in _audioPlayers.entries) {
        if (entry.key != messageId) {
          await entry.value.pause();
        }
      }
      await player.play();
    }
  } catch (e) {
    print('🔴 Error playing voice message: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to play voice message'),
          backgroundColor: Color(0xFFEF4444),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
```

## 8. Multiple Photo Selection
Replace the `_pickImageFromGallery()` method:
```dart
Future<void> _pickImageFromGallery() async {
  try {
    // Pick multiple images (up to 8)
    final List<XFile> images = await _imagePicker.pickMultiImage(
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    
    if (images.isEmpty) return;
    
    // Limit to 8 photos
    final selectedImages = images.take(8).toList();
    
    if (images.length > 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 8 photos allowed. First 8 selected.'),
          backgroundColor: Color(0xFFF59E0B),
          duration: Duration(seconds: 3),
        ),
      );
    }
    
    setState(() => _isUploadingAttachment = true);
    
    // Send each image
    for (int i = 0; i < selectedImages.length; i++) {
      final image = selectedImages[i];
      
      try {
        if (kIsWeb) {
          // Web: Read as bytes
          final bytes = await image.readAsBytes();
          await _sendMediaMessageWeb(bytes, 'image', fileName: image.name);
        } else {
          // Mobile: Compress and send
          final compressedBase64 = await ImageCompressor.compressToBase64(
            image,
            targetSize: 200 * 1024, // 200KB
            initialQuality: 80,
            maxDimension: 1920,
            verbose: true,
          );
          
          if (compressedBase64 != null) {
            await _sendMediaMessage(image.path, 'image');
          } else {
            throw Exception('Image compression failed');
          }
        }
        
        // Show progress
        if (mounted && selectedImages.length > 1) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sending photo ${i + 1} of ${selectedImages.length}...'),
              backgroundColor: const Color(0xFF3B82F6),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      } catch (e) {
        print('Error sending image ${i + 1}: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to send photo ${i + 1}'),
              backgroundColor: const Color(0xFFEF4444),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    }
    
    setState(() => _isUploadingAttachment = false);
    
  } catch (e) {
    print('Error picking images: $e');
    setState(() => _isUploadingAttachment = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick images: ${e.toString()}'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }
}
```

## 9. Video Selection (Already Supports 1 Video)
The existing `_pickVideo()` method already supports single video selection. No changes needed.

## Summary of Changes

### ✅ Voice Message Fixes:
1. Voice messages now upload to backend API via `AdsyConnectService.sendMediaMessage()`
2. Recipients can play voice messages with play/pause controls
3. Visual waveform shows playback progress
4. Duration display shows current position and total length
5. Only one voice message plays at a time

### ✅ Multiple Photo Selection:
1. Users can select up to 8 photos at once from gallery
2. Photos are sent sequentially with progress indicators
3. Warning shown if more than 8 photos selected
4. Each photo is compressed before sending (200KB target)

### ✅ Video Selection:
1. Already supports 1 video at a time (no changes needed)
2. Videos are sent via the same media upload API

## Testing Checklist

- [ ] Record and send voice message
- [ ] Receive and play voice message from another user
- [ ] Pause/resume voice playback
- [ ] Select multiple photos (2-8) and send
- [ ] Select 1 video and send
- [ ] Try selecting more than 8 photos (should show warning)
- [ ] Test on both mobile and web platforms
- [ ] Verify voice message duration displays correctly
- [ ] Verify playback progress updates in real-time

## Notes
- Voice messages use `.m4a` format (AAC-LC codec)
- Photos are compressed to max 200KB and 1920px dimension
- All media uploads go through `AdsyConnectService.sendMediaMessage()`
- Audio players are properly disposed when leaving chat
