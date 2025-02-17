import 'package:flutter/cupertino.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hello_flutter/util/ad_helper.dart';

class AdWidgetContainer extends StatefulWidget {
  final double adHeight;
  AdWidgetContainer({super.key, required this.adHeight});

  @override
  _AdWidgetContainerState createState() => _AdWidgetContainerState(adHeight: adHeight);
}

class _AdWidgetContainerState extends State<AdWidgetContainer> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  final double adHeight;

  _AdWidgetContainerState({required this.adHeight});

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          print("Ad load failed: $error");
          ad.dispose();
        },
      ),
    );

    _bannerAd!.load();
  }

  @override
  Widget build(BuildContext context) {
    return _isAdLoaded
        ? Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: adHeight==-1 ? _bannerAd!.size.height.toDouble() : adHeight,
      child: AdWidget(ad: _bannerAd!),
    )
        : SizedBox.shrink();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }
}