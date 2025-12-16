import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:lzf_music/utils/common_utils.dart';
import 'package:path/path.dart' as p;
import './tables.dart';
import 'dart:ui';
import '../widgets/lyric/lyrics_models.dart';
import '../model/song_list_item.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Songs, Playlists, PlaylistSongs])
class MusicDatabase extends _$MusicDatabase {
  static late MusicDatabase _database;
  static MusicDatabase get database => _database;

  MusicDatabase._() : super(_openConnection());

  static MusicDatabase initialize() {
    _database = MusicDatabase._();
    return _database;
  }

  @override
  int get schemaVersion => 3;

 @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          await customStatement('PRAGMA foreign_keys = OFF');
          for (final table in allTables) {
            await m.deleteTable(table.actualTableName);
          }
          await customStatement('PRAGMA foreign_keys = ON');
          await m.createAll();
        },
        beforeOpen: (details) async {
        }
      );

  Future<Song?> getSongById(int id) async {
    final query = select(songs)..where((song) => song.id.equals(id));
    return await query.getSingleOrNull();
  }

  Future<List<SongListItem>> getSongsByIds(List<int> ids) async {
    if (ids.isEmpty) return [];

    final query = select(songs)..where((song) => song.id.isIn(ids));
    final result = await query.get();

    return result
        .map((row) => SongListItem(
              id: row.id,
              title: row.title,
              artist: row.artist,
              album: row.album,
              genre: row.genre,
              albumArtThumbPath: row.albumArtThumbPath,
              duration: row.duration,
              sampleRate: row.sampleRate,
              bitrate: row.bitrate,
              isFavorite: row.isFavorite,
            ))
        .toList();
  }

  Future<List<SongListItem>> smartSearch(
    String? keyword, {
    String? orderField,
    String? orderDirection,
    bool? isFavorite,
    bool? isLastPlayed,
  }) async {
    final query = select(songs);

    // 搜索关键字
    if (keyword != null && keyword.trim().isNotEmpty) {
      final lowerKeyword = keyword.toLowerCase();
      query.where(
        (song) =>
            song.title.lower().like('%$lowerKeyword%') |
            song.artist.lower().like('%$lowerKeyword%') |
            song.album.lower().like('%$lowerKeyword%'),
      );

      // 优先排序逻辑
      if (isLastPlayed == null) {
        query.orderBy([
          (song) => OrderingTerm(
                expression: CaseWhenExpression(
                  cases: [
                    CaseWhen(song.title.lower().equals(lowerKeyword),
                        then: const Constant(0)),
                    CaseWhen(song.artist.lower().equals(lowerKeyword),
                        then: const Constant(1)),
                    CaseWhen(song.album.lower().equals(lowerKeyword),
                        then: const Constant(2)),
                    CaseWhen(song.title.lower().like('$lowerKeyword%'),
                        then: const Constant(3)),
                    CaseWhen(song.artist.lower().like('$lowerKeyword%'),
                        then: const Constant(4)),
                    CaseWhen(song.album.lower().like('$lowerKeyword%'),
                        then: const Constant(5)),
                  ],
                  orElse: const Constant(6),
                ),
              ),
        ]);
      }
    }

    // 过滤收藏
    if (isFavorite != null) {
      query.where((song) => song.isFavorite.equals(isFavorite));
    }

    // 最近播放
    if (isLastPlayed == true) {
      query.where((song) => song.playedCount.isBiggerThanValue(0));
      query.orderBy([(song) => OrderingTerm.desc(song.lastPlayedTime)]);
      query.limit(100);
      final result = await query.get();
      return result
          .map((row) => SongListItem(
                id: row.id,
                title: row.title,
                artist: row.artist,
                album: row.album,
                genre: row.genre,
                albumArtThumbPath: row.albumArtThumbPath,
                duration: row.duration,
                sampleRate: row.sampleRate,
                bitrate: row.bitrate,
                isFavorite: row.isFavorite,
              ))
          .toList();
    }

    // 普通排序
    query.orderBy([
      (song) {
        if (orderField == null || orderDirection == null) {
          return OrderingTerm.desc(song.id);
        }
        final Expression orderExpr;
        switch (orderField) {
          case 'id':
            orderExpr = song.id;
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

    // 执行查询
    final result = await query.get();

    // 映射为轻量级 DTO
    return result
        .map((row) => SongListItem(
              id: row.id,
              title: row.title,
              artist: row.artist,
              album: row.album,
              genre: row.genre,
              albumArtThumbPath: row.albumArtThumbPath,
              duration: row.duration,
              sampleRate: row.sampleRate,
              bitrate: row.bitrate,
              isFavorite: row.isFavorite,
            ))
        .toList();
  }

  Future<int> insertSong(SongsCompanion song) async {
    return await into(songs).insert(song);
  }

  Future<bool> updateSong(Song song) async {
    return await update(songs).replace(song);
  }

  Future<int> updateSongFavorite(int songId, bool isFavorite) async {
  return await (update(songs)..where((t) => t.id.equals(songId)))
      .write(SongsCompanion(
    isFavorite: Value(isFavorite),
  ));
}

  Future<int> deleteSong(int id) async {
    return await (delete(songs)..where((song) => song.id.equals(id))).go();
  }
}

Future<File> get databaseFile async {
  final basePath = await CommonUtils.getAppBaseDirectory();
  final file = File(p.join(basePath, 'lzf-music.db'));
  return file;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    return NativeDatabase.createInBackground(await databaseFile);
  });
}
