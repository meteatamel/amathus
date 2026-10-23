// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feeditem.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FeedItem _$FeedItemFromJson(Map<String, dynamic> json) => FeedItem(
      (json['Title'] as String?) ?? '',
      json['PublishDate'] == null
          ? DateTime.now()
          : DateTime.parse(json['PublishDate'] as String),
      json['Summary'] as String?,
      json['Detail'] as String?,
      json['ImageUrl'] as String?,
      json['Url'] as String?,
      author: json['Author'] as String?,
      isColumnist: (json['IsColumnist'] as bool?) ?? false,
    );

Map<String, dynamic> _$FeedItemToJson(FeedItem instance) => <String, dynamic>{
      'Title': instance.title,
      'PublishDate': instance.publishDate.toIso8601String(),
      'Summary': instance.summary,
      'Detail': instance.detail,
      'ImageUrl': instance.imageUrl,
      'Url': instance.url,
      'Author': instance.author,
      'IsColumnist': instance.isColumnist,
    };
