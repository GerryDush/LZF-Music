// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $SongsTable extends Songs with TableInfo<$SongsTable, Song> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SongsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _artistMeta = const VerificationMeta('artist');
  @override
  late final GeneratedColumn<String> artist = GeneratedColumn<String>(
      'artist', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _albumMeta = const VerificationMeta('album');
  @override
  late final GeneratedColumn<String> album = GeneratedColumn<String>(
      'album', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _genreMeta = const VerificationMeta('genre');
  @override
  late final GeneratedColumn<String> genre = GeneratedColumn<String>(
      'genre', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _filePathMeta =
      const VerificationMeta('filePath');
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
      'file_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _lyricsMeta = const VerificationMeta('lyrics');
  @override
  late final GeneratedColumn<String> lyrics = GeneratedColumn<String>(
      'lyrics', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  late final GeneratedColumnWithTypeConverter<LyricsData?, Uint8List>
      lyricsBlob = GeneratedColumn<Uint8List>('lyrics_blob', aliasedName, true,
              type: DriftSqlType.blob, requiredDuringInsert: false)
          .withConverter<LyricsData?>($SongsTable.$converterlyricsBlobn);
  static const VerificationMeta _bitrateMeta =
      const VerificationMeta('bitrate');
  @override
  late final GeneratedColumn<int> bitrate = GeneratedColumn<int>(
      'bitrate', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _sampleRateMeta =
      const VerificationMeta('sampleRate');
  @override
  late final GeneratedColumn<int> sampleRate = GeneratedColumn<int>(
      'sample_rate', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _durationMeta =
      const VerificationMeta('duration');
  @override
  late final GeneratedColumn<int> duration = GeneratedColumn<int>(
      'duration', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _albumArtPathMeta =
      const VerificationMeta('albumArtPath');
  @override
  late final GeneratedColumn<String> albumArtPath = GeneratedColumn<String>(
      'album_art_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _albumArtThumbPathMeta =
      const VerificationMeta('albumArtThumbPath');
  @override
  late final GeneratedColumn<String> albumArtThumbPath =
      GeneratedColumn<String>('album_art_thumb_path', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _dateAddedMeta =
      const VerificationMeta('dateAdded');
  @override
  late final GeneratedColumn<DateTime> dateAdded = GeneratedColumn<DateTime>(
      'date_added', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _isFavoriteMeta =
      const VerificationMeta('isFavorite');
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
      'is_favorite', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_favorite" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _lastPlayedTimeMeta =
      const VerificationMeta('lastPlayedTime');
  @override
  late final GeneratedColumn<DateTime> lastPlayedTime =
      GeneratedColumn<DateTime>('last_played_time', aliasedName, false,
          type: DriftSqlType.dateTime,
          requiredDuringInsert: false,
          defaultValue: currentDateAndTime);
  static const VerificationMeta _playedCountMeta =
      const VerificationMeta('playedCount');
  @override
  late final GeneratedColumn<int> playedCount = GeneratedColumn<int>(
      'played_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  late final GeneratedColumnWithTypeConverter<List<Color>?, String> palette =
      GeneratedColumn<String>('palette', aliasedName, true,
              type: DriftSqlType.string, requiredDuringInsert: false)
          .withConverter<List<Color>?>($SongsTable.$converterpaletten);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('local'));
  static const VerificationMeta _fileSizeMeta =
      const VerificationMeta('fileSize');
  @override
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
      'file_size', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _lastModifiedMeta =
      const VerificationMeta('lastModified');
  @override
  late final GeneratedColumn<DateTime> lastModified = GeneratedColumn<DateTime>(
      'last_modified', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _skipCountMeta =
      const VerificationMeta('skipCount');
  @override
  late final GeneratedColumn<int> skipCount = GeneratedColumn<int>(
      'skip_count', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        title,
        artist,
        album,
        genre,
        filePath,
        lyrics,
        lyricsBlob,
        bitrate,
        sampleRate,
        duration,
        albumArtPath,
        albumArtThumbPath,
        sortOrder,
        dateAdded,
        isFavorite,
        lastPlayedTime,
        playedCount,
        palette,
        source,
        fileSize,
        lastModified,
        skipCount
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'songs';
  @override
  VerificationContext validateIntegrity(Insertable<Song> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('artist')) {
      context.handle(_artistMeta,
          artist.isAcceptableOrUnknown(data['artist']!, _artistMeta));
    }
    if (data.containsKey('album')) {
      context.handle(
          _albumMeta, album.isAcceptableOrUnknown(data['album']!, _albumMeta));
    }
    if (data.containsKey('genre')) {
      context.handle(
          _genreMeta, genre.isAcceptableOrUnknown(data['genre']!, _genreMeta));
    }
    if (data.containsKey('file_path')) {
      context.handle(_filePathMeta,
          filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta));
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('lyrics')) {
      context.handle(_lyricsMeta,
          lyrics.isAcceptableOrUnknown(data['lyrics']!, _lyricsMeta));
    }
    if (data.containsKey('bitrate')) {
      context.handle(_bitrateMeta,
          bitrate.isAcceptableOrUnknown(data['bitrate']!, _bitrateMeta));
    }
    if (data.containsKey('sample_rate')) {
      context.handle(
          _sampleRateMeta,
          sampleRate.isAcceptableOrUnknown(
              data['sample_rate']!, _sampleRateMeta));
    }
    if (data.containsKey('duration')) {
      context.handle(_durationMeta,
          duration.isAcceptableOrUnknown(data['duration']!, _durationMeta));
    }
    if (data.containsKey('album_art_path')) {
      context.handle(
          _albumArtPathMeta,
          albumArtPath.isAcceptableOrUnknown(
              data['album_art_path']!, _albumArtPathMeta));
    }
    if (data.containsKey('album_art_thumb_path')) {
      context.handle(
          _albumArtThumbPathMeta,
          albumArtThumbPath.isAcceptableOrUnknown(
              data['album_art_thumb_path']!, _albumArtThumbPathMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('date_added')) {
      context.handle(_dateAddedMeta,
          dateAdded.isAcceptableOrUnknown(data['date_added']!, _dateAddedMeta));
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
          _isFavoriteMeta,
          isFavorite.isAcceptableOrUnknown(
              data['is_favorite']!, _isFavoriteMeta));
    }
    if (data.containsKey('last_played_time')) {
      context.handle(
          _lastPlayedTimeMeta,
          lastPlayedTime.isAcceptableOrUnknown(
              data['last_played_time']!, _lastPlayedTimeMeta));
    }
    if (data.containsKey('played_count')) {
      context.handle(
          _playedCountMeta,
          playedCount.isAcceptableOrUnknown(
              data['played_count']!, _playedCountMeta));
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    }
    if (data.containsKey('file_size')) {
      context.handle(_fileSizeMeta,
          fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta));
    }
    if (data.containsKey('last_modified')) {
      context.handle(
          _lastModifiedMeta,
          lastModified.isAcceptableOrUnknown(
              data['last_modified']!, _lastModifiedMeta));
    }
    if (data.containsKey('skip_count')) {
      context.handle(_skipCountMeta,
          skipCount.isAcceptableOrUnknown(data['skip_count']!, _skipCountMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Song map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Song(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      artist: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}artist']),
      album: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}album']),
      genre: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}genre']),
      filePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_path'])!,
      lyrics: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}lyrics']),
      lyricsBlob: $SongsTable.$converterlyricsBlobn.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.blob, data['${effectivePrefix}lyrics_blob'])),
      bitrate: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}bitrate']),
      sampleRate: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sample_rate']),
      duration: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration']),
      albumArtPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}album_art_path']),
      albumArtThumbPath: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}album_art_thumb_path']),
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order']),
      dateAdded: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date_added'])!,
      isFavorite: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_favorite'])!,
      lastPlayedTime: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_played_time'])!,
      playedCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}played_count'])!,
      palette: $SongsTable.$converterpaletten.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}palette'])),
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source']),
      fileSize: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}file_size']),
      lastModified: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_modified']),
      skipCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}skip_count']),
    );
  }

  @override
  $SongsTable createAlias(String alias) {
    return $SongsTable(attachedDatabase, alias);
  }

  static TypeConverter<LyricsData, Uint8List> $converterlyricsBlob =
      const LyricsDataConverter();
  static TypeConverter<LyricsData?, Uint8List?> $converterlyricsBlobn =
      NullAwareTypeConverter.wrap($converterlyricsBlob);
  static TypeConverter<List<Color>, String> $converterpalette =
      const ColorListConverter();
  static TypeConverter<List<Color>?, String?> $converterpaletten =
      NullAwareTypeConverter.wrap($converterpalette);
}

class Song extends DataClass implements Insertable<Song> {
  /// 主键，自增 ID
  final int id;

  /// 歌曲标题
  final String title;

  /// 艺术家 / 歌手
  final String? artist;

