import 'package:amathus/controllers/feeds_controller.dart';
import 'package:amathus/models/feed.dart';
import 'package:amathus/views/common/drawer.dart';
import 'package:amathus/views/feed_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:amathus/utils/constants.dart' as Constants;

class FeedsView extends StatefulWidget {
  static const String routeName = '/feeds';

  @override
  _FeedsViewState createState() => _FeedsViewState();
}

class _FeedsViewState extends State<FeedsView> {
  List<Feed> _feeds;
  FeedsController _controller;

  _FeedsViewState() {
    _controller = FeedsController();
  }

  @override
  void initState() {
    super.initState();
    loadData().whenComplete(() => {});
  }

  Future<void> loadData({storage = true}) async {
    if (storage) {
      print("Loading from storage");
      var feeds = await _controller.readFromStorage();
      if (feeds != null) {
        print("Loaded from storage");
        setState(() {
          _feeds = feeds;
        });
      }
    }

    print("Loading from server");
    var receivedFeeds = await _controller.readFromServer();
    if (receivedFeeds != null) {
      print("Loaded from server");
      var orderedFeeds = await _controller.orderAndStoreFeeds(receivedFeeds);
      setState(() {
        _feeds = orderedFeeds;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(centerTitle: true, title: new Text(Constants.ALL_NEWS)),
        drawer: AppDrawer(),
        body: _feeds == null
            ? Center(
                child: SizedBox(
                    height: 200.0,
                    width: 200.0,
                    child: CircularProgressIndicator()))
            : RefreshIndicator(
                child: ListView.separated(
                  itemCount: _feeds.length,
                  //padding: const EdgeInsets.all(16),
                  separatorBuilder: (BuildContext context, int index) =>
                      const Divider(),
                  itemBuilder: (context, index) {
                    final item = _feeds[index];
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
                ),
                onRefresh: () async {
                  await loadData(storage: false);
                },
              ));
  }
}
