import 'package:flutter/material.dart';
import '../database/database.dart';
import 'lzf_dialog.dart';

class SongActionMenu extends StatelessWidget {
  final Song song;
  final VoidCallback? onDelete;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onImportLyrics;

  const SongActionMenu({
    super.key,
    required this.song,
    this.onDelete,
    this.onFavoriteToggle,
    this.onImportLyrics
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded),
      iconSize: 20,
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'import_lyrics',
          child: Row(
            children: [
              Icon(Icons.book_rounded, size: 18),
              SizedBox(width: 8),
              Text('导入歌词'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text('删除', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        
      ],
      onSelected: (value) {
        switch (value) {
          case 'import_lyrics':
          onImportLyrics?.call();
          case 'favorite':
            onFavoriteToggle?.call();
            break;
          case 'delete':
            LZFDialog.show(
              context,
              titleText: '删除歌曲',
              content: Text('确定要删除歌曲 "${song.title} - ${song.artist}" 吗？'),
              cancelText: '取消',
              confirmText: '确定',
              danger: true,
              onConfirm: () {
                onDelete?.call();
              },
            );
            break;
        }
      },
    );
  }
}

class FavoriteButton extends StatelessWidget {
  final Song song;
  final VoidCallback? onToggle;

  const FavoriteButton({super.key, required this.song, this.onToggle});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onToggle,
      iconSize: 20,
      icon: Icon(
        song.isFavorite
            ? Icons.favorite_rounded
            : Icons.favorite_outline_rounded,
        color: song.isFavorite ? Colors.red : null,
      ),
    );
  }
}
