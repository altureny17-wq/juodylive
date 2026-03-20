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

// ✅ نموذج تصنيف الهدايا
class _GiftCategory {
  final String key;
  final String label;
  _GiftCategory(this.key, this.label);
}

class _CoinsFlowWidgetState extends State<_CoinsFlowWidget>
    with TickerProviderStateMixin {
  AnimationController? _animationController;
  int bottomSheetCurrentIndex = 0;

  // ✅ تصنيفات الهدايا فقط (بدون منتجات المتجر)
  final List<_GiftCategory> _giftCategories = [
    _GiftCategory(GiftsModel.giftCategoryTypeClassic, 'كلاسيك'),
    _GiftCategory(GiftsModel.giftCategoryType3D, '3D'),
    _GiftCategory(GiftsModel.giftCategoryTypeVIP, 'VIP'),
    _GiftCategory(GiftsModel.giftCategoryTypeLove, 'حب'),
    _GiftCategory(GiftsModel.giftCategoryTypeMoods, 'مزاج'),
    _GiftCategory(GiftsModel.giftCategoryTypeArtists, 'فنون'),
    _GiftCategory(GiftsModel.giftCategoryTypeCollectibles, 'مجموعة'),
    _GiftCategory(GiftsModel.giftCategoryTypeGames, 'ألعاب'),
    _GiftCategory(GiftsModel.giftCategoryTypeFamily, 'عائلة'),
    _GiftCategory(GiftsModel.categorySvgaGifts, 'SVGA'),
  ];

  int _selectedCategoryIndex = 0;
  late TabController _giftTabController;

  late Offerings offerings;
  bool _isAvailable = false;
  bool _loading = true;
  InAppPurchaseModel? _inAppPurchaseModel;

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
    _giftTabController = TabController(
      length: _giftCategories.length,
      vsync: this,
    )..addListener(() {
        if (!_giftTabController.indexIsChanging) {
          setState(() {
            _selectedCategoryIndex = _giftTabController.index;
          });
        }
      });
    initProducts();
  }

  @override
  void dispose() {
    _giftTabController.dispose();
    super.dispose();
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
              // ✅ تبويب الهدايا (مبسط بدون تصنيفات)
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
                body: _buildSimpleGiftList(setState), // ✅ استخدم القائمة المبسطة
              ),
              // ✅ تبويب شراء العملات
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

  // ✅ قائمة الهدايا مع تبويبات التصنيفات
  Widget _buildSimpleGiftList(StateSetter setState) {
    return Column(
      children: [
        // ✅ شريط التبويبات (التصنيفات)
        Container(
          height: 40,
          color: Colors.transparent,
          child: TabBar(
            controller: _giftTabController,
            isScrollable: true,
            indicatorColor: Colors.purple,
            indicatorWeight: 2,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            labelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: const TextStyle(fontSize: 11),
            tabs: _giftCategories
                .map((cat) => Tab(text: cat.label))
                .toList(),
          ),
        ),

        // ✅ محتوى التصنيف المختار
        Expanded(
          child: FutureBuilder<ParseResponse>(
            future: _fetchGiftsByCategory(
                _giftCategories[_selectedCategoryIndex].key),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.purple),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'حدث خطأ في التحميل',
                    style: TextStyle(color: Colors.white70),
                  ),
                );
              }

              final response = snapshot.data;
              if (response == null ||
                  !response.success ||
                  response.results == null ||
                  response.results!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.card_giftcard,
                          size: 60, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(
                        'لا توجد هدايا في هذا التصنيف',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ],
                  ),
                );
              }

              final gifts = response.results!.cast<GiftsModel>();

              return GridView.builder(
                padding: const EdgeInsets.all(10),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.78,
                ),
                itemCount: gifts.length,
                itemBuilder: (context, index) {
                  final gift = gifts[index];
                  return GestureDetector(
                    onTap: () => _checkCredits(gift, setState),
                    child: ValueListenableBuilder<GiftsModel?>(
                      valueListenable: selectedGiftItemNotifier,
                      builder: (context, selectedGift, _) {
                        final isSelected =
                            selectedGift?.objectId == gift.objectId;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.purple.withOpacity(0.3)
                                : Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.purple
                                  : Colors.white24,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      6, 8, 6, 2),
                                  child: ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(6),
                                    child: _buildGiftImageSimple(gift),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                gift.getName ?? '',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 9,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  SvgPicture.asset(
                                    "assets/svg/ic_coin_with_star.svg",
                                    width: 9,
                                    height: 9,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    gift.getCoins.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ✅ جلب الهدايا حسب التصنيف فقط — يُستثنى منتجات المتجر تلقائياً
  Future<ParseResponse> _fetchGiftsByCategory(String category) async {
    QueryBuilder<GiftsModel> query = QueryBuilder<GiftsModel>(GiftsModel());
    query.whereEqualTo(GiftsModel.keyGiftCategories, category);
    query.orderByAscending(GiftsModel.keyCoins);
    query.setLimit(100);
    return await query.query();
  }

  // ✅ دالة مبسطة لعرض صورة الهدية
  Widget _buildGiftImageSimple(GiftsModel gift) {
    try {
      // التحقق من وجود الصورة
      if (gift.getPreview != null) {
        String? imageUrl = gift.getPreview!.url;
        
        if (imageUrl != null && imageUrl.isNotEmpty) {
          return Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey.shade800,
                child: Icon(
                  Icons.broken_image,
                  color: Colors.white54,
                  size: 20,
                ),
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: Colors.grey.shade800,
                child: Center(
                  child: SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                    ),
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
      // في حالة حدوث أي خطأ
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
