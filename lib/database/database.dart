import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:lzf_music/utils/common_utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';
part 'database.g.dart';

class Songs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get artist => text().nullable()();
  TextColumn get album => text().nullable()();
  TextColumn get filePath => text()();
  TextColumn get lyrics => text().nullable()();
  IntColumn get bitrate => integer().nullable()();
  IntColumn get sampleRate => integer().nullable()();
  IntColumn get duration => integer().nullable()(); // Duration in seconds
  TextColumn get albumArtPath => text().nullable()();
  DateTimeColumn get dateAdded => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastPlayedTime =>
      dateTime().withDefault(currentDateAndTime)();
  IntColumn get playedCount => integer().withDefault(const Constant(0))();
}

@DriftDatabase(tables: [Songs])
class MusicDatabase extends _$MusicDatabase {
  static late MusicDatabase _database;
  static MusicDatabase get database => _database;
  MusicDatabase._() : super(_openConnection());
  static MusicDatabase initialize() {
    _database = MusicDatabase._();
    return _database;
  }

  @override
  int get schemaVersion => 1;

  // 获取所有歌曲
  Future<List<Song>> getAllSongs() async {
    return await select(songs).get();
  }

  // 模糊查询 - 支持歌曲名称、艺术家、专辑
  Future<List<Song>> searchSongs(String keyword) async {
    if (keyword.trim().isEmpty) {
      return await getAllSongs();
    }

    final query = select(songs)
      ..where(
        (song) =>
            song.title.like('%$keyword%') |
            song.artist.like('%$keyword%') |
            song.album.like('%$keyword%'),
      )
      ..orderBy([
        // 优先显示标题匹配的结果
        (song) => OrderingTerm(
          expression: CaseWhenExpression(
            cases: [
              CaseWhen(song.title.like('%$keyword%'), then: const Constant(0)),
              CaseWhen(song.artist.like('%$keyword%'), then: const Constant(1)),
              CaseWhen(song.album.like('%$keyword%'), then: const Constant(2)),
            ],
            orElse: const Constant(3),
          ),
        ),
        // 然后按标题排序
        (song) => OrderingTerm.asc(song.title),
      ]);

    return await query.get();
  }

  // 更精确的模糊查询 - 分别指定搜索字段
  Future<List<Song>> searchSongsAdvanced({
    String? title,
    String? artist,
    String? album,
  }) async {
    final query = select(songs);

    Expression<bool>? whereExpression;

    if (title != null && title.isNotEmpty) {
      whereExpression = songs.title.like('%$title%');
    }

    if (artist != null && artist.isNotEmpty) {
      final artistCondition = songs.artist.like('%$artist%');
      whereExpression = whereExpression == null
          ? artistCondition
          : whereExpression & artistCondition;
    }

    if (album != null && album.isNotEmpty) {
      final albumCondition = songs.album.like('%$album%');
      whereExpression = whereExpression == null
          ? albumCondition
          : whereExpression & albumCondition;
    }

    if (whereExpression != null) {
      query.where((song) => whereExpression!);
    }

    query.orderBy([(song) => OrderingTerm.asc(song.title)]);

    return await query.get();
  }

  // 按艺术家搜索
  Future<List<Song>> searchByArtist(String artist) async {
    if (artist.trim().isEmpty) return [];

    return await (select(songs)
          ..where((song) => song.artist.like('%$artist%'))
          ..orderBy([
            (song) => OrderingTerm.asc(song.album),
            (song) => OrderingTerm.asc(song.title),
          ]))
        .get();
  }

  // 按专辑搜索
  Future<List<Song>> searchByAlbum(String album) async {
    if (album.trim().isEmpty) return [];

    return await (select(songs)
          ..where((song) => song.album.like('%$album%'))
          ..orderBy([(song) => OrderingTerm.asc(song.title)]))
        .get();
  }

  // 获取所有艺术家（用于搜索提示）
  Future<List<String>> getAllArtists() async {
    final query = selectOnly(songs)
      ..addColumns([songs.artist])
      ..where(songs.artist.isNotNull())
      ..groupBy([songs.artist])
      ..orderBy([OrderingTerm.asc(songs.artist)]);

    final result = await query.get();
    return result
        .map((row) => row.read(songs.artist))
        .where((artist) => artist != null)
        .cast<String>()
        .toList();
  }

  // 获取所有专辑（用于搜索提示）
  Future<List<String>> getAllAlbums() async {
    final query = selectOnly(songs)
      ..addColumns([songs.album])
      ..where(songs.album.isNotNull())
      ..groupBy([songs.album])
      ..orderBy([OrderingTerm.asc(songs.album)]);

    final result = await query.get();
    return result
        .map((row) => row.read(songs.album))
        .where((album) => album != null)
        .cast<String>()
        .toList();
  }

