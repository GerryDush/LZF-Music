import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:drift/drift.dart';
import '../database/database.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p; // 跨平台路径处理
class CoverImage {
  final Uint8List bytes;
  final String type;

  CoverImage._(this.bytes, this.type);

  static CoverImage? fromBytes(Uint8List data) {
    final pngHeader = [0x89, 0x50, 0x4E, 0x47]; // PNG
    final jpegHeader = [0xFF, 0xD8];           // JPEG

    int start = -1;
    String? type;

    for (int i = 0; i < data.length - 4; i++) {
      if (data.sublist(i, i + 4).join(',') == pngHeader.join(',')) {
        start = i;
        type = 'png';
        break;
      }
      if (i < data.length - 2 && data.sublist(i, i + 2).join(',') == jpegHeader.join(',')) {
        start = i;
        type = 'jpeg';
        break;
      }
    }
    if (start == -1 || type == null) return null;
    return CoverImage._(data.sublist(start), type);
  }
}

class MusicImportService {
  final MusicDatabase database;

  MusicImportService(this.database);

  Future<String> importFromDirectory({
    void Function(int processed, int total)? onProgress,
  }) async {
    final result = await FilePicker.platform.getDirectoryPath(
      lockParentWindow: true,
    );
    if (result != null) {
      return await processDirectoryWithProgress(Directory(result), 
        onProgress: onProgress ?? (processed, total) {
          print('Processed $processed of $total files');
        },
        fileCount: await countMusicFiles(Directory(result))
      );
    }
    return '';
  }

  Future<String> importFiles(
    {required void Function(int processed, int total) onProgress}
  ) async {
    final result = await FilePicker.platform.pickFiles(
      allowedExtensions: ['mp3', 'm4a', 'wav', 'flac', 'aac'],
      type: FileType.custom,
      allowMultiple: true,
      lockParentWindow: true,
    );
    List<String> failedFiles = [];
    if (result != null) {
      int count = result.files.length;
      int successCount = 0;
      int failCount = 0;
      for (final file in result.files) {
        if (file.path != null) {
          try {
            await _processMusicFile(File(file.path!));
            successCount++;
          } catch (e) {
            failCount++;
            failedFiles.add(file.path!);
          }
        }
        onProgress(successCount + failCount, count);
      }
    }
    return failedFiles.join(',');
  }

  Future<void> importLRC(Song song) async {
    final result = await FilePicker.platform.pickFiles(
      allowedExtensions: ['lrc'],
      type: FileType.custom,
      allowMultiple: false,
      lockParentWindow: false,
    );

    if (result != null) {
      for (final file in result.files) {
        final lyric = File(file.path!).readAsStringSync();
        updateMetadata(File(song.filePath), (metadata) {
          metadata.setLyrics("fuck you");
        });
        print(lyric);

        final a = readMetadata(File(song.filePath), getImage: true);
        print(a);
        return;
      }
    }
  }

  Future<int> countMusicFiles(
    Directory directory, {
    int maxDepth = 3,
    int currentDepth = 0,
  }) async {
    if (currentDepth > maxDepth) return 0;

    int count = 0;

    await for (final entity in directory.list(followLinks: false)) {
      if (entity is File) {
        final extension = p.extension(entity.path).toLowerCase().replaceFirst('.', '');
        if (['mp3', 'm4a', 'wav', 'flac', 'aac'].contains(extension)) {
          count++;
        }
      } else if (entity is Directory) {
        count += await countMusicFiles(
          entity,
          maxDepth: maxDepth,
          currentDepth: currentDepth + 1,
        );
      }
    }

    return count;
  }

  Future<String> processDirectoryWithProgress(
    Directory directory, {
    required int fileCount,
    required void Function(int processed, int total) onProgress,
    int successCount = 0,
    int failCount = 0,
    List<String>? failedFiles,
    int maxDepth = 3,
    int currentDepth = 0,
  }) async {
    failedFiles ??= [];
    if (currentDepth > maxDepth) return '';
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is File) {
        final extension = p
            .extension(entity.path)
            .toLowerCase()
            .replaceFirst('.', '');
        if (['mp3', 'm4a', 'wav', 'flac', 'aac'].contains(extension)) {
          try {
            await _processMusicFile(entity);
            successCount++;
          } catch (e) {
            failCount++;
            failedFiles.add(entity.path);
            print('Failed to process ${entity.path}: $e');
          }
          onProgress(successCount + failCount, fileCount);
        } else {
          print('Unsupported file format: ${entity.path}');
        }
      } else if (entity is Directory) {
        String failedSubdirectories = await processDirectoryWithProgress(
          entity,
          maxDepth: maxDepth,
          currentDepth: currentDepth + 1,
          fileCount: fileCount,
          onProgress: onProgress,
        );
        failedFiles.add(failedSubdirectories);
      }
    }
    return failedFiles.join(',');
  }

  Future<void> _processMusicFile(File file) async {
      final metadata = await readMetadata(file, getImage: true);

      final String title = metadata.title ?? p.basename(file.path);
      final String? artist = metadata.artist;

      final existingSongs =
          await (database.songs.select()..where(
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
        if(cover!=null){
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

      await database.insertSong(
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
