import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class HomePagetest extends StatefulWidget {
  const HomePagetest({super.key});

  @override
  State<HomePagetest> createState() => _HomePagetestState();
}

class _HomePagetestState extends State<HomePagetest> {
  late final IO.Socket socket;
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();
  MediaStream? _localStream;
  RTCPeerConnection? pc;

  @override
  void initState() {
    init();
    super.initState();
  }

  Future init() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    await connection();
    await joinRoom();
  }

  Future connection() async {
    socket = IO.io('http://192.168.1.141:4444',
        IO.OptionBuilder().setTransports(['websocket']).build());
    socket.onConnect((data) => print('Conected'));

    socket.on('joined', (data) {
      _sendOffer();
    });
    socket.on('offer', (data) async {
      data = jsonDecode(data);
      await _gotOffer(RTCSessionDescription(data['sdp'], data['type']));
      await _sendAnswer();
    });
    socket.on('answer', (data) {
      data = jsonDecode(data);
      _gotAnswer(RTCSessionDescription(data['sdp'], data['type']));
    });
    socket.on('ice', (data) {
      // print('aaaaaaaaaaaaaaaaaaaaaaaaa${data['candidate'].runtimeType}');
      // print(data['sdpMid'].runtimeType);
      // print(data['sdpMLineIndex'].runtimeType);
      _gotIce(RTCIceCandidate(
          data['candidate'], data['sdpMid'], int.parse(data['sdpMLineIndex'])));
    });
  }

  Future joinRoom() async {
    final config = {
      'iceServer': [
        {
          'url': 'stun:stun.l.google.com:19302',
        },
      ]
    };

    final sdpCnstraints = {
      'mandatory': {
        // 'OfferToReciveAudio': true,
        // 'OfferToReciveVideo': true,
      },
      'optional': [
        {'DtlsSrtpKeyAgreement': true}
      ]
    };
    pc = await createPeerConnection(config, sdpCnstraints);

    final mediaConstraints = {
      'audio': true,
      'video': {'facingMode': 'user'},
    };

    _localStream = await Helper.openCamera(mediaConstraints);
    _localStream!.getTracks().forEach((track) {
      pc!.addTrack(track, _localStream!);
    });

    _localRenderer.srcObject = _localStream;

    pc!.onIceCandidate = (candidate) {
      _sendIce(candidate);
    };
    pc!.onAddStream = (stream) {
      _remoteRenderer.srcObject = stream;
    };

    socket.emit('join');
  }

  Future _sendOffer() async {
    print('send offer');
    var offer = await pc!.createOffer();
    pc!.setLocalDescription(offer);
    socket.emit('offer', jsonEncode(offer.toMap()));
  }

  Future _gotOffer(RTCSessionDescription offer) async {
    print('got offer: $offer');
    pc!.setLocalDescription(offer);
  }

  Future _sendAnswer() async {
    print('send answer');
    var answer = await pc!.createAnswer();
    socket.emit('answer', jsonEncode(answer.toMap()));
  }

  Future _gotAnswer(RTCSessionDescription answer) async {
    print('got answer: $answer');
    pc!.setRemoteDescription(answer);
  }

  Future _sendIce(RTCIceCandidate ice) async {
    print('send Ice: $ice');
    socket.emit('ice', jsonEncode(ice.toMap()));
  }

  Future _gotIce(RTCIceCandidate ice) async {
    print('got ice: $ice');
    pc!.addCandidate(ice);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Row(
        children: [
          Expanded(child: RTCVideoView(_localRenderer)),
          Expanded(child: RTCVideoView(_remoteRenderer)),
        ],
      ),
    );
  }
}
