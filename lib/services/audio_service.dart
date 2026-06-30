import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioPlayer _player = AudioPlayer();
  static bool _isPlaying = false;

  static Future<void> toggleBGM() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.play(AssetSource('music.mp3'));
      _player.setReleaseMode(ReleaseMode.loop);
    }
    _isPlaying = !_isPlaying;
  }
}
