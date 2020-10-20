import 'package:json_annotation/json_annotation.dart';
import 'feeditem.dart';

// Run the following to generate it:
// flutter packages pub run build_runner build
part 'feed.g.dart';

@JsonSerializable()
class Feed {

  @JsonKey(name: 'Id')
  final String id;

  @JsonKey(name: 'Title')
  final String title;

  @JsonKey(name: 'LastUpdatedTime')
  final DateTime lastUpdatedTime;

  @JsonKey(name: 'ImageUrl')
  final String imageUrl;

  @JsonKey(name: 'Url')
  final String url;

  @JsonKey(name: 'Items')
  final List<FeedItem> items;

  Feed(this.id, this.title, this.lastUpdatedTime, this.imageUrl, this.url,
      this.items);

  factory Feed.fromJson(Map<String, dynamic> json) {
    var feed = _$FeedFromJson(json);
    if (feed.items != null) {
      feed.items.forEach((element) {
        element.feed = feed;
      });
    }
    return feed;
  }

  Map<String, dynamic> toJson() => _$FeedToJson(this);
}