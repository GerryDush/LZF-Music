import 'dart:convert';
import 'dart:typed_data';

class LyricsData {
  final List<LyricLine> lines;
  final Map<String, dynamic>? metadata; 

  LyricsData({required this.lines, this.metadata});

  Map<String, dynamic> toJson() {
    return {
      'lines': lines.map((l) => l.toJson()).toList(),
      'metadata': metadata,
    };
  }

  factory LyricsData.fromJson(Map<String, dynamic> json) {
    return LyricsData(
      lines: (json['lines'] as List)
          .map((e) => LyricLine.fromJson(e))
          .toList(),
      metadata: json['metadata'],
    );
  }

  Uint8List toBlob() {
    final jsonString = jsonEncode(toJson());
    return utf8.encode(jsonString) as Uint8List;
  }

  factory LyricsData.fromBlob(Uint8List blob) {
    final jsonString = utf8.decode(blob);
    return LyricsData.fromJson(jsonDecode(jsonString));
  }
}

class LyricLine {
  final List<LyricSpan> spans; // 原文片段 (字或词)
  final Duration startTime;
  final Duration endTime;
  final String? translation; // [新增] 翻译文本

  LyricLine({
    required this.spans,
    required this.startTime,
    required this.endTime,
    this.translation,
  });

  Map<String, dynamic> toJson() {
    return {
      'spans': spans.map((s) => s.toJson()).toList(),
      'startTime': startTime.inMilliseconds,
      'endTime': endTime.inMilliseconds,
      'translation': translation,
    };
  }

  factory LyricLine.fromJson(Map<String, dynamic> json) {
    return LyricLine(
      spans: (json['spans'] as List)
          .map((e) => LyricSpan.fromJson(e))
          .toList(),
      startTime: Duration(milliseconds: json['startTime']),
      endTime: Duration(milliseconds: json['endTime']),
      translation: json['translation'],
    );
  }
}

class LyricSpan {
  final String text; 
  final Duration start;
  final Duration end;

  LyricSpan({required this.text, required this.start, required this.end});

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'start': start.inMilliseconds,
      'end': end.inMilliseconds,
    };
  }

  factory LyricSpan.fromJson(Map<String, dynamic> json) {
    return LyricSpan(
      text: json['text'],
      start: Duration(milliseconds: json['start']),
      end: Duration(milliseconds: json['end']),
    );
  }
}