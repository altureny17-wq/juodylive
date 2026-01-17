import 'dart:ui';


class Config {
  
  static const String packageNameAndroid = "com.juodylive.app";
  static const String packageNameiOS = "com.juodylive.app";
  static const String iosAppStoreId = "1048";
  static final String appName = "juodylive";
  static final String appVersion = "1.0.0";
  static final String companyName = "juodylive, inc";
  static final String appOrCompanyUrl = "https://juodylive.com";
  static final String initialCountry = 'AO'; // United States

  static final String serverUrl = "https://parseapi.back4app.com";
  static final String liveQueryUrl = "wss://juodylive.b4a.io";
  static final String appId = "HcSOWjniJeuMeleN3KSjo9SlOcUiE3kGul0ST4Ky";
  static final String clientKey = "vofuFokus7ck7MQbi8cyeKopMQVrYspCeGW43Lli";

  //OneSignal
  static final String oneSignalAppId = "d5afccd9-e25e-4816-b0db-3e3e852979fc";

  // Firebase Cloud Messaging
  static final String pushGcm = "";
  static final String webPushCertificate = "";

  // User support objectId
  static final String supportId = "";

  // Play Store and App Store public keys
  static final String publicGoogleSdkKey = "";
  static final String publicIosSdkKey = "";

  // Languages
  static String defaultLanguage = "en"; // English is default language.
  static List<Locale> languages = [
    Locale(defaultLanguage),
    //Locale('pt'),
    //Locale('fr')
  ];

  // Android Admob ad
  static const String admobAndroidOpenAppAd = "ca-app-pub-5660393455301038/4652262037";
  static const String admobAndroidHomeBannerAd = "ca-app-pub-5660393455301038/9357793808";
  static const String admobAndroidFeedNativeAd = "ca-app-pub-5660393455301038/8917798346";
  static const String admobAndroidChatListBannerAd = "ca-app-pub-5660393455301038/1535144108";
  static const String admobAndroidLiveBannerAd = "ca-app-pub-5660393455301038/5226977103";
  static const String admobAndroidFeedBannerAd = "ca-app-pub-5660393455301038/6899151425";

  // iOS Admob ad
  static const String admobIOSOpenAppAd = "ca-app-pub-5660393455301038/7660556994";
  static const String admobIOSHomeBannerAd = "ca-app-pub-5660393455301038/6239664113";
  static const String admobIOSFeedNativeAd = "ca-app-pub-5660393455301038/3143739248";
  static const String admobIOSChatListBannerAd = "ca-app-pub-5660393455301038/8016791972";
  static const String admobIOSLiveBannerAd = "ca-app-pub-5660393455301038/7552745783";
  static const String admobIOSFeedBannerAd = "ca-app-pub-5660393455301038/7118643272";

  // Web links for help, privacy policy and terms of use.
  static final String helpCenterUrl = "https://trace-34749.web.app/terms/";
  static final String privacyPolicyUrl = "https://trace-34749.web.app/pivacy/";
  static final String termsOfUseUrl = "https://trace-34749.web.app/terms/";
  static final String termsOfUseInAppUrl = "https://trace-34749.web.app/terms/";
  static final String dataSafetyUrl = "https://ladylivea.net/help.hmtl";
  static final String openSourceUrl = "https://www.ladylivea.net/third-party-license.html";
  static final String instructionsUrl = "https://ladylivea.net/instructions.hmtl";
  static final String cashOutUrl = "https://ladylivea.net/cashout.hmtl";
  static final String supportUrl = "https://www.ladylivea.net/support";
  static final String liveAgreementUrl = "https://trace-34749.web.app/live/";
  static final String userAgreementUrl = "https://trace-34749.web.app/user/";

  // Google Play and Apple Pay In-app Purchases IDs
  static final String credit100 = "trace.100.credits";
  static final String credit200 = "trace.200.credits";
  static final String credit500 = "trace.500.credits";
  static final String credit1000 = "trace.1000.credits";
  static final String credit2100 = "trace.2100.credits";
  static final String credit5250 = "trace.5250.credits";
  static final String credit10500 = "trace.10500.credits";
}
