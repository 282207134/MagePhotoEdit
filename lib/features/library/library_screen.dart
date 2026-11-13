import 'package:flutter/material.dart';

import '../../app.dart';
import '../../data/project_store.dart';
import '../../ui/kit.dart';
import '../editor/editor_screen.dart';
import '../editor/editor_model.dart';
import '../editor/editor_canvas.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({
    super.key,
    required this.screen,
    required this.store,
    this.onSelect,
  });
  final String screen;
  final ProjectStore store;
  final ValueChanged<String>? onSelect;
  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String query = '', category = '';
  late bool folders = widget.screen.startsWith('Folders');
  late bool selecting = widget.screen == 'Projects Select';
  final Set<String> selected = {};
  bool get graphic => widget.screen.startsWith('Graphic');
  bool get shape => widget.screen == 'Shape';
  bool get discover => widget.screen.startsWith('Discover');
  void go(String name) => openScreen(context, name, widget.store);
  void choose(String value) {
    if (widget.onSelect != null) {
      widget.onSelect!(value);
      return;
    }
    if (shape || graphic) {
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => EditorScreen(
            screen: shape ? 'Edit Shape' : 'Edit Graphic',
            store: widget.store,
            chosenAsset: value,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => EditorScreen(
            screen: 'Edit Template',
            store: widget.store,
            document: EditorDocument(background: value, title: 'My design'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: graphic && widget.screen == 'Graphic Collection Detail'
          ? _collection()
          : ListenableBuilder(
              listenable: widget.store,
              builder: (_, child) => _body(),
            ),
    ),
    bottomNavigationBar: graphic || shape ? null : _bottom(),
  );
  Widget _body() => ListView(
    padding: const EdgeInsets.fromLTRB(32, 42, 0, 24),
    children: [
      Padding(
        padding: const EdgeInsets.only(right: 32),
        child: Row(
          children: [
            if (widget.screen == 'Folders Detail')
              IconButton(
                tooltip: 'Back',
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.arrow_back_ios_new),
              ),
            Expanded(
              child: Text(
                discover
                    ? 'Discover'
                    : graphic
                    ? 'Graphic'
                    : shape
                    ? 'Shape'
                    : widget.screen == 'Folders Detail'
                    ? 'Nice Photos'
                    : 'Projects',
                style: TextStyle(
                  fontSize: widget.screen == 'Folders Detail' ? 19 : 32,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (!discover && !graphic && !shape)
              IconButton(
                tooltip: 'Settings',
                onPressed: () => go('Settings'),
                icon: const Icon(
                  Icons.settings_outlined,
                  size: 23,
                  color: muted,
                ),
              ),
            if (widget.onSelect != null)
              IconButton(
                tooltip: 'Close library',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      if (discover || graphic || shape) ...[
        Padding(
          padding: const EdgeInsets.only(right: 32),
          child: SearchBox(
            hint: discover
                ? 'Search Templates'
                : graphic
                ? 'Search Graphics'
                : 'Search Shapes',
            initial: widget.screen == 'Discover 2' ? 'Carm|' : '',
            onChanged: (v) => setState(() => query = v),
          ),
        ),
        const SizedBox(height: 24),
        ChoiceStrip(
          discover
              ? const ['Christmas', 'Inspiration', 'Cyber Monday']
              : graphic
              ? const ['Pattern', 'Floral', 'Retro', 'Abstract']
              : const ['Basic', 'Holiday', 'Outline', 'Brushes'],
          selected: category,
          onSelected: (v) => setState(() => category = category == v ? '' : v),
        ),
        const SizedBox(height: 30),
      ],
      if (discover) ..._discover(),
      if (graphic) ..._graphics(),
      if (shape) _shapes(),
      if (!discover && !graphic && !shape) ...[
        Padding(
          padding: const EdgeInsets.only(right: 32),
          child: ChoiceStrip(
            ['Projects', 'Folders', selecting ? 'Cancel' : 'Select'],
            selected: selecting
                ? 'Cancel'
                : folders
                ? 'Folders'
                : 'Projects',
            onSelected: (v) => setState(() {
              if (v == 'Projects') {
                folders = false;
              } else if (v == 'Folders') {
                folders = true;
              } else {
                selecting = !selecting;
                selected.clear();
              }
            }),
          ),
        ),
        const SizedBox(height: 30),
        if (folders && widget.screen != 'Folders Detail')
          _folders()
        else
          _projects(),
      ],
    ],
  );
  List<Widget> _discover() => [
    SizedBox(
      height: 124,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (_, i) => const SizedBox(width: 16),
        itemBuilder: (_, i) {
          const names = [
            'Instagram\nStory',
            'Facebook\nPost',
            'Birthday\nCard',
          ];
          const colors = [pink, Color(0xff008bf5), Color(0xff8c00f5)];
          return InkWell(
            onTap: () => choose(
              i == 0
                  ? 'poster'
                  : i == 1
                  ? 'summer-vibes'
                  : 'summer-card',
            ),
            child: Container(
              width: 124,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors[i],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    [
                      Icons.slow_motion_video,
                      Icons.facebook,
                      Icons.card_giftcard,
                    ][i],
                    size: 24,
                  ),
                  const Spacer(),
                  Text(
                    names[i],
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ),
    const SizedBox(height: 32),
    const Text(
      'Featured Templates',
      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
    ),
    const SizedBox(height: 20),
    _masonry(_filteredTemplates()),
  ];
  List<String> _filteredTemplates() {
    const templates = [
      'summer-vibes',
      'poster',
      'orange',
      'summer-card',
      'party-poster',
      'summer-poster',
    ];
    if (query.isNotEmpty) {
      return templates
          .where((s) => s.contains(query.toLowerCase().replaceAll(' ', '-')))
          .toList();
    }
    if (category == 'Christmas') {
      return ['christmas', 'poster', 'summer-card', 'summer-vibes'];
    }
    if (category == 'Cyber Monday') {
      return ['mega-sale', 'party-poster', 'poster', 'orange'];
    }
    return templates;
  }

  Widget _masonry(List<String> assets) => Padding(
    padding: const EdgeInsets.only(right: 32),
    child: assets.isEmpty
        ? const Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No matching designs. Try another search.',
              style: TextStyle(color: muted),
            ),
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var col = 0; col < 2; col++) ...[
                if (col == 1) const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      for (var i = col; i < assets.length; i += 2)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: InkWell(
                            onTap: () => choose(assets[i]),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: art(
                                assets[i],
                                height: i % 3 == 0 ? 146 : 222,
                                width: double.infinity,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
  );
  Widget _projects() {
    var docs = widget.store.projects;
    if (widget.screen == 'Folders Detail') {
      docs = docs.where((d) => d.folder == 'Nice Photos').toList();
    }
    if (docs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(right: 32, top: 64),
        child: Center(
          child: Text(
            'No projects yet. Tap + to create one.',
            style: TextStyle(color: muted),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(right: 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var col = 0; col < 2; col++) ...[
            if (col == 1) const SizedBox(width: 16),
            Expanded(
              child: Column(
                children: [
                  for (var i = col; i < docs.length; i += 2)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        onTap: () {
                          if (selecting) {
                            setState(() {
                              selected.contains(docs[i].id)
                                  ? selected.remove(docs[i].id)
                                  : selected.add(docs[i].id);
                            });
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => EditorScreen(
                                  screen: 'Edit Template',
                                  store: widget.store,
                                  document: docs[i].copy(),
                                ),
                              ),
                            );
                          }
                        },
                        onLongPress: () => setState(() {
                          selecting = true;
                          selected.add(docs[i].id);
                        }),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selected.contains(docs[i].id)
                                  ? pink
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Stack(
                              children: [
                                SizedBox(
                                  height: i % 3 == 0 ? 238 : 177,
                                  width: double.infinity,
                                  child: EditorCanvas(
                                    controller: EditorController(docs[i]),
                                    handles: false,
                                  ),
                                ),
                                if (selected.contains(docs[i].id))
                                  const Positioned(
                                    right: 8,
                                    top: 8,
                                    child: Icon(
                                      Icons.check_circle,
                                      color: pink,
                                      size: 22,
                                    ),
                                  ),
                                if (!docs[i].id.startsWith('sample'))
                                  Positioned(
                                    left: 8,
                                    right: 8,
                                    bottom: 8,
                                    child: Container(
                                      color: Colors.black54,
                                      padding: const EdgeInsets.all(6),
                                      child: Text(
                                        docs[i].title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _folders() => Padding(
    padding: const EdgeInsets.only(right: 32),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('My Folders', style: TextStyle(fontSize: 17)),
        const SizedBox(height: 18),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 20,
            childAspectRatio: .84,
          ),
          itemCount: widget.store.folders.length + 1,
          itemBuilder: (_, i) {
            final create = i == widget.store.folders.length;
            final name = create ? 'New Folder' : widget.store.folders[i];
            return InkWell(
              onTap: () => create ? _newFolder() : _folderDetail(name),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: double.infinity,
                        color: panel,
                        child: create
                            ? const Icon(Icons.add, color: muted, size: 28)
                            : name == 'Favorites'
                            ? const Icon(
                                Icons.favorite,
                                color: Color(0xffdc4c79),
                              )
                            : art(i == 0 ? 'flamingo-photo' : 'curtain'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(name, style: const TextStyle(fontSize: 13)),
                  const SizedBox(height: 5),
                  if (!create)
                    Text(
                      '${widget.store.projects.where((p) => p.folder == name).length}',
                      style: const TextStyle(fontSize: 11, color: muted),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    ),
  );
  void _folderDetail(String name) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(name)),
          body: ListenableBuilder(
            listenable: widget.store,
            builder: (_, child) {
              final docs = widget.store.projects
                  .where((p) => p.folder == name)
                  .toList();
              return docs.isEmpty
                  ? const Center(child: Text('This folder is empty.'))
                  : GridView.builder(
                      padding: const EdgeInsets.all(24),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: .7,
                          ),
                      itemCount: docs.length,
                      itemBuilder: (_, i) => InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => EditorScreen(
                              screen: 'Edit Template',
                              store: widget.store,
                              document: docs[i].copy(),
                            ),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: EditorCanvas(
                            controller: EditorController(docs[i]),
                            handles: false,
                          ),
                        ),
                      ),
                    );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _newFolder() async {
    final name = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('New Folder'),
        content: TextField(
          controller: name,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Folder name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, name.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (result != null) await widget.store.addFolder(result);
    name.dispose();
  }

  List<Widget> _graphics() => [
    for (final section in [
      'Latest Collections',
      'Featured Graphics',
      'Recommended Graphics',
    ]) ...[
      Padding(
        padding: const EdgeInsets.only(right: 25),
        child: Row(
          children: [
            Expanded(
              child: Text(section, style: const TextStyle(fontSize: 16)),
            ),
            TextButton(
              onPressed: () => go('Graphic Collection Detail'),
              child: const Text(
                'See All ›',
                style: TextStyle(color: muted, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: 205,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          separatorBuilder: (_, i) => const SizedBox(width: 16),
          itemCount: 3,
          itemBuilder: (_, i) {
            final assets = section == 'Latest Collections'
                ? ['christmas', 'summer-collection', 'floral']
                : ['mega-sale', 'tropical', 'fancy'];
            final names = section == 'Latest Collections'
                ? ['Merry Christmas', 'Summer jam', 'Floral']
                : ['Mega Sale', 'Tropical Pattern', 'Fancy Girl Tools'];
            if (query.isNotEmpty &&
                !names[i].toLowerCase().contains(query.toLowerCase())) {
              return const SizedBox.shrink();
            }
            return InkWell(
              onTap: () => widget.onSelect != null
                  ? choose(assets[i])
                  : go('Graphic Collection Detail'),
              child: SizedBox(
                width: 147,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: art(assets[i], height: 140, width: 147),
                    ),
                    const SizedBox(height: 8),
                    Text(names[i], style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 6),
                    Text(
                      i == 0 ? '18 graphics' : '32 graphics',
                      style: const TextStyle(fontSize: 11, color: muted),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 18),
    ],
  ];
  Widget _collection() => Column(
    children: [
      SizedBox(
        height: 230,
        child: Stack(
          fit: StackFit.expand,
          children: [
            art('summer-collection'),
            Positioned(
              top: 25,
              left: 12,
              child: IconButton(
                tooltip: 'Back',
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.arrow_back_ios_new),
              ),
            ),
            const Positioned(
              left: 20,
              bottom: 22,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Summer Jam',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                  Text('32 graphics', style: TextStyle(fontSize: 15)),
                ],
              ),
            ),
          ],
        ),
      ),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.all(32),
          children: [
            _masonry([
              'flamingo',
              'pineapple',
              'summer-sticker',
              'pattern',
              'hello-summer',
              'popsicle',
            ]),
          ],
        ),
      ),
    ],
  );
  Widget _shapes() => Padding(
    padding: const EdgeInsets.only(right: 32),
    child: GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 15,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemBuilder: (_, i) => InkWell(
        onTap: () => choose('shape:$i'),
        child: Container(
          decoration: BoxDecoration(
            color: panel,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            [
              Icons.star,
              Icons.star_rounded,
              Icons.hexagon,
              Icons.change_history,
              Icons.signal_cellular_4_bar,
              Icons.square,
              Icons.hexagon,
              Icons.hexagon_rounded,
              Icons.diamond,
              Icons.stop_rounded,
              Icons.stop,
              Icons.favorite,
              Icons.favorite,
              Icons.favorite,
              Icons.favorite,
            ][i],
            size: 78,
            color: Color.lerp(
              const Color(0xff66c9e8),
              const Color(0xffe33b79),
              i / 14,
            ),
          ),
        ),
      ),
    ),
  );
  Widget _bottom() => Container(
    height: 80,
    decoration: const BoxDecoration(
      color: panel,
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    child: selecting
        ? Row(
            children: [
              IconButton(
                tooltip: 'Move to folder',
                onPressed: selected.isEmpty ? null : _moveSelected,
                icon: const Icon(Icons.drive_file_move_outlined, color: muted),
              ),
              Expanded(
                child: Text(
                  '${selected.length} Projects Selected',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              IconButton(
                tooltip: 'Delete selected projects',
                onPressed: selected.isEmpty ? null : _deleteSelected,
                icon: const Icon(Icons.delete_outline, color: muted),
              ),
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                tooltip: 'Discover',
                onPressed: () => openScreen(
                  context,
                  'Discover',
                  widget.store,
                  replace: true,
                ),
                icon: Icon(
                  Icons.grid_view_outlined,
                  color: discover ? Colors.white : muted,
                ),
              ),
              IconButton(
                tooltip: 'New project',
                onPressed: () => go('New Project'),
                icon: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: muted),
                  ),
                  child: const Icon(Icons.add, color: muted),
                ),
              ),
              IconButton(
                tooltip: 'Projects',
                onPressed: () => openScreen(
                  context,
                  'Projects',
                  widget.store,
                  replace: true,
                ),
                icon: Icon(
                  Icons.person_outline,
                  color: discover ? muted : Colors.white,
                ),
              ),
            ],
          ),
  );
  Future<void> _deleteSelected() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete selected projects?'),
        content: const Text(
          'This removes the selected drafts from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (yes == true) {
      await widget.store.delete(selected);
      if (mounted) setState(() => selected.clear());
    }
  }

  Future<void> _moveSelected() async {
    final folder = await showModalBottomSheet<String>(
      context: context,
      builder: (c) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final f in widget.store.folders)
              ListTile(title: Text(f), onTap: () => Navigator.pop(c, f)),
          ],
        ),
      ),
    );
    if (folder != null) {
      for (final d
          in widget.store.projects
              .where((d) => selected.contains(d.id))
              .toList()) {
        d.folder = folder;
        await widget.store.save(d);
      }
      if (mounted) {
        setState(() => selected.clear());
        tell(context, 'Moved to $folder');
      }
    }
  }
}
