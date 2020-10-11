import 'package:amathus/controllers/feeds_controller.dart';
import 'package:amathus/models/feed_model.dart';
import 'package:amathus/views/feed_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_admob/firebase_admob.dart';
import 'package:flutter/material.dart';

import '../ad_manager.dart';

class FeedsView extends StatefulWidget {
  @override
  _FeedsViewState createState() => _FeedsViewState();
}

class _FeedsViewState extends State<FeedsView> {
  Future<List<Feed>> futureFeeds;
  BannerAd _bannerAd;

  @override
  void initState() {
    FirebaseAdMob.instance.initialize(appId: AdManager.appId);
    _bannerAd = BannerAd(
      adUnitId: AdManager.bannerAdUnitId,
      size: AdSize.banner,
    );
    _loadBannerAd();

    super.initState();
    futureFeeds = fetchFeeds();
  }

  void _loadBannerAd() {
    _bannerAd
      ..load()
      ..show(anchorOffset: 100,anchorType: AnchorType.top);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(centerTitle: true, title: new Text("Tüm Haberler")),
        body: FutureBuilder<List<Feed>>(
            future: futureFeeds,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                var feeds = snapshot.data;
                return ListView.separated(
                  itemCount: feeds.length,
                  padding: const EdgeInsets.only(top: kToolbarHeight + 75),
                  separatorBuilder: (BuildContext context, int index) =>
                  const Divider(),
                  itemBuilder: (context, index) {
                    final item = feeds[index];
                    return ListTile(
                      //contentPadding: EdgeInsets.symmetric(horizontal: 0.0),
                        title: Container(
                          //color: Colors.grey[150],
                            child: item.imageUrl != null
                                ? SizedBox(
                                width: 200,
                                height: 50,
                                child: CachedNetworkImage(
                                  imageUrl: item.imageUrl,
                                  placeholder: (context, url) =>
                                  new LinearProgressIndicator(),
                                  errorWidget: (context, url, error) =>
                                      Text(item.title,
                                          style: Theme.of(context)
                                              .textTheme
                                              .headline4),
                                ))
                            //Image.network(item.imageUrl)
                                : Text(item.title,
                                style:
                                Theme.of(context).textTheme.headline4)),
                        trailing: Icon(Icons.keyboard_arrow_right),
                        onTap: () => {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      FeedView(feed: item)))
                        });
                  },
                );
              } else {
                // TODO
              }
              return CircularProgressIndicator();
            }));
  }
}
