import 'package:get/get.dart';

class PlayAudioController extends GetxController {
  List<String> audioStoreList = [];
  List<String> addAudioListData = [];
}

class StoreAudioData {
  String? name;
  String? artiest;
  String? songUri;
  int? id;

  StoreAudioData({this.name, this.id, this.artiest, this.songUri});
}
