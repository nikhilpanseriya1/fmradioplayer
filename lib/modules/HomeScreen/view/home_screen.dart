import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fmradioplayer/modules/HomeScreen/controller/home_controller.dart';
import 'package:fmradioplayer/modules/PlayAudio/view/play_audio.dart';
import 'package:fmradioplayer/utility/color_utility.dart';
import 'package:fmradioplayer/utility/constant.dart';
import 'package:get/get.dart';
import 'package:on_audio_query/on_audio_query.dart';

RxList<String> allSongs = [''].obs;
RxList<String> allTitle = [''].obs;

class HomeScreen extends StatefulWidget {
  bool? flag;

  HomeScreen({Key? key, this.flag}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  @override
  void initState() {
    super.initState();
    requestPermission();
  }

  requestPermission() async {
    if (!kIsWeb) {
      bool permissionStatus = await _audioQuery.permissionsStatus();
      if (!permissionStatus) {
        await _audioQuery.permissionsRequest();
      }
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Music Library"),
        backgroundColor: colorRed,
        elevation: 2,
      ),
      body: FutureBuilder<List<SongModel>>(
        // Default values:
        future: _audioQuery.querySongs(
          sortType: null,
          orderType: OrderType.ASC_OR_SMALLER,
          uriType: UriType.EXTERNAL,
          ignoreCase: true,
        ),

        builder: (context, item) {
          if (item.data == null) {
            return const Center(
                child: CircularProgressIndicator(
              color: colorRed,
            ));
          }

          if (item.data != null) {
            kHomeController.audioDetails.clear();
            item.data?.forEach((element) {
            kHomeController.audioDetails.add(AudioData(title: element.title,audioUrl: element.data,artist: element.artist,img: element.id));
          });

          }

          if (item.data!.isEmpty) return const Text("Nothing found!");

          return ListView.builder(
            itemCount: widget.flag == true
                ? kHomeController.audioList.length
                : item.data?.length,
            itemBuilder: (context, index) {
              return ListTile(
                onTap: () {
                  Get.to(() => PlayAudio(
                        audio: widget.flag == true
                            ? kHomeController.audioList[index].audioUrl
                            : item.data?[index].data,
                        image: item.data?[index].id,
                        title: widget.flag == true
                            ? kHomeController.audioList[index].title
                            : item.data?[index].title,
                        artist: widget.flag == true
                            ? kHomeController.audioList[index].artist
                            : item.data?[index].artist,
                        flag: widget.flag,
                        index: index,
                      ));
                  // print('{}{}{}{}{}{{}{${item.data?[index].uri}');
                },
                title: Text(widget.flag == true
                    ? (kHomeController. audioList[index].title ?? '')
                    : item.data?[index].title ?? ''),
                subtitle: Text(widget.flag == true
                    ? (kHomeController.audioList[index].artist ?? '')
                    : item.data![index].artist ?? "No Artist"),
                trailing: const Icon(Icons.music_note_sharp),
                leading: QueryArtworkWidget(
                  id: item.data![index].id,
                  type: ArtworkType.AUDIO,
                  nullArtworkWidget: Image.asset('assets/images/audio_icon.png',scale: 3.5,color: colorGrey),
                  quality: 100,

                ),
              );
            },
          );
        },
      ),
    );
  }
}
