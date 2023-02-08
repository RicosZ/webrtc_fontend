import 'package:get/get.dart';
import 'package:webrtc_fontend/bindings/home_binding.dart';
import 'package:webrtc_fontend/bindings/loby_binding.dart';
import 'package:webrtc_fontend/bindings/meeting_binding.dart';
import 'package:webrtc_fontend/homepage.dart';
import 'package:webrtc_fontend/views/home_view.dart';
import 'package:webrtc_fontend/views/meeting_view.dart';

class AppPage {
  static var routes = [
    //ถ้ามี binding ก็ใส่ลงไปในนี้เลย
    GetPage(
      name: '/home',
      page: () => HomePage(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: '/loby',
      page: () => HomePagetest(),
      binding: LobyBinding(),
    ),
    GetPage(
      name: '/meeting',
      page: () => MeetingPage(),
      binding: MeetingBinding(),
    ),
  ];
}
