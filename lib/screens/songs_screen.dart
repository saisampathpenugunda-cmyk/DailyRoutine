import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controllers/guitar_songs_controller.dart';
import '../models/guitar_song.dart';
import '../theme/app_theme.dart';

class SongsScreen extends StatefulWidget {
  final GuitarSongsController? controller;

  const SongsScreen({
    super.key,
    this.controller,
  });

  @override
  State<SongsScreen> createState() => _SongsScreenState();
}

class _SongsScreenState extends State<SongsScreen> {
  GuitarSongsController? _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller;
      _isLoading = false;
    } else {
      _initController();
    }
  }

  Future<void> _initController() async {
    final ctrl = await GuitarSongsController.init();
    if (mounted) {
      setState(() {
        _controller = ctrl;
        _isLoading = false;
      });
    }
  }

  Future<void> _openVideoLink(String link) async {
    String url = link.trim();
    if (url.isEmpty) return;

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    final uri = Uri.tryParse(url);
    if (uri != null) {
      try {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (!launched && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open video link.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open video link.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid video link URL.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _copyLink(String link) async {
    await Clipboard.setData(ClipboardData(text: link));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link copied to clipboard!'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showAddSongDialog() {
    final nameController = TextEditingController();
    final linkController = TextEditingController();
    String? errorMessage;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final colors = context.appColors;

          return AlertDialog(
            backgroundColor: colors.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              side: BorderSide(
                color: colors.border,
                width: AppTheme.borderWidth,
              ),
            ),
            title: Text(
              'Add Song',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: colors.textMain,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    key: const Key('song_name_input'),
                    controller: nameController,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Song / Video Name',
                      hintText: 'e.g. Stairway to Heaven Solo',
                      labelStyle: TextStyle(color: colors.textSecondary),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        borderSide: BorderSide(color: colors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        borderSide: BorderSide(color: colors.primary, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const Key('song_link_input'),
                    controller: linkController,
                    decoration: InputDecoration(
                      labelText: 'Video Link',
                      hintText: 'e.g. https://youtu.be/...',
                      labelStyle: TextStyle(color: colors.textSecondary),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        borderSide: BorderSide(color: colors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        borderSide: BorderSide(color: colors.primary, width: 2),
                      ),
                    ),
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      errorMessage!,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.missed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                key: const Key('cancel_add_song_button'),
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                key: const Key('save_song_button'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                ),
                onPressed: () async {
                  final name = nameController.text.trim();
                  final link = linkController.text.trim();

                  if (name.isEmpty || link.isEmpty) {
                    setDialogState(() {
                      errorMessage = 'Song name and video link cannot be empty.';
                    });
                    return;
                  }

                  if (_controller != null) {
                    await _controller!.addSong(name, link);
                  }
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditSongDialog(GuitarSong song) {
    final nameController = TextEditingController(text: song.name);
    final linkController = TextEditingController(text: song.videoLink);
    String? errorMessage;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final colors = context.appColors;

          return AlertDialog(
            backgroundColor: colors.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              side: BorderSide(
                color: colors.border,
                width: AppTheme.borderWidth,
              ),
            ),
            title: Text(
              'Edit Song',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: colors.textMain,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    key: const Key('edit_song_name_input'),
                    controller: nameController,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Song / Video Name',
                      hintText: 'e.g. Stairway to Heaven Solo',
                      labelStyle: TextStyle(color: colors.textSecondary),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        borderSide: BorderSide(color: colors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        borderSide: BorderSide(color: colors.primary, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const Key('edit_song_link_input'),
                    controller: linkController,
                    decoration: InputDecoration(
                      labelText: 'Video Link',
                      hintText: 'e.g. https://youtu.be/...',
                      labelStyle: TextStyle(color: colors.textSecondary),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        borderSide: BorderSide(color: colors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        borderSide: BorderSide(color: colors.primary, width: 2),
                      ),
                    ),
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      errorMessage!,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.missed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                key: const Key('cancel_edit_song_button'),
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                key: const Key('save_edit_song_button'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                ),
                onPressed: () async {
                  final name = nameController.text.trim();
                  final link = linkController.text.trim();

                  if (name.isEmpty || link.isEmpty) {
                    setDialogState(() {
                      errorMessage = 'Song name and video link cannot be empty.';
                    });
                    return;
                  }

                  if (_controller != null) {
                    await _controller!.updateSong(song.id, name, link);
                  }
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading || _controller == null) {
      return Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          title: const Text('Songs'),
          backgroundColor: colors.background,
          elevation: 0,
          iconTheme: IconThemeData(color: colors.textMain),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          'Songs',
          style: TextStyle(
            color: colors.textMain,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: colors.background,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textMain),
      ),
      body: ValueListenableBuilder<List<GuitarSong>>(
        valueListenable: _controller!,
        builder: (context, songs, _) {
          if (songs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: colors.barBackground,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colors.border,
                          width: AppTheme.borderWidth,
                        ),
                      ),
                      child: Icon(
                        Icons.queue_music_outlined,
                        size: 32,
                        color: colors.secondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Songs Added Yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: colors.textMain,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tap + below to add your practice songs and video lessons.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];
              return Container(
                key: Key('song_card_${song.id}'),
                margin: const EdgeInsets.only(bottom: 12.0),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  border: Border.all(
                    color: colors.border,
                    width: AppTheme.borderWidth,
                  ),
                  boxShadow: isDark ? null : AppTheme.lightCardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: colors.highlight,
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                          ),
                          child: Icon(
                            Icons.music_note,
                            size: 20,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            song.name,
                            key: Key('song_name_${song.id}'),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: colors.textMain,
                            ),
                          ),
                        ),
                        IconButton(
                          key: Key('edit_song_button_${song.id}'),
                          icon: Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: colors.textSecondary,
                          ),
                          tooltip: 'Edit / replace song',
                          onPressed: () => _showEditSongDialog(song),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10.0,
                        vertical: 6.0,
                      ),
                      decoration: BoxDecoration(
                        color: colors.barBackground,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        border: Border.all(color: colors.border, width: 1),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.link,
                            size: 16,
                            color: colors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              key: Key('song_link_${song.id}'),
                              onTap: () => _openVideoLink(song.videoLink),
                              behavior: HitTestBehavior.opaque,
                              child: Text(
                                song.videoLink,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: colors.primary,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            key: Key('copy_link_button_${song.id}'),
                            icon: Icon(
                              Icons.copy_rounded,
                              size: 16,
                              color: colors.secondary,
                            ),
                            tooltip: 'Copy video link',
                            visualDensity: VisualDensity.compact,
                            onPressed: () => _copyLink(song.videoLink),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('add_song_button'),
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        onPressed: _showAddSongDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
