import 'package:amathus/models/feeditem.dart';
import 'package:amathus/views/common/feed_image.dart';
import 'package:amathus/views/common/share_iconbutton.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:amathus/utils/constants.dart' as Constants;
import 'package:url_launcher/url_launcher.dart';

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
      ),
      body: buildColumn(context),
    );
  }

  Widget buildColumn(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
            child: Text(item.summary, style: TextStyle(fontSize: 18.0))),
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
