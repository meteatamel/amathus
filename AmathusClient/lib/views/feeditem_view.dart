import 'package:amathus/controllers/feeditem_controller.dart';
import 'package:amathus/models/feeditem.dart';
import 'package:flutter/material.dart';

class FeedItemView extends StatelessWidget {
  final FeedItem item;

  FeedItemView({Key key, @required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        //title: Text(""),
      ),
      body: buildColumn(context),
    );
  }

  Widget buildColumn(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start,
          //mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            new Container(
                padding: const EdgeInsets.all(12.0),
                child: Text(item.title,
                    style: Theme.of(context).textTheme.headline5)),
            new Container(
                padding: const EdgeInsets.all(8.0),
                child: item.imageUrl != null
                    ? Image.network(item.imageUrl)
                    : null),
            new Container(
                padding: const EdgeInsets.all(8.0),
                child: Text(item.summary, style: TextStyle(fontSize: 16.0))),
            new Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  new Container(
                      padding: const EdgeInsets.all(10.0),
                      child: RaisedButton(
                        child: Row(children: [
                          Text("Daha fazla"),
                          Icon(Icons.more_vert)
                        ]),
                        onPressed: () => launchURL(item.url),
                      )),
                  new Container(
                    padding: const EdgeInsets.all(10.0),
                    child: RaisedButton(
                      child: Row(children: [Text("Paylaş"), Icon(Icons.share)]),
                      onPressed: () =>
                          socialShare(context, item.title, item.url),
                    ),
                  )
                ])
          ]);

}