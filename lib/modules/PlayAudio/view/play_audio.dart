import 'dart:io';
import 'dart:math';
import 'package:audio_session/audio_session.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:fmradioplayer/modules/HomeScreen/view/notification.dart';
import 'package:fmradioplayer/modules/PlayAudio/view/example_effects.dart';
import 'package:fmradioplayer/utility/color_utility.dart';
import 'package:fmradioplayer/utility/common_method.dart';
import 'package:fmradioplayer/utility/constant.dart';
import 'package:get/get.dart' as get_x;
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:share_plus/share_plus.dart';

// ignore: must_be_immutable
class PlayAudio extends StatefulWidget {
  String? audio;
  String? artist;
  String? title;
  int? image;
  bool? flag;
  int index;

  PlayAudio(
      {Key? key,
      this.audio,
      this.image,
      this.artist,
      this.title,
      this.flag,
      required this.index})
      : super(key: key);

  @override
  State<PlayAudio> createState() => _PlayAudioState();
}

class _PlayAudioState extends State<PlayAudio> with WidgetsBindingObserver {
  late AudioPlayer _player;
  get_x.RxString progressString = ''.obs;
  get_x.RxDouble progressPercentage = 0.0.obs;
  String? imageDownloadPath;
  File? file;
  get_x.RxBool isSoundVisible = false.obs;
  get_x.RxBool downloading = false.obs;
  Dio dio = Dio();
  int audioIndex = 0;
  get_x.RxBool? click = false.obs;
  get_x.RxDouble? receivedData;
  get_x.RxBool likeBool = false.obs;

  final _playlist = ConcatenatingAudioSource(children: [
    if (kIsWeb ||
        ![TargetPlatform.windows, TargetPlatform.linux]
            .contains(defaultTargetPlatform))
      ClippingAudioSource(
        start: const Duration(seconds: 60),
        end: const Duration(seconds: 90),
        child: AudioSource.uri(Uri.parse(
            "https://s3.amazonaws.com/scifri-episodes/scifri20181123-episode.mp3")),
        tag: AudioMetadata(
          album: "Science Friday",
          title: "A Salute To Head-Scratching Science (30 seconds)",
          artwork:
              "https://media.wnyc.org/i/1400/1400/l/80/1/ScienceFriday_WNYCStudios_1400.jpg",
        ),
      ),
    AudioSource.uri(
      Uri.parse(
          "https://s3.amazonaws.com/scifri-episodes/scifri20181123-episode.mp3"),
      tag: AudioMetadata(
        album: "Science Friday",
        title: "A Salute To Head-Scratching Science",
        artwork:
            "https://media.wnyc.org/i/1400/1400/l/80/1/ScienceFriday_WNYCStudios_1400.jpg",
      ),
    ),
    AudioSource.uri(
      Uri.parse("https://s3.amazonaws.com/scifri-segments/scifri201711241.mp3"),
      tag: AudioMetadata(
        album: "Science Friday",
        title: "From Cat Rheology To Operatic Incompetence",
        artwork:
            "https://media.wnyc.org/i/1400/1400/l/80/1/ScienceFriday_WNYCStudios_1400.jpg",
      ),
    ),
    AudioSource.uri(
      Uri.parse("asset:///audio/nature.mp3"),
      tag: AudioMetadata(
        album: "Public Domain",
        title: "Nature Sounds",
        artwork:
            "https://media.wnyc.org/i/1400/1400/l/80/1/ScienceFriday_WNYCStudios_1400.jpg",
      ),
    ),
  ]);

