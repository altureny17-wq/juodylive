import 'package:juodylive/app/config.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:easy_localization/easy_localization.dart';

import 'constants.dart';

class Setup {
  static final bool isDebug = kDebugMode;

  static String appName = Config.appName;
  static String appPackageName = Constants.appPackageName();
  static String appVersion = Config.appVersion;
  static String bio = "welcome_bio".tr(namedArgs: {"app_name": appName});
  static final List<String> allowedCountries =
      []; //['FR', 'CA', 'US', 'AO', 'BR'];
  static final int verificationCodeDigits = 6;

  // Social login= Config.appName
  static final bool isPhoneLoginEnabled = true;
  static final bool isFacebookLoginEnabled = true;
  static final bool isGoogleLoginEnabled = true;
  static final bool isAppleLoginEnabled = true;

  // App config
  static final bool isCallsEnabled = true;
  static final String streamingProviderType = 'zego'; // webrtc
  static final String streamingProviderKey = '';


  //Zego Cloud Credentials
  static final int zegoLiveStreamAppID = 1621841553;
  static final String zegoLiveStreamAppSign = "e08f51993cdbd3ace808f3846c69ce38951d6ff1d74e56fd741f41c474ffed17";
  static final String zegoLiveStreamServerSecret = "374792fb6eecd5165185590ce76127af";
  static final String zegoPushResourceID = "";


  static const String licenseToken = "";


  static const channelName = 'startActivity/VideoEditorChannel';
  static const methodInitVideoEditor = 'InitBanubaVideoEditor';
  static const methodStartVideoEditor = 'StartBanubaVideoEditor';
  static const methodStartVideoEditorPIP = 'StartBanubaVideoEditorPIP';
  static const methodStartVideoEditorTrimmer = 'StartBanubaVideoEditorTrimmer';
  static const methodDemoPlayExportedVideo = 'PlayExportedVideo';
  static const errEditorNotInitializedCode = 'ERR_VIDEO_EDITOR_NOT_INITIALIZED';
  static String errEditorNotInitializedMessage = "banuba_video_editor_sdk.sdk_not_initialized".tr();
  static const errEditorLicenseRevokedCode = 'ERR_VIDEO_EDITOR_LICENSE_REVOKED';
  static String errEditorLicenseRevokedMessage = "banuba_video_editor_sdk.license_revoked_or_expired".tr();

  static const argExportedVideoFile = 'exportedVideoFilePath';
  static const argExportedVideoCoverPreviewPath = 'exportedVideoCoverPreviewPath';

  static final bool isWithdrawIbanEnabled = true;
  static final bool isWithdrawPayoneerEnabled = true;
  static final bool isWithdrawPaypalEnabled = true;
  static final bool isWithdrawUSDTlEnabled = true;

  // Additional Payments method, Google Play and Apple Pay are enabled by default
  static final bool isStripePaymentsEnabled = true;
  static final bool isPayPalPaymentsEnabled = true;

  // User fields
  static final int welcomeCredit = 0;
  static final int minimumAgeToRegister = 16;
  static final int maximumAgeToRegister = 16;
  static final int? maxDistanceBetweenUsers = 80;

  // Live Streaming and Calls
  static final int minimumDiamondsToPopular = 100;
  static final int callWaitingDuration = 30; // seconds

  //Withdraw calculations
  static final int diamondsEarnPercent = 60; //Percent to give the streamer.
  static final int withDrawPercent = 50; //Percent to give the streamer.
  static final int agencyPercent = 10; //Percent to give the agency.
  static final int diamondsNeededToRedeem = 100000; // Minimum diamonds needed to redeem

  // Calls cost
  static final int coinsNeededForVideoCallPerMinute =
      120; //Coins per minute needed to make video call
  static final int coinsNeededForVoiceCallPerMinute =
      60; //Coins per minute needed to make Voice call

  //Leaders
  static final int diamondsNeededForLeaders = 10;

  //Lives
  static final double maxDistanceToNearBy = 500; //In Km
  static final int maxSecondsToShowBigGift = 5; //In seconds

  // Feed
  static final int coinsNeededToForExclusivePost = 50;

  // Ads Config
  static final bool isBannerAdsOnHomeReelsEnabled = true;
  static final bool isAdsOnMessageListEnabled = true;
  static final bool isAdsOnFeedEnabled = true;
  static final bool isOpenAppAdsEnabled = false;

  //Languages Setup
  static List<String> languages = ["en", "fr", "pt", "ar"];

  //Wealth level required for male before go live
  static int wealthRequiredLevel = 10;

  //Social media links
  static const String facebookPage =
      "https://www.facebook.com/share/1GuxWxGPkv/";
  static const String facebookProfile =
      "https://www.facebook.com/share/1GuxWxGPkv/";
  static const String youtube =
      "https://www.youtube.com/channel/UCtsFF65NSAGiq-5Ese1Jg_w";
  static const String instagram = "https://www.instagram.com/chancilson/";
  static const String gmail = "juodylive@gmail.com";

  //Admob
  static const String admobAndroidWalletReward =
      "ca-app-pub-5660393455301038/8917798346";
  static const int earnCredit = 25;

