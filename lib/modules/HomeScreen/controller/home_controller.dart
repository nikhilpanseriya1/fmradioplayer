import 'package:get/get.dart';

class HomeController extends GetxController {
  List<AudioData> audioList = [
    AudioData(
        title: 'amazonaws',
        audioUrl:
            'https://s3.amazonaws.com/scifri-episodes/scifri20181123-episode.mp3',
        artist: 'T. Schürger'),
    AudioData(
        title: 'learningcontainer',
        audioUrl:
            'https://www.learningcontainer.com/wp-content/uploads/2020/02/Kalimba.mp3',
        artist: 'T. Schürger'),
    AudioData(
        title: 'kozco',
        audioUrl: 'https://www.kozco.com/tech/LRMonoPhase4.mp3',
        artist: 'T. Schürger'),
    AudioData(
        title: 'kozco',
        audioUrl: 'https://www.kozco.com/tech/piano2-Audacity1.2.5.mp3',
        artist: 'T. Schürger'),
    AudioData(
        title: 'examples',
        audioUrl:
            'https://file-examples.com/storage/fecadf937e62d089e9bc0c7/2017/11/file_example_MP3_700KB.mp3',
        artist: 'T. Schürger'),
    AudioData(
        title: '32000hz',
        audioUrl: 'https://dl.espressif.com/dl/audio/ff-16b-1c-32000hz.mp3',
        artist: 'T. Schürger'),
    AudioData(
        title: '22050hz',
        audioUrl: 'https://dl.espressif.com/dl/audio/ff-16b-2c-22050hz.mp3',
        artist: 'T. Schürger'),
    AudioData(
        title: '24000hz',
        audioUrl: 'https://dl.espressif.com/dl/audio/ff-16b-2c-24000hz.mp3',
        artist: 'Arijit')
  ];

  List<AudioData> audioDetails = [];
}

class AudioData {
  String? audioUrl;
  String? artist;
  String? title;
  int? img;

  AudioData({this.audioUrl, this.artist, this.title, this.img});
}
