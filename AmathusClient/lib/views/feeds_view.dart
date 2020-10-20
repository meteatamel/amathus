import 'package:amathus/ad_manager.dart';
import 'package:amathus/controllers/feeds_controller.dart';
import 'package:amathus/views/common/bottom_nav_bar.dart';
import 'package:amathus/views/common/drawer.dart';
import 'package:amathus/views/common/feeds_list.dart';
import 'package:firebase_admob/firebase_admob.dart';
import 'package:flutter/material.dart';
import 'package:amathus/utils/constants.dart' as Constants;

class FeedsView extends StatefulWidget {
  static const String routeName = '/feeds';

  @override
  _FeedsViewState createState() => _FeedsViewState();
}

class _FeedsViewState extends State<FeedsView> {
  FeedsController _controller;
  BannerAd _bannerAd;
  InterstitialAd _interstitialAd;
  bool _isInterstitialAdReady;
  DateTime interstitialLastShown;

  void _loadInterstitialAd() {
    _interstitialAd.load();
  }

  void _onInterstitialAdEvent(MobileAdEvent event) {
    switch (event) {
      case MobileAdEvent.loaded:
        _isInterstitialAdReady = true;
        break;
      case MobileAdEvent.failedToLoad:
        _isInterstitialAdReady = false;
        print('Failed to load an interstitial ad');
        break;
      case MobileAdEvent.closed:
        break;
      default:
      // do nothing
    }
  }

  _FeedsViewState() {
    _controller = FeedsController();
  }

  @override
  void initState() {
    FirebaseAdMob.instance.initialize(appId: AdManager.appId);
    _bannerAd = BannerAd(
      adUnitId: AdManager.bannerAdUnitId,
      size: AdSize.banner,
    );

    // TODO: Add or remove after ads are fixed
    //_loadBannerAd();

    _isInterstitialAdReady = false;
    _interstitialAd = InterstitialAd(
      adUnitId: AdManager.interstitialAdUnitId,
      listener: _onInterstitialAdEvent,
    );

    _loadInterstitialAd();

    super.initState();

    if (interstitialLastShown == null) {
      interstitialLastShown = DateTime.now();
    }

    if (DateTime.now().difference(interstitialLastShown).inHours > 1) {
      _interstitialAd.show();
    }
  }

  void _loadBannerAd() {
    _bannerAd
      ..load()
      ..show(anchorOffset: kToolbarHeight + 75, anchorType: AnchorType.top);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: new Text(Constants.ALL_NEWS)),
      drawer: AppDrawer(),
      body: FeedsList(
          loadDataStorageCallback: () => _controller.readAllStored(),
          loadDataServerCallback: () => _controller.readAll()),
      bottomNavigationBar: AppBottomNavigationBar(selectedIndex: 0)
    );
  }
}
