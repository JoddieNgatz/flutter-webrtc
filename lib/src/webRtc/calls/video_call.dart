import 'package:flutter/material.dart';
import 'dart:core';
import 'signaling.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class CallSample extends StatefulWidget {
  static String tag = 'call_sample';
  final String host;
  CallSample({this.host});

  @override
  _CallSampleState createState() => _CallSampleState();
}

class _CallSampleState extends State<CallSample> {
  Signaling _signaling;
  List<dynamic> _peers = [];
  String _selfId = 'hosters id';
  RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  bool _inCalling = false;
  Session _session;

  bool _waitAccept = false;
  bool _localUserJoined = false;
  // ignore: unused_element
  _CallSampleState();

  String chanelId = '';
  bool enableTextChat = true;
  bool _remoteUserJoined = false;
  bool muted = false;
  bool videoMuted = false;
  String hosteeId = '';
  String hosterId = '';
  bool audio = false;
  bool inviteSent = false;

  @override
  initState() {
    super.initState();

    initRenderers();
  }

  initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    _connect();
  }

  @override
  deactivate() {
    super.deactivate();
    _signaling?.close();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
  }

  void _connect() async {
    _signaling ??= Signaling()..connect(false, hosteeId, hosterId);
    _signaling?.onSignalingStateChange = (SignalingState state) {
      switch (state) {
        case SignalingState.ConnectionClosed:
        case SignalingState.ConnectionError:
        case SignalingState.ConnectionOpen:
          break;
      }
    };

    _signaling?.onCallStateChange = (Session session, CallState state) async {
      switch (state) {
        case CallState.CallStateNew:
          if (mounted) {
            setState(() {
              _session = session;
            });
          }
          break;
        case CallState.CallStateRinging:
          _accept(session);
          if (mounted) {
            setState(() {
              _inCalling = true;
            });
          }
          break;
        case CallState.CallStateBye:
          if (_waitAccept) {
            _localUserJoined = false;
            _waitAccept = false;
            Navigator.of(context).pop(false);
          }
          if (mounted) {
            setState(() {
              _localRenderer.srcObject = null;
              _remoteRenderer.srcObject = null;
              _inCalling = false;
              _session = null;
            });
          }
          break;
        case CallState.CallStateInvite:
          _waitAccept = true;

          break;
        case CallState.CallStateConnected:
          if (_waitAccept) {
            _waitAccept = false;
          }
          if (mounted) {
            setState(() {
              _inCalling = true;
            });
          }
          break;
      }
    };

    _signaling?.onPeersUpdate = ((event) {
      if (mounted) {
        setState(() {
          _peers = event['peers'];
          debugPrint('peers length **** ${_peers.length}');
          // try {
          //   if (_remoteUserJoined != true && _peers.length > 1) {
          //     while (!inviteSent) {
          //       for (var i = 0; i < _peers.length; i++) {
          //         if (_peers[i]['id'].contains(providerId)) {
          //           debugPrint('sending invite to peer: $providerId');
          //           _invitePeer(context, providerId, false, _selfId);
          //           break;
          //         }
          //       }
          //     }
          //   }
          // } catch (e) {
          //   debugPrint('peers invite error: ${e.toString()}');
          // }
        });
      }
    });

    _signaling?.onLocalStream = ((stream) {
      _localRenderer.srcObject = stream;
      if (mounted) {
        setState(() {
          _localUserJoined = true;
        });
      }
    });

    _signaling?.onAddRemoteStream = ((_, stream) {
      _remoteRenderer.srcObject = stream;
      if (mounted) {
        setState(() {
          _remoteUserJoined = true;
        });
      }
    });

    _signaling?.onRemoveRemoteStream = ((_, stream) {
      _remoteRenderer.srcObject = null;
      if (mounted) {
        setState(() {
          _remoteUserJoined = false;
        });
      }
    });
  }

  BoxDecoration myBoxDecoration() {
    return BoxDecoration(
      border: Border.all(
        width: 2,
        color: Colors.white,
      ),
    );
  }

  /// Toolbar layout
  Widget _toolbar() {
    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          RawMaterialButton(
            onPressed: _muteMic,
            child: Icon(
              muted ? Icons.mic_off : Icons.mic,
              color: muted ? Colors.white : Colors.blueAccent,
              size: 20.0,
            ),
            shape: CircleBorder(),
            elevation: 2.0,
            fillColor: muted ? Colors.blueAccent : Colors.white,
            padding: const EdgeInsets.all(12.0),
          ),
          RawMaterialButton(
            onPressed: _onToggleVideo,
            child: Icon(
              videoMuted ? Icons.videocam_off : Icons.videocam,
              color: videoMuted ? Colors.white : Colors.blueAccent,
              size: 20.0,
            ),
            shape: CircleBorder(),
            elevation: 2.0,
            fillColor: videoMuted ? Colors.blueAccent : Colors.white,
            padding: const EdgeInsets.all(12.0),
          ),
          RawMaterialButton(
            onPressed: () async {
              await _hangUp();
              Navigator.pop(context);
              debugPrint('hang up');
            },
            child: Icon(
              Icons.call_end,
              color: Colors.white,
              size: 35.0,
            ),
            shape: CircleBorder(),
            elevation: 2.0,
            fillColor: Colors.redAccent,
            padding: const EdgeInsets.all(15.0),
          ),
          RawMaterialButton(
            onPressed: _switchCamera,
            child: Icon(
              Icons.switch_camera,
              color: Colors.blueAccent,
              size: 20.0,
            ),
            shape: CircleBorder(),
            elevation: 2.0,
            fillColor: Colors.white,
            padding: const EdgeInsets.all(12.0),
          ),
        ],
      ),
    );
  }

  _invitePeer(BuildContext context, String peerId, bool useScreen,
      String hosteeId) async {
    inviteSent = true;
    if (_signaling != null && peerId != _selfId && peerId != null) {
      _signaling?.invite(peerId, chanelId, 'video', useScreen, _selfId);
    }
  }

  _accept(session) async {
    if (session != null) {
      debugPrint('Session pid: ${_session.pid} is $hosterId ?');
      if (_session.sid.contains(chanelId)) {
        debugPrint('Accept session for  ${session.sid}');
        await _signaling.accept(_session.sid, hosteeId);
      }
    }
  }

  _hangUp() {
    if (_session != null) {
      _signaling.bye(_session.sid, hosteeId);
    }
  }

  _switchCamera() async {
    _signaling.switchCamera();
  }

  _onToggleVideo() async {
    if (mounted) {
      setState(() {
        videoMuted = !videoMuted;
        _localUserJoined = true;
      });
    }

    await _signaling.turnOffCamera();
  }

  _muteMic() {
    if (mounted) {
      setState(() {
        muted = !muted;
      });
    }
    _signaling.muteMic();
  }

// Display remote user's video
  Widget _remoteVideo() {
    if (_remoteUserJoined) {
      return RTCVideoView(_remoteRenderer);
    } else {
      return Column(children: [
        SizedBox(
          height: 400,
        ),
        SizedBox(
          height: 10,
        ),
        Text(
          'Please wait for your invitee to join',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white),
        ),
      ]);
    }
  }

  // Display local user's video
  Widget _localVideo() {
    if (_localUserJoined) {
      return videoMuted
          ? Icon(
              Icons.videocam_off,
              color: Colors.white,
              size: 22.0,
            )
          : RTCVideoView(_localRenderer, mirror: true);
    } else {
      return CircularProgressIndicator();
    }
  }

  @override
  Widget build(BuildContext context) {
    double statusBarHeight = MediaQuery.of(context).padding.top;
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return WillPopScope(
      onWillPop: () async {
        await _hangUp();
        return true;
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        body: Center(
          child: Stack(
            children: <Widget>[
              Center(
                child: _remoteVideo(),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _toolbar(),
                ],
              ),
              Positioned(
                top: statusBarHeight + 10,
                right: 10,
                child: Container(
                  width: 100,
                  height: 150,
                  decoration: myBoxDecoration(),
                  child: Center(
                    child: _localVideo(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
