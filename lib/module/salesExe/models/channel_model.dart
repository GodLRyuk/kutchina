import 'package:kutchina/core/network/masters_api.dart';

class ChannelModel {
  static List<String> channels = [];
  static Future<void> loadChannels() async {
    final list = await MastersApi.fetchChannels();
    channels = list.map((c) => c.name).toList();
  }
}
