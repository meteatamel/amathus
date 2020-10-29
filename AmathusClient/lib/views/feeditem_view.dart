import 'package:amathus/models/feeditem.dart';
import 'package:amathus/views/common/feed_image.dart';
import 'package:amathus/views/common/share_iconbutton.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:amathus/utils/constants.dart' as Constants;
import 'package:flutter_html/style.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:amathus/extensions.dart';

class FeedItemView extends StatelessWidget {
  final FeedItem item;

  FeedItemView({Key key, @required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FeedImage(item: item.feed),
        centerTitle: true,
        actions: [ShareIconButton(item: item)],
      ).withBottomAdmobBanner(context),
      body: buildColumn(context),
    );
  }

  Widget buildColumn(BuildContext context) => ListView(
          children: [
        new Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 0, 0),
            child:
                Text(item.title, style: Theme.of(context).textTheme.headline5)),
        new Container(
            padding: const EdgeInsets.all(12.0),
            child: item.imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: item.imageUrl,
                    placeholder: (context, url) =>
                        new LinearProgressIndicator())
                : null),
        new Container(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
            child: Text(item.summary, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
        item.detail != null
            ? new Container(
                child: Html(data: item.detail, style: {
                "body": Style(
                  fontSize: FontSize(16.0),
                ),
              }))
            : new Container(),
        _moreButton()
      ]);

  Widget _moreButton() {
    return Align(
        alignment: Alignment.bottomRight,
        child: TextButton(
            onPressed: () async => await _launchURL(item.url),
            child: Column(
              children: <Widget>[Icon(Icons.open_in_new), Text(Constants.MORE)],
            )));
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url, forceWebView: true, enableJavaScript: true);
    } else {
      throw 'Could not launch $url';
    }
  }
}
