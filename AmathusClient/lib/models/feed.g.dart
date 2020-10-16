// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Feed _$FeedFromJson(Map<String, dynamic> json) {
  return Feed(
    json['Id'] as String,
    json['Title'] as String,
    json['LastUpdatedTime'] == null
        ? null
        : DateTime.parse(json['LastUpdatedTime'] as String),
    json['ImageUrl'] as String,
    json['Url'] as String,
    (json['Items'] as List)
        ?.map((e) =>
            e == null ? null : FeedItem.fromJson(e as Map<String, dynamic>))
        ?.toList(),
  );
}

Map<String, dynamic> _$FeedToJson(Feed instance) => <String, dynamic>{
      'Id': instance.id,
      'Title': instance.title,
      'LastUpdatedTime': instance.lastUpdatedTime?.toIso8601String(),
      'ImageUrl': instance.imageUrl,
      'Url': instance.url,
      'Items': instance.items,
    };
