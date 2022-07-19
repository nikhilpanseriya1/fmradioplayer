import 'package:flutter/material.dart';
import 'package:fmradioplayer/utility/constant.dart';

class FavoritePlayListScreen extends StatefulWidget {
  const FavoritePlayListScreen({Key? key}) : super(key: key);

  @override
  State<FavoritePlayListScreen> createState() => _FavoritePlayListScreenState();
}

class _FavoritePlayListScreenState extends State<FavoritePlayListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
/*      body: ListView.builder(
          itemCount: kPlayAudioController.audioStoreList.length,
          itemBuilder: (context, index) {
        return ListTile(
          onTap: () {},
          title:
          Text(kPlayAudioController.audioStoreList[index].),
          subtitle: Text(widget.flag == true
              ? (kHomeController.audioList[index].artist ?? '')
              : item.data![index].artist ?? "No Artist"),
          trailing: const Icon(Icons.music_note_sharp),
          leading: QueryArtworkWidget(
            id: item.data![index].id,
            type: ArtworkType.AUDIO,
            nullArtworkWidget: Image.asset('assets/images/audio_icon.png',
                scale: 3.5, color: colorGrey),
            quality: 100,
          ),
        );
      }),*/
    );
  }
}
