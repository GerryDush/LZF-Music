import 'package:flutter/foundation.dart';
import 'package:xml/xml.dart';
import 'lyrics_models.dart';

class LyricsParser {
  /// 统一入口解析
  static Future<LyricsData> parse(String content) async {
    if (content.trim().isEmpty) {
      return LyricsData(lines: []);
    }

    final trimmed = content.trim();

    // TTML 格式
    if (trimmed.startsWith('<tt') || trimmed.contains('xmlns:tt')) {
      return _parseTtml(trimmed);
    }
    // LRC 格式 (包含时间戳)
    else if (RegExp(r'\[\d{2}:\d{2}\.\d{1,3}\]').hasMatch(trimmed)) {
      return _parseLrc(trimmed);
    } 
    // 纯文本或其他
    else {
      debugPrint("Unknown lyrics format");
      return LyricsData(lines: []);
    }
  }

  // --- LRC 解析逻辑 ---
  static Future<LyricsData> _parseLrc(String lrcContent, {bool originalOnly = true}) async {
    final Map<int, List<String>> timeToTexts = {};
    final lines = lrcContent.split('\n');
    
    // 1. 基础解析
    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      // 匹配 [mm:ss.xxx]
      final matches = RegExp(r'\[(\d{2}):(\d{2})\.(\d{1,3})\]').allMatches(line);
      final text = line.substring(line.lastIndexOf(']') + 1).trim();
      
      if (matches.isNotEmpty && text.isNotEmpty) {
        for (final match in matches) {
          final m = int.parse(match.group(1)!);
          final s = int.parse(match.group(2)!);
          final msStr = match.group(3)!;
          // 补齐毫秒位，如 .2 -> 200, .20 -> 200, .02 -> 020
          final ms = int.parse(msStr.padRight(3, '0')); 
          final timeInMs = (m * 60 + s) * 1000 + ms;
          
          if (!timeToTexts.containsKey(timeInMs)) timeToTexts[timeInMs] = [];
          timeToTexts[timeInMs]!.add(text);
        }
      }
    }

    final sortedTimes = timeToTexts.keys.toList()..sort();
    final lyricLines = <LyricLine>[];

    // 2. 构建行与片段
    for (int i = 0; i < sortedTimes.length; i++) {
      final timeInMs = sortedTimes[i];
      // 简单处理：如果有两行文本在同一时间，且 originalOnly=false，可能需要合并
      // 这里为了演示翻译，假设如果同一时间有第二行文本，它可能是翻译（这取决于LRC的具体规范，此处为简易实现）
      final texts = timeToTexts[timeInMs]!;
      final mainText = texts.first;
      // 尝试获取翻译：如果同一时间戳有多个文本，取第二个作为翻译
      final transText = texts.length > 1 ? texts[1] : null;

      final nextTimeInMs = (i + 1 < sortedTimes.length)
          ? sortedTimes[i + 1]
          : timeInMs + 5000; // 默认最后一行5秒

      final startTime = Duration(milliseconds: timeInMs);
      final endTime = Duration(milliseconds: nextTimeInMs);
      
      lyricLines.add(_buildLine(mainText, startTime, endTime, transText));
    }

