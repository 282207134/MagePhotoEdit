import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/editor/editor_model.dart';

class ProjectStore extends ChangeNotifier {
  final List<EditorDocument> projects = [];
  final List<String> folders = ['Summer Time', 'Nice Photos', 'Favorites'];
  String language = 'English';
  SharedPreferences? _prefs;
  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    language = _prefs?.getString('language') ?? 'English';
    try {
      final saved = jsonDecode(_prefs?.getString('projects') ?? '[]') as List;
      projects.addAll(
        saved.map((x) => EditorDocument.fromJson(Map<String, dynamic>.from(x))),
      );
      final savedFolders = _prefs?.getStringList('folders');
      if (savedFolders != null) {
        folders
          ..clear()
          ..addAll(savedFolders);
      }
    } catch (_) {
      /* Invalid drafts must not prevent the editor from opening. */
    }
    if (_prefs?.getString('projects') == null) {
      const assets = [
        'summer-poster',
        'flamingo-photo',
        'city',
        'party-poster',
        'portrait',
        'curtain',
      ];
      for (var i = 0; i < assets.length; i++) {
        projects.add(
          EditorDocument(
            id: 'sample-$i',
            title: 'Design ${i + 1}',
            background: assets[i],
            folder: i == 1 ? 'Summer Time' : 'Nice Photos',
          ),
        );
      }
    }
  }

  Future<void> save(EditorDocument doc) async {
    final index = projects.indexWhere((p) => p.id == doc.id);
    final copy = doc.copy();
    if (index < 0) {
      projects.insert(0, copy);
    } else {
      projects[index] = copy;
    }
    await _persist();
    notifyListeners();
  }

  Future<void> delete(Set<String> ids) async {
    projects.removeWhere((p) => ids.contains(p.id));
    await _persist();
    notifyListeners();
  }

  Future<void> addFolder(String name) async {
    if (name.trim().isEmpty || folders.contains(name.trim())) return;
    folders.add(name.trim());
    await _prefs?.setStringList('folders', folders);
    notifyListeners();
  }

  Future<void> setLanguage(String value) async {
    language = value;
    await _prefs?.setString('language', value);
    notifyListeners();
  }

  Future<void> _persist() async {
    await _prefs?.setString(
      'projects',
      jsonEncode(projects.map((p) => p.toJson()).toList()),
    );
  }
}
