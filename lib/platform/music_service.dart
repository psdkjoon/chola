import 'dart:io';

import 'package:flutter/services.dart';

class MusicTrack {
  const MusicTrack(this.name);

  final String name;
}

abstract class MusicService {
  static const _channel = MethodChannel('chola/music');

  static const List<MusicTrack> tracks = <MusicTrack>[
    MusicTrack('Chola'),
    MusicTrack('Dawn'),
    MusicTrack('Rainy window'),
    MusicTrack('Lo-fi study'),
    MusicTrack('Music box'),
    MusicTrack('Night sky'),
    MusicTrack('Focus'),
    MusicTrack('Morning breeze'),
    MusicTrack('Piano evening'),
    MusicTrack('Forest walk'),
    MusicTrack('Ocean waves'),
    MusicTrack('Cafe jazz'),
    MusicTrack('Snowfall'),
    MusicTrack('Starlight'),
    MusicTrack('Zen garden'),
    MusicTrack('Campfire'),
    MusicTrack('Deep focus'),
    MusicTrack('Sunny day'),
  ];

  static Future<void> play({int track = -1}) =>
      _send('play', <String, int>{'track': track});

  static Future<void> pause() => _send('pause');

  static Future<void> stop() => _send('stop');

  static Future<void> next() => _send('next');

  static Future<void> _send(String method, [Object? arguments]) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>(method, arguments);
    } on PlatformException {
      return;
    } on MissingPluginException {
      return;
    }
  }
}
