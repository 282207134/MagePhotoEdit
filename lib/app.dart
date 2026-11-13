import 'package:flutter/material.dart';

import 'data/project_store.dart';
import 'features/library/library_screen.dart';
import 'features/account/account_screen.dart';
import 'features/editor/editor_screen.dart';
import 'ui/kit.dart';

const referenceScreens = <String>[
  'Sign In',
  'Sign In Filled',
  'Sign Up',
  'Discover',
  'Discover 2',
  'New Project',
  'Edit Template',
  'Add Image',
  'Add Image 2',
  'Layers',
  'Filters',
  'Filters 2',
  'Filters Intensity',
  'Adjust',
  'Crop',
  'Shadow Size',
  'Shadow Angle',
  'Shadow Blur',
  'Shadow Color',
  'Shadow Opacity',
  'Opacity',
  'Background Image',
  'Background Transparent',
  'Background Color',
  'Background Gradient',
  'Background Pastel',
  'Background Color Picker',
  'Edit Template Text Sample',
  'Edit Text',
  'Text Pick a Color',
  'Text Pick a Color 2',
  'Text Fill',
  'Text Color Picker',
  'Text Fonts',
  'Text Style',
  'Graphic Sample',
  'Graphic',
  'Graphic Collection Detail',
  'Edit Graphic',
  'Shape Sample',
  'Shape',
  'Edit Shape',
  'Projects',
  'Folders',
  'Folders Detail',
  'Projects Select',
  'Settings',
  'Language',
  'Privacy Policy',
  'Subscription',
];

class MageApp extends StatelessWidget {
  const MageApp({super.key, required this.store, this.initialScreen});
  final ProjectStore store;
  final String? initialScreen;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'mage',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: ink,
      fontFamily: 'Montserrat',
      colorScheme: const ColorScheme.dark(
        primary: pink,
        surface: panel,
        secondary: pink,
      ),
      splashFactory: NoSplash.splashFactory,
      textTheme: const TextTheme(
        bodyMedium: TextStyle(fontSize: 14, color: Colors.white),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: Colors.white,
        inactiveTrackColor: Color(0xff414144),
        thumbColor: Colors.white,
        trackHeight: 2,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
        overlayShape: RoundSliderOverlayShape(overlayRadius: 14),
      ),
    ),
    builder: (context, child) => ColoredBox(
      color: const Color(0xff0c0d0e),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: child,
        ),
      ),
    ),
    home: MageRoute(
      screen:
          initialScreen ??
          const String.fromEnvironment('SCREEN', defaultValue: 'Sign In'),
      store: store,
    ),
  );
}

class MageRoute extends StatelessWidget {
  const MageRoute({super.key, required this.screen, required this.store});
  final String screen;
  final ProjectStore store;
  @override
  Widget build(BuildContext context) {
    if (screen.startsWith('Sign ') ||
        [
          'Settings',
          'Language',
          'Privacy Policy',
          'Subscription',
        ].contains(screen)) {
      return AccountScreen(screen: screen, store: store);
    }
    if ([
      'Discover',
      'Discover 2',
      'Projects',
      'Folders',
      'Folders Detail',
      'Projects Select',
      'Graphic',
      'Graphic Collection Detail',
      'Shape',
    ].contains(screen)) {
      return LibraryScreen(screen: screen, store: store);
    }
    return EditorScreen(screen: screen, store: store);
  }
}

void openScreen(
  BuildContext context,
  String screen,
  ProjectStore store, {
  bool replace = false,
}) {
  final route = MaterialPageRoute<void>(
    settings: RouteSettings(name: screen),
    builder: (_) => MageRoute(screen: screen, store: store),
  );
  if (replace) {
    Navigator.of(context).pushReplacement(route);
  } else {
    Navigator.of(context).push(route);
  }
}