  Future<void> _init({required String audioUrl}) async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
    // Listen to errors during playback.
    _player.playbackEventStream.listen((event) {},
        onError: (Object e, StackTrace stackTrace) {
      print('A stream error occurred: $e');
    });
    try {
      // Preloading audio is not currently supported on Linux.
      await _player.setAudioSource(
          widget.flag == true
              ? AudioSource.uri(Uri.parse(audioUrl /*widget.audio*/))
              // ? AudioSource.uri(Uri.parse(/*'https://s3.amazonaws.com/scifri-episodes/scifri20181123-episode.mp3'*/ audioUrl))
              : AudioSource.uri(Uri.file(audioUrl /*widget.audio*/)),
          preload: kIsWeb || defaultTargetPlatform != TargetPlatform.linux);
    } catch (e) {
      // Catch load errors: 404, invalid url...
      print("Error loading audio source: $e");
    }
  }

  @override
  void dispose() {
    ambiguate(WidgetsBinding.instance)?.removeObserver(this);
    _player.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Release the player's resources when not in use. We use "stop" so that
      // if the app resumes later, it will still remember what position to
      // resume from.
      _player.stop();
    }
  }

  Stream<PositionData> get _positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
          _player.positionStream,
          _player.bufferedPositionStream,
          _player.durationStream,
          (position, bufferedPosition, duration) => PositionData(
              position, bufferedPosition, duration ?? Duration.zero));

  final _equalizer = AndroidEqualizer();
  final _loudnessEnhancer = AndroidLoudnessEnhancer();

  @override
  void initState() {
    super.initState();

    tz.initializeTimeZones();

    audioIndex = widget.index;

    ambiguate(WidgetsBinding.instance)?.addObserver(this);

    _player = AudioPlayer(
      audioPipeline: AudioPipeline(
        androidAudioEffects: [
          _loudnessEnhancer,
          _equalizer,
        ],
      ),
    );

    _player.play();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
    ));

    _init(
        audioUrl: widget.flag == true
            ? (kHomeController.audioList[widget.index].audioUrl ?? '')
            : kHomeController.audioDetails[widget.index].audioUrl ?? '');

    kPlayAudioController.audioStoreList = getStorageValue('mySongs') ?? [];
    likeBool.value = kPlayAudioController.audioStoreList
            .contains(kHomeController.audioList[widget.index].audioUrl)
        ? true
        : false;

    // print('opopopop${audioStoreList}');
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        bool exit = isSoundVisible.value;
        isSoundVisible.value = false;
        return Future<bool>.value(!exit ? true : false);
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: StreamBuilder<SequenceState?>(
                      stream: _player.sequenceStateStream,
                      builder: (context, snapshot) {
                        final state = snapshot.data;
                        if (state?.sequence.isEmpty ?? true) {
                          return const SizedBox();
                        }
                        // final metadata = state?.currentSource?.tag as AudioMetadata;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Center(
                                  child: QueryArtworkWidget(
                                    quality: 100,
                                    artworkFit: BoxFit.fitWidth,
                                    artworkHeight: 500,
                                    artworkWidth: 500,
                                    artworkBorder: BorderRadius.zero,
                                    id: kHomeController
                                            .audioDetails[audioIndex].img ??
                                        0,
                                    nullArtworkWidget: Image.asset(
                                        'assets/images/audio_icon.png',
                                        color: colorGrey,
                                        fit: BoxFit.fitHeight),
                                    type: ArtworkType.AUDIO,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 5.0),
                              child: Text(
                                widget.flag == true
                                    ? (kHomeController
                                            .audioList[audioIndex].title ??
                                        '')
                                    : kHomeController
                                            .audioDetails[audioIndex].title ??
                                        '',
                                style: Theme.of(context)
                                    .textTheme
                                    .headline6
                                    ?.copyWith(height: 1.5),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(
                              height: 5.0,
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(kHomeController
                                      .audioDetails[audioIndex].artist ??
                                  ''),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  ControlButtonsBottom(
                      context,
                      _player,
                      widget.flag == true
                          ? (kHomeController.audioList[widget.index].audioUrl ??
                              '')
                          : kHomeController.audioDetails[widget.index].audioUrl ??
                              '',
                      widget.flag == true
                          ? (kHomeController.audioList[widget.index].title ??
                              '')
                          : kHomeController.audioDetails[widget.index].title ??
                              '',
                      widget.flag == true
                          ? (kHomeController.audioList[widget.index].img ?? 0)
                          : kHomeController.audioDetails[widget.index].img ?? 0,
                      widget.flag == true
                          ? (kHomeController.audioList[widget.index].artist ??
                              '')
                          : kHomeController.audioDetails[widget.index].artist ??
                              ''),
                  StreamBuilder<PositionData>(
                    stream: _positionDataStream,
                    builder: (context, snapshot) {
                      final positionData = snapshot.data;
                      return SeekBar(
                        duration: positionData?.duration ?? Duration.zero,
                        position: positionData?.position ?? Duration.zero,
                        bufferedPosition:
                            positionData?.bufferedPosition ?? Duration.zero,
                        onChangeEnd: (newPosition) {
                          _player.seek(newPosition);
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      StreamBuilder<LoopMode>(
                        stream: _player.loopModeStream,
                        builder: (context, snapshot) {
                          final loopMode = snapshot.data ?? LoopMode.off;
                          const icons = [
                            Icon(Icons.repeat, color: Colors.grey),
                            Icon(Icons.repeat, color: Colors.orange),
                            Icon(Icons.repeat_one, color: Colors.orange),
                          ];
                          const cycleModes = [
                            LoopMode.off,
                            LoopMode.all,
                            LoopMode.one,
                          ];
                          final index = cycleModes.indexOf(loopMode);
                          return Expanded(
                            child: IconButton(
                              icon: icons[index],
                              onPressed: () {
                                _player.setLoopMode(cycleModes[
                                    (cycleModes.indexOf(loopMode) + 1) %
                                        cycleModes.length]);
                                print('oioioioioioioii${_player.loopMode}');
                              },
                            ),
                          );
                        },
                      ),
                      Expanded(
                        child: IconButton(
                            onPressed: () {
                              widget.flag == true
                                  ? file != null
                                      ? Sharefile()
                                      : Fluttertoast.showToast(
                                          msg: 'Download First')
                                  : Share.shareFiles([
                                      kHomeController.audioDetails[audioIndex]
                                              .audioUrl ??
                                          ''
                                    ]);
                            },
                            icon: const Icon(
                              Icons.share,
                              color: Colors.grey,
                            )),
                      ),
                      Expanded(
                        child: IconButton(
                            onPressed: () {
                              isSoundVisible.value = true;
                            },
                            icon: const Icon(
                              Icons.waves,
                              color: Colors.grey,
                            )),
                      ),
                      /*widget.flag == true
                          ?*/
                      Visibility(
                        visible: widget.flag ?? false,
                        child: get_x.Obx(() {
                          return Expanded(
                            child: click?.value == false
                                ? IconButton(
                                    onPressed: () async {
                                      try {
                                        var dir =
                                            await getExternalStorageDirectory();
                                        file = File(
                                            '${dir?.path}/${kHomeController.audioList[audioIndex].title}.mp3');
                                        if (await File(file?.path ?? '')
                                            .exists()) {
                                          Fluttertoast.showToast(
                                              msg: "Song is Already Downloaded",
                                              toastLength: Toast.LENGTH_SHORT,
                                              gravity: ToastGravity.BOTTOM,
                                              timeInSecForIosWeb: 1,
                                              backgroundColor: Colors.black,
                                              textColor: Colors.white,
                                              fontSize: 16.0);
                                        } else {
                                          click?.value = true;
                                          await dio.download(
                                              kHomeController
                                                      .audioList[audioIndex]
                                                      .audioUrl ??
                                                  '',
                                              file?.path, onReceiveProgress:
                                                  (received, total) {
                                            receivedData?.value =
                                                total.toDouble();
                                            print(
                                                ':::::::::::>${receivedData?.value}');
                                            downloading.value = true;
                                            progressString.value =
                                                ((received / total) * 100)
                                                    .toStringAsFixed(0);

                                            // progressPercentage.value =
                                            //     double.parse(
                                            //         ((received / total) * 100)
                                            //             .toStringAsFixed(0));

                                            print('chichcihcihcihi>>  $total');
                                            print(
                                                'lololololololol>>  $received');
                                            NotificationService()
                                                .showNotification(
                                                    1,
                                                    "Notification",
                                                    "Download Complete..",
                                                    1);
                                          });
                                        }
                                      } catch (e) {
                                        print(e);
                                      }
                                      downloading.value = false;
                                      // return imageDownloadPath;

                                      // download2(dio, widget.audio, fullPath);
                                    },
                                    icon: const Icon(
                                      Icons.download_for_offline_outlined,
                                    ),
                                    color: Colors.grey,
                                  )
                                : CircularPercentIndicator(
                                    radius: 20.0,
                                    lineWidth: 5.0,
                                    animation: false,
                                    percent: progressString.value != ''
                                        ? (double.parse(progressString.value) /
                                            100)
                                        : 0.0,
                                    center: Text('${progressString.value}%',
                                        style: const TextStyle(fontSize: 10)),
                                    progressColor: Colors.green,
                                  ),
                          );
                        }),
                      )
                      /* : const SizedBox()*/

                      /* Expanded(
                              child: Text(
                                "Playlist",
                                style: Theme.of(context).textTheme.headline6,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            StreamBuilder<bool>(
                              stream: _player.shuffleModeEnabledStream,
                              builder: (context, snapshot) {
                                final shuffleModeEnabled = snapshot.data ?? false;
                                return IconButton(
                                  icon: shuffleModeEnabled
                                      ? const Icon(Icons.shuffle, color: Colors.orange)
                                      : const Icon(Icons.shuffle, color: Colors.grey),
                                  onPressed: () async {
                                    final enable = !shuffleModeEnabled;
                                    if (enable) {
                                      await _player.shuffle();
                                    }
                                    await _player.setShuffleModeEnabled(enable);
                                  },
                                );
                              },
                            ),*/
                    ],
                  ),
                  /*SizedBox(
                          height: 240.0,
                          child: StreamBuilder<SequenceState?>(
                            stream: _player.sequenceStateStream,
                            builder: (context, snapshot) {
                              final state = snapshot.data;
                              final sequence = state?.sequence ?? [];
                              return ReorderableListView(
                                onReorder: (int oldIndex, int newIndex) {
                                  if (oldIndex < newIndex) newIndex--;
                                  _playlist.move(oldIndex, newIndex);
                                },
                                children: [
                                  for (var i = 0; i < sequence.length; i++)
                                    Dismissible(
                                      key: ValueKey(sequence[i]),
                                      background: Container(
                                        color: Colors.redAccent,
                                        alignment: Alignment.centerRight,
                                        child: const Padding(
                                          padding: EdgeInsets.only(right: 8.0),
                                          child: Icon(Icons.delete, color: Colors.white),
                                        ),
                                      ),
                                      onDismissed: (dismissDirection) {
                                        _playlist.removeAt(i);
                                      },
                                      child: Material(
                                        color: i == state!.currentIndex
                                            ? Colors.grey.shade300
                                            : null,
                                        child: ListTile(
                                          title: Text(sequence[i].tag.title as String),
                                          onTap: () {
                                            _player.seek(Duration.zero, index: i);
                                          },
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ),*/
                ],
              ),
              StreamBuilder<Object>(
                  stream: isSoundVisible.stream,
                  builder: (context, snapshot) {
                    return Visibility(
                      visible: isSoundVisible.value,
                      child: Container(
                        color: Colors.white,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                                onPressed: () {
                                  isSoundVisible.value = false;
                                },
                                icon: const Icon(Icons.arrow_back)),
                            StreamBuilder<bool>(
                              stream: _loudnessEnhancer.enabledStream,
                              builder: (context, snapshot) {
                                final enabled = snapshot.data ?? false;
                                return SwitchListTile(
                                  title: const Text('Loudness Enhancer'),
                                  value: enabled,
                                  onChanged: _loudnessEnhancer.setEnabled,
                                  activeColor: colorRed,
                                );
                              },
                            ),
                            LoudnessEnhancerControls(
                                loudnessEnhancer: _loudnessEnhancer),
                            StreamBuilder<bool>(
                              stream: _equalizer.enabledStream,
                              builder: (context, snapshot) {
                                final enabled = snapshot.data ?? false;
                                return SwitchListTile(
                                  title: const Text('Equalizer'),
                                  value: enabled,
                                  onChanged: _equalizer.setEnabled,
                                  activeColor: colorRed,
                                );
                              },
                            ),
                            Expanded(
                              child: EqualizerControls(equalizer: _equalizer),
                            ),
                            const SizedBox(
                              height: 50.0,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              /* get_x.Obx(
                () => downloading.value
                    ? Center(
                        child: SizedBox(
                          height: 120.0,
                          width: 200.0,
                          child: Card(
                            shape: const RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10))),
                            color: Colors.black.withOpacity(0.8),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                const CircularProgressIndicator(
                                  color: colorRed,
                                ),
                                const SizedBox(
                                  height: 20.0,
                                ),
                                Text(
                                  "Downloading Audio: $progressString",
                                  style: const TextStyle(
                                    color: Colors.white,
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      )
                    : const SizedBox(),
              ),*/
            ],
          ),
        ),
        /*floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () {
            _playlist.add(AudioSource.uri(
              Uri.parse("asset:///audio/nature.mp3"),
              tag: AudioMetadata(
                album: "Public Domain",
                title: "Nature Sounds ${++_addedCount}",
                artwork:
                "https://media.wnyc.org/i/1400/1400/l/80/1/ScienceFriday_WNYCStudios_1400.jpg",
              ),
            ));
          },
        ),*/
      ),
    );
  }

  Sharefile() async {
    await Share.shareFiles([file?.path ?? '']);
  }

  Widget ControlButtonsBottom(
    BuildContext context,
    AudioPlayer player,
    String audio,
    String title,
    int image,
    String artist,
  ) {
    // final AudioPlayer player;
    // final String audio;
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        StreamBuilder<Object>(
            stream: likeBool.stream,
            builder: (context, snapshot) {
              return IconButton(
                  splashColor: colorRed,
                  onPressed: () async {
                    likeBool.value = !likeBool.value;
                    if (likeBool.value == true) {
                      kPlayAudioController.addAudioListData.add(audio);
                      setStorageValue(
                          'mySongs', kPlayAudioController.addAudioListData);
                      // setStorageValue('mySongs', kHomeController.audioList);

                      /*    kPlayAudioController.addAudioListData.add(StoreAudioData(
                          songUri: audio,
                          id: image,
                          artiest: artist,
                          name: title));*/
                    } else if (likeBool.value == false) {
                      kPlayAudioController.addAudioListData.remove(audio);

                      /*  kPlayAudioController.addAudioListData.remove(
                          StoreAudioData(
                              songUri: audio,
                              id: image,
                              artiest: artist,
                              name: title));*/
                    }
                  },
                  icon: likeBool.value == true
                      ? const Icon(
                          CupertinoIcons.heart_fill,
                          color: colorRed,
                        )
                      : const Icon(CupertinoIcons.heart));
            }),
        IconButton(
          icon: const Icon(Icons.volume_up),
          onPressed: () {
            showSliderDialog(
              context: context,
              title: "Adjust volume",
              divisions: 10,
              min: 0.0,
              max: 1.0,
              value: player.volume,
              stream: player.volumeStream,
              onChanged: player.setVolume,
            );
          },
        ),
        StreamBuilder<SequenceState?>(
          stream: player.sequenceStateStream,
          builder: (context, snapshot) => IconButton(
              icon: const Icon(Icons.skip_previous),
              onPressed: () {
                // player.hasPrevious ? player.seekToPrevious : null;
                // print('>>>>>>>>${player.hasPrevious}');
                audioIndex = audioIndex - 1;
                _init(
                    audioUrl: widget.flag == true
                        ? (kHomeController.audioList[audioIndex].audioUrl ?? '')
                        : kHomeController.audioDetails[audioIndex].audioUrl ??
                            '');
              }),
        ),
        StreamBuilder<PlayerState>(
          stream: player.playerStateStream,
          builder: (context, snapshot) {
            final playerState = snapshot.data;
            final processingState = playerState?.processingState;
            final playing = playerState?.playing;
            if (processingState == ProcessingState.loading ||
                processingState == ProcessingState.buffering) {
              return Container(
                margin: const EdgeInsets.all(8.0),
                width: 64.0,
                height: 64.0,
                child: const CircularProgressIndicator(),
              );
            } else if (playing != true) {
              return IconButton(
                icon: const Icon(Icons.play_arrow),
                iconSize: 64.0,
                onPressed: player.play,
              );
            } else if (processingState != ProcessingState.completed) {
              return IconButton(
                icon: const Icon(Icons.pause),
                iconSize: 64.0,
                onPressed: player.pause,
              );
            } else {
              return IconButton(
                icon: const Icon(Icons.replay),
                iconSize: 64.0,
                onPressed: () => player.seek(Duration.zero,
                    index: player.effectiveIndices!.first),
              );
            }
          },
        ),
        StreamBuilder<SequenceState?>(
          stream: player.sequenceStateStream,
          builder: (context, snapshot) => IconButton(
              icon: const Icon(Icons.skip_next),
              // onPressed: player.hasNext ? player.seekToNext : null,
              onPressed: () {
                if (_player.loopMode == LoopMode.off) {
                  audioIndex = audioIndex + 1;
                  _init(
                      audioUrl: widget.flag == true
                          ? (kHomeController.audioList[audioIndex].audioUrl ??
                              '')
                          : kHomeController.audioDetails[audioIndex].audioUrl ??
                              '');
                } else if (_player.loopMode == LoopMode.all) {
                  audioIndex = Random().nextInt(10);
                  _init(
                      audioUrl: widget.flag == true
                          ? (kHomeController.audioList[audioIndex].audioUrl ??
                              '')
                          : kHomeController.audioDetails[audioIndex].audioUrl ??
                              '');
                } else if (_player.loopMode == LoopMode.one) {
                  _init(
                      audioUrl: widget.flag == true
                          ? (kHomeController.audioList[audioIndex].audioUrl ??
                              '')
                          : kHomeController.audioDetails[audioIndex].audioUrl ??
                              '');
                }
              }),
        ),
        StreamBuilder<double>(
          stream: player.speedStream,
          builder: (context, snapshot) => IconButton(
            icon: Text("${snapshot.data?.toStringAsFixed(1)}x",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () {
              showSliderDialog(
                context: context,
                title: "Adjust speed",
                divisions: 10,
                min: 0.5,
                max: 1.5,
                value: player.speed,
                stream: player.speedStream,
                onChanged: player.setSpeed,
              );
            },
          ),
        ),
      ],
    );
  }
}

