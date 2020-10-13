import 'package:amathus/controllers/feeds_controller.dart';
import 'package:amathus/models/feed_model.dart';
import 'package:amathus/views/feed_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class FeedsView extends StatefulWidget {
  @override
  _FeedsViewState createState() => _FeedsViewState();
}

class _FeedsViewState extends State<FeedsView> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(centerTitle: true, title: new Text("Tüm Haberler")),
        body: FutureBuilder<List<Feed>>(
            future: fetchFeeds(),
            builder: (context, snapshot) {

              if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                var feeds = snapshot.data;
                return RefreshIndicator(
                  child: ListView.separated(
                    itemCount: feeds.length,
                    //padding: const EdgeInsets.all(16),
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
                  onRefresh: onRefreshCallback,
                );
              }

              //if (snapshot.hasError) {
                // TODO: Handle
              //}

              return Center(
                  child: SizedBox(
                      height: 200.0,
                      width: 200.0,
                      child: CircularProgressIndicator()));
            }));
  }

  Future<void> onRefreshCallback() async {
    setState(() {});
  }

}
