import 'package:get/get.dart';
import 'package:webrtc_fontend/controllers/loby_controller.dart';

class LobyBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => LobyController());
  }
}