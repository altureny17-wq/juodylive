// ignore_for_file: unused_field

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:juodylive/helpers/quick_actions.dart';
import 'package:juodylive/helpers/quick_help.dart';
import 'package:juodylive/models/GiftsModel.dart';
import 'package:juodylive/models/UserModel.dart';
import 'package:juodylive/models/others/in_app_model.dart';
import 'package:juodylive/ui/container_with_corner.dart';
import 'package:juodylive/ui/text_with_tap.dart';
import 'package:juodylive/utils/colors.dart';

import '../../app/config.dart';

class CoinsFlowPayment {
  CoinsFlowPayment({
    required BuildContext context,
    required UserModel currentUser,
    Function(GiftsModel giftsModel)? onGiftSelected,
    Function(int coins)? onCoinsPurchased,
    bool isDismissible = true,
    bool enableDrag = true,
    bool isScrollControlled = false,
    bool showOnlyCoinsPurchase = false,
    Color backgroundColor = Colors.transparent,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: backgroundColor,
      enableDrag: enableDrag,
      isDismissible: isDismissible,
      builder: (context) {
        return _CoinsFlowWidget(
          currentUser: currentUser,
          onCoinsPurchased: onCoinsPurchased,
          onGiftSelected: onGiftSelected,
          showOnlyCoinsPurchase: showOnlyCoinsPurchase,
        );
      },
    );
  }

  static void show({
    required BuildContext context,
    required UserModel currentUser,
    Function(GiftsModel)? onGiftSelected,
    Function(int)? onCoinsPurchased,
    bool showOnlyCoinsPurchase = false,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      builder: (context) {
        return _CoinsFlowWidget(
          currentUser: currentUser,
          onCoinsPurchased: onCoinsPurchased,
          onGiftSelected: onGiftSelected,
          showOnlyCoinsPurchase: showOnlyCoinsPurchase,
        );
      },
    );
  }
}

// ignore: must_be_immutable
class _CoinsFlowWidget extends StatefulWidget {
  final Function? onCoinsPurchased;
  final Function? onGiftSelected;
  final bool? showOnlyCoinsPurchase;
  UserModel currentUser;

  _CoinsFlowWidget({
    required this.currentUser,
    this.onCoinsPurchased,
    this.onGiftSelected,
    this.showOnlyCoinsPurchase = false,
  });

  @override
  State<_CoinsFlowWidget> createState() => _CoinsFlowWidgetState();
}

