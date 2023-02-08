import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webrtc_fontend/bindings/home_binding.dart';
import 'package:webrtc_fontend/routes/app_pages.dart';
import 'package:webrtc_fontend/views/home_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'FuckRTC',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
      initialBinding: HomeBinding(),
      //initialRoute: '/',// Route เริ่มต้น
      //unknownRoute: GetPage(name : '/notfound',page: (() => UnknownRoutePage())), //กรณีไม่มี Route ที่อยู่ใน GetPage
      getPages: AppPage.routes,
      //locale
    );
  }
}
