class SongListItem {
  int id;
  String title;
  String? artist;
  String? album;
  String? genre;
  String? albumArtThumbPath;
  int? duration;
  int? sampleRate;
  int? bitrate;
  bool isFavorite;

  SongListItem({
    required this.id,
    required this.title,
    this.artist,
    this.album,
    this.genre,
    this.albumArtThumbPath,
    this.duration,
    this.sampleRate,
    this.bitrate,
    required this.isFavorite,
  });
}