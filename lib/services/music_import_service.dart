import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:drift/drift.dart';
import '../database/database.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p; // 跨平台路径处理
import 'dart:async';
import '../services/audio_player_service.dart';

class CoverImage {
  final Uint8List bytes;
  final String type;

  CoverImage._(this.bytes, this.type);

  String get mime {
    switch (type.toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'jpeg':
      case 'jpg':
        return 'image/jpeg';
      default:
        return 'application/octet-stream';
    }
  }

  static CoverImage? fromBytes(Uint8List data) {
    final pngHeader = [0x89, 0x50, 0x4E, 0x47]; // PNG
    final jpegHeader = [0xFF, 0xD8]; // JPEG

    int start = -1;
    String? type;

    for (int i = 0; i < data.length - 4; i++) {
      if (data.sublist(i, i + 4).join(',') == pngHeader.join(',')) {
        start = i;
        type = 'png';
        break;
      }
      if (i < data.length - 2 &&
          data.sublist(i, i + 2).join(',') == jpegHeader.join(',')) {
        start = i;
        type = 'jpeg';
        break;
      }
    }
    if (start == -1 || type == null) return null;
    return CoverImage._(data.sublist(start), type);
  }
}

abstract class ImportEvent {
  const ImportEvent();
}

class SelectedEvent extends ImportEvent {
  const SelectedEvent();
}

class ScaningEvent extends ImportEvent {
  final int count;
  const ScaningEvent(this.count);
}

class ScanCompletedEvent extends ImportEvent {
  final int count;
  final List<File> musicFiles;
  ScanCompletedEvent(this.count, [this.musicFiles = const []]);
}

class ProgressingEvent extends ImportEvent {
  final String currentFile;
  final int processed;
  final int total;

  const ProgressingEvent(this.currentFile, this.processed, this.total);

  double get progress => total > 0 ? processed / total : 0.0;
}

class CompletedEvent extends ImportEvent {
  const CompletedEvent();
}

class FailedEvent extends ImportEvent {
  final String error;
  final String? filePath;

  const FailedEvent(this.error, {this.filePath});
}

class CancelledEvent extends ImportEvent {
  const CancelledEvent();
}

class MusicImportService {
  final List<String> supportedExtensions = ['mp3', 'm4a', 'wav', 'flac'];

  MusicImportService();

  bool _isCancelled = false;

  /// 从文件夹导入音乐
  Stream<ImportEvent> importFromDirectory() async* {
    _isCancelled = false;

    try {
      final dir = await FilePicker.platform.getDirectoryPath(
        lockParentWindow: true,
      );

      if (dir == null) return;

      yield const SelectedEvent();

      if (_isCancelled) {
        yield const CancelledEvent();
        return;
      }

      List<File> musicFiles = [];

      // 监听扫描事件并转发
      final scanStream = _listMusicFiles(Directory(dir));
      await for (final event in scanStream) {
        if (event is ScaningEvent) {
          yield event; // 转发扫描事件
        } else if (event is ScanCompletedEvent) {
          musicFiles = event.musicFiles;
          yield event;
          break;
        } else if (event is FailedEvent) {
          yield event;
          return;
        }
      }

      if (musicFiles.isEmpty) {
        yield const FailedEvent('未找到支持的音乐文件');
        yield const CompletedEvent();
        return;
      }

      yield* _processFiles(musicFiles);
    } catch (e) {
      yield FailedEvent('选择文件夹时发生错误: ${e.toString()}');
      yield const CompletedEvent();
    }
  }

  /// 导入选定的文件
  Stream<ImportEvent> importFiles() async* {
    _isCancelled = false;

    try {
      final result = await FilePicker.platform.pickFiles(
        allowedExtensions: supportedExtensions,
        type: FileType.custom,
        allowMultiple: true,
        lockParentWindow: true,
      );

      if (result == null) return;

      yield const SelectedEvent();

      if (_isCancelled) {
        yield const CancelledEvent();
        return;
      }

      final musicFiles = result.files
          .where((file) => file.path != null)
          .map((file) => File(file.path!))
          .toList();

      yield ScanCompletedEvent(musicFiles.length);

      if (musicFiles.isEmpty) {
        yield const FailedEvent('未选择有效的音乐文件');
        yield const CompletedEvent();
        return;
      }

      yield* _processFiles(musicFiles);
    } catch (e) {
      yield FailedEvent('选择文件时发生错误: ${e.toString()}');
      yield const CompletedEvent();
    }
  }

  static Future<bool> importLyrics(Song song) async {
    final result = await FilePicker.platform.pickFiles(
      allowedExtensions: ['lrc', 'ttml'],
      type: FileType.custom,
      allowMultiple: false,
      lockParentWindow: false,
    );

    try {
      if (result != null) {
        for (final file in result.files) {
          final lyrics = File(file.path!).readAsStringSync();
          AudioPlayerService.database.updateSong(
            song.copyWith(lyrics: Value(lyrics)),
          );
          updateMetadata(File(song.filePath), (metadata) {
            metadata.setLyrics(lyrics);
          });
          return true;
        }
      }
    } catch (e) {
      return false;
    }
    return false;
  }

