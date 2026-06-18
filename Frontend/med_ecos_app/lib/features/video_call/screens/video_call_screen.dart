import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/agora_service.dart';

class VideoCallScreen extends StatefulWidget {
  final String channelName;

  const VideoCallScreen({Key? key, required this.channelName}) : super(key: key);

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final AgoraService _agoraService = AgoraService();
  final int _localUid = Random().nextInt(100000) + 1;
  int? _remoteUid;
  bool _localUserJoined = false;
  bool _muted = false;
  bool _videoOff = false;
  late RtcEngine _engine;

  @override
  void initState() {
    super.initState();
    initAgora();
  }

  Future<void> initAgora() async {
    // Retrieve permissions
    await [Permission.microphone, Permission.camera].request();

    // Create the engine
    _engine = createAgoraRtcEngine();
    
    // The App ID is safe to embed in the client app. The App Certificate remains secret on the backend.
    final appId = '0493c83dfe054c64a38fb68197f703ea';

    await _engine.initialize(RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint("local user ${connection.localUid} joined");
          setState(() {
            _localUserJoined = true;
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint("remote user $remoteUid joined");
          setState(() {
            _remoteUid = remoteUid;
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          debugPrint("remote user $remoteUid left channel");
          setState(() {
            _remoteUid = null;
          });
        },
        onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
          debugPrint('[onTokenPrivilegeWillExpire] connection: ${connection.toJson()}, token: $token');
        },
        onError: (ErrorCodeType err, String msg) {
          debugPrint('[onError] err: $err, msg: $msg');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Agora Error: $msg')));
          }
        },
      ),
    );

    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine.enableVideo();
    
    try {
      await _engine.startPreview();
      debugPrint('Preview started');
    } catch (e) {
      debugPrint('Error starting preview: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Warning: Camera preview failed ($e)')));
      }
    }

    try {
      // Fetch token from server
      final token = await _agoraService.fetchToken(widget.channelName, _localUid);
      debugPrint('Fetched token: $token');
      
      if (token != null) {
        await _engine.joinChannel(
          token: token,
          channelId: widget.channelName,
          uid: _localUid,
          options: const ChannelMediaOptions(
            clientRoleType: ClientRoleType.clientRoleBroadcaster,
            publishCameraTrack: true,
            publishMicrophoneTrack: true,
            autoSubscribeAudio: true,
            autoSubscribeVideo: true,
          ),
        );
      } else {
        debugPrint('Failed to get token');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: Could not fetch video call token.')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error joining channel: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error joining channel: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
    _dispose();
  }

  Future<void> _dispose() async {
    await _engine.leaveChannel();
    await _engine.release();
  }

  // Create UI with local view and remote view
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Call'),
      ),
      body: Stack(
        children: [
          // Remote video - full screen
          Positioned.fill(
            child: _remoteVideo(),
          ),
          // Local video preview - top left corner
          Align(
            alignment: Alignment.topLeft,
            child: Container(
              width: 120,
              height: 160,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 2),
              ),
              clipBehavior: Clip.hardEdge,
              child: _localUserJoined
                  ? AgoraVideoView(
                      controller: VideoViewController(
                        rtcEngine: _engine,
                        canvas: const VideoCanvas(uid: 0, renderMode: RenderModeType.renderModeHidden),
                        useFlutterTexture: false,
                      ),
                    )
                  : const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
            ),
          ),
          // Debug status - top right corner
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _localUserJoined
                    ? (_remoteUid != null ? '🟢 Connected (Remote: $_remoteUid)' : '⏳ Waiting for other user...')
                    : '🔄 Joining channel...',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
          _toolbar(),
        ],
      ),
    );
  }

  // Display remote user's video
  Widget _remoteVideo() {
    if (_remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine,
          canvas: VideoCanvas(uid: _remoteUid, renderMode: RenderModeType.renderModeHidden),
          connection: RtcConnection(channelId: widget.channelName),
          useFlutterTexture: false,
        ),
      );
    } else {
      return const Center(
        child: Text(
          'Please wait for the other user to join',
          textAlign: TextAlign.center,
        ),
      );
    }
  }

  // Toolbar for Mute and End Call
  Widget _toolbar() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            RawMaterialButton(
              onPressed: _onToggleMute,
              shape: const CircleBorder(),
              elevation: 2.0,
              fillColor: _muted ? Colors.blueAccent : Colors.white,
              padding: const EdgeInsets.all(12.0),
              child: Icon(
                _muted ? Icons.mic_off : Icons.mic,
                color: _muted ? Colors.white : Colors.blueAccent,
                size: 20.0,
              ),
            ),
            RawMaterialButton(
              onPressed: () => _onCallEnd(context),
              shape: const CircleBorder(),
              elevation: 2.0,
              fillColor: Colors.redAccent,
              padding: const EdgeInsets.all(15.0),
              child: const Icon(
                Icons.call_end,
                color: Colors.white,
                size: 35.0,
              ),
            ),
            RawMaterialButton(
              onPressed: _onToggleVideo,
              shape: const CircleBorder(),
              elevation: 2.0,
              fillColor: _videoOff ? Colors.blueAccent : Colors.white,
              padding: const EdgeInsets.all(12.0),
              child: Icon(
                _videoOff ? Icons.videocam_off : Icons.videocam,
                color: _videoOff ? Colors.white : Colors.blueAccent,
                size: 20.0,
              ),
            ),
            RawMaterialButton(
              onPressed: _onSwitchCamera,
              shape: const CircleBorder(),
              elevation: 2.0,
              fillColor: Colors.white,
              padding: const EdgeInsets.all(12.0),
              child: const Icon(
                Icons.switch_camera,
                color: Colors.blueAccent,
                size: 20.0,
              ),
            )
          ],
        ),
      ),
    );
  }

  void _onCallEnd(BuildContext context) {
    Navigator.pop(context);
  }

  void _onToggleMute() {
    setState(() {
      _muted = !_muted;
    });
    _engine.muteLocalAudioStream(_muted);
  }

  void _onSwitchCamera() {
    _engine.switchCamera();
  }

  void _onToggleVideo() {
    setState(() {
      _videoOff = !_videoOff;
    });
    _engine.muteLocalVideoStream(_videoOff);
  }
}
