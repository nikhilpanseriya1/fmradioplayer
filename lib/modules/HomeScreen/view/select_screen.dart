import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fmradioplayer/modules/HomeScreen/view/home_screen.dart';
import 'package:fmradioplayer/utility/color_utility.dart';
import 'package:get/get.dart';

class SelectScreen extends StatefulWidget {
  const SelectScreen({Key? key}) : super(key: key);

  @override
  State<SelectScreen> createState() => _SelectScreenState();
}

class _SelectScreenState extends State<SelectScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('FM Music Library'),
          backgroundColor: Color(0x000000)),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  InkWell(
                    onTap: () {
                      Get.to(() => HomeScreen(flag: true));
                    },
                    child: Image.asset(
                      'assets/images/music.jpeg',
                      fit: BoxFit.cover,
                      height: 180,
                      width: 180,
                    ),
                  ),
                  const SizedBox(
                    height: 8.0,
                  ),
                  const Text(
                    'Online Songs',
                    style: TextStyle(fontSize: 15),
                  )
                ],
              ),
              const SizedBox(
                width: 10,
              ),
              Column(
                children: [
                  InkWell(
                    onTap: () {
                      Get.to(() => HomeScreen());
                    },
                    child: Image.asset(
                      'assets/images/music2.jpeg',
                      fit: BoxFit.fill,
                      height: 180.0,
                      width: 180.0,
                    ),
                  ),
                  const SizedBox(
                    height: 8.0,
                  ),
                  const Text(
                    'Offline Songs',
                    style: TextStyle(fontSize: 15.0),
                  )
                ],
              ),
            ],
          ),
          const SizedBox(
            width: 10,
          ),
          Column(
            children: [
              InkWell(
                  onTap: () {
                    Get.to(() => () {});
                  },
                  child: const Icon(
                    CupertinoIcons.heart_circle_fill,
                    color: colorRed,
                    size: 100,
                  )),
              /*Image.asset(
                  'assets/images/music2.jpeg',
                  fit: BoxFit.fill,
                  height: 180.0,
                  width: 180.0,
                ),
              ),*/
              const SizedBox(
                height: 8.0,
              ),
              const Text(
                'Favorite Songs,',
                style: TextStyle(fontSize: 15.0),
              )
            ],
          )
        ],
      ),
    );
  }
}
