import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:sdp_transform/sdp_transform.dart';

import 'package:socket_io_client/socket_io_client.dart' as IO;

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _localVideoRenderer = RTCVideoRenderer();
  final _remoteVideoRenderer = RTCVideoRenderer();
  final sdpController = TextEditingController();

  late final IO.Socket socket;

  bool _offer = false;

  RTCPeerConnection? _peerConnection;
  late MediaStream _localStream;

  initRenderer() async {
    await _localVideoRenderer.initialize();
    await _remoteVideoRenderer.initialize();
  }

  _getUserMedia() async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': {
        'facingMode': 'user',
      }
    };

    MediaStream stream =
        await navigator.mediaDevices.getUserMedia(mediaConstraints);

        

    _localVideoRenderer.srcObject = stream;
    return stream;
  }

  _createPeerConnecion() async {
    Map<String, dynamic> configuration = {
      "sdpSemantics": "plan-b",
      "iceServers": [
        {"url": "stun:stun.l.google.com:19302"},
      ]
    };

    final Map<String, dynamic> offerSdpConstraints = {
      "mandatory": {
        "OfferToReceiveAudio": true,
        "OfferToReceiveVideo": true,
      },
      "optional": [],
    };

    _localStream = await _getUserMedia();

    RTCPeerConnection pc =
        await createPeerConnection(configuration, offerSdpConstraints);

    pc.addStream(_localStream);
    var send = 1;
    pc.onIceCandidate = (e) {
      // print {"candidate": ..., "sdpMid":"1", "sdpMlineIndex":1 }
      if (e.candidate != null) {
        // print(json.encode({
        //   'candidate': e.candidate.toString(),
        //   'sdpMid': e.sdpMid.toString(),
        //   'sdpMlineIndex': e.sdpMLineIndex,
        // }));
        final session = json.encode({
          'candidate': e.candidate.toString(),
          'sdpMid': e.sdpMid.toString(),
          'sdpMlineIndex': e.sdpMLineIndex,
        });
        if (send == 1 && _offer == false) {
          socket.emit('candidiate', json.encode(session));
          print(session);
          print('object');
          send += 1;
        }
      }
    };

    pc.onIceConnectionState = (e) {
      print(e);
    };
    
    pc.onAddStream = (stream) {
      print('addStream: ' + stream.id);
      _remoteVideoRenderer.srcObject = stream;
    };
    socket.emit('join');
    return pc;
  }

  _createOffer() async {
    RTCSessionDescription description =
        await _peerConnection!.createOffer({'offerToReceiveVideo': 1});
    var session = parse(description.sdp.toString());
    print(session);
    _offer = true;

    _peerConnection!.setLocalDescription(description);

    socket.emit('offer', json.encode(session));
  }

  _createAnswer() async {
    RTCSessionDescription description =
        await _peerConnection!.createAnswer({'offerToReceiveVideo': 1});

    var session = parse(description.sdp.toString());
    print('answer');

    _peerConnection!.setLocalDescription(description);

    socket.emit('answer', json.encode(session));
  }

  _setAnswerRemoteDescription({String? jsonString}) async {
    // String jsonString = sdpController.text;
    dynamic session = await jsonDecode(jsonString!);

    String sdp = write(session, null);

    RTCSessionDescription description = RTCSessionDescription(sdp, 'offer');
    print('remote offer');

    await _peerConnection!.setRemoteDescription(description);
  }

  _setOfferRemoteDescription({String? jsonString}) async {
    // String jsonString = sdpController.text;
    dynamic session = await jsonDecode(jsonString!);

    String sdp = write(session, null);

    RTCSessionDescription description = RTCSessionDescription(sdp, 'answer');
    print('remote answer');

    await _peerConnection!.setRemoteDescription(description);
  }

  _addCandidate({String? jsonString}) async {
    // String jsonString = sdpController.text;
    dynamic session = await jsonDecode(jsonString!);
    print('candidate');
    final candidate = RTCIceCandidate(
        session['candidate'], session['sdpMid'], session['sdpMlineIndex']);
    await _peerConnection!.addCandidate(candidate);
  }

  Future connection() async {
    socket = IO.io('http://192.168.1.141:4444',
        IO.OptionBuilder().setTransports(['websocket']).build());
    socket.onConnect((data) => print('Conected'));

    socket.on('joined', (data) {
      // data == 2 ? _createOffer() : print('object');
      _createOffer();
    });
    socket.on('offer', (data) async {
      // data = jsonDecode(data);
      await _setAnswerRemoteDescription(jsonString: data);
      _createAnswer();
    });
    socket.on('answer', (data) async {
      // data = jsonDecode(data);
      _setOfferRemoteDescription(jsonString: data);
    });
    socket.on('candidiate', (data) {
      _addCandidate(jsonString: data);
    });
  }

  @override
  void initState() {
    initRenderer();
    connection();
    _createPeerConnecion().then((pc) {
      _peerConnection = pc;
    });
    // _getUserMedia();
    super.initState();
  }

  @override
  void dispose() async {
    await _localVideoRenderer.dispose();
    sdpController.dispose();
    super.dispose();
  }

  SizedBox videoRenderers() => SizedBox(
        height: 210,
        child: Column(children: [
          Flexible(
            child: Container(
              key: const Key('local'),
              margin: const EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 5.0),
              decoration: const BoxDecoration(color: Colors.black),
              child: RTCVideoView(_localVideoRenderer),
            ),
          ),
          Flexible(
            child: Container(
              key: const Key('remote'),
              margin: const EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 5.0),
              decoration: const BoxDecoration(color: Colors.black),
              child: RTCVideoView(_remoteVideoRenderer),
            ),
          ),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('FuckRTC'),
        ),
        body: Column(
          children: [
            // videoRenderers(),
            Container(
              height: 240,
              key: const Key('local'),
              margin: const EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 5.0),
              decoration: const BoxDecoration(color: Colors.black),
              child: RTCVideoView(_localVideoRenderer),
            ),
            Container(
              height: 240,
              key: const Key('remote'),
              margin: const EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 5.0),
              decoration: const BoxDecoration(color: Colors.black),
              child: RTCVideoView(_remoteVideoRenderer),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _createOffer,
                  child: const Text("Offer"),
                ),
                const SizedBox(
                  height: 10,
                ),
                ElevatedButton(
                  onPressed: _createAnswer,
                  child: const Text("Answer"),
                ),
                const SizedBox(
                  height: 10,
                ),
                ElevatedButton(
                  onPressed: _setOfferRemoteDescription,
                  child: const Text("Set Remote Description"),
                ),
                const SizedBox(
                  height: 10,
                ),
                ElevatedButton(
                  onPressed: _addCandidate,
                  child: const Text("Set Candidate"),
                ),
              ],
            ),
          ],
        ));
  }
}