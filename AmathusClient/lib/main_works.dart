import 'package:flutter/material.dart';

// TODO
// 1. Create Feed and FeedItem POJOs
// 2. Create FeedsScreen
// 3. Create FeedItemScreen
// 4. Find a way to have lists inside lists for FeedsScreen

void main() {
  runApp(
//      MaterialApp(
//        initialRoute: '/',
//        routes: {
//          '/': (context) => FeedsPage(),
//          '/second': (context) => FeedItemPage(),
//        },
//      )
      MaterialApp(
          title: "Test",
          home: FeedsPage()
      )
  );
}

class FeedsPage extends StatelessWidget {
  final List<ListItem> items = List<ListItem>.generate(
      100,
          (i) => i % 4 == 0
          ? i % 8 == 0
          ? Feed("Feed $i", null)
          : Feed("Feed $i", "http://s.yeniduzen.com/i/logo.png")
          : i % 6 == 0
          ? FeedItem("Title $i", null, "Published $i")
          : FeedItem("Title $i", "https://www.halkinsesikibris.com/images/haberler/thumbs2/2020/08/turkiye_nin_buyuleyen_guzelligi_kus_cennetleri_h140898_15e2f.jpg", "Published $i")
  );

  //FeedsPage({Key key, @required this.items}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
          title: new Text("Tum Haberlerr")
      ),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];

          return ListTile(
            title: item.buildTitle(context),
            subtitle: item.buildSubtitle(context),
            leading: item.buildLeading(context),
            trailing: item.buildTrailing(context),
            onTap: () => item.onTap(context),
          );
        },
      ),
    );
  }
}

class FeedItemPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text("Second Route"),
      ),
      body: Center(
        child: RaisedButton(
          onPressed: () {
            // Navigate back to first route when tapped.

          },
          child: Text('Go back!'),
        ),
      ),
    );
  }
}

abstract class ListItem {
  Widget buildTitle(BuildContext context) => null;

  Widget buildSubtitle(BuildContext context) => null;

  Widget buildLeading(BuildContext context) => null;

  buildTrailing(BuildContext context) => null;

  onTap(BuildContext context);
}

class Feed extends ListItem {
  final String title;
  final String imageUrl;

  Feed(this.title, this.imageUrl);

  Widget buildLeading(BuildContext context) {
    return imageUrl != null ? Image.network(imageUrl) : null;
  }

  Widget buildTitle(BuildContext context) {
    return imageUrl == null
        ? Text(
      title,
      style: Theme.of(context).textTheme.headline4,
    )
        : null;
  }

  Widget buildTrailing(BuildContext context) {
    return Icon(Icons.keyboard_arrow_right);
  }

  @override
  onTap(BuildContext context) {
    Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => FeedItemPage()));
//    Navigator.pushNamed(context, '/second');
  }
}

class FeedItem extends ListItem {
  final String title;
  final String imageUrl;
  final String publishDate;

  FeedItem(this.title, this.imageUrl, this.publishDate);

  Widget buildTitle(BuildContext context) {
    return Text(
      title,
    );
  }

  Widget buildSubtitle(BuildContext context) {
    // TODO: See if I can use 2 days ago like style
    return Text(
      publishDate,
    );
  }

  Widget buildLeading(BuildContext context) {
    // Wrapping into a SizedBoxed so the placeholder image is aligned properly
    return SizedBox(
        width: 100.0,
        child: imageUrl != null
            ? Image.network(imageUrl)
            : Image.asset("assets/newsicon-128px.png"));
  }

  Widget buildTrailing(BuildContext context) {
    return Icon(Icons.keyboard_arrow_right);
  }

  @override
  onTap(BuildContext context) {
//    Navigator.push(
//      context,
//      MaterialPageRoute(builder: (context) => FeedItemPage()),
//    );
  }
}
