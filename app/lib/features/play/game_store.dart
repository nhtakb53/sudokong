import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../settings/settings_provider.dart';
import 'model/play_state.dart';
import 'model/saved_game_codec.dart';

final gameStoreProvider = Provider<GameStore>(
  (ref) => GameStore(ref.watch(sharedPreferencesProvider)),
);

/// Keeps the game in progress across restarts.
class GameStore {
  GameStore(this._prefs);

  static const String key = 'game.v1';

  final SharedPreferencesWithCache _prefs;

  SavedGame? load() => SavedGameCodec.decodeString(_prefs.getString(key));

  Future<void> save(PlayState state, int seconds) =>
      _prefs.setString(key, SavedGameCodec.encodeString(state, seconds));

  Future<void> clear() => _prefs.remove(key);
}