  /// 专辑名称
  final String? album;

  /// 音乐流派
  final String? genre;

  /// 本地文件路径或资源路径
  final String filePath;

  /// 歌词内容（可为空）
  final String? lyrics;
  final LyricsData? lyricsBlob;

  /// 比特率（kbps）
  final int? bitrate;

  /// 采样率（Hz）
  final int? sampleRate;

  /// 歌曲时长（毫秒）
  final int? duration;

  /// 专辑封面图片路径
  final String? albumArtPath;

  /// 专辑封面缩略图路径
  final String? albumArtThumbPath;

  /// 全局排序字段（越小越靠前）
  final int? sortOrder;

  /// 加入音乐库的时间
  final DateTime dateAdded;

  /// 是否标记为喜欢 / 收藏
  final bool isFavorite;

  /// 最近一次播放时间
  final DateTime lastPlayedTime;

  /// 播放次数统计
  final int playedCount;

  /// 主题调色板
  final List<Color>? palette;

  /// 歌曲来源 // local / stream / online
  final String? source;

  /// 文件大小
  final int? fileSize;

  /// 文件最后修改时间
  final DateTime? lastModified;

  /// 被用户跳过的次数
  final int? skipCount;
  const Song(
      {required this.id,
      required this.title,
      this.artist,
      this.album,
      this.genre,
      required this.filePath,
      this.lyrics,
      this.lyricsBlob,
      this.bitrate,
      this.sampleRate,
      this.duration,
      this.albumArtPath,
      this.albumArtThumbPath,
      this.sortOrder,
      required this.dateAdded,
      required this.isFavorite,
      required this.lastPlayedTime,
      required this.playedCount,
      this.palette,
      this.source,
      this.fileSize,
      this.lastModified,
      this.skipCount});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || artist != null) {
      map['artist'] = Variable<String>(artist);
    }
    if (!nullToAbsent || album != null) {
      map['album'] = Variable<String>(album);
    }
    if (!nullToAbsent || genre != null) {
      map['genre'] = Variable<String>(genre);
    }
    map['file_path'] = Variable<String>(filePath);
    if (!nullToAbsent || lyrics != null) {
      map['lyrics'] = Variable<String>(lyrics);
    }
    if (!nullToAbsent || lyricsBlob != null) {
      map['lyrics_blob'] = Variable<Uint8List>(
          $SongsTable.$converterlyricsBlobn.toSql(lyricsBlob));
    }
    if (!nullToAbsent || bitrate != null) {
      map['bitrate'] = Variable<int>(bitrate);
    }
    if (!nullToAbsent || sampleRate != null) {
      map['sample_rate'] = Variable<int>(sampleRate);
    }
    if (!nullToAbsent || duration != null) {
      map['duration'] = Variable<int>(duration);
    }
    if (!nullToAbsent || albumArtPath != null) {
      map['album_art_path'] = Variable<String>(albumArtPath);
    }
    if (!nullToAbsent || albumArtThumbPath != null) {
      map['album_art_thumb_path'] = Variable<String>(albumArtThumbPath);
    }
    if (!nullToAbsent || sortOrder != null) {
      map['sort_order'] = Variable<int>(sortOrder);
    }
    map['date_added'] = Variable<DateTime>(dateAdded);
    map['is_favorite'] = Variable<bool>(isFavorite);
    map['last_played_time'] = Variable<DateTime>(lastPlayedTime);
    map['played_count'] = Variable<int>(playedCount);
    if (!nullToAbsent || palette != null) {
      map['palette'] =
          Variable<String>($SongsTable.$converterpaletten.toSql(palette));
    }
    if (!nullToAbsent || source != null) {
      map['source'] = Variable<String>(source);
    }
    if (!nullToAbsent || fileSize != null) {
      map['file_size'] = Variable<int>(fileSize);
    }
    if (!nullToAbsent || lastModified != null) {
      map['last_modified'] = Variable<DateTime>(lastModified);
    }
    if (!nullToAbsent || skipCount != null) {
      map['skip_count'] = Variable<int>(skipCount);
    }
    return map;
  }

  SongsCompanion toCompanion(bool nullToAbsent) {
    return SongsCompanion(
      id: Value(id),
      title: Value(title),
      artist:
          artist == null && nullToAbsent ? const Value.absent() : Value(artist),
      album:
          album == null && nullToAbsent ? const Value.absent() : Value(album),
      genre:
          genre == null && nullToAbsent ? const Value.absent() : Value(genre),
      filePath: Value(filePath),
      lyrics:
          lyrics == null && nullToAbsent ? const Value.absent() : Value(lyrics),
      lyricsBlob: lyricsBlob == null && nullToAbsent
          ? const Value.absent()
          : Value(lyricsBlob),
      bitrate: bitrate == null && nullToAbsent
          ? const Value.absent()
          : Value(bitrate),
      sampleRate: sampleRate == null && nullToAbsent
          ? const Value.absent()
          : Value(sampleRate),
      duration: duration == null && nullToAbsent
          ? const Value.absent()
          : Value(duration),
      albumArtPath: albumArtPath == null && nullToAbsent
          ? const Value.absent()
          : Value(albumArtPath),
      albumArtThumbPath: albumArtThumbPath == null && nullToAbsent
          ? const Value.absent()
          : Value(albumArtThumbPath),
      sortOrder: sortOrder == null && nullToAbsent
          ? const Value.absent()
          : Value(sortOrder),
      dateAdded: Value(dateAdded),
      isFavorite: Value(isFavorite),
      lastPlayedTime: Value(lastPlayedTime),
      playedCount: Value(playedCount),
      palette: palette == null && nullToAbsent
          ? const Value.absent()
          : Value(palette),
      source:
          source == null && nullToAbsent ? const Value.absent() : Value(source),
      fileSize: fileSize == null && nullToAbsent
          ? const Value.absent()
          : Value(fileSize),
      lastModified: lastModified == null && nullToAbsent
          ? const Value.absent()
          : Value(lastModified),
      skipCount: skipCount == null && nullToAbsent
          ? const Value.absent()
          : Value(skipCount),
    );
  }

  factory Song.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Song(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      artist: serializer.fromJson<String?>(json['artist']),
      album: serializer.fromJson<String?>(json['album']),
      genre: serializer.fromJson<String?>(json['genre']),
      filePath: serializer.fromJson<String>(json['filePath']),
      lyrics: serializer.fromJson<String?>(json['lyrics']),
      lyricsBlob: serializer.fromJson<LyricsData?>(json['lyricsBlob']),
      bitrate: serializer.fromJson<int?>(json['bitrate']),
      sampleRate: serializer.fromJson<int?>(json['sampleRate']),
      duration: serializer.fromJson<int?>(json['duration']),
      albumArtPath: serializer.fromJson<String?>(json['albumArtPath']),
      albumArtThumbPath:
          serializer.fromJson<String?>(json['albumArtThumbPath']),
      sortOrder: serializer.fromJson<int?>(json['sortOrder']),
      dateAdded: serializer.fromJson<DateTime>(json['dateAdded']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      lastPlayedTime: serializer.fromJson<DateTime>(json['lastPlayedTime']),
      playedCount: serializer.fromJson<int>(json['playedCount']),
      palette: serializer.fromJson<List<Color>?>(json['palette']),
      source: serializer.fromJson<String?>(json['source']),
      fileSize: serializer.fromJson<int?>(json['fileSize']),
      lastModified: serializer.fromJson<DateTime?>(json['lastModified']),
      skipCount: serializer.fromJson<int?>(json['skipCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'artist': serializer.toJson<String?>(artist),
      'album': serializer.toJson<String?>(album),
      'genre': serializer.toJson<String?>(genre),
      'filePath': serializer.toJson<String>(filePath),
      'lyrics': serializer.toJson<String?>(lyrics),
      'lyricsBlob': serializer.toJson<LyricsData?>(lyricsBlob),
      'bitrate': serializer.toJson<int?>(bitrate),
      'sampleRate': serializer.toJson<int?>(sampleRate),
      'duration': serializer.toJson<int?>(duration),
      'albumArtPath': serializer.toJson<String?>(albumArtPath),
      'albumArtThumbPath': serializer.toJson<String?>(albumArtThumbPath),
      'sortOrder': serializer.toJson<int?>(sortOrder),
      'dateAdded': serializer.toJson<DateTime>(dateAdded),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'lastPlayedTime': serializer.toJson<DateTime>(lastPlayedTime),
      'playedCount': serializer.toJson<int>(playedCount),
      'palette': serializer.toJson<List<Color>?>(palette),
      'source': serializer.toJson<String?>(source),
      'fileSize': serializer.toJson<int?>(fileSize),
      'lastModified': serializer.toJson<DateTime?>(lastModified),
      'skipCount': serializer.toJson<int?>(skipCount),
    };
  }

  Song copyWith(
          {int? id,
          String? title,
          Value<String?> artist = const Value.absent(),
          Value<String?> album = const Value.absent(),
          Value<String?> genre = const Value.absent(),
          String? filePath,
          Value<String?> lyrics = const Value.absent(),
          Value<LyricsData?> lyricsBlob = const Value.absent(),
          Value<int?> bitrate = const Value.absent(),
          Value<int?> sampleRate = const Value.absent(),
          Value<int?> duration = const Value.absent(),
          Value<String?> albumArtPath = const Value.absent(),
          Value<String?> albumArtThumbPath = const Value.absent(),
          Value<int?> sortOrder = const Value.absent(),
          DateTime? dateAdded,
          bool? isFavorite,
          DateTime? lastPlayedTime,
          int? playedCount,
          Value<List<Color>?> palette = const Value.absent(),
          Value<String?> source = const Value.absent(),
          Value<int?> fileSize = const Value.absent(),
          Value<DateTime?> lastModified = const Value.absent(),
          Value<int?> skipCount = const Value.absent()}) =>
      Song(
        id: id ?? this.id,
        title: title ?? this.title,
        artist: artist.present ? artist.value : this.artist,
        album: album.present ? album.value : this.album,
        genre: genre.present ? genre.value : this.genre,
        filePath: filePath ?? this.filePath,
        lyrics: lyrics.present ? lyrics.value : this.lyrics,
        lyricsBlob: lyricsBlob.present ? lyricsBlob.value : this.lyricsBlob,
        bitrate: bitrate.present ? bitrate.value : this.bitrate,
        sampleRate: sampleRate.present ? sampleRate.value : this.sampleRate,
        duration: duration.present ? duration.value : this.duration,
        albumArtPath:
            albumArtPath.present ? albumArtPath.value : this.albumArtPath,
        albumArtThumbPath: albumArtThumbPath.present
            ? albumArtThumbPath.value
            : this.albumArtThumbPath,
        sortOrder: sortOrder.present ? sortOrder.value : this.sortOrder,
        dateAdded: dateAdded ?? this.dateAdded,
        isFavorite: isFavorite ?? this.isFavorite,
        lastPlayedTime: lastPlayedTime ?? this.lastPlayedTime,
        playedCount: playedCount ?? this.playedCount,
        palette: palette.present ? palette.value : this.palette,
        source: source.present ? source.value : this.source,
        fileSize: fileSize.present ? fileSize.value : this.fileSize,
        lastModified:
            lastModified.present ? lastModified.value : this.lastModified,
        skipCount: skipCount.present ? skipCount.value : this.skipCount,
      );
  Song copyWithCompanion(SongsCompanion data) {
    return Song(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      artist: data.artist.present ? data.artist.value : this.artist,
      album: data.album.present ? data.album.value : this.album,
      genre: data.genre.present ? data.genre.value : this.genre,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      lyrics: data.lyrics.present ? data.lyrics.value : this.lyrics,
      lyricsBlob:
          data.lyricsBlob.present ? data.lyricsBlob.value : this.lyricsBlob,
      bitrate: data.bitrate.present ? data.bitrate.value : this.bitrate,
      sampleRate:
          data.sampleRate.present ? data.sampleRate.value : this.sampleRate,
      duration: data.duration.present ? data.duration.value : this.duration,
      albumArtPath: data.albumArtPath.present
          ? data.albumArtPath.value
          : this.albumArtPath,
      albumArtThumbPath: data.albumArtThumbPath.present
          ? data.albumArtThumbPath.value
          : this.albumArtThumbPath,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      dateAdded: data.dateAdded.present ? data.dateAdded.value : this.dateAdded,
      isFavorite:
          data.isFavorite.present ? data.isFavorite.value : this.isFavorite,
      lastPlayedTime: data.lastPlayedTime.present
          ? data.lastPlayedTime.value
          : this.lastPlayedTime,
      playedCount:
          data.playedCount.present ? data.playedCount.value : this.playedCount,
      palette: data.palette.present ? data.palette.value : this.palette,
      source: data.source.present ? data.source.value : this.source,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
      skipCount: data.skipCount.present ? data.skipCount.value : this.skipCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Song(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('artist: $artist, ')
          ..write('album: $album, ')
          ..write('genre: $genre, ')
          ..write('filePath: $filePath, ')
          ..write('lyrics: $lyrics, ')
          ..write('lyricsBlob: $lyricsBlob, ')
          ..write('bitrate: $bitrate, ')
          ..write('sampleRate: $sampleRate, ')
          ..write('duration: $duration, ')
          ..write('albumArtPath: $albumArtPath, ')
          ..write('albumArtThumbPath: $albumArtThumbPath, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('dateAdded: $dateAdded, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('lastPlayedTime: $lastPlayedTime, ')
          ..write('playedCount: $playedCount, ')
          ..write('palette: $palette, ')
          ..write('source: $source, ')
          ..write('fileSize: $fileSize, ')
          ..write('lastModified: $lastModified, ')
          ..write('skipCount: $skipCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        title,
        artist,
        album,
        genre,
        filePath,
        lyrics,
        lyricsBlob,
        bitrate,
        sampleRate,
        duration,
        albumArtPath,
        albumArtThumbPath,
        sortOrder,
        dateAdded,
        isFavorite,
        lastPlayedTime,
        playedCount,
        palette,
        source,
        fileSize,
        lastModified,
        skipCount
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Song &&
          other.id == this.id &&
          other.title == this.title &&
          other.artist == this.artist &&
          other.album == this.album &&
          other.genre == this.genre &&
          other.filePath == this.filePath &&
          other.lyrics == this.lyrics &&
          other.lyricsBlob == this.lyricsBlob &&
          other.bitrate == this.bitrate &&
          other.sampleRate == this.sampleRate &&
          other.duration == this.duration &&
          other.albumArtPath == this.albumArtPath &&
          other.albumArtThumbPath == this.albumArtThumbPath &&
          other.sortOrder == this.sortOrder &&
          other.dateAdded == this.dateAdded &&
          other.isFavorite == this.isFavorite &&
          other.lastPlayedTime == this.lastPlayedTime &&
          other.playedCount == this.playedCount &&
          other.palette == this.palette &&
          other.source == this.source &&
          other.fileSize == this.fileSize &&
          other.lastModified == this.lastModified &&
          other.skipCount == this.skipCount);
}

class SongsCompanion extends UpdateCompanion<Song> {
  final Value<int> id;
  final Value<String> title;
  final Value<String?> artist;
  final Value<String?> album;
  final Value<String?> genre;
  final Value<String> filePath;
  final Value<String?> lyrics;
  final Value<LyricsData?> lyricsBlob;
  final Value<int?> bitrate;
  final Value<int?> sampleRate;
  final Value<int?> duration;
  final Value<String?> albumArtPath;
  final Value<String?> albumArtThumbPath;
  final Value<int?> sortOrder;
  final Value<DateTime> dateAdded;
  final Value<bool> isFavorite;
  final Value<DateTime> lastPlayedTime;
  final Value<int> playedCount;
  final Value<List<Color>?> palette;
  final Value<String?> source;
  final Value<int?> fileSize;
  final Value<DateTime?> lastModified;
  final Value<int?> skipCount;
  const SongsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.artist = const Value.absent(),
    this.album = const Value.absent(),
    this.genre = const Value.absent(),
    this.filePath = const Value.absent(),
    this.lyrics = const Value.absent(),
    this.lyricsBlob = const Value.absent(),
    this.bitrate = const Value.absent(),
    this.sampleRate = const Value.absent(),
    this.duration = const Value.absent(),
    this.albumArtPath = const Value.absent(),
    this.albumArtThumbPath = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.dateAdded = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.lastPlayedTime = const Value.absent(),
    this.playedCount = const Value.absent(),
    this.palette = const Value.absent(),
    this.source = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.skipCount = const Value.absent(),
  });
  SongsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.artist = const Value.absent(),
    this.album = const Value.absent(),
    this.genre = const Value.absent(),
    required String filePath,
    this.lyrics = const Value.absent(),
    this.lyricsBlob = const Value.absent(),
    this.bitrate = const Value.absent(),
    this.sampleRate = const Value.absent(),
    this.duration = const Value.absent(),
    this.albumArtPath = const Value.absent(),
    this.albumArtThumbPath = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.dateAdded = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.lastPlayedTime = const Value.absent(),
    this.playedCount = const Value.absent(),
    this.palette = const Value.absent(),
    this.source = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.skipCount = const Value.absent(),
  })  : title = Value(title),
        filePath = Value(filePath);
  static Insertable<Song> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? artist,
    Expression<String>? album,
    Expression<String>? genre,
    Expression<String>? filePath,
    Expression<String>? lyrics,
    Expression<Uint8List>? lyricsBlob,
    Expression<int>? bitrate,
    Expression<int>? sampleRate,
    Expression<int>? duration,
    Expression<String>? albumArtPath,
    Expression<String>? albumArtThumbPath,
    Expression<int>? sortOrder,
    Expression<DateTime>? dateAdded,
    Expression<bool>? isFavorite,
    Expression<DateTime>? lastPlayedTime,
    Expression<int>? playedCount,
    Expression<String>? palette,
    Expression<String>? source,
    Expression<int>? fileSize,
    Expression<DateTime>? lastModified,
    Expression<int>? skipCount,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (artist != null) 'artist': artist,
      if (album != null) 'album': album,
      if (genre != null) 'genre': genre,
      if (filePath != null) 'file_path': filePath,
      if (lyrics != null) 'lyrics': lyrics,
      if (lyricsBlob != null) 'lyrics_blob': lyricsBlob,
      if (bitrate != null) 'bitrate': bitrate,
      if (sampleRate != null) 'sample_rate': sampleRate,
      if (duration != null) 'duration': duration,
      if (albumArtPath != null) 'album_art_path': albumArtPath,
      if (albumArtThumbPath != null) 'album_art_thumb_path': albumArtThumbPath,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (dateAdded != null) 'date_added': dateAdded,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (lastPlayedTime != null) 'last_played_time': lastPlayedTime,
      if (playedCount != null) 'played_count': playedCount,
      if (palette != null) 'palette': palette,
      if (source != null) 'source': source,
      if (fileSize != null) 'file_size': fileSize,
      if (lastModified != null) 'last_modified': lastModified,
      if (skipCount != null) 'skip_count': skipCount,
    });
  }

  SongsCompanion copyWith(
      {Value<int>? id,
      Value<String>? title,
      Value<String?>? artist,
      Value<String?>? album,
      Value<String?>? genre,
      Value<String>? filePath,
      Value<String?>? lyrics,
      Value<LyricsData?>? lyricsBlob,
      Value<int?>? bitrate,
      Value<int?>? sampleRate,
      Value<int?>? duration,
      Value<String?>? albumArtPath,
      Value<String?>? albumArtThumbPath,
      Value<int?>? sortOrder,
      Value<DateTime>? dateAdded,
      Value<bool>? isFavorite,
      Value<DateTime>? lastPlayedTime,
      Value<int>? playedCount,
      Value<List<Color>?>? palette,
      Value<String?>? source,
      Value<int?>? fileSize,
      Value<DateTime?>? lastModified,
      Value<int?>? skipCount}) {
    return SongsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      genre: genre ?? this.genre,
      filePath: filePath ?? this.filePath,
      lyrics: lyrics ?? this.lyrics,
      lyricsBlob: lyricsBlob ?? this.lyricsBlob,
      bitrate: bitrate ?? this.bitrate,
      sampleRate: sampleRate ?? this.sampleRate,
      duration: duration ?? this.duration,
      albumArtPath: albumArtPath ?? this.albumArtPath,
      albumArtThumbPath: albumArtThumbPath ?? this.albumArtThumbPath,
      sortOrder: sortOrder ?? this.sortOrder,
      dateAdded: dateAdded ?? this.dateAdded,
      isFavorite: isFavorite ?? this.isFavorite,
      lastPlayedTime: lastPlayedTime ?? this.lastPlayedTime,
      playedCount: playedCount ?? this.playedCount,
      palette: palette ?? this.palette,
      source: source ?? this.source,
      fileSize: fileSize ?? this.fileSize,
      lastModified: lastModified ?? this.lastModified,
      skipCount: skipCount ?? this.skipCount,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (artist.present) {
      map['artist'] = Variable<String>(artist.value);
    }
    if (album.present) {
      map['album'] = Variable<String>(album.value);
    }
    if (genre.present) {
      map['genre'] = Variable<String>(genre.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (lyrics.present) {
      map['lyrics'] = Variable<String>(lyrics.value);
    }
    if (lyricsBlob.present) {
      map['lyrics_blob'] = Variable<Uint8List>(
          $SongsTable.$converterlyricsBlobn.toSql(lyricsBlob.value));
    }
    if (bitrate.present) {
      map['bitrate'] = Variable<int>(bitrate.value);
    }
    if (sampleRate.present) {
      map['sample_rate'] = Variable<int>(sampleRate.value);
    }
    if (duration.present) {
      map['duration'] = Variable<int>(duration.value);
    }
    if (albumArtPath.present) {
      map['album_art_path'] = Variable<String>(albumArtPath.value);
    }
    if (albumArtThumbPath.present) {
      map['album_art_thumb_path'] = Variable<String>(albumArtThumbPath.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (dateAdded.present) {
      map['date_added'] = Variable<DateTime>(dateAdded.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (lastPlayedTime.present) {
      map['last_played_time'] = Variable<DateTime>(lastPlayedTime.value);
    }
    if (playedCount.present) {
      map['played_count'] = Variable<int>(playedCount.value);
    }
    if (palette.present) {
      map['palette'] =
          Variable<String>($SongsTable.$converterpaletten.toSql(palette.value));
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<DateTime>(lastModified.value);
    }
    if (skipCount.present) {
      map['skip_count'] = Variable<int>(skipCount.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SongsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('artist: $artist, ')
          ..write('album: $album, ')
          ..write('genre: $genre, ')
          ..write('filePath: $filePath, ')
          ..write('lyrics: $lyrics, ')
          ..write('lyricsBlob: $lyricsBlob, ')
          ..write('bitrate: $bitrate, ')
          ..write('sampleRate: $sampleRate, ')
          ..write('duration: $duration, ')
          ..write('albumArtPath: $albumArtPath, ')
          ..write('albumArtThumbPath: $albumArtThumbPath, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('dateAdded: $dateAdded, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('lastPlayedTime: $lastPlayedTime, ')
          ..write('playedCount: $playedCount, ')
          ..write('palette: $palette, ')
          ..write('source: $source, ')
          ..write('fileSize: $fileSize, ')
          ..write('lastModified: $lastModified, ')
          ..write('skipCount: $skipCount')
          ..write(')'))
        .toString();
  }
}

class $PlaylistsTable extends Playlists
    with TableInfo<$PlaylistsTable, Playlist> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaylistsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  late final GeneratedColumnWithTypeConverter<List<Color>?, String> palette =
      GeneratedColumn<String>('palette', aliasedName, true,
              type: DriftSqlType.string, requiredDuringInsert: false)
          .withConverter<List<Color>?>($PlaylistsTable.$converterpaletten);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('manual'));
  static const VerificationMeta _coverPathMeta =
      const VerificationMeta('coverPath');
  @override
  late final GeneratedColumn<String> coverPath = GeneratedColumn<String>(
      'cover_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _coverThumbPathMeta =
      const VerificationMeta('coverThumbPath');
  @override
  late final GeneratedColumn<String> coverThumbPath = GeneratedColumn<String>(
      'cover_thumb_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        description,
        createdAt,
        palette,
        type,
        coverPath,
        coverThumbPath
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playlists';
  @override
  VerificationContext validateIntegrity(Insertable<Playlist> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    }
    if (data.containsKey('cover_path')) {
      context.handle(_coverPathMeta,
          coverPath.isAcceptableOrUnknown(data['cover_path']!, _coverPathMeta));
    }
    if (data.containsKey('cover_thumb_path')) {
      context.handle(
          _coverThumbPathMeta,
          coverThumbPath.isAcceptableOrUnknown(
              data['cover_thumb_path']!, _coverThumbPathMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Playlist map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Playlist(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      palette: $PlaylistsTable.$converterpaletten.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}palette'])),
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      coverPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cover_path']),
      coverThumbPath: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}cover_thumb_path']),
    );
  }

  @override
  $PlaylistsTable createAlias(String alias) {
    return $PlaylistsTable(attachedDatabase, alias);
  }

  static TypeConverter<List<Color>, String> $converterpalette =
      const ColorListConverter();
  static TypeConverter<List<Color>?, String?> $converterpaletten =
      NullAwareTypeConverter.wrap($converterpalette);
}

class Playlist extends DataClass implements Insertable<Playlist> {
  /// 主键，自增 ID
  final int id;

  /// 歌单名称
  final String name;

  /// 歌单描述信息
  final String? description;

  /// 歌单创建时间
  final DateTime createdAt;

  /// 歌单主题调色板
  final List<Color>? palette;

  /// 歌单类型
  /// manual：手动创建
  /// smart：智能歌单
  /// system：系统歌单
  final String type;

  /// 歌单封面原始大图路径（用户上传）
  final String? coverPath;

  /// 歌单封面缩略图路径
  final String? coverThumbPath;
  const Playlist(
      {required this.id,
      required this.name,
      this.description,
      required this.createdAt,
      this.palette,
      required this.type,
      this.coverPath,
      this.coverThumbPath});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || palette != null) {
      map['palette'] =
          Variable<String>($PlaylistsTable.$converterpaletten.toSql(palette));
    }
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || coverPath != null) {
      map['cover_path'] = Variable<String>(coverPath);
    }
    if (!nullToAbsent || coverThumbPath != null) {
      map['cover_thumb_path'] = Variable<String>(coverThumbPath);
    }
    return map;
  }

  PlaylistsCompanion toCompanion(bool nullToAbsent) {
    return PlaylistsCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      createdAt: Value(createdAt),
      palette: palette == null && nullToAbsent
          ? const Value.absent()
          : Value(palette),
      type: Value(type),
      coverPath: coverPath == null && nullToAbsent
          ? const Value.absent()
          : Value(coverPath),
      coverThumbPath: coverThumbPath == null && nullToAbsent
          ? const Value.absent()
          : Value(coverThumbPath),
    );
  }

  factory Playlist.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Playlist(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      palette: serializer.fromJson<List<Color>?>(json['palette']),
      type: serializer.fromJson<String>(json['type']),
      coverPath: serializer.fromJson<String?>(json['coverPath']),
      coverThumbPath: serializer.fromJson<String?>(json['coverThumbPath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'palette': serializer.toJson<List<Color>?>(palette),
      'type': serializer.toJson<String>(type),
      'coverPath': serializer.toJson<String?>(coverPath),
      'coverThumbPath': serializer.toJson<String?>(coverThumbPath),
    };
  }

  Playlist copyWith(
          {int? id,
          String? name,
          Value<String?> description = const Value.absent(),
          DateTime? createdAt,
          Value<List<Color>?> palette = const Value.absent(),
          String? type,
          Value<String?> coverPath = const Value.absent(),
          Value<String?> coverThumbPath = const Value.absent()}) =>
      Playlist(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description.present ? description.value : this.description,
        createdAt: createdAt ?? this.createdAt,
        palette: palette.present ? palette.value : this.palette,
        type: type ?? this.type,
        coverPath: coverPath.present ? coverPath.value : this.coverPath,
        coverThumbPath:
            coverThumbPath.present ? coverThumbPath.value : this.coverThumbPath,
      );
  Playlist copyWithCompanion(PlaylistsCompanion data) {
    return Playlist(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description:
          data.description.present ? data.description.value : this.description,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      palette: data.palette.present ? data.palette.value : this.palette,
      type: data.type.present ? data.type.value : this.type,
      coverPath: data.coverPath.present ? data.coverPath.value : this.coverPath,
      coverThumbPath: data.coverThumbPath.present
          ? data.coverThumbPath.value
          : this.coverThumbPath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Playlist(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('palette: $palette, ')
          ..write('type: $type, ')
          ..write('coverPath: $coverPath, ')
          ..write('coverThumbPath: $coverThumbPath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, description, createdAt, palette,
      type, coverPath, coverThumbPath);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Playlist &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.createdAt == this.createdAt &&
          other.palette == this.palette &&
          other.type == this.type &&
          other.coverPath == this.coverPath &&
          other.coverThumbPath == this.coverThumbPath);
}

class PlaylistsCompanion extends UpdateCompanion<Playlist> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<DateTime> createdAt;
  final Value<List<Color>?> palette;
  final Value<String> type;
  final Value<String?> coverPath;
  final Value<String?> coverThumbPath;
  const PlaylistsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.palette = const Value.absent(),
    this.type = const Value.absent(),
    this.coverPath = const Value.absent(),
    this.coverThumbPath = const Value.absent(),
  });
  PlaylistsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.palette = const Value.absent(),
    this.type = const Value.absent(),
    this.coverPath = const Value.absent(),
    this.coverThumbPath = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Playlist> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<DateTime>? createdAt,
    Expression<String>? palette,
    Expression<String>? type,
    Expression<String>? coverPath,
    Expression<String>? coverThumbPath,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (createdAt != null) 'created_at': createdAt,
      if (palette != null) 'palette': palette,
      if (type != null) 'type': type,
      if (coverPath != null) 'cover_path': coverPath,
      if (coverThumbPath != null) 'cover_thumb_path': coverThumbPath,
    });
  }

  PlaylistsCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String?>? description,
      Value<DateTime>? createdAt,
      Value<List<Color>?>? palette,
      Value<String>? type,
      Value<String?>? coverPath,
      Value<String?>? coverThumbPath}) {
    return PlaylistsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      palette: palette ?? this.palette,
      type: type ?? this.type,
      coverPath: coverPath ?? this.coverPath,
      coverThumbPath: coverThumbPath ?? this.coverThumbPath,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (palette.present) {
      map['palette'] = Variable<String>(
          $PlaylistsTable.$converterpaletten.toSql(palette.value));
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (coverPath.present) {
      map['cover_path'] = Variable<String>(coverPath.value);
    }
    if (coverThumbPath.present) {
      map['cover_thumb_path'] = Variable<String>(coverThumbPath.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('palette: $palette, ')
          ..write('type: $type, ')
          ..write('coverPath: $coverPath, ')
          ..write('coverThumbPath: $coverThumbPath')
          ..write(')'))
        .toString();
  }
}

class $PlaylistSongsTable extends PlaylistSongs
    with TableInfo<$PlaylistSongsTable, PlaylistSong> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaylistSongsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _playlistIdMeta =
      const VerificationMeta('playlistId');
  @override
  late final GeneratedColumn<int> playlistId = GeneratedColumn<int>(
      'playlist_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES playlists (id)'));
  static const VerificationMeta _songIdMeta = const VerificationMeta('songId');
  @override
  late final GeneratedColumn<int> songId = GeneratedColumn<int>(
      'song_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES songs (id)'));
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [id, playlistId, songId, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playlist_songs';
  @override
  VerificationContext validateIntegrity(Insertable<PlaylistSong> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('playlist_id')) {
      context.handle(
          _playlistIdMeta,
          playlistId.isAcceptableOrUnknown(
              data['playlist_id']!, _playlistIdMeta));
    } else if (isInserting) {
      context.missing(_playlistIdMeta);
    }
    if (data.containsKey('song_id')) {
      context.handle(_songIdMeta,
          songId.isAcceptableOrUnknown(data['song_id']!, _songIdMeta));
    } else if (isInserting) {
      context.missing(_songIdMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlaylistSong map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaylistSong(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      playlistId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}playlist_id'])!,
      songId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}song_id'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order']),
    );
  }

  @override
  $PlaylistSongsTable createAlias(String alias) {
    return $PlaylistSongsTable(attachedDatabase, alias);
  }
}