  static Future<String?> importAlbumArt(Song song) async {
  try {
    final result = await FilePicker.platform.pickFiles(
      allowedExtensions: ['jpg', 'jpeg', 'png'],
      type: FileType.custom,
      allowMultiple: false,
      lockParentWindow: false,
    );

    if (result == null || result.files.isEmpty) return null;

    final file = result.files.first;
    if (file.path == null) return null;

    CoverImage? cover = CoverImage.fromBytes(await File(file.path!).readAsBytes());
    if(cover==null){
      return null;
    }

    final dbFolder = await getApplicationSupportDirectory();
    final albumArtDir = Directory(p.join(dbFolder.path, '.album_art'));
    await albumArtDir.create(recursive: true);

    // 删除旧封面
    if (song.albumArtPath != null && song.albumArtPath != null) {
      final oldFile = File(song.albumArtPath!);
      if (await oldFile.exists()) {
        await oldFile.delete();
      }
    }

    // 使用 MD5 命名新封面
    final md5Hash = md5.convert(cover.bytes).toString();
    final ext = p.extension(file.path!).replaceFirst('.', '');
    final albumArtFile = File(p.join(albumArtDir.path, '$md5Hash.$ext'));

    await albumArtFile.writeAsBytes(cover.bytes, flush: true);

    // 更新数据库
    AudioPlayerService.database.updateSong(
      song.copyWith(albumArtPath: Value(albumArtFile.path)),
    );
    updateMetadata(File(song.filePath), (metadata) {
            metadata.setPictures([Picture(cover.bytes, cover.mime, PictureType.coverFront)]);
          });

    return albumArtFile.path;
  } catch (e) {
    print('Failed to import album art: $e');
    return null;
  }
}

  Stream<ImportEvent> _listMusicFiles(Directory dir) async* {
    final List<File> musicFiles = [];

    try {
      await for (final entity in dir.list(recursive: true)) {
        if (_isCancelled) {
          yield const CancelledEvent();
          return;
        }

        if (entity is File) {
          final extension = p.extension(entity.path).toLowerCase();
          if (supportedExtensions.contains(extension.replaceFirst('.', ''))) {
            musicFiles.add(entity);
          }
          yield ScaningEvent(musicFiles.length);
        }
      }

      yield ScanCompletedEvent(musicFiles.length, musicFiles);
    } catch (e) {
      yield FailedEvent('扫描目录失败: ${e.toString()}');
    }
  }

  /// 处理文件列表的Stream
  Stream<ImportEvent> _processFiles(List<File> musicFiles) async* {
    int processed = 0;

    for (final file in musicFiles) {
      if (_isCancelled) {
        yield const CancelledEvent();
        return;
      }
      final fileName = p.basename(file.path);
      yield ProgressingEvent(fileName, processed, musicFiles.length);

      try {
        await _processMusicFile(file);
        processed++;
        yield ProgressingEvent(fileName, processed, musicFiles.length);
      } catch (e) {
        yield FailedEvent(e.toString(), filePath: file.path);
        continue;
      }
    }

    yield const CompletedEvent();
  }

  /// 取消导入
  void cancel() {
    _isCancelled = true;
  }

  Future<void> _processMusicFile(File file) async {
    final metadata = readMetadata(file, getImage: true);
    final String title = metadata.title ?? p.basename(file.path);
    final String? artist = metadata.artist;

    final existingSongs =
        await (AudioPlayerService.database.songs.select()..where(
              (tbl) =>
                  tbl.title.equals(title) &
                  (artist != null
                      ? tbl.artist.equals(artist)
                      : tbl.artist.isNull()),
            ))
            .get();

    if (existingSongs.isNotEmpty) {
      return;
    }

    String? albumArtPath;
    if (metadata.pictures.isNotEmpty) {
      final dbFolder = await getApplicationSupportDirectory();
      final picture = metadata.pictures.first;
      CoverImage? cover = CoverImage.fromBytes(picture.bytes);
      if (cover != null) {
        // 计算图片内容的MD5哈希
        final md5Hash = md5.convert(cover.bytes).toString();
        final fileName = '$md5Hash.${cover.type}';

        final albumArtFile = File(
          p.join(dbFolder.path, '.album_art', fileName),
        );
        await albumArtFile.parent.create(recursive: true);
        // 如果文件已存在则不重复写入
        if (!await albumArtFile.exists()) {
          await albumArtFile.writeAsBytes(cover.bytes);
        }
        albumArtPath = albumArtFile.path;
      }
    }

    await AudioPlayerService.database.insertSong(
      SongsCompanion.insert(
        title: title,
        artist: Value(artist),
        album: Value(metadata.album),
        filePath: file.path,
        lyrics: Value(metadata.lyrics),
        bitrate: Value(metadata.bitrate),
        sampleRate: Value(metadata.sampleRate),
        duration: Value(metadata.duration?.inSeconds),
        albumArtPath: Value(albumArtPath),
      ),
    );
  }
}