// class ControlButtons extends StatelessWidget {
//   final AudioPlayer player;
//   final String audio;
//   const ControlButtons(this.player, this.audio, {Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//
//         IconButton(onPressed: (){
//           List<String>addList = [];
//           addList.add(audio);
//         }, icon: const Icon(Icons.playlist_add)),
//
//         IconButton(
//           icon: const Icon(Icons.volume_up),
//           onPressed: () {
//             showSliderDialog(
//               context: context,
//               title: "Adjust volume",
//               divisions: 10,
//               min: 0.0,
//               max: 1.0,
//               value: player.volume,
//               stream: player.volumeStream,
//               onChanged: player.setVolume,
//             );
//           },
//         ),
//         StreamBuilder<SequenceState?>(
//           stream: player.sequenceStateStream,
//           builder: (context, snapshot) => IconButton(
//             icon: const Icon(Icons.skip_previous),
//             onPressed: (){
//               player.hasPrevious ? player.seekToPrevious : null;
//             print('>>>>>>>>${player.hasPrevious}');
//             }
//           ),
//         ),
//         StreamBuilder<PlayerState>(
//           stream: player.playerStateStream,
//           builder: (context, snapshot) {
//             final playerState = snapshot.data;
//             final processingState = playerState?.processingState;
//             final playing = playerState?.playing;
//             if (processingState == ProcessingState.loading ||
//                 processingState == ProcessingState.buffering) {
//               return Container(
//                 margin: const EdgeInsets.all(8.0),
//                 width: 64.0,
//                 height: 64.0,
//                 child: const CircularProgressIndicator(),
//               );
//             } else if (playing != true) {
//               return IconButton(
//                 icon: const Icon(Icons.play_arrow),
//                 iconSize: 64.0,
//                 onPressed: player.play,
//               );
//             } else if (processingState != ProcessingState.completed) {
//               return IconButton(
//                 icon: const Icon(Icons.pause),
//                 iconSize: 64.0,
//                 onPressed: player.pause,
//               );
//             } else {
//               return IconButton(
//                 icon: const Icon(Icons.replay),
//                 iconSize: 64.0,
//                 onPressed: () => player.seek(Duration.zero,
//                     index: player.effectiveIndices!.first),
//               );
//             }
//           },
//         ),
//         StreamBuilder<SequenceState?>(
//           stream: player.sequenceStateStream,
//           builder: (context, snapshot) => IconButton(
//             icon: const Icon(Icons.skip_next),
//             // onPressed: player.hasNext ? player.seekToNext : null,
//             onPressed: ,
//           ),
//         ),
//         StreamBuilder<double>(
//           stream: player.speedStream,
//           builder: (context, snapshot) => IconButton(
//             icon: Text("${snapshot.data?.toStringAsFixed(1)}x",
//                 style: const TextStyle(fontWeight: FontWeight.bold)),
//             onPressed: () {
//               showSliderDialog(
//                 context: context,
//                 title: "Adjust speed",
//                 divisions: 10,
//                 min: 0.5,
//                 max: 1.5,
//                 value: player.speed,
//                 stream: player.speedStream,
//                 onChanged: player.setSpeed,
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }
// }
