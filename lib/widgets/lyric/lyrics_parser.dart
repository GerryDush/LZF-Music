import 'dart:math';

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

    // TTML 格式 (XML)
    if (trimmed.startsWith('<tt') || trimmed.contains('xmlns:tt')) {
      return _parseTtml(trimmed);
    }
    // LRC 格式 (包含时间戳)
    else if (RegExp(r'\[\d{2}:\d{2}\.\d{1,3}\]').hasMatch(trimmed)) {
      return _parseLrc(trimmed);
    }
    // 纯文本或其他
    else {
      debugPrint("Unknown lyrics format. Treating as plain text.");
      // 如果没有时间戳，可以尝试按行切分，给一个默认时间，或者直接返回空
      return LyricsData(lines: []);
    }
  }

  // --- LRC 解析逻辑 ---
  static Future<LyricsData> _parseLrc(String lrcContent) async {
    final Map<int, _RawLrcLine> timeToRawLines = {};
    final Map<String, dynamic> metadata = {};
    final lines = lrcContent.split(RegExp(r'\r\n|\r|\n'));
    
    int globalOffset = 0; // 全局偏移量 (毫秒)

    // 1. 基础解析：提取元数据和原始行
    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;

      // 解析元数据标签 [key:value]
      // 常见标签: ti(标题), ar(歌手), al(专辑), by(制作者), offset(偏移量ms)
      final metadataMatch = RegExp(r'^\[([a-zA-Z]+):(.*)\]$').firstMatch(trimmedLine);
      if (metadataMatch != null) {
        final key = metadataMatch.group(1)?.toLowerCase();
        final value = metadataMatch.group(2)?.trim();
        if (key != null && value != null) {
          if (key == 'offset') {
            globalOffset = int.tryParse(value) ?? 0;
          } else {
            metadata[key] = value;
          }
        }
        continue; // 元数据行不作为歌词行处理
      }

      // 解析时间戳 [mm:ss.xxx]
      final timeMatches = RegExp(r'\[(\d{2}):(\d{2})\.(\d{1,3})\]').allMatches(trimmedLine);
      if (timeMatches.isEmpty) continue;

      // 提取歌词文本 (移除所有时间戳标签)
      final text = trimmedLine.replaceAll(RegExp(r'\[\d{2}:\d{2}\.\d{1,3}\]'), '').trim();
      if (text.isEmpty) continue;

      for (final match in timeMatches) {
        final m = int.parse(match.group(1)!);
        final s = int.parse(match.group(2)!);
        final msStr = match.group(3)!;
        // 补齐毫秒位 (如 .2 -> 200, .20 -> 200, .02 -> 020)
        final ms = int.parse(msStr.padRight(3, '0'));
        
        // 计算绝对时间 (包含 offset)
        // 注意：LRC offset 正值表示歌词显示提前(时间减少)，负值表示推后(时间增加)
        // 但也有播放器实现相反，这里采用标准逻辑：Time = ParseTime - Offset
        final timeInMs = ((m * 60 + s) * 1000 + ms) - globalOffset;

        if (!timeToRawLines.containsKey(timeInMs)) {
          timeToRawLines[timeInMs] = _RawLrcLine();
        }
        timeToRawLines[timeInMs]!.texts.add(text);
      }
    }

    final sortedTimes = timeToRawLines.keys.toList()..sort();
    final lyricLines = <LyricLine>[];

    // 2. 构建行与片段，处理翻译
    for (int i = 0; i < sortedTimes.length; i++) {
      final timeInMs = sortedTimes[i];
      final rawLine = timeToRawLines[timeInMs]!;
      
      // 处理多行文本：通常第一行是原文，后续行可能是翻译
      final mainText = rawLine.texts.first;
      final Map<String, String> translations = {};
      
      // 简单的翻译探测逻辑：
      // 如果同一时间戳有多行文本，我们将第二行视为中文翻译 'zh' (这是一个假设，实际可能需要更复杂的语言检测)
      // 你也可以根据业务需求，解析类似 [tr:zh]xxx 的非标准标签
      if (rawLine.texts.length > 1) {
        // 这里简单地把第二行当做 'zh' 翻译。
        // 如果你的LRC来源有特定格式（比如 T1...），可以在这里适配。
        translations['zh'] = rawLine.texts[1]; 
      }

      // 计算结束时间：下一行的开始时间，或者当前时间+5秒(如果是最后一行)
      final nextTimeInMs = (i + 1 < sortedTimes.length)
          ? sortedTimes[i + 1]
          : timeInMs + 5000; 

      final startTime = Duration(milliseconds: timeInMs > 0 ? timeInMs : 0);
      final endTime = Duration(milliseconds: nextTimeInMs);

      lyricLines.add(LyricLine(
        spans: _tokenizeAndDistribute(mainText, startTime, endTime),
        startTime: startTime,
        endTime: endTime,
        translations: translations.isNotEmpty ? translations : null,
      ));
    }

    return LyricsData(
      lines: lyricLines,
      metadata: metadata.isNotEmpty ? metadata : null,
    );
  }

  // --- TTML 解析逻辑 ---
  static Future<LyricsData> _parseTtml(String ttmlContent) async {
    try {
      final document = XmlDocument.parse(ttmlContent);
      final paragraphs = document.findAllElements('p');
      final lyricLines = <LyricLine>[];
      final Map<String, dynamic> metadata = {};

      // 尝试提取 metadata (TTML head -> metadata)
      // 简单实现，视具体 TTML 结构而定
      try {
        final head = document.findAllElements('head').firstOrNull;
        if (head != null) {
           final title = head.findAllElements('ttm:title').firstOrNull?.text;
           if (title != null) metadata['title'] = title;
        }
      } catch (_) {}

      for (final p in paragraphs) {
        final lineStartTimeStr = p.getAttribute('begin') ?? '0.0s';
        final lineEndTimeStr = p.getAttribute('end') ?? '0.0s';
        final lineStartTime = _parseTtmlTime(lineStartTimeStr);
        final lineEndTime = _parseTtmlTime(lineEndTimeStr);
        
        final tempSpans = <_TempSpan>[];

        // 第一次遍历：提取 span
        for (final node in p.children) {
          if (node is XmlElement && node.name.local == 'span') {
            // 过滤掉角色标记等非歌词内容
            if (node.getAttribute('ttm:role') != null) continue;
            
            final text = node.text;
            if (text.isNotEmpty) {
              final sTime = _parseTtmlTime(node.getAttribute('begin') ?? lineStartTimeStr);
              final eTimeStr = node.getAttribute('end');
              final eTime = eTimeStr != null ? _parseTtmlTime(eTimeStr) : null;
              
              tempSpans.add(_TempSpan(text, sTime, eTime));
            }
          } else if (node is XmlText && node.text.trim().isEmpty && tempSpans.isNotEmpty) {
             // 补空格逻辑 (XML 解析时可能会丢失单词间的空格)
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
            // 确保 end > start
            validEnd = nextStart > current.startTime ? nextStart : current.startTime + const Duration(milliseconds: 100);
          }

          // 这里调用分词逻辑，把句子打散成字/词
          // 注意：TTML 如果本身已经是逐词的 span，则不需要再 split，直接作为一个 span
          // 这里为了保险（有些 span 是半句话），还是走一遍分词
          finalSpans.addAll(_tokenizeAndDistribute(current.text, current.startTime, validEnd));
        }

        if (finalSpans.isNotEmpty) {
          lyricLines.add(LyricLine(
            spans: finalSpans,
            startTime: lineStartTime,
            endTime: lineEndTime,
            // TTML 翻译通常在另一个 div 或 p 中，结构较复杂，此处暂不处理行内翻译
            translations: null, 
          ));
        }
      }
      return LyricsData(lines: lyricLines, metadata: metadata);
    } catch (e) {
      debugPrint('Error parsing TTML: $e');
      return LyricsData(lines: []);
    }
  }

  /// 核心算法：将一段文本在指定时间内均匀分配给每个字/词
  static List<LyricSpan> _tokenizeAndDistribute(String text, Duration start, Duration end) {
    final spans = <LyricSpan>[];
    final totalDurationMs = (end - start).inMilliseconds;
    
    if (totalDurationMs <= 0 || text.isEmpty) {
      spans.add(LyricSpan(text: text, start: start, end: end));
      return spans;
    }

    // --- 语言检测与分词 ---
    // 简单策略：包含空格则按空格分（西文），否则按字分（CJK）
    // 优化：处理标点符号粘连问题
    final isEnglishLike = RegExp(r'[a-zA-Z]').hasMatch(text);
    List<String> tokens;

    if (isEnglishLike) {
      // 英文：按空格分词，保留空格到前一个单词
      // 例子: "Hello world" -> ["Hello ", "world"]
      final words = text.split(' ');
      tokens = [];
      for (int w = 0; w < words.length; w++) {
        // 如果不是最后一个词，加上空格
        tokens.add(words[w] + (w < words.length - 1 ? ' ' : ''));
      }
    } else {
      // 中文/日文：按单字分词
      tokens = text.split('');
    }

    // 过滤空 token
    tokens = tokens.where((t) => t.isNotEmpty).toList();
    if (tokens.isEmpty) return spans;

    // --- 时间分配 ---
    // 简单策略：按字符长度比例分配时间
    final totalLen = tokens.fold(0, (sum, t) => sum + t.length);
    if (totalLen == 0) return spans;

    double msPerChar = totalDurationMs.toDouble() / totalLen;
    Duration currentStart = start;

    for (final token in tokens) {
      // 计算该 token 的时长
      final tokenDurationMs = (msPerChar * token.length).round();
      // 至少 1ms
      final tokenDuration = Duration(milliseconds: max(1, tokenDurationMs));
      final tokenEnd = currentStart + tokenDuration;

      spans.add(LyricSpan(text: token, start: currentStart, end: tokenEnd));
      currentStart = tokenEnd;
    }
    
    // 修正最后一个 span 的结束时间，确保与行结束时间对齐（消除舍入误差）
    if (spans.isNotEmpty) {
      // 重新创建一个修正了 end 时间的 span
      final last = spans.removeLast();
      spans.add(LyricSpan(text: last.text, start: last.start, end: end));
    }

    return spans;
  }

  /// TTML 时间解析
  static Duration _parseTtmlTime(String time) {
    // 格式: 100.5s
    if (time.endsWith('s')) {
      final seconds = double.tryParse(time.replaceAll('s', '')) ?? 0.0;
      return Duration(milliseconds: (seconds * 1000).round());
    }
    // 格式: 00:01:02.500
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

// 辅助类：用于 LRC 解析过程中聚合同一时间戳的多行文本
class _RawLrcLine {
  final List<String> texts = [];
}

// 辅助类：用于 TTML 解析过程
class _TempSpan {
  String text;
  Duration startTime;
  Duration? endTime;
  _TempSpan(this.text, this.startTime, [this.endTime]);
}