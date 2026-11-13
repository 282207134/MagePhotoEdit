import 'package:flutter_test/flutter_test.dart';
import 'package:mage_photo_edit/features/editor/editor_model.dart';
import 'package:mage_photo_edit/data/project_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('undo and redo preserve layer edits without sharing mutable state', () {
    final c = EditorController(EditorDocument());
    c.add(EditorLayer(kind: 'text', value: 'Before'));
    c.change(() => c.layer!.value = 'After');
    c.undo();
    expect(c.document.layers.single.value, 'Before');
    c.redo();
    expect(c.document.layers.single.value, 'After');
    final copy = c.document.copy();
    copy.layers.single.value = 'Independent';
    expect(c.document.layers.single.value, 'After');
    c.dispose();
  });
  test('drafts and folders survive reload; deletion is persisted', () async {
    SharedPreferences.setMockInitialValues({});
    final store = ProjectStore();
    await store.load();
    final doc = EditorDocument(
      id: 'test',
      title: 'Saved',
      layers: [EditorLayer(kind: 'shape', value: 'shape:11', opacity: .3)],
    );
    await store.addFolder('Test folder');
    doc.folder = 'Test folder';
    await store.save(doc);
    final reloaded = ProjectStore();
    await reloaded.load();
    expect(reloaded.projects.first.title, 'Saved');
    expect(reloaded.projects.first.layers.single.opacity, .3);
    expect(reloaded.folders, contains('Test folder'));
    await reloaded.delete({'test'});
    final after = ProjectStore();
    await after.load();
    expect(after.projects.any((p) => p.id == 'test'), false);
  });
}
