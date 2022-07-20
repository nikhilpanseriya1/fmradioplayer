import 'package:flutter/material.dart';
import 'package:fmradioplayer/utility/constant.dart';

class FavoriteListScreen extends StatefulWidget {
  const FavoriteListScreen({Key? key}) : super(key: key);

  @override
  State<FavoriteListScreen> createState() => _FavoriteListScreenState();
}

class _FavoriteListScreenState extends State<FavoriteListScreen> {
  List<dynamic> playList = [];

  @override
  void initState() {
    for (int i = 0; i < kHomeController.audioList.length; i++) {
      if (kHomeController.audioList[i].audioUrl!.contains(kPlayAudioController.audioStoreList[0])) {
        playList.add(i);
      }
    }
    print('yoyoyoyoyoyo${playList.length}');
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
          itemCount: playList.length,
          itemBuilder: (context, index) {
            return ListTile(
                // title: playList,
                );
          }),
    );
  }
}
