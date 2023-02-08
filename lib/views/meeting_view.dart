import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import 'package:webrtc_fontend/controllers/meting_controller.dart';

class MeetingPage extends GetView<MeetingController> {
  const MeetingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Obx(
            () => Container(
              child: controller.remoteConnected.value
                  ? RTCVideoView(controller.remoteVideoRenderer)
                  : const Center(
                      child: Padding(
                        padding: EdgeInsets.all(10),
                        child: Text(
                          'Waiting .......',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 24,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          Positioned(
            bottom: 10,
            right: 0,
            child: Obx(() => SizedBox(
                  width: 150,
                  height: 200,
                  child: controller.openCamera.value
                      ? RTCVideoView(controller.localVideoRenderer)
                      : Container(),
                )),
          )
        ],
      ),
      bottomNavigationBar: Container(
        color: Colors.blueGrey[900],
        height: 60,
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          ElevatedButton(
            child: Text('offer'),
            onPressed: () {
              controller.createOffer();
            },
          ),
          ElevatedButton(
            child: Text('refresh remote state'),
            onPressed: () {
              controller.remoteConnected(true);
            },
          ),
        ]),
      ),
    );
  }
}
