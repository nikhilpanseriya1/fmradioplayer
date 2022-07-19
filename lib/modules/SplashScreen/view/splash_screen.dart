import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fmradioplayer/utility/color_utility.dart';
import 'package:get/get.dart';

import '../../HomeScreen/view/select_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  initState() {
    Timer(const Duration(seconds: 2), () {
      Get.offAll(() => const SelectScreen());
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.my_library_music_rounded, color: colorRed, size: 100),
          SizedBox(height: 10.0,),
          Text('FM Music Player',
              style: TextStyle(color: colorRed, fontSize: 20.0)),
        ],
      ),
    ));
  }
}
