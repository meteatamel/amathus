import 'package:flutter/material.dart';
import 'package:share/share.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:amathus/utils/constants.dart' as Constants;

launchURL(String url) async {
  if (await canLaunch(url)) {
    await launch(url, forceWebView: true, enableJavaScript: true);
  } else {
    throw 'Could not launch $url';
  }
}

socialShare(BuildContext context, title, String url) {
  final RenderBox box = context.findRenderObject();
  Share.share('${Constants.APP_NAME}: $title - $url',
      subject: '${Constants.APP_NAME}: $title',
      sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size);
}