    return LyricsData(lines: lyricLines);
  }

  // --- TTML 解析逻辑 ---
  static Future<LyricsData> _parseTtml(String ttmlContent) async {
    try {
      final document = XmlDocument.parse(ttmlContent);
      final paragraphs = document.findAllElements('p');
      final lyricLines = <LyricLine>[];

      for (final p in paragraphs) {
        final lineStartTimeStr = p.getAttribute('begin') ?? '0.0s';
        final lineEndTimeStr = p.getAttribute('end') ?? '0.0s';
        final lineStartTime = _parseTtmlTime(lineStartTimeStr);
        final lineEndTime = _parseTtmlTime(lineEndTimeStr);
        
        // 尝试从 span 中获取 metadata 或者 agent 属性作为翻译
        // TTML 翻译通常比较复杂，可能在另一个 <div> 里，这里暂且只解析主结构
        
        final tempSpans = <_TempSpan>[];

        // 第一次遍历：提取 span
        for (final node in p.children) {
          if (node is XmlElement && node.name.local == 'span') {
             // 过滤掉角色标记等非歌词内容
            if (node.getAttribute('ttm:role') != null) continue;
            
            final text = node.text;
            if (text.isNotEmpty) {
              final sTime = _parseTtmlTime(node.getAttribute('begin') ?? lineStartTimeStr);
               // 有些 TTML 会有显式的 end，如果没有就留空待计算
              final eTimeStr = node.getAttribute('end');
              final eTime = eTimeStr != null ? _parseTtmlTime(eTimeStr) : null;
              
              tempSpans.add(_TempSpan(text, sTime, eTime));
            }
          } else if (node is XmlText && node.text.trim().isEmpty && tempSpans.isNotEmpty) {
             // 补空格逻辑
             tempSpans.last.text += node.text;
          }
        }

        if (tempSpans.isEmpty) continue;

        // 第二次遍历：构建最终 Span
        final finalSpans = <LyricSpan>[];
        for (int i = 0; i < tempSpans.length; i++) {
          final current = tempSpans[i];
          
          // 确定结束时间
          Duration validEnd;
          if (current.endTime != null) {
            validEnd = current.endTime!;
          } else {
            // 如果没有显式结束时间，使用下一个词的开始时间，或者是整行的结束时间
            final nextStart = (i + 1 < tempSpans.length) ? tempSpans[i + 1].startTime : lineEndTime;
            validEnd = nextStart > current.startTime ? nextStart : current.startTime + const Duration(milliseconds: 1);
          }

          // 这里调用分词逻辑，把句子打散成字/词
          finalSpans.addAll(_tokenizeAndDistribute(current.text, current.startTime, validEnd));
        }

        if (finalSpans.isNotEmpty) {
          lyricLines.add(LyricLine(
            spans: finalSpans,
            startTime: lineStartTime,
            endTime: lineEndTime,
            translation: null, // TTML 翻译解析需根据具体 XML 结构定制
          ));
        }
      }
      return LyricsData(lines: lyricLines);
    } catch (e) {
      debugPrint('Error parsing TTML: $e');
      return LyricsData(lines: []);
    }
  }

  /// 辅助：构建单行（包含自动分词逻辑）
  static LyricLine _buildLine(String text, Duration start, Duration end, String? translation) {
    return LyricLine(
      spans: _tokenizeAndDistribute(text, start, end),
      startTime: start,
      endTime: end,
      translation: translation,
    );
  }

  /// 核心算法：将一段文本在指定时间内均匀分配给每个字/词
  static List<LyricSpan> _tokenizeAndDistribute(String text, Duration start, Duration end) {
    final spans = <LyricSpan>[];
    final totalDurationMs = (end - start).inMilliseconds;
    
    if (totalDurationMs <= 0 || text.isEmpty) {
      spans.add(LyricSpan(text: text, start: start, end: end));
      return spans;
    }

    // 语言检测与分词
    final isEnglishLike = RegExp(r'[a-zA-Z]').hasMatch(text);
    List<String> tokens;

    if (isEnglishLike) {
      final words = text.split(' ');
      tokens = [];
      for (int w = 0; w < words.length; w++) {
        tokens.add(words[w] + (w < words.length - 1 ? ' ' : ''));
      }
    } else {
      tokens = text.split('');
    }

    if (tokens.isEmpty) return spans;

    final totalChars = text.length; // 注意：分配权重是用总字符数，不是 token 数
    if (totalChars == 0) return spans;

    double msPerChar = totalDurationMs.toDouble() / totalChars;
    Duration currentStart = start;

    for (final token in tokens) {
      if (token.isEmpty) continue;
      // 英文单词按长度分配时间，长单词唱得久
      final tokenDurationMs = (msPerChar * token.length).round(); 
      final tokenDuration = Duration(milliseconds: tokenDurationMs > 0 ? tokenDurationMs : 1);
      final tokenEnd = currentStart + tokenDuration;

      spans.add(LyricSpan(text: token, start: currentStart, end: tokenEnd));
      currentStart = tokenEnd;
    }
    
    return spans;
  }

  static Duration _parseTtmlTime(String time) {
    if (time.endsWith('s')) {
      final seconds = double.tryParse(time.replaceAll('s', '')) ?? 0.0;
      return Duration(milliseconds: (seconds * 1000).round());
    }
    final parts = time.split(':');
    try {
      if (parts.length == 3) {
        return Duration(milliseconds: int.parse(parts[0]) * 3600000 + int.parse(parts[1]) * 60000 + (double.parse(parts[2]) * 1000).round());
      } else if (parts.length == 2) {
        return Duration(milliseconds: int.parse(parts[0]) * 60000 + (double.parse(parts[1]) * 1000).round());
      }
      return Duration(milliseconds: (double.parse(parts[0]) * 1000).round());
    } catch (e) {
      return Duration.zero;
    }
  }
}

class _TempSpan {
  String text;
  Duration startTime;
  Duration? endTime;
  _TempSpan(this.text, this.startTime, [this.endTime]);
}