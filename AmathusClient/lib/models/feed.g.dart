// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Feed _$FeedFromJson(Map<String, dynamic> json) => Feed(
      (json['Id'] as String?) ?? '',
      (json['Title'] as String?) ?? '',
      json['LastUpdatedTime'] == null
          ? DateTime.now()
          : DateTime.parse(json['LastUpdatedTime'] as String),
      json['ImageUrl'] as String?,
      json['Url'] as String?,
      (json['Items'] as List<dynamic>?)
          ?.map((e) => FeedItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      json['Language'] as String?,
    );

Map<String, dynamic> _$FeedToJson(Feed instance) => <String, dynamic>{
      'Id': instance.id,
      'Title': instance.title,
      'Language': instance.language,
      'LastUpdatedTime': instance.lastUpdatedTime.toIso8601String(),
      'ImageUrl': instance.imageUrl,
      'Url': instance.url,
      'Items': instance.items?.map((e) => e.toJson()).toList(),
    };
