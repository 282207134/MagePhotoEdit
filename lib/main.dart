import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'data/project_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  final store = ProjectStore();
  await store.load();
  if (kDebugMode &&
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android) {
    const channel = MethodChannel('mage/export');
    final requested = await channel.invokeMethod<String>('previewScreen');
    final screen = ValueNotifier<String?>(
      referenceScreens.contains(requested) ? requested : null,
    );
    channel.setMethodCallHandler((call) async {
      if (call.method == 'previewScreenChanged' &&
          referenceScreens.contains(call.arguments)) {
        screen.value = call.arguments as String;
      }
    });
    runApp(
      ValueListenableBuilder<String?>(
        valueListenable: screen,
        builder: (_, name, _) =>
            MageApp(key: ValueKey(name), store: store, initialScreen: name),
      ),
    );
    return;
  }
  runApp(MageApp(store: store));
}
