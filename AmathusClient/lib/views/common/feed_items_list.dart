import 'package:amathus/models/feeditem.dart';
import 'package:amathus/views/common/progress_indicator.dart';
import 'package:amathus/views/feeditem_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

typedef StringValue = String Function(String);
typedef LoadDataCallback = Future<List<FeedItem>> Function();

class FeedItemsList extends StatefulWidget {
  final LoadDataCallback loadDataCallback;

  FeedItemsList({Key key, @required this.loadDataCallback}) : super(key: key);

  @override
  _FeedItemsListState createState() => _FeedItemsListState();
}

class _FeedItemsListState extends State<FeedItemsList> {
  List<FeedItem> _items;

  @override
  void initState() {
    super.initState();
    _loadDataAndUpdateState().whenComplete(() => {});
  }

  Future<void> _loadDataAndUpdateState() async {
    var items = await widget.loadDataCallback();
    setState(() {
      _items = items;
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      child: _items == null
          ? CenteredProgressIndicator()
          : ListView.separated(
              itemCount: _items.length,
              padding: const EdgeInsets.only(top: kToolbarHeight + 75),
              separatorBuilder: (BuildContext context, int index) =>
                  const Divider(),
              itemBuilder: (context, index) {
                final item = _items[index];
                return ListTile(
                    //contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    title: Text(item.title),
                    subtitle:
                        Text(timeago.format(item.publishDate, locale: 'tr')),
                    leading: SizedBox(
                        width: 100.0,
                        child: item.imageUrl != null
                            ? CachedNetworkImage(
                                imageUrl: item.imageUrl,
                                placeholder: (context, url) =>
                                    new LinearProgressIndicator(),
                                errorWidget: (context, url, error) =>
                                    Image.asset("assets/newsicon-128px.png"))
                            : Image.asset("assets/newsicon-128px.png")),
                    trailing: Icon(Icons.keyboard_arrow_right),
                    onTap: () => {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      FeedItemView(item: item)))
                        });
              }),
      onRefresh: () async {
        await _loadDataAndUpdateState();
      },
    );
  }
}
