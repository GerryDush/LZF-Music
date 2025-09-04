enum PlayerPage { library, favorite, playlist, recently, settings }

enum SettingsPageKeys { settings, storage }

enum PlayMode { single, singleLoop, sequence, loop, shuffle }

class SortState {
  String? field;
  String? direction;

  SortState({this.field, this.direction});

  Map<String, dynamic> toJson() => {'field': field, 'direction': direction};

  factory SortState.fromJson(Map<String, dynamic> json) {
    return SortState(
      field: json['field'] as String?,
      direction: json['direction'] as String?,
    );
  }
}
