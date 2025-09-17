import 'package:flutter/material.dart';
import '../services/music_import_service.dart';
import 'dart:async';
import '../widgets/lzf_dialog.dart';
import '../utils/theme_utils.dart';

class _ImportProgress {
  final bool scaning;
  final String currentFile;
  final int processed;
  final int total;
  final double progress;
  final List<String> failedFiles;
  final bool completed;

  _ImportProgress({
    required this.scaning,
    required this.currentFile,
    required this.processed,
    required this.total,
    required this.progress,
    required this.failedFiles,
    required this.completed,
  });
  _ImportProgress copyWith({
    bool? scaning,
    String? currentFile,
    int? processed,
    int? total,
    double? progress,
    List<String>? failedFiles,
    bool? completed,
  }) {
    return _ImportProgress(
      scaning: scaning ?? this.scaning,
      currentFile: currentFile ?? this.currentFile,
      processed: processed ?? this.processed,
      total: total ?? this.total,
      progress: progress ?? this.progress,
      failedFiles: failedFiles ?? this.failedFiles,
      completed: completed ?? this.completed,
    );
  }

  _ImportProgress.empty()
    : scaning = false,
      currentFile = '',
      processed = 0,
      total = 0,
      progress = 0.0,
      failedFiles = [],
      completed = false;
}

// 使用Stream版本的Widget实现
class MusicImporter {
  static MusicImportService? _importService;
  static StreamSubscription<ImportEvent>? _subscription;
  static void Function()? _onCompleted;

  static final ValueNotifier<_ImportProgress> _progressNotifier = ValueNotifier(
    _ImportProgress.empty(),
  );

  /// 从文件夹导入音乐
  static void importFromDirectory(
    BuildContext context, {
    void Function()? onCompleted,
  }) {
    _onCompleted = onCompleted;
    _startImport(context, _importService!.importFromDirectory());
  }

  /// 导入选定的文件
  static void importFiles(
    BuildContext context,{
    void Function()? onCompleted,
  }) {
    _onCompleted = onCompleted;
    _startImport(context, _importService!.importFiles());
  }

  static void _startImport(
    BuildContext context,
    Stream<ImportEvent> importStream,
  ) {
    _progressNotifier.value = _ImportProgress.empty();

    _subscription = importStream.listen(
      (event) {
        _handleImportEvent(context, event);
      },
      onError: (error) {
        // Navigator.of(context).pop(); // 关闭弹窗
        // _showErrorSnackBar(context, '导入过程中发生错误: ${error.toString()}');
      },
    );
  }

  static void _handleImportEvent(BuildContext context, ImportEvent event) {
    switch (event) {
      case SelectedEvent():
        _progressNotifier.value = _progressNotifier.value.copyWith(
          scaning: true,
        );
        _showProgressDialog(context);
        break;
      case ScaningEvent():
        _progressNotifier.value = _progressNotifier.value.copyWith(
          scaning: true,
          total: event.count,
        );
        break;
      case ScanCompletedEvent():
        _progressNotifier.value = _progressNotifier.value.copyWith(
          scaning: false,
          total: event.count,
        );
        break;

      case ProgressingEvent():
        _progressNotifier.value = _progressNotifier.value.copyWith(
          currentFile: event.currentFile,
          processed: event.processed,
          total: event.total,
          progress: event.progress,
        );
        break;

      case CompletedEvent():
        debugPrint('导入完成');
        _onCompleted?.call();
        _progressNotifier.value = _progressNotifier.value.copyWith(
          completed: true,
        );
        break;

      case FailedEvent():
        debugPrint('导入失败: ${event.error}');
        final failedFiles = List<String>.from(
          _progressNotifier.value.failedFiles,
        )..add(event.error);
        _progressNotifier.value = _progressNotifier.value.copyWith(
          failedFiles: failedFiles,
        );
        break;

      case CancelledEvent():
        _progressNotifier.value = _progressNotifier.value.copyWith(
          completed: true,
        );
        _onCompleted?.call();
        break;
    }
  }

  static void _showProgressDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ValueListenableBuilder<_ImportProgress>(
        valueListenable: _progressNotifier,
        builder: (context, progress, _) {
          return LZFDialog(
            danger: !progress.completed,
            titleText: progress.completed ? '导入完成' : '正在导入歌曲',
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(
                  value: progress.progress,
                  minHeight: 8,
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                  backgroundColor: ThemeUtils.select(
                    context,
                    light: Colors.grey[400],
                    dark: Colors.grey[800],
                  ),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    ThemeUtils.primaryColor(context),
                  ),
                ),
                const SizedBox(height: 10),
                // 当前导入歌曲名和进度数字
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        !progress.scaning ? progress.currentFile : '扫描中...',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text('${progress.processed}/${progress.total}'),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...progress.failedFiles.map(
                          (err) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              '• 导入失败: $err',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red[600],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            confirmText: progress.completed ? '确定' : '取消',
            cancelText: null,
            onConfirm: () {
              _importService?.cancel();
            },
          );
        },
      ),
    );
  }

  /// 清理资源
  static void dispose() {
    _subscription?.cancel();
    _importService = null;
  }
}
