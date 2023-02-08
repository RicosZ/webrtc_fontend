import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('RTCHome')),
      body: Column(
        children: [
          const Align(
            alignment: Alignment.center,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 40, 0, 0),
            child: ElevatedButton.icon(
              onPressed: () {
                Get.toNamed('/meeting');
              },
              icon: const Icon(Icons.chat),
              label: const Text('Start RTC'),
              style: ElevatedButton.styleFrom(
                fixedSize: const Size(350, 30),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
