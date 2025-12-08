import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:lzf_music/utils/common_utils.dart';
import 'package:path/path.dart' as p;
import './tables.dart';
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
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          final dbFile = await databaseFile;
          if (await dbFile.exists()) {
            await dbFile.delete();
          }
          await m.createAll();
        },
      );

  Future<List<Song>> getAllSongs() async {
    return await select(songs).get();
  }

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
        (song) => OrderingTerm(
              expression: CaseWhenExpression(
                cases: [
                  CaseWhen(song.title.like('%$keyword%'),
                      then: const Constant(0)),
                  CaseWhen(song.artist.like('%$keyword%'),
                      then: const Constant(1)),
                  CaseWhen(song.album.like('%$keyword%'),
                      then: const Constant(2)),
                ],
                orElse: const Constant(3),
              ),
            ),
        // 然后按标题排序
        (song) => OrderingTerm.asc(song.title),
      ]);

    return await query.get();
  }

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

  Future<List<Song>> searchByAlbum(String album) async {
    if (album.trim().isEmpty) return [];

    return await (select(songs)
          ..where((song) => song.album.like('%$album%'))
          ..orderBy([(song) => OrderingTerm.asc(song.title)]))
        .get();
  }

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

  Future<List<Song>> searchSongsMultipleKeywords(List<String> keywords) async {
    if (keywords.isEmpty) {
      return await getAllSongs();
    }

    Expression<bool>? whereExpression;

    for (final keyword in keywords) {
      if (keyword.trim().isEmpty) continue;

      final keywordCondition = songs.title.like('%$keyword%') |
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

  Future<List<Song>> basicSearch(String keyword) async {
    if (keyword.trim().isEmpty) {
      return await getAllSongs();
    }

    final lowerKeyword = keyword.toLowerCase();

    final query = select(songs)
      ..where(
        (song) =>
            song.title.like('%$lowerKeyword%') |
            song.artist.like('%$lowerKeyword%') |
            song.album.like('%$lowerKeyword%'),
      )
      ..orderBy([
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

  Future<List<Song>> caseInsensitiveSearch(String keyword) async {
    if (keyword.trim().isEmpty) {
      return await getAllSongs();
    }

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

    filteredSongs.sort((a, b) {
      final aTitle = a.title.toLowerCase();
      final bTitle = b.title.toLowerCase();
      final aArtist = (a.artist ?? '').toLowerCase();
      final bArtist = (b.artist ?? '').toLowerCase();

      if (aTitle == lowerKeyword) return -1;
      if (bTitle == lowerKeyword) return 1;
      if (aArtist == lowerKeyword) return -1;
      if (bArtist == lowerKeyword) return 1;

      if (aTitle.startsWith(lowerKeyword) && !bTitle.startsWith(lowerKeyword))
        return -1;
      if (bTitle.startsWith(lowerKeyword) && !aTitle.startsWith(lowerKeyword))
        return 1;
      if (aArtist.startsWith(lowerKeyword) && !bArtist.startsWith(lowerKeyword))
        return -1;
      if (bArtist.startsWith(lowerKeyword) && !aArtist.startsWith(lowerKeyword))
        return 1;

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

  Future<int> insertSong(SongsCompanion song) async {
    return await into(songs).insert(song);
  }

  Future<void> insertSongs(List<SongsCompanion> songsList) async {
    await batch((batch) {
      batch.insertAll(songs, songsList);
    });
  }

  Future<bool> updateSong(Song song) async {
    return await update(songs).replace(song);
  }

  Future<int> deleteSong(int id) async {
    return await (delete(songs)..where((song) => song.id.equals(id))).go();
  }

  Future<Song?> getSongByPath(String filePath) async {
    final query = select(songs)
      ..where((song) => song.filePath.equals(filePath));
    final result = await query.getSingleOrNull();
    return result;
  }

  Future<int> getSongsCount() async {
    final count = countAll();
    final query = selectOnly(songs)..addColumns([count]);
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  Future<List<Song>> getRecentSongs([int limit = 20]) async {
    return await (select(songs)
          ..orderBy([(song) => OrderingTerm.desc(song.dateAdded)])
          ..limit(limit))
        .get();
  }

  Future<int> createPlaylist(String name) async {
    return into(playlists).insert(
      PlaylistsCompanion.insert(name: name),
    );
  }

  Future<void> deletePlaylist(int playlistId) async {
    await batch((b) {
      b.deleteWhere(playlistSongs, (tbl) => tbl.playlistId.equals(playlistId));
      b.deleteWhere(playlists, (tbl) => tbl.id.equals(playlistId));
    });
  }

  Future<List<Playlist>> getAllPlaylists() {
    return select(playlists).get();
  }

  Future<int> addSongToPlaylist(int playlistId, int songId) {
    return into(playlistSongs).insert(
      PlaylistSongsCompanion.insert(
        playlistId: playlistId,
        songId: songId,
      ),
    );
  }

  Future<int> removeSongFromPlaylist(int playlistSongId) {
    return (delete(playlistSongs)..where((t) => t.id.equals(playlistSongId)))
        .go();
  }

  Future<List<Song>> getSongsInPlaylist(int playlistId) async {
    final query = select(songs).join([
      innerJoin(
        playlistSongs,
        playlistSongs.songId.equalsExp(songs.id),
      )
    ])
      ..where(playlistSongs.playlistId.equals(playlistId));

    final rows = await query.get();
    return rows.map((row) => row.readTable(songs)).toList();
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
