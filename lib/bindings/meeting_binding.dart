import 'package:get/get.dart';
import 'package:webrtc_fontend/controllers/meting_controller.dart';

class MeetingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => MeetingController());
  }
}