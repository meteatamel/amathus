import 'package:amathus/models/feed.dart';
import 'package:json_annotation/json_annotation.dart';

// Run the following to generate it:
// flutter packages pub run build_runner build
part 'feeditem.g.dart';

@JsonSerializable()
class FeedItem {

  @JsonKey(name: 'Title')
  final String title;

  @JsonKey(name: 'PublishDate')
  final DateTime publishDate;

  @JsonKey(name: 'Summary')
  final String summary;

  @JsonKey(name: 'Detail')
  final String detail;

  @JsonKey(name: 'ImageUrl')
  final String imageUrl;

  @JsonKey(name: 'Url')
  final String url;

  @JsonKey(ignore: true)
  Feed feed;

  FeedItem(this.title, this.publishDate, this.summary, this.detail,
      this.imageUrl, this.url);

  factory FeedItem.fromJson(Map<String, dynamic> json) => _$FeedItemFromJson(json);

  Map<String, dynamic> toJson() => _$FeedItemToJson(this);
}