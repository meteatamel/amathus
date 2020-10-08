import 'feeditem_model.dart';

class Feed {
  final String id;
  final String title;
  final DateTime lastUpdatedTime;
  final String imageUrl;
  final String url;
  final List<FeedItem> items;

  Feed(this.id, this.title, this.lastUpdatedTime, this.imageUrl, this.url,
      this.items);

  factory Feed.fromJson(Map<String, dynamic> json) {
    return Feed(
      json['Id'] as String,
      json['Title'] as String,
      DateTime.parse(json['LastUpdatedTime']),
      json['ImageUrl'] as String,
      json['Url'] as String,
      json['Items'] == null? null : (json['Items'] as List)
          .map((itemJson) => FeedItem.fromJson(itemJson))
          .toList(),
    );
  }
}