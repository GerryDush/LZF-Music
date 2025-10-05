import 'package:path_provider/path_provider.dart';

class CommonUtils {
  CommonUtils._();
  static T select<T>(bool condition, {required T t, required T f}) {
    return condition ? t : f;
  }

  static String formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  static Future<String> getAppBaseDirectory() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    return "${dbFolder.path}/LZF-Music";
  }
}
