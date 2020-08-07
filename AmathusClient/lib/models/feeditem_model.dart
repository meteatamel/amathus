class FeedItem {
  final String title;
  final DateTime publishDate;
  final String summary;
  final String detail;
  final String imageUrl;
  final String url;

  FeedItem(this.title, this.publishDate, this.summary, this.detail,
      this.imageUrl, this.url);

  factory FeedItem.fromJson(Map<String, dynamic> json) {
    return FeedItem(
        json['Title'] as String,
        DateTime.parse(json['PublishDate']),
        json['Summary'] as String,
        json['Detail'] as String,
        json['ImageUrl'] as String,
        json['Url'] as String);
  }
}