class PlaylistSong extends DataClass implements Insertable<PlaylistSong> {
  /// 主键，自增 ID
  final int id;

  /// 所属歌单 ID
  final int playlistId;

  /// 歌曲 ID
  final int songId;

  /// 歌曲在当前歌单中的排序顺序
  final int? sortOrder;
  const PlaylistSong(
      {required this.id,
      required this.playlistId,
      required this.songId,
      this.sortOrder});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['playlist_id'] = Variable<int>(playlistId);
    map['song_id'] = Variable<int>(songId);
    if (!nullToAbsent || sortOrder != null) {
      map['sort_order'] = Variable<int>(sortOrder);
    }
    return map;
  }

  PlaylistSongsCompanion toCompanion(bool nullToAbsent) {
    return PlaylistSongsCompanion(
      id: Value(id),
      playlistId: Value(playlistId),
      songId: Value(songId),
      sortOrder: sortOrder == null && nullToAbsent
          ? const Value.absent()
          : Value(sortOrder),
    );
  }

  factory PlaylistSong.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaylistSong(
      id: serializer.fromJson<int>(json['id']),
      playlistId: serializer.fromJson<int>(json['playlistId']),
      songId: serializer.fromJson<int>(json['songId']),
      sortOrder: serializer.fromJson<int?>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'playlistId': serializer.toJson<int>(playlistId),
      'songId': serializer.toJson<int>(songId),
      'sortOrder': serializer.toJson<int?>(sortOrder),
    };
  }

  PlaylistSong copyWith(
          {int? id,
          int? playlistId,
          int? songId,
          Value<int?> sortOrder = const Value.absent()}) =>
      PlaylistSong(
        id: id ?? this.id,
        playlistId: playlistId ?? this.playlistId,
        songId: songId ?? this.songId,
        sortOrder: sortOrder.present ? sortOrder.value : this.sortOrder,
      );
  PlaylistSong copyWithCompanion(PlaylistSongsCompanion data) {
    return PlaylistSong(
      id: data.id.present ? data.id.value : this.id,
      playlistId:
          data.playlistId.present ? data.playlistId.value : this.playlistId,
      songId: data.songId.present ? data.songId.value : this.songId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistSong(')
          ..write('id: $id, ')
          ..write('playlistId: $playlistId, ')
          ..write('songId: $songId, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, playlistId, songId, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaylistSong &&
          other.id == this.id &&
          other.playlistId == this.playlistId &&
          other.songId == this.songId &&
          other.sortOrder == this.sortOrder);
}

class PlaylistSongsCompanion extends UpdateCompanion<PlaylistSong> {
  final Value<int> id;
  final Value<int> playlistId;
  final Value<int> songId;
  final Value<int?> sortOrder;
  const PlaylistSongsCompanion({
    this.id = const Value.absent(),
    this.playlistId = const Value.absent(),
    this.songId = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  PlaylistSongsCompanion.insert({
    this.id = const Value.absent(),
    required int playlistId,
    required int songId,
    this.sortOrder = const Value.absent(),
  })  : playlistId = Value(playlistId),
        songId = Value(songId);
  static Insertable<PlaylistSong> custom({
    Expression<int>? id,
    Expression<int>? playlistId,
    Expression<int>? songId,
    Expression<int>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (playlistId != null) 'playlist_id': playlistId,
      if (songId != null) 'song_id': songId,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  PlaylistSongsCompanion copyWith(
      {Value<int>? id,
      Value<int>? playlistId,
      Value<int>? songId,
      Value<int?>? sortOrder}) {
    return PlaylistSongsCompanion(
      id: id ?? this.id,
      playlistId: playlistId ?? this.playlistId,
      songId: songId ?? this.songId,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (playlistId.present) {
      map['playlist_id'] = Variable<int>(playlistId.value);
    }
    if (songId.present) {
      map['song_id'] = Variable<int>(songId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistSongsCompanion(')
          ..write('id: $id, ')
          ..write('playlistId: $playlistId, ')
          ..write('songId: $songId, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

abstract class _$MusicDatabase extends GeneratedDatabase {
  _$MusicDatabase(QueryExecutor e) : super(e);
  $MusicDatabaseManager get managers => $MusicDatabaseManager(this);
  late final $SongsTable songs = $SongsTable(this);
  late final $PlaylistsTable playlists = $PlaylistsTable(this);
  late final $PlaylistSongsTable playlistSongs = $PlaylistSongsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [songs, playlists, playlistSongs];
}

typedef $$SongsTableCreateCompanionBuilder = SongsCompanion Function({
  Value<int> id,
  required String title,
  Value<String?> artist,
  Value<String?> album,
  Value<String?> genre,
  required String filePath,
  Value<String?> lyrics,
  Value<LyricsData?> lyricsBlob,
  Value<int?> bitrate,
  Value<int?> sampleRate,
  Value<int?> duration,
  Value<String?> albumArtPath,
  Value<String?> albumArtThumbPath,
  Value<int?> sortOrder,
  Value<DateTime> dateAdded,
  Value<bool> isFavorite,
  Value<DateTime> lastPlayedTime,
  Value<int> playedCount,
  Value<List<Color>?> palette,
  Value<String?> source,
  Value<int?> fileSize,
  Value<DateTime?> lastModified,
  Value<int?> skipCount,
});
typedef $$SongsTableUpdateCompanionBuilder = SongsCompanion Function({
  Value<int> id,
  Value<String> title,
  Value<String?> artist,
  Value<String?> album,
  Value<String?> genre,
  Value<String> filePath,
  Value<String?> lyrics,
  Value<LyricsData?> lyricsBlob,
  Value<int?> bitrate,
  Value<int?> sampleRate,
  Value<int?> duration,
  Value<String?> albumArtPath,
  Value<String?> albumArtThumbPath,
  Value<int?> sortOrder,
  Value<DateTime> dateAdded,
  Value<bool> isFavorite,
  Value<DateTime> lastPlayedTime,
  Value<int> playedCount,
  Value<List<Color>?> palette,
  Value<String?> source,
  Value<int?> fileSize,
  Value<DateTime?> lastModified,
  Value<int?> skipCount,
});

final class $$SongsTableReferences
    extends BaseReferences<_$MusicDatabase, $SongsTable, Song> {
  $$SongsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PlaylistSongsTable, List<PlaylistSong>>
      _playlistSongsRefsTable(_$MusicDatabase db) =>
          MultiTypedResultKey.fromTable(db.playlistSongs,
              aliasName:
                  $_aliasNameGenerator(db.songs.id, db.playlistSongs.songId));

  $$PlaylistSongsTableProcessedTableManager get playlistSongsRefs {
    final manager = $$PlaylistSongsTableTableManager($_db, $_db.playlistSongs)
        .filter((f) => f.songId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_playlistSongsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$SongsTableFilterComposer
    extends Composer<_$MusicDatabase, $SongsTable> {
  $$SongsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get artist => $composableBuilder(
      column: $table.artist, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get album => $composableBuilder(
      column: $table.album, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get genre => $composableBuilder(
      column: $table.genre, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get filePath => $composableBuilder(
      column: $table.filePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lyrics => $composableBuilder(
      column: $table.lyrics, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<LyricsData?, LyricsData, Uint8List>
      get lyricsBlob => $composableBuilder(
          column: $table.lyricsBlob,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<int> get bitrate => $composableBuilder(
      column: $table.bitrate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sampleRate => $composableBuilder(
      column: $table.sampleRate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get duration => $composableBuilder(
      column: $table.duration, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get albumArtPath => $composableBuilder(
      column: $table.albumArtPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get albumArtThumbPath => $composableBuilder(
      column: $table.albumArtThumbPath,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get dateAdded => $composableBuilder(
      column: $table.dateAdded, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastPlayedTime => $composableBuilder(
      column: $table.lastPlayedTime,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get playedCount => $composableBuilder(
      column: $table.playedCount, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<List<Color>?, List<Color>, String>
      get palette => $composableBuilder(
          column: $table.palette,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get fileSize => $composableBuilder(
      column: $table.fileSize, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastModified => $composableBuilder(
      column: $table.lastModified, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get skipCount => $composableBuilder(
      column: $table.skipCount, builder: (column) => ColumnFilters(column));

  Expression<bool> playlistSongsRefs(
      Expression<bool> Function($$PlaylistSongsTableFilterComposer f) f) {
    final $$PlaylistSongsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.playlistSongs,
        getReferencedColumn: (t) => t.songId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PlaylistSongsTableFilterComposer(
              $db: $db,
              $table: $db.playlistSongs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$SongsTableOrderingComposer
    extends Composer<_$MusicDatabase, $SongsTable> {
  $$SongsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get artist => $composableBuilder(
      column: $table.artist, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get album => $composableBuilder(
      column: $table.album, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get genre => $composableBuilder(
      column: $table.genre, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get filePath => $composableBuilder(
      column: $table.filePath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lyrics => $composableBuilder(
      column: $table.lyrics, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<Uint8List> get lyricsBlob => $composableBuilder(
      column: $table.lyricsBlob, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get bitrate => $composableBuilder(
      column: $table.bitrate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sampleRate => $composableBuilder(
      column: $table.sampleRate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get duration => $composableBuilder(
      column: $table.duration, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get albumArtPath => $composableBuilder(
      column: $table.albumArtPath,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get albumArtThumbPath => $composableBuilder(
      column: $table.albumArtThumbPath,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get dateAdded => $composableBuilder(
      column: $table.dateAdded, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastPlayedTime => $composableBuilder(
      column: $table.lastPlayedTime,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get playedCount => $composableBuilder(
      column: $table.playedCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get palette => $composableBuilder(
      column: $table.palette, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get fileSize => $composableBuilder(
      column: $table.fileSize, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastModified => $composableBuilder(
      column: $table.lastModified,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get skipCount => $composableBuilder(
      column: $table.skipCount, builder: (column) => ColumnOrderings(column));
}

class $$SongsTableAnnotationComposer
    extends Composer<_$MusicDatabase, $SongsTable> {
  $$SongsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get artist =>
      $composableBuilder(column: $table.artist, builder: (column) => column);

  GeneratedColumn<String> get album =>
      $composableBuilder(column: $table.album, builder: (column) => column);

  GeneratedColumn<String> get genre =>
      $composableBuilder(column: $table.genre, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get lyrics =>
      $composableBuilder(column: $table.lyrics, builder: (column) => column);

  GeneratedColumnWithTypeConverter<LyricsData?, Uint8List> get lyricsBlob =>
      $composableBuilder(
          column: $table.lyricsBlob, builder: (column) => column);

  GeneratedColumn<int> get bitrate =>
      $composableBuilder(column: $table.bitrate, builder: (column) => column);

  GeneratedColumn<int> get sampleRate => $composableBuilder(
      column: $table.sampleRate, builder: (column) => column);

  GeneratedColumn<int> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => column);

  GeneratedColumn<String> get albumArtPath => $composableBuilder(
      column: $table.albumArtPath, builder: (column) => column);

  GeneratedColumn<String> get albumArtThumbPath => $composableBuilder(
      column: $table.albumArtThumbPath, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get dateAdded =>
      $composableBuilder(column: $table.dateAdded, builder: (column) => column);

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => column);

  GeneratedColumn<DateTime> get lastPlayedTime => $composableBuilder(
      column: $table.lastPlayedTime, builder: (column) => column);

  GeneratedColumn<int> get playedCount => $composableBuilder(
      column: $table.playedCount, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<Color>?, String> get palette =>
      $composableBuilder(column: $table.palette, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<int> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => column);

  GeneratedColumn<DateTime> get lastModified => $composableBuilder(
      column: $table.lastModified, builder: (column) => column);

  GeneratedColumn<int> get skipCount =>
      $composableBuilder(column: $table.skipCount, builder: (column) => column);

  Expression<T> playlistSongsRefs<T extends Object>(
      Expression<T> Function($$PlaylistSongsTableAnnotationComposer a) f) {
    final $$PlaylistSongsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.playlistSongs,
        getReferencedColumn: (t) => t.songId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PlaylistSongsTableAnnotationComposer(
              $db: $db,
              $table: $db.playlistSongs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$SongsTableTableManager extends RootTableManager<
    _$MusicDatabase,
    $SongsTable,
    Song,
    $$SongsTableFilterComposer,
    $$SongsTableOrderingComposer,
    $$SongsTableAnnotationComposer,
    $$SongsTableCreateCompanionBuilder,
    $$SongsTableUpdateCompanionBuilder,
    (Song, $$SongsTableReferences),
    Song,
    PrefetchHooks Function({bool playlistSongsRefs})> {
  $$SongsTableTableManager(_$MusicDatabase db, $SongsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SongsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SongsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SongsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> artist = const Value.absent(),
            Value<String?> album = const Value.absent(),
            Value<String?> genre = const Value.absent(),
            Value<String> filePath = const Value.absent(),
            Value<String?> lyrics = const Value.absent(),
            Value<LyricsData?> lyricsBlob = const Value.absent(),
            Value<int?> bitrate = const Value.absent(),
            Value<int?> sampleRate = const Value.absent(),
            Value<int?> duration = const Value.absent(),
            Value<String?> albumArtPath = const Value.absent(),
            Value<String?> albumArtThumbPath = const Value.absent(),
            Value<int?> sortOrder = const Value.absent(),
            Value<DateTime> dateAdded = const Value.absent(),
            Value<bool> isFavorite = const Value.absent(),
            Value<DateTime> lastPlayedTime = const Value.absent(),
            Value<int> playedCount = const Value.absent(),
            Value<List<Color>?> palette = const Value.absent(),
            Value<String?> source = const Value.absent(),
            Value<int?> fileSize = const Value.absent(),
            Value<DateTime?> lastModified = const Value.absent(),
            Value<int?> skipCount = const Value.absent(),
          }) =>
              SongsCompanion(
            id: id,
            title: title,
            artist: artist,
            album: album,
            genre: genre,
            filePath: filePath,
            lyrics: lyrics,
            lyricsBlob: lyricsBlob,
            bitrate: bitrate,
            sampleRate: sampleRate,
            duration: duration,
            albumArtPath: albumArtPath,
            albumArtThumbPath: albumArtThumbPath,
            sortOrder: sortOrder,
            dateAdded: dateAdded,
            isFavorite: isFavorite,
            lastPlayedTime: lastPlayedTime,
            playedCount: playedCount,
            palette: palette,
            source: source,
            fileSize: fileSize,
            lastModified: lastModified,
            skipCount: skipCount,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String title,
            Value<String?> artist = const Value.absent(),
            Value<String?> album = const Value.absent(),
            Value<String?> genre = const Value.absent(),
            required String filePath,
            Value<String?> lyrics = const Value.absent(),
            Value<LyricsData?> lyricsBlob = const Value.absent(),
            Value<int?> bitrate = const Value.absent(),
            Value<int?> sampleRate = const Value.absent(),
            Value<int?> duration = const Value.absent(),
            Value<String?> albumArtPath = const Value.absent(),
            Value<String?> albumArtThumbPath = const Value.absent(),
            Value<int?> sortOrder = const Value.absent(),
            Value<DateTime> dateAdded = const Value.absent(),
            Value<bool> isFavorite = const Value.absent(),
            Value<DateTime> lastPlayedTime = const Value.absent(),
            Value<int> playedCount = const Value.absent(),
            Value<List<Color>?> palette = const Value.absent(),
            Value<String?> source = const Value.absent(),
            Value<int?> fileSize = const Value.absent(),
            Value<DateTime?> lastModified = const Value.absent(),
            Value<int?> skipCount = const Value.absent(),
          }) =>
              SongsCompanion.insert(
            id: id,
            title: title,
            artist: artist,
            album: album,
            genre: genre,
            filePath: filePath,
            lyrics: lyrics,
            lyricsBlob: lyricsBlob,
            bitrate: bitrate,
            sampleRate: sampleRate,
            duration: duration,
            albumArtPath: albumArtPath,
            albumArtThumbPath: albumArtThumbPath,
            sortOrder: sortOrder,
            dateAdded: dateAdded,
            isFavorite: isFavorite,
            lastPlayedTime: lastPlayedTime,
            playedCount: playedCount,
            palette: palette,
            source: source,
            fileSize: fileSize,
            lastModified: lastModified,
            skipCount: skipCount,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$SongsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({playlistSongsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (playlistSongsRefs) db.playlistSongs
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (playlistSongsRefs)
                    await $_getPrefetchedData<Song, $SongsTable, PlaylistSong>(
                        currentTable: table,
                        referencedTable:
                            $$SongsTableReferences._playlistSongsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$SongsTableReferences(db, table, p0)
                                .playlistSongsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.songId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$SongsTableProcessedTableManager = ProcessedTableManager<
    _$MusicDatabase,
    $SongsTable,
    Song,
    $$SongsTableFilterComposer,
    $$SongsTableOrderingComposer,
    $$SongsTableAnnotationComposer,
    $$SongsTableCreateCompanionBuilder,
    $$SongsTableUpdateCompanionBuilder,
    (Song, $$SongsTableReferences),
    Song,
    PrefetchHooks Function({bool playlistSongsRefs})>;
typedef $$PlaylistsTableCreateCompanionBuilder = PlaylistsCompanion Function({
  Value<int> id,
  required String name,
  Value<String?> description,
  Value<DateTime> createdAt,
  Value<List<Color>?> palette,
  Value<String> type,
  Value<String?> coverPath,
  Value<String?> coverThumbPath,
});
typedef $$PlaylistsTableUpdateCompanionBuilder = PlaylistsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String?> description,
  Value<DateTime> createdAt,
  Value<List<Color>?> palette,
  Value<String> type,
  Value<String?> coverPath,
  Value<String?> coverThumbPath,
});

final class $$PlaylistsTableReferences
    extends BaseReferences<_$MusicDatabase, $PlaylistsTable, Playlist> {
  $$PlaylistsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PlaylistSongsTable, List<PlaylistSong>>
      _playlistSongsRefsTable(_$MusicDatabase db) =>
          MultiTypedResultKey.fromTable(db.playlistSongs,
              aliasName: $_aliasNameGenerator(
                  db.playlists.id, db.playlistSongs.playlistId));

  $$PlaylistSongsTableProcessedTableManager get playlistSongsRefs {
    final manager = $$PlaylistSongsTableTableManager($_db, $_db.playlistSongs)
        .filter((f) => f.playlistId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_playlistSongsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$PlaylistsTableFilterComposer
    extends Composer<_$MusicDatabase, $PlaylistsTable> {
  $$PlaylistsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<List<Color>?, List<Color>, String>
      get palette => $composableBuilder(
          column: $table.palette,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get coverPath => $composableBuilder(
      column: $table.coverPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get coverThumbPath => $composableBuilder(
      column: $table.coverThumbPath,
      builder: (column) => ColumnFilters(column));

  Expression<bool> playlistSongsRefs(
      Expression<bool> Function($$PlaylistSongsTableFilterComposer f) f) {
    final $$PlaylistSongsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.playlistSongs,
        getReferencedColumn: (t) => t.playlistId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PlaylistSongsTableFilterComposer(
              $db: $db,
              $table: $db.playlistSongs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$PlaylistsTableOrderingComposer
    extends Composer<_$MusicDatabase, $PlaylistsTable> {
  $$PlaylistsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get palette => $composableBuilder(
      column: $table.palette, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get coverPath => $composableBuilder(
      column: $table.coverPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get coverThumbPath => $composableBuilder(
      column: $table.coverThumbPath,
      builder: (column) => ColumnOrderings(column));
}

class $$PlaylistsTableAnnotationComposer
    extends Composer<_$MusicDatabase, $PlaylistsTable> {
  $$PlaylistsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<Color>?, String> get palette =>
      $composableBuilder(column: $table.palette, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get coverPath =>
      $composableBuilder(column: $table.coverPath, builder: (column) => column);

  GeneratedColumn<String> get coverThumbPath => $composableBuilder(
      column: $table.coverThumbPath, builder: (column) => column);

  Expression<T> playlistSongsRefs<T extends Object>(
      Expression<T> Function($$PlaylistSongsTableAnnotationComposer a) f) {
    final $$PlaylistSongsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.playlistSongs,
        getReferencedColumn: (t) => t.playlistId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PlaylistSongsTableAnnotationComposer(
              $db: $db,
              $table: $db.playlistSongs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$PlaylistsTableTableManager extends RootTableManager<
    _$MusicDatabase,
    $PlaylistsTable,
    Playlist,
    $$PlaylistsTableFilterComposer,
    $$PlaylistsTableOrderingComposer,
    $$PlaylistsTableAnnotationComposer,
    $$PlaylistsTableCreateCompanionBuilder,
    $$PlaylistsTableUpdateCompanionBuilder,
    (Playlist, $$PlaylistsTableReferences),
    Playlist,
    PrefetchHooks Function({bool playlistSongsRefs})> {
  $$PlaylistsTableTableManager(_$MusicDatabase db, $PlaylistsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaylistsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaylistsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlaylistsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<List<Color>?> palette = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String?> coverPath = const Value.absent(),
            Value<String?> coverThumbPath = const Value.absent(),
          }) =>
              PlaylistsCompanion(
            id: id,
            name: name,
            description: description,
            createdAt: createdAt,
            palette: palette,
            type: type,
            coverPath: coverPath,
            coverThumbPath: coverThumbPath,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<String?> description = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<List<Color>?> palette = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String?> coverPath = const Value.absent(),
            Value<String?> coverThumbPath = const Value.absent(),
          }) =>
              PlaylistsCompanion.insert(
            id: id,
            name: name,
            description: description,
            createdAt: createdAt,
            palette: palette,
            type: type,
            coverPath: coverPath,
            coverThumbPath: coverThumbPath,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$PlaylistsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({playlistSongsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (playlistSongsRefs) db.playlistSongs
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (playlistSongsRefs)
                    await $_getPrefetchedData<Playlist, $PlaylistsTable,
                            PlaylistSong>(
                        currentTable: table,
                        referencedTable: $$PlaylistsTableReferences
                            ._playlistSongsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$PlaylistsTableReferences(db, table, p0)
                                .playlistSongsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.playlistId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$PlaylistsTableProcessedTableManager = ProcessedTableManager<
    _$MusicDatabase,
    $PlaylistsTable,
    Playlist,
    $$PlaylistsTableFilterComposer,
    $$PlaylistsTableOrderingComposer,
    $$PlaylistsTableAnnotationComposer,
    $$PlaylistsTableCreateCompanionBuilder,
    $$PlaylistsTableUpdateCompanionBuilder,
    (Playlist, $$PlaylistsTableReferences),
    Playlist,
    PrefetchHooks Function({bool playlistSongsRefs})>;
typedef $$PlaylistSongsTableCreateCompanionBuilder = PlaylistSongsCompanion
    Function({
  Value<int> id,
  required int playlistId,
  required int songId,
  Value<int?> sortOrder,
});
typedef $$PlaylistSongsTableUpdateCompanionBuilder = PlaylistSongsCompanion
    Function({
  Value<int> id,
  Value<int> playlistId,
  Value<int> songId,
  Value<int?> sortOrder,
});

final class $$PlaylistSongsTableReferences
    extends BaseReferences<_$MusicDatabase, $PlaylistSongsTable, PlaylistSong> {
  $$PlaylistSongsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $PlaylistsTable _playlistIdTable(_$MusicDatabase db) =>
      db.playlists.createAlias(
          $_aliasNameGenerator(db.playlistSongs.playlistId, db.playlists.id));

  $$PlaylistsTableProcessedTableManager get playlistId {
    final $_column = $_itemColumn<int>('playlist_id')!;

    final manager = $$PlaylistsTableTableManager($_db, $_db.playlists)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_playlistIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $SongsTable _songIdTable(_$MusicDatabase db) => db.songs
      .createAlias($_aliasNameGenerator(db.playlistSongs.songId, db.songs.id));

  $$SongsTableProcessedTableManager get songId {
    final $_column = $_itemColumn<int>('song_id')!;

    final manager = $$SongsTableTableManager($_db, $_db.songs)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_songIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$PlaylistSongsTableFilterComposer
    extends Composer<_$MusicDatabase, $PlaylistSongsTable> {
  $$PlaylistSongsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  $$PlaylistsTableFilterComposer get playlistId {
    final $$PlaylistsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.playlistId,
        referencedTable: $db.playlists,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PlaylistsTableFilterComposer(
              $db: $db,
              $table: $db.playlists,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$SongsTableFilterComposer get songId {
    final $$SongsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.songId,
        referencedTable: $db.songs,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SongsTableFilterComposer(
              $db: $db,
              $table: $db.songs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PlaylistSongsTableOrderingComposer
    extends Composer<_$MusicDatabase, $PlaylistSongsTable> {
  $$PlaylistSongsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  $$PlaylistsTableOrderingComposer get playlistId {
    final $$PlaylistsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.playlistId,
        referencedTable: $db.playlists,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PlaylistsTableOrderingComposer(
              $db: $db,
              $table: $db.playlists,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$SongsTableOrderingComposer get songId {
    final $$SongsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.songId,
        referencedTable: $db.songs,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SongsTableOrderingComposer(
              $db: $db,
              $table: $db.songs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PlaylistSongsTableAnnotationComposer
    extends Composer<_$MusicDatabase, $PlaylistSongsTable> {
  $$PlaylistSongsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  $$PlaylistsTableAnnotationComposer get playlistId {
    final $$PlaylistsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.playlistId,
        referencedTable: $db.playlists,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PlaylistsTableAnnotationComposer(
              $db: $db,
              $table: $db.playlists,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$SongsTableAnnotationComposer get songId {
    final $$SongsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.songId,
        referencedTable: $db.songs,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SongsTableAnnotationComposer(
              $db: $db,
              $table: $db.songs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PlaylistSongsTableTableManager extends RootTableManager<
    _$MusicDatabase,
    $PlaylistSongsTable,
    PlaylistSong,
    $$PlaylistSongsTableFilterComposer,
    $$PlaylistSongsTableOrderingComposer,
    $$PlaylistSongsTableAnnotationComposer,
    $$PlaylistSongsTableCreateCompanionBuilder,
    $$PlaylistSongsTableUpdateCompanionBuilder,
    (PlaylistSong, $$PlaylistSongsTableReferences),
    PlaylistSong,
    PrefetchHooks Function({bool playlistId, bool songId})> {
  $$PlaylistSongsTableTableManager(
      _$MusicDatabase db, $PlaylistSongsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaylistSongsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaylistSongsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlaylistSongsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> playlistId = const Value.absent(),
            Value<int> songId = const Value.absent(),
            Value<int?> sortOrder = const Value.absent(),
          }) =>
              PlaylistSongsCompanion(
            id: id,
            playlistId: playlistId,
            songId: songId,
            sortOrder: sortOrder,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int playlistId,
            required int songId,
            Value<int?> sortOrder = const Value.absent(),
          }) =>
              PlaylistSongsCompanion.insert(
            id: id,
            playlistId: playlistId,
            songId: songId,
            sortOrder: sortOrder,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$PlaylistSongsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({playlistId = false, songId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (playlistId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.playlistId,
                    referencedTable:
                        $$PlaylistSongsTableReferences._playlistIdTable(db),
                    referencedColumn:
                        $$PlaylistSongsTableReferences._playlistIdTable(db).id,
                  ) as T;
                }
                if (songId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.songId,
                    referencedTable:
                        $$PlaylistSongsTableReferences._songIdTable(db),
                    referencedColumn:
                        $$PlaylistSongsTableReferences._songIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$PlaylistSongsTableProcessedTableManager = ProcessedTableManager<
    _$MusicDatabase,
    $PlaylistSongsTable,
    PlaylistSong,
    $$PlaylistSongsTableFilterComposer,
    $$PlaylistSongsTableOrderingComposer,
    $$PlaylistSongsTableAnnotationComposer,
    $$PlaylistSongsTableCreateCompanionBuilder,
    $$PlaylistSongsTableUpdateCompanionBuilder,
    (PlaylistSong, $$PlaylistSongsTableReferences),
    PlaylistSong,
    PrefetchHooks Function({bool playlistId, bool songId})>;

class $MusicDatabaseManager {
  final _$MusicDatabase _db;
  $MusicDatabaseManager(this._db);
  $$SongsTableTableManager get songs =>
      $$SongsTableTableManager(_db, _db.songs);
  $$PlaylistsTableTableManager get playlists =>
      $$PlaylistsTableTableManager(_db, _db.playlists);
  $$PlaylistSongsTableTableManager get playlistSongs =>
      $$PlaylistSongsTableTableManager(_db, _db.playlistSongs);
}
