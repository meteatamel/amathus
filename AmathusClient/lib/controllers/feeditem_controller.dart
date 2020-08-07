import 'package:flutter/material.dart';
import 'package:share/share.dart';
import 'package:url_launcher/url_launcher.dart';

launchURL(String url) async {
  if (await canLaunch(url)) {
    await launch(url, forceWebView: true);
  } else {
    throw 'Could not launch $url';
  }
}

socialShare(BuildContext context, title, String url) {
  final RenderBox box = context.findRenderObject();
  Share.share('Kuzey Kıbrıs Haber: $title - $url',
      subject: 'Kuzey Kıbrıs Haber: $title',
      sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size);
}