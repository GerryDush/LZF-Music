import 'package:drift/drift.dart';
import 'dart:convert';
import 'dart:ui';
import '../widgets/lyric/lyrics_models.dart';

class Songs extends Table {
  /// 主键，自增 ID
  IntColumn get id => integer().autoIncrement()();

  /// 歌曲标题
  TextColumn get title => text()();

  /// 艺术家 / 歌手
  TextColumn get artist => text().nullable()();

  /// 专辑名称
  TextColumn get album => text().nullable()();

  /// 音乐流派
  TextColumn get genre => text().nullable()();

  /// 本地文件路径或资源路径
  TextColumn get filePath => text()();

  /// 歌词内容（可为空）
  TextColumn get lyrics => text().nullable()();
  
  BlobColumn get lyricsBlob =>
    blob().map(const LyricsDataConverter()).nullable()();

  /// 比特率（kbps）
  IntColumn get bitrate => integer().nullable()();

  /// 采样率（Hz）
  IntColumn get sampleRate => integer().nullable()();

  /// 歌曲时长（毫秒）
  IntColumn get duration => integer().nullable()();

  /// 专辑封面图片路径
  TextColumn get albumArtPath => text().nullable()();
  
  /// 专辑封面缩略图路径
  TextColumn get albumArtThumbPath => text().nullable()();

  /// 全局排序字段（越小越靠前）
  IntColumn get sortOrder => integer().nullable().withDefault(const Constant(0))();

  /// 加入音乐库的时间
  DateTimeColumn get dateAdded => dateTime().withDefault(currentDateAndTime)();

  /// 是否标记为喜欢 / 收藏
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();

  /// 最近一次播放时间
  DateTimeColumn get lastPlayedTime =>
      dateTime().withDefault(currentDateAndTime)();

  /// 播放次数统计
  IntColumn get playedCount => integer().withDefault(const Constant(0))();

  /// 主题调色板
  TextColumn get palette => text().map(const ColorListConverter()).nullable()();

  /// 歌曲来源 // local / stream / online
  TextColumn get source => text().nullable().withDefault(const Constant('local'))();

  /// 文件大小
  IntColumn get fileSize => integer().nullable()();

  /// 文件最后修改时间
  DateTimeColumn get lastModified => dateTime().nullable()();

  /// 被用户跳过的次数
  IntColumn get skipCount => integer().nullable().withDefault(const Constant(0))();
}

/// 歌单表
class Playlists extends Table {
  /// 主键，自增 ID
  IntColumn get id => integer().autoIncrement()();

  /// 歌单名称
  TextColumn get name => text()();

  /// 歌单描述信息
  TextColumn get description => text().nullable()();

  /// 歌单创建时间
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// 歌单主题调色板
  TextColumn get palette => text().map(const ColorListConverter()).nullable()();

  /// 歌单类型
  /// manual：手动创建
  /// smart：智能歌单
  /// system：系统歌单
  TextColumn get type => text().withDefault(const Constant('manual'))();
  
    /// 歌单封面原始大图路径（用户上传）
  TextColumn get coverPath => text().nullable()();

  /// 歌单封面缩略图路径
  TextColumn get coverThumbPath => text().nullable()();
}

/// 歌单-歌曲关联表
class PlaylistSongs extends Table {
  /// 主键，自增 ID
  IntColumn get id => integer().autoIncrement()();

  /// 所属歌单 ID
  IntColumn get playlistId => integer().references(Playlists, #id)();

  /// 歌曲 ID
  IntColumn get songId => integer().references(Songs, #id)();

  /// 歌曲在当前歌单中的排序顺序
  IntColumn get sortOrder => integer().nullable().withDefault(const Constant(0))();
}

class Albums extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get artist => text().nullable()();
  TextColumn get releaseDate => text().nullable()();
  TextColumn get coverPath => text().nullable()();
  TextColumn get coverThumbPath => text().nullable()();
}

class AlbumSongs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get albumId => integer().references(Albums, #id)();
  IntColumn get songId => integer().references(Songs, #id)();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

class ColorListConverter extends TypeConverter<List<Color>, String> {
  const ColorListConverter();

  @override
  List<Color> fromSql(String fromDb) {
    try {
      final List<dynamic> jsonList = jsonDecode(fromDb);
      return jsonList.map((value) => Color(value as int)).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  String toSql(List<Color> value) {
    // ✅ 先把 Color 转成 int
    final intList = value.map((c) => c.value).toList();
    return jsonEncode(intList);
  }
}


class LyricsDataConverter extends TypeConverter<LyricsData, Uint8List> {
  const LyricsDataConverter();

  @override
  LyricsData fromSql(Uint8List fromDb) {
    return LyricsData.fromBlob(fromDb);
  }

  @override
  Uint8List toSql(LyricsData value) {
    return value.toBlob();
  }
}