class _CoinsFlowWidgetState extends State<_CoinsFlowWidget>
    with TickerProviderStateMixin {
  AnimationController? _animationController;
  int bottomSheetCurrentIndex = 0;

  late Offerings offerings;
  bool _isAvailable = false;
  bool _loading = true;
  InAppPurchaseModel? _inAppPurchaseModel;

  final List<Map<String, String>> giftCategories = [
    {'key': 'classic', 'name': 'كلاسيك', 'icon': '🎁'},
    {'key': 'vip', 'name': 'VIP', 'icon': '👑'},
    {'key': '_3d', 'name': 'ثلاثي الأبعاد', 'icon': '🎨'},
    {'key': 'love', 'name': 'رومانسي', 'icon': '❤️'},
    {'key': 'svga_gifts', 'name': 'متحركة', 'icon': '🎬'},
  ];

  List<InAppPurchaseModel> getInAppList() {
    List<Package> myProductList = offerings.current!.availablePackages;
    List<InAppPurchaseModel> inAppPurchaseList = [];

    for (Package package in myProductList) {
      if (package.storeProduct.identifier == Config.credit200) {
        InAppPurchaseModel credits200 = InAppPurchaseModel(
            id: Config.credit200,
            coins: 200,
            price: package.storeProduct.priceString,
            image: "assets/images/ic_coins_4.png",
            type: InAppPurchaseModel.typeNormal,
            storeProduct: package.storeProduct,
            package: package,
            currency: package.storeProduct.currencyCode,
            currencySymbol: package.storeProduct.currencyCode);

        if (!inAppPurchaseList.contains(Config.credit200)) {
          inAppPurchaseList.add(credits200);
        }
      }

      if (package.storeProduct.identifier == Config.credit1000) {
        InAppPurchaseModel credits1000 = InAppPurchaseModel(
            id: Config.credit1000,
            coins: 1000,
            price: package.storeProduct.priceString,
            image: "assets/images/ic_coins_1.png",
            discount: (package.storeProduct.price * 1.1).toStringAsFixed(2),
            type: InAppPurchaseModel.typeNormal,
            storeProduct: package.storeProduct,
            package: package,
            currency: package.storeProduct.currencyCode,
            currencySymbol: package.storeProduct.currencyCode);

        if (!inAppPurchaseList.contains(Config.credit1000)) {
          inAppPurchaseList.add(credits1000);
        }
      }

      if (package.storeProduct.identifier == Config.credit100) {
        InAppPurchaseModel credits100 = InAppPurchaseModel(
            id: Config.credit100,
            coins: 100,
            price: package.storeProduct.priceString,
            image: "assets/images/ic_coins_3.png",
            type: InAppPurchaseModel.typeNormal,
            storeProduct: package.storeProduct,
            package: package,
            currency: package.storeProduct.currencyCode,
            currencySymbol: package.storeProduct.currencyCode);

        if (!inAppPurchaseList.contains(Config.credit100)) {
          inAppPurchaseList.add(credits100);
        }
      }

      if (package.storeProduct.identifier == Config.credit500) {
        InAppPurchaseModel credits500 = InAppPurchaseModel(
            id: Config.credit500,
            coins: 500,
            price: package.storeProduct.priceString,
            image: "assets/images/ic_coins_6.png",
            type: InAppPurchaseModel.typeNormal,
            discount: (package.storeProduct.price * 1.1).toStringAsFixed(2),
            package: package,
            currency: package.storeProduct.currencyCode,
            currencySymbol: package.storeProduct.currencyCode);

        if (!inAppPurchaseList.contains(Config.credit500)) {
          inAppPurchaseList.add(credits500);
        }
      }

      if (package.storeProduct.identifier == Config.credit2100) {
        InAppPurchaseModel credits2100 = InAppPurchaseModel(
            id: Config.credit2100,
            coins: 2100,
            price: package.storeProduct.priceString,
            discount: (package.storeProduct.price * 1.2).toStringAsFixed(2),
            image: "assets/images/ic_coins_5.png",
            type: InAppPurchaseModel.typeNormal,
            storeProduct: package.storeProduct,
            package: package,
            currency: package.storeProduct.currencyCode,
            currencySymbol: package.storeProduct.currencyCode);

        if (!inAppPurchaseList.contains(Config.credit2100)) {
          inAppPurchaseList.add(credits2100);
        }
      }

      if (package.storeProduct.identifier == Config.credit5250) {
        InAppPurchaseModel credits5250 = InAppPurchaseModel(
            id: Config.credit5250,
            coins: 5250,
            price: package.storeProduct.priceString,
            discount: (package.storeProduct.price * 1.3).toStringAsFixed(2),
            image: "assets/images/ic_coins_7.png",
            type: InAppPurchaseModel.typeNormal,
            storeProduct: package.storeProduct,
            package: package,
            currency: package.storeProduct.currencyCode,
            currencySymbol: package.storeProduct.currencyCode);

        if (!inAppPurchaseList.contains(Config.credit5250)) {
          inAppPurchaseList.add(credits5250);
        }
      }

      if (package.storeProduct.identifier == Config.credit10500) {
        InAppPurchaseModel credits10500 = InAppPurchaseModel(
            id: Config.credit10500,
            coins: 10500,
            price: package.storeProduct.priceString,
            discount: (package.storeProduct.price * 1.4).toStringAsFixed(2),
            image: "assets/images/ic_coins_2.png",
            type: InAppPurchaseModel.typeNormal,
            storeProduct: package.storeProduct,
            package: package,
            currency: package.storeProduct.currencyCode,
            currencySymbol: package.storeProduct.currencyCode);

        if (!inAppPurchaseList.contains(Config.credit10500)) {
          inAppPurchaseList.add(credits10500);
        }
      }
    }

    return inAppPurchaseList;
  }

  final selectedGiftItemNotifier = ValueNotifier<GiftsModel?>(null);
  final countNotifier = ValueNotifier<String>('1');

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController.unbounded(vsync: this);
    initProducts();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAllGifts();
    });
  }

  void _checkAllGifts() async {
    print("🔍 بدء التحقق من الهدايا في قاعدة البيانات...");
    
    QueryBuilder<GiftsModel> query = QueryBuilder<GiftsModel>(GiftsModel());
    ParseResponse response = await query.query();
    
    if (response.success && response.results != null) {
      print("✅ تم العثور على ${response.results!.length} هدية في قاعدة البيانات");
      
      for (var gift in response.results!) {
        GiftsModel g = gift as GiftsModel;
        print("📦 هدية: ${g.getName} | التصنيف: ${g.getGiftCategories} | السعر: ${g.getCoins}");
      }
    } else {
      print("❌ لا توجد هدايا في قاعدة البيانات أو فشل الاتصال");
      print("   الخطأ: ${response.error?.message}");
    }
  }

  initProducts() async {
    try {
      offerings = await Purchases.getOfferings();

      if (offerings.current!.availablePackages.length > 0) {
        setState(() {
          _isAvailable = true;
          _loading = false;
        });
      }
    } on PlatformException {
      setState(() {
        _isAvailable = false;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _showGiftAndGetCoinsBottomSheet();
  }

  _purchaseProduct(InAppPurchaseModel inAppPurchaseModel) async {
    QuickHelp.showLoadingDialog(context);
    Future.delayed(Duration(seconds: 3)).then((value) {
      QuickHelp.hideLoadingDialog(context);
    });
  }

  void handleInvalidPurchase() {
    QuickHelp.showAppNotification(
        context: context, title: "in_app_purchases.invalid_purchase".tr());
    QuickHelp.hideLoadingDialog(context);
  }

  void handleError(PlatformException error) {
    QuickHelp.hideLoadingDialog(context);
    QuickHelp.showAppNotification(context: context, title: error.message);
  }

  showPendingUI() {
    QuickHelp.showLoadingDialog(context);
    print("InAppPurchase showPendingUI");
  }

  Widget _showGiftAndGetCoinsBottomSheet() {
    return StatefulBuilder(builder: (context, setState) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(25.0),
            topRight: const Radius.circular(25.0),
          ),
        ),
        child: ContainerCorner(
          color: kTransparentColor,
          child: IndexedStack(
            index: widget.showOnlyCoinsPurchase!
                ? 1
                : bottomSheetCurrentIndex,
            children: [
              Scaffold(
                backgroundColor: kTransparentColor,
                appBar: AppBar(
                  automaticallyImplyLeading: false,
                  leading: BackButton(color: Colors.white),
                  actions: [
                    ContainerCorner(
                      height: 30,
                      borderRadius: 50,
                      marginRight: 10,
                      marginTop: 10,
                      marginBottom: 10,
                      color: kWarninngColor,
                      onTap: () {
                        setState(() {
                          bottomSheetCurrentIndex = 1;
                        });
                      },
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: SvgPicture.asset(
                              "assets/svg/coin.svg",
                              width: 20,
                              height: 20,
                            ),
                          ),
                          TextWithTap(
                            "message_screen.get_coins".tr(),
                            marginRight: 10,
                          )
                        ],
                      ),
                    )
                  ],
                  backgroundColor: kTransparentColor,
                  centerTitle: true,
                  title: Row(
                    children: [
                      SvgPicture.asset(
                        "assets/svg/ic_coin_with_star.svg",
                        width: 20,
                        height: 20,
                      ),
                      TextWithTap(
                        widget.currentUser.getCredits.toString(),
                        color: Colors.white,
                        fontSize: 16,
                        marginLeft: 5,
                      )
                    ],
                  ),
                ),
                body: _buildGiftTabs(setState),
              ),
              Scaffold(
                backgroundColor: kTransparentColor,
                appBar: AppBar(
                  actions: [
                    Row(
                      children: [
                        SvgPicture.asset(
                          "assets/svg/ic_coin_with_star.svg",
                          width: 20,
                          height: 20,
                        ),
                        TextWithTap(
                          widget.currentUser.getCredits.toString(),
                          color: Colors.white,
                          marginLeft: 5,
                          marginRight: 15,
                        )
                      ],
                    ),
                  ],
                  backgroundColor: kTransparentColor,
                  title: TextWithTap(
                    "message_screen.get_coins".tr(),
                    marginRight: 10,
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  centerTitle: true,
                  automaticallyImplyLeading: false,
                  leading: BackButton(
                    color: Colors.white,
                    onPressed: () {
                      if (widget.showOnlyCoinsPurchase!) {
                        Navigator.of(context).pop();
                      } else {
                        setState(() {
                          bottomSheetCurrentIndex = 0;
                        });
                      }
                    },
                  ),
                ),
                body: getBody(),
              )
            ],
          ),
        ),
      );
    });
  }

  Widget _buildGiftTabs(StateSetter setState) {
    return DefaultTabController(
      length: giftCategories.length,
      child: Column(
        children: [
          Container(
            height: 50,
            margin: EdgeInsets.symmetric(horizontal: 8),
            child: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                color: Colors.purple.withOpacity(0.3),
              ),
              dividerColor: Colors.transparent,
              tabs: giftCategories.map((category) {
                return Tab(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        Text(
                          category['icon']!,
                          style: TextStyle(fontSize: 14),
                        ),
                        SizedBox(width: 4),
                        Text(
                          category['name']!,
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: Container(
              margin: EdgeInsets.only(top: 8),
              child: TabBarView(
                children: giftCategories.map((category) {
                  return _getGiftsByCategory(category['key']!, setState);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getGiftsByCategory(String category, StateSetter setState) {
    print("🔍 جلب هدايا للتصنيف: $category");
    
    QueryBuilder<GiftsModel> giftQuery = QueryBuilder<GiftsModel>(GiftsModel());
    
    giftQuery.whereEqualTo(GiftsModel.keyGiftCategories, category);
    giftQuery.orderByAscending(GiftsModel.keyCoins);
    giftQuery.setLimit(50);

    return ContainerCorner(
      color: kTransparentColor,
      child: ParseLiveGridWidget<GiftsModel>(
        query: giftQuery,
        crossAxisCount: 4,
        reverse: false,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        lazyLoading: false,
        shrinkWrap: true,
        padding: EdgeInsets.all(12),
        childBuilder: (BuildContext context,
            ParseLiveListElementSnapshot<GiftsModel> snapshot) {
          
          if (snapshot.hasData) {
            GiftsModel gift = snapshot.loadedData!;
            print("✅ تم العثور على هدية: ${gift.getName} في تصنيف $category");
            
            return GestureDetector(
              onTap: () => _checkCredits(gift, setState),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white24,
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Container(
                        width: 50,
                        height: 50,
                        margin: EdgeInsets.only(top: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          // ✅ حل مشكلة null safety بشكل صحيح
                          child: _buildGiftImage(gift),
                        ),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      gift.getName ?? 'هدية',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 8,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          "assets/svg/ic_coin_with_star.svg",
                          width: 10,
                          height: 10,
                        ),
                        SizedBox(width: 2),
                        Text(
                          gift.getCoins.toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                  ],
                ),
              ),
            );
          } else {
            return SizedBox();
          }
        },
        queryEmptyElement: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.card_giftcard,
                size: 50,
                color: Colors.grey,
              ),
              SizedBox(height: 10),
              Text(
                "لا توجد هدايا في هذا التصنيف",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              if (category.isNotEmpty)
                Text(
                  "التصنيف: $category",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
        gridLoadingElement: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
          ),
        ),
      ),
    );
  }

  // ✅ دالة مساعدة لبناء صورة الهدية مع معالجة null بأمان
  Widget _buildGiftImage(GiftsModel gift) {
    try {
      final preview = gift.getPreview;
      
      if (preview != null) {
        final url = preview.url;
        if (url != null && url.isNotEmpty) {
          return Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              print("❌ خطأ في تحميل صورة الهدية: ${gift.getName} - $error");
              return Container(
                color: Colors.grey.shade800,
                child: Icon(
                  Icons.card_giftcard,
                  color: Colors.white54,
                  size: 25,
                ),
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: Colors.grey.shade800,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                  ),
                ),
              );
            },
          );
        }
      }
      
      // إذا لم توجد صورة
      return Container(
        color: Colors.grey.shade800,
        child: Icon(
          Icons.card_giftcard,
          color: Colors.white54,
          size: 25,
        ),
      );
    } catch (e) {
      print("❌ خطأ غير متوقع في بناء صورة الهدية: $e");
      return Container(
        color: Colors.grey.shade800,
        child: Icon(
          Icons.card_giftcard,
          color: Colors.white54,
          size: 25,
        ),
      );
    }
  }

  Widget getBody() {
    if (_loading) {
      return QuickHelp.appLoading();
    } else if (_isAvailable) {
      return ContainerCorner(
        color: kTransparentColor,
        marginLeft: 5,
        marginRight: 5,
        child: GridView.count(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          shrinkWrap: true,
          physics: BouncingScrollPhysics(),
          children: List.generate(
            getInAppList().length,
            (index) {
              InAppPurchaseModel inApp = getInAppList()[index];

              return ContainerCorner(
                color: kDarkColorsTheme,
                borderRadius: 8,
                onTap: () {
                  _inAppPurchaseModel = inApp;
                  _purchaseProduct(inApp);
                },
                child: Column(
                  children: [
                    TextWithTap(
                      QuickHelp.checkFundsWithString(amount: "${inApp.coins}"),
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      marginTop: 5,
                      color: Colors.white,
                    ),
                    Expanded(
                      child: Image.asset(
                        "assets/images/coin_bling.webp",
                        height: 20,
                        width: 20,
                      ),
                    ),
                    ContainerCorner(
                      borderRadius: 50,
                      borderWidth: 0,
                      height: 30,
                      marginRight: 10,
                      marginLeft: 10,
                      color: Colors.deepPurpleAccent,
                      marginBottom: 5,
                      child: TextWithTap(
                        "${inApp.price}",
                        color: Colors.white,
                        alignment: Alignment.center,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    } else {
      return QuickActions.noContentFound(context);
    }
  }

  _checkCredits(GiftsModel gift, StateSetter setState) {
    if (widget.currentUser.getCredits! >= gift.getCoins!) {
      if (widget.onGiftSelected != null) {
        widget.onGiftSelected!(gift);
        Navigator.of(context).pop();
      }
    } else {
      setState(() {
        bottomSheetCurrentIndex = 1;
      });
    }
  }
}
