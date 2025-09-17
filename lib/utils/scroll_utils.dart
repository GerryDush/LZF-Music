import 'package:flutter/widgets.dart';
import '../database/database.dart';

class ScrollUtils {
  /// 滚动到指定的索引位置
  ///
  /// [controller] 滚动控制器
  /// [index] 要滚动到的目标索引
  /// [itemHeight] 单个 item 的高度
  /// [cardMargin] item 上下的额外边距
  /// [animate] 是否使用动画
  static void scrollToIndex(
    ScrollController controller,
    int index, {
    double itemHeight = 70.0,
    double cardMargin = 0,
    bool animate = false,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) {
    if (!controller.hasClients) return;

    final targetPosition = index * (itemHeight + cardMargin);

    // 获取可视区域高度
    final viewportHeight = controller.position.viewportDimension;
    final maxScrollExtent = controller.position.maxScrollExtent;

    // 计算理想的滚动位置（让目标元素出现在视口中央）
    final idealPosition =
        targetPosition - (viewportHeight / 2) + (itemHeight / 2);

    // 限制在范围内
    final scrollPosition = idealPosition.clamp(0.0, maxScrollExtent);

    if (animate) {
      controller.animateTo(scrollPosition, duration: duration, curve: curve);
    } else {
      controller.jumpTo(scrollPosition);
    }
  }

  static scrollToCurrentSong(
    ScrollController scrollController,
    List<Song> songs,
    Song? song,
  ) {
    if (song == null) {
      return;
    }
    final index = songs.indexWhere((s) => s.id == song.id);
    if (index == -1) return; // 歌曲不在列表中

    scrollToIndex(
      scrollController,
      index,
      itemHeight: 70.0,
      cardMargin: 0,
      animate: false, // 改成 true 会平滑滚动
    );
  }
}
