import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/guitar_song.dart';

class GuitarSongsController extends ValueNotifier<List<GuitarSong>> {
  static const String prefsKey = 'guitar_songs_list';
  final SharedPreferences? _prefs;

  GuitarSongsController([this._prefs, List<GuitarSong>? initialSongs])
      : super(initialSongs ?? []) {
    if (initialSongs == null && _prefs != null) {
      _loadFromPrefs();
    }
  }

  static Future<GuitarSongsController> init({SharedPreferences? prefs}) async {
    final preferences = prefs ?? await SharedPreferences.getInstance();
    final controller = GuitarSongsController(preferences);
    return controller;
  }

  void _loadFromPrefs() {
    final raw = _prefs?.getString(prefsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          final List<GuitarSong> loaded = [];
          for (final item in decoded) {
            if (item is Map) {
              try {
                loaded.add(GuitarSong.fromJson(Map<String, dynamic>.from(item)));
              } catch (_) {}
            }
          }
          value = loaded;
        }
      } catch (_) {}
    }
  }

  static int _idCounter = 0;

  Future<bool> addSong(String name, String videoLink) async {
    final trimmedName = name.trim();
    final trimmedLink = videoLink.trim();
    if (trimmedName.isEmpty || trimmedLink.isEmpty) {
      return false;
    }

    _idCounter++;
    final newSong = GuitarSong(
      id: '${DateTime.now().microsecondsSinceEpoch}_$_idCounter',
      name: trimmedName,
      videoLink: trimmedLink,
      createdAt: DateTime.now(),
    );

    value = [...value, newSong];
    await _saveToPrefs();
    return true;
  }

  List<GuitarSong> get songs => value;

  Future<bool> updateSong(String id, String name, String videoLink) async {
    final trimmedName = name.trim();
    final trimmedLink = videoLink.trim();
    if (trimmedName.isEmpty || trimmedLink.isEmpty) {
      return false;
    }

    final index = value.indexWhere((song) => song.id == id);
    if (index == -1) return false;

    final existing = value[index];
    final updated = existing.copyWith(
      name: trimmedName,
      videoLink: trimmedLink,
    );

    final updatedList = List<GuitarSong>.from(value);
    updatedList[index] = updated;
    value = updatedList;
    await _saveToPrefs();
    return true;
  }

  Future<void> _saveToPrefs() async {
    final prefs = _prefs;
    if (prefs != null) {
      final encoded = jsonEncode(value.map((s) => s.toJson()).toList());
      await prefs.setString(prefsKey, encoded);
    }
  }
}
