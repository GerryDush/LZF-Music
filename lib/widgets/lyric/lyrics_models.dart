import 'dart:convert';
import 'dart:typed_data';

class LyricsData {
  /// 歌词格式版本
  final int version;

  /// 歌词行
  final List<LyricLine> lines;

  /// 元数据（offset、source、creator 等）
  final Map<String, dynamic>? metadata;

  static const int currentVersion = 1;

  LyricsData({
    this.version = currentVersion,
    required this.lines,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'version': version,
        'lines': lines.map((l) => l.toJson()).toList(),
        'metadata': metadata,
      };

  factory LyricsData.fromJson(Map<String, dynamic> json) {
    final int version = json['version'] ?? 0;

    switch (version) {
      case 0: // 兼容老数据（无 version）
      case 1:
        return LyricsData(
          version: 1,
          lines: (json['lines'] as List)
              .map((e) => LyricLine.fromJson(e))
              .toList(),
          metadata: json['metadata'],
        );

      default:
        throw UnsupportedError(
          'Unsupported LyricsData version: $version',
        );
    }
  }

  Uint8List toBlob() {
    final jsonString = jsonEncode(toJson());
    return utf8.encode(jsonString);
  }

  factory LyricsData.fromBlob(Uint8List blob) {
    final jsonString = utf8.decode(blob);
    return LyricsData.fromJson(jsonDecode(jsonString));
  }

  /// 根据当前播放时间获取歌词行
  LyricLine? getLineAt(Duration position) {
    if (lines.isEmpty) return null;
    try {
      return lines.firstWhere(
        (line) => position >= line.startTime && position <= line.endTime,
      );
    } catch (_) {
      return null;
    }
  }

  /// 获取当前播放时间对应的行索引
  int getLineIndexByProgress(Duration position) {
    if (lines.isEmpty) return 0;
    final index =
        lines.lastIndexWhere((line) => position >= line.startTime);
    return index == -1 ? 0 : index;
  }
}

class LyricLine {
  /// 逐字/逐词时间片
  final List<LyricSpan> spans;

  /// 行开始时间
  final Duration startTime;

  /// 行结束时间
  final Duration endTime;

  /// 多语言翻译
  /// key 示例：zh / en / jp / romaji
  final Map<String, String>? translations;

  LyricLine({
    required this.spans,
    required this.startTime,
    required this.endTime,
    this.translations,
  });

  Map<String, dynamic> toJson() => {
        'spans': spans.map((s) => s.toJson()).toList(),
        'startTime': startTime.inMilliseconds,
        'endTime': endTime.inMilliseconds,
        'translations': translations,
      };

  factory LyricLine.fromJson(Map<String, dynamic> json) {
    return LyricLine(
      spans: (json['spans'] as List)
          .map((e) => LyricSpan.fromJson(e))
          .toList(),
      startTime: Duration(milliseconds: json['startTime']),
      endTime: Duration(milliseconds: json['endTime']),
      translations: (json['translations'] as Map?)
          ?.map((k, v) => MapEntry(k.toString(), v.toString())),
    );
  }

  /// 获取当前正在唱的字/词
  LyricSpan? getSpanAt(Duration position) {
    if (spans.isEmpty) return null;
    try {
      return spans.firstWhere(
        (span) => position >= span.start && position <= span.end,
      );
    } catch (_) {
      return null;
    }
  }

  /// 获取整行播放进度 (0.0 - 1.0)
  double getLineProgress(Duration position) {
    final total =
        endTime.inMilliseconds - startTime.inMilliseconds;
    if (total <= 0) return 0.0;
    final current =
        position.inMilliseconds - startTime.inMilliseconds;
    return (current / total).clamp(0.0, 1.0);
  }

  /// 获取指定语言的翻译
  String? getTranslation(String lang) {
    return translations?[lang];
  }
}

class LyricSpan {
  final String text;
  final Duration start;
  final Duration end;

  LyricSpan({
    required this.text,
    required this.start,
    required this.end,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'start': start.inMilliseconds,
        'end': end.inMilliseconds,
      };

  factory LyricSpan.fromJson(Map<String, dynamic> json) {
    return LyricSpan(
      text: json['text'],
      start: Duration(milliseconds: json['start']),
      end: Duration(milliseconds: json['end']),
    );
  }

  /// 当前字/词播放进度（逐字填充）
  double getSpanProgress(Duration position) {
    final duration =
        end.inMilliseconds - start.inMilliseconds;
    if (duration <= 0) return 1.0;

    if (position < start) return 0.0;
    if (position > end) return 1.0;

    final current =
        position.inMilliseconds - start.inMilliseconds;
    return current / duration;
  }
}
