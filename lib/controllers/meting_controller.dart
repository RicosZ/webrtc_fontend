import 'dart:convert';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';

import 'package:sdp_transform/sdp_transform.dart';

import 'package:socket_io_client/socket_io_client.dart' as IO;

class MeetingController extends GetxController {
  var openCamera = false.obs;
  var remoteConnected = false.obs;

  final localVideoRenderer = RTCVideoRenderer();
  final remoteVideoRenderer = RTCVideoRenderer();
  RTCPeerConnection? _peerConnection;
  late MediaStream _localStream;

  late final IO.Socket socket;

  var offer = false.obs;

  @override
  Future<void> onInit() async {
    await localVideoRenderer.initialize();
    await remoteVideoRenderer.initialize();
    await connection();
    await _createPeerConnecion().then((pc) {
      _peerConnection = pc;
    });
    super.onInit();
  }

  @override
  Future<void> onReady() async {
    super.onReady();
  }

  @override
  void onClose() {
    localVideoRenderer.dispose();
  }

  getUserMedia() async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': {
        'facingMode': 'user',
      }
    };

    MediaStream stream = await Helper.openCamera(mediaConstraints);

    localVideoRenderer.srcObject = stream;
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

    _localStream = await getUserMedia();

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
        if (send == 1 && offer.value == false) {
          socket.emit('candidiate', json.encode(session));
          print(session);
          // print('object');
          send += 1;
        }
      }
    };
    pc.onIceConnectionState = (e) {
      print(e);
    };

    pc.onAddStream = (stream) {
      // print('addStream: ' + stream.id);
      remoteVideoRenderer.srcObject = stream;
    };
    socket.emit('join');
    openCamera(true);
    return pc;
  }

  createOffer() async {
    RTCSessionDescription description =
        await _peerConnection!.createOffer({'offerToReceiveVideo': 1});
    var session = parse(description.sdp.toString());
    print(session);
    offer.value = true;

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
    socket = IO.io('https://rtc-backend-vs6r.onrender.com',
        IO.OptionBuilder().setTransports(['websocket']).build());
    socket.onConnect((data) => print('Conected'));

    socket.on('joined', (data) {
      // data == 2 ? _createOffer() : print('object');
      // remoteConnected(true);
      createOffer();
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
}