  // 组合搜索 - 支持多个关键词
  Future<List<Song>> searchSongsMultipleKeywords(List<String> keywords) async {
    if (keywords.isEmpty) {
      return await getAllSongs();
    }

    Expression<bool>? whereExpression;

    for (final keyword in keywords) {
      if (keyword.trim().isEmpty) continue;

      final keywordCondition =
          songs.title.like('%$keyword%') |
          songs.artist.like('%$keyword%') |
          songs.album.like('%$keyword%');

      whereExpression = whereExpression == null
          ? keywordCondition
          : whereExpression & keywordCondition;
    }

    final query = select(songs);
    if (whereExpression != null) {
      query.where((song) => whereExpression!);
    }

    query.orderBy([(song) => OrderingTerm.asc(song.title)]);
    return await query.get();
  }

  // 基本搜索（不使用 lower() 函数）
  Future<List<Song>> basicSearch(String keyword) async {
    if (keyword.trim().isEmpty) {
      return await getAllSongs();
    }

    // 转为小写进行搜索（在 Dart 层面处理）
    final lowerKeyword = keyword.toLowerCase();

    final query = select(songs)
      ..where(
        (song) =>
            song.title.like('%$lowerKeyword%') |
            song.artist.like('%$lowerKeyword%') |
            song.album.like('%$lowerKeyword%'),
      )
      ..orderBy([
        // 标题匹配优先
        (song) => OrderingTerm(
          expression: CaseWhenExpression(
            cases: [
              CaseWhen(
                song.title.like('%$lowerKeyword%'),
                then: const Constant(0),
              ),
              CaseWhen(
                song.artist.like('%$lowerKeyword%'),
                then: const Constant(1),
              ),
              CaseWhen(
                song.album.like('%$lowerKeyword%'),
                then: const Constant(2),
              ),
            ],
            orElse: const Constant(3),
          ),
        ),
        (song) => OrderingTerm.asc(song.title),
      ]);

    return await query.get();
  }

  // 不区分大小写的搜索（手动转换）
  Future<List<Song>> caseInsensitiveSearch(String keyword) async {
    if (keyword.trim().isEmpty) {
      return await getAllSongs();
    }

    // 获取所有歌曲，然后在内存中过滤
    final allSongs = await getAllSongs();
    final lowerKeyword = keyword.toLowerCase();

    final filteredSongs = allSongs.where((song) {
      final title = song.title.toLowerCase();
      final artist = (song.artist ?? '').toLowerCase();
      final album = (song.album ?? '').toLowerCase();

      return title.contains(lowerKeyword) ||
          artist.contains(lowerKeyword) ||
          album.contains(lowerKeyword);
    }).toList();

    // 排序：标题匹配优先
    filteredSongs.sort((a, b) {
      final aTitle = a.title.toLowerCase();
      final bTitle = b.title.toLowerCase();
      final aArtist = (a.artist ?? '').toLowerCase();
      final bArtist = (b.artist ?? '').toLowerCase();

      // 完全匹配优先
      if (aTitle == lowerKeyword) return -1;
      if (bTitle == lowerKeyword) return 1;
      if (aArtist == lowerKeyword) return -1;
      if (bArtist == lowerKeyword) return 1;

      // 开头匹配次优先
      if (aTitle.startsWith(lowerKeyword) && !bTitle.startsWith(lowerKeyword))
        return -1;
      if (bTitle.startsWith(lowerKeyword) && !aTitle.startsWith(lowerKeyword))
        return 1;
      if (aArtist.startsWith(lowerKeyword) && !bArtist.startsWith(lowerKeyword))
        return -1;
      if (bArtist.startsWith(lowerKeyword) && !aArtist.startsWith(lowerKeyword))
        return 1;

      // 其他情况按标题排序
      return aTitle.compareTo(bTitle);
    });

    return filteredSongs;
  }

