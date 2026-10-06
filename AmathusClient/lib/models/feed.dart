import 'package:json_annotation/json_annotation.dart';
import 'feeditem.dart';

part 'feed.g.dart';

@JsonSerializable()
class Feed {
  @JsonKey(name: 'Id')
  final String id;

  @JsonKey(name: 'Title')
  final String title;

  @JsonKey(name: 'Language')
  final String? language;

  @JsonKey(name: 'LastUpdatedTime')
  final DateTime lastUpdatedTime;

  @JsonKey(name: 'ImageUrl')
  final String? imageUrl;

  @JsonKey(name: 'Url')
  final String? url;

  @JsonKey(name: 'Items')
  final List<FeedItem>? items;

  Feed(
    this.id,
    this.title,
    this.lastUpdatedTime,
    this.imageUrl,
    this.url,
    this.items, [
    this.language,
  ]);

  factory Feed.fromJson(Map<String, dynamic> json) {
    final feed = _$FeedFromJson(json);
    if (feed.items != null) {
      for (final element in feed.items!) {
        element.feed = feed;
      }
    }
    return feed;
  }

  Map<String, dynamic> toJson() => _$FeedToJson(this);
}