  //Max video size allowed
  static const maxVideoSize = 10; //MegaBytes

  // Level Points Map for levels 1 to 200
  static final Map<int, int> levelPoints = {
    1: 11795,
    2: 31905,
    3: 69085,
    4: 129345,
    5: 209035,
    6: 309030,
    7: 400915,
    8: 500915,
    9: 610925,
    10: 709251,
    11: 839295,
    12: 909125,
    13: 1091523,
    14: 1192053,
    15: 1293054,
    16: 1934052,
    17: 1490059,
    18: 1598588,
    19: 1693533,
    20: 1971523,
    21: 1890500,
    22: 1992523,
    23: 2093545,
    24: 2193500,
    25: 2298593,
    26: 2395930,
    27: 3395930,
    28: 4396040,
    29: 5396550,
    30: 6397060,
    31: 7397570,
    32: 8398080,
    33: 93958590,
    34: 1039590100,
    35: 2139595110,
    36: 32395100120,
    37: 33395100120,
    38: 34395100120,
    39: 35395100120,
    40: 36395100120,
    41: 37395100120,
    42: 38395100120,
    43: 39395100120,
    44: 40395100120,
    45: 41395100120,
    46: 42395100120,
    47: 43395100120,
    48: 44395100120,
    49: 45395100120,
    50: 46395100120,
    51: 47395100120,
    52: 48395100120,
    53: 49395100120,
    54: 50395100120,
    55: 51395100120,
    56: 52395100120,
    57: 53395100120,
    58: 54395100120,
    59: 55395100120,
    60: 56395100120,
    61: 57395100120,
    62: 58395100120,
    63: 59395100120,
    64: 60395100120,
    65: 61395100120,
    66: 62395100120,
    67: 63395100120,
    68: 64395100120,
    69: 65395100120,
    70: 66395100120,
    71: 67395100120,
    72: 68395100120,
    73: 69395100120,
    74: 70395100120,
    75: 71395100120,
    76: 72395100120,
    77: 73395100120,
    78: 74395100120,
    79: 75395100120,
    80: 76395100120,
    81: 77395100120,
    82: 78395100120,
    83: 79395100120,
    84: 80395100120,
    85: 81395100120,
    86: 82395100120,
    87: 83395100120,
    88: 84395100120,
    89: 85395100120,
    90: 86395100120,
    91: 87395100120,
    92: 88395100120,
    93: 89395100120,
    94: 90395100120,
    95: 91395100120,
    96: 92395100120,
    97: 93395100120,
    98: 94395100120,
    99: 95395100120,
    100: 96395100120,
    101: 97395100120,
    102: 98395100120,
    103: 99395100120,
    104: 100395100120,
    105: 101395100120,
    106: 102395100120,
    107: 103395100120,
    108: 104395100120,
    109: 105395100120,
    110: 106395100120,
    111: 107395100120,
    112: 108395100120,
    113: 109395100120,
    114: 110395100120,
    115: 111395100120,
    116: 112395100120,
    117: 113395100120,
    118: 114395100120,
    119: 115395100120,
    120: 116395100120,
    121: 117395100120,
    122: 118395100120,
    123: 119395100120,
    124: 120395100120,
    125: 121395100120,
    126: 122395100120,
    127: 123395100120,
    128: 124395100120,
    129: 125395100120,
    130: 126395100120,
    131: 127395100120,
    132: 128395100120,
    133: 129395100120,
    134: 130395100120,
    135: 131395100120,
    136: 132395100120,
    137: 133395100120,
    138: 134395100120,
    139: 135395100120,
    140: 136395100120,
    141: 137395100120,
    142: 138395100120,
    143: 139395100120,
    144: 140395100120,
    145: 141395100120,
    146: 142395100120,
    147: 143395100120,
    148: 144395100120,
    149: 145395100120,
    150: 146395100120,
    151: 147395100120,
    152: 148395100120,
    153: 149395100120,
    154: 150395100120,
    155: 151395100120,
    156: 152395100120,
    157: 153395100120,
    158: 154395100120,
    159: 155395100120,
    160: 156395100120,
    161: 157395100120,
    162: 158395100120,
    163: 159395100120,
    164: 160395100120,
    165: 161395100120,
    166: 162395100120,
    167: 163395100120,
    168: 164395100120,
    169: 165395100120,
    170: 166395100120,
    171: 167395100120,
    172: 168395100120,
    173: 169395100120,
    174: 170395100120,
    175: 171395100120,
    176: 172395100120,
    177: 173395100120,
    178: 174395100120,
    179: 175395100120,
    180: 176395100120,
    181: 177395100120,
    182: 178395100120,
    183: 179395100120,
    184: 180395100120,
    185: 181395100120,
    186: 182395100120,
    187: 183395100120,
    188: 184395100120,
    189: 185395100120,
    190: 186395100120,
    191: 187395100120,
    192: 188395100120,
    193: 189395100120,
    194: 190395100120,
    195: 191395100120,
    196: 192395100120,
    197: 193395100120,
    198: 194395100120,
    199: 195395100120,
    200: 196395100120,
  };

  static int getLevelMaxPoints(int level) {
    return levelPoints[level] ?? levelPoints[200]!;
  }
}