  Future<List<Song>> smartSearch(
    String? keyword, {
    String? orderField,
    String? orderDirection,
    bool? isFavorite,
    bool? isLastPlayed,
  }) async {
    final query = select(songs);
    if (keyword != null && keyword.trim().isNotEmpty) {
      final lowerKeyword = keyword.toLowerCase();

      query.where(
        (song) =>
            song.title.lower().like('%$lowerKeyword%') |
            song.artist.lower().like('%$lowerKeyword%') |
            song.album.lower().like('%$lowerKeyword%'),
      );

      // 优先级排序的条件
      if (isLastPlayed == null) {
        query.orderBy([
          (song) => OrderingTerm(
            expression: CaseWhenExpression(
              cases: [
                CaseWhen(
                  song.title.lower().equals(lowerKeyword),
                  then: const Constant(0),
                ),
                CaseWhen(
                  song.artist.lower().equals(lowerKeyword),
                  then: const Constant(1),
                ),
                CaseWhen(
                  song.album.lower().equals(lowerKeyword),
                  then: const Constant(2),
                ),
                CaseWhen(
                  song.title.lower().like('$lowerKeyword%'),
                  then: const Constant(3),
                ),
                CaseWhen(
                  song.artist.lower().like('$lowerKeyword%'),
                  then: const Constant(4),
                ),
                CaseWhen(
                  song.album.lower().like('$lowerKeyword%'),
                  then: const Constant(5),
                ),
              ],
              orElse: const Constant(6),
            ),
          ),
        ]);
      }
    }
    if (isFavorite != null) {
      query.where((song) => song.isFavorite.equals(isFavorite));
    }
    if (isLastPlayed == true) {
      query.where((song) => song.playedCount.isBiggerThanValue(0));
      query.orderBy([(song) => OrderingTerm.desc(song.lastPlayedTime)]);
      query.limit(100);
      return await query.get();
    }

    // 无论有没有关键字，都执行排序逻辑
    query.orderBy([
      (song) {
        if (orderField == null || orderDirection == null) {
          return OrderingTerm.desc(song.id);
        }
        final Expression orderExpr;
        switch (orderField) {
          case 'id':
            orderExpr = song.duration;
            break;
          case 'title':
            orderExpr = song.title;
            break;
          case 'artist':
            orderExpr = song.artist;
            break;
          case 'album':
            orderExpr = song.album;
            break;
          case 'duration':
            orderExpr = song.duration;
            break;
          default:
            orderExpr = song.id;
        }
        return orderDirection.toLowerCase() == 'desc'
            ? OrderingTerm.desc(orderExpr)
            : OrderingTerm.asc(orderExpr);
      },
    ]);

    return await query.get();
  }

  // 插入歌曲
  Future<int> insertSong(SongsCompanion song) async {
    return await into(songs).insert(song);
  }

  // 批量插入歌曲
  Future<void> insertSongs(List<SongsCompanion> songsList) async {
    await batch((batch) {
      batch.insertAll(songs, songsList);
    });
  }

  // 更新歌曲
  Future<bool> updateSong(Song song) async {
    return await update(songs).replace(song);
  }

  // 删除歌曲
  Future<int> deleteSong(int id) async {
    return await (delete(songs)..where((song) => song.id.equals(id))).go();
  }

  // 检查歌曲是否已存在
  Future<Song?> getSongByPath(String filePath) async {
    final query = select(songs)
      ..where((song) => song.filePath.equals(filePath));
    final result = await query.getSingleOrNull();
    return result;
  }

  // 获取歌曲总数
  Future<int> getSongsCount() async {
    final count = countAll();
    final query = selectOnly(songs)..addColumns([count]);
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  // 按日期获取最近添加的歌曲
  Future<List<Song>> getRecentSongs([int limit = 20]) async {
    return await (select(songs)
          ..orderBy([(song) => OrderingTerm.desc(song.dateAdded)])
          ..limit(limit))
        .get();
  }
}

Future<void> _deleteDirectoryContents(Directory directory) async {
  try {
    await for (var entity in directory.list(recursive: true)) {
      if (entity is File) {
        if (p.basename(entity.path) == 'libCachedImageData.db') {
          continue;
        }
        await entity.delete();
        debugPrint('已删除文件：${entity.path}');
      } else if (entity is Directory) {
        await _deleteDirectoryContents(entity);
        entity.deleteSync();
        debugPrint('已删除子目录：${entity.path}');
      }
    }
  } catch (e) {
    debugPrint('删除目录内容时出错: $e');
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final oldDbFolder = await getApplicationSupportDirectory();
    if (await oldDbFolder.exists()) {
      await _deleteDirectoryContents(oldDbFolder);
      debugPrint('旧目录及其内容已删除：$oldDbFolder');
    } else {
      debugPrint('旧目录不存在：$oldDbFolder');
    }

    final basePath = await CommonUtils.getAppBaseDirectory();
    debugPrint("APP根目录：${basePath}");
    final file = File(p.join(basePath, 'lzf-music.db'));
    return NativeDatabase.createInBackground(file);
  });
}
