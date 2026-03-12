// ignore_for_file: must_be_immutable

import 'package:easy_localization/easy_localization.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:juodylive/helpers/quick_actions.dart';
import 'package:juodylive/helpers/quick_help.dart';
import 'package:juodylive/models/LeadersModel.dart';
import 'package:juodylive/ui/text_with_tap.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import 'package:flutter_svg/flutter_svg.dart';

import '../../models/UserModel.dart';
import '../../ui/container_with_corner.dart';
import '../../utils/colors.dart';
import '../profile/user_profile_screen.dart';

class RankingScreen extends StatefulWidget {
  UserModel? currentUser;

  RankingScreen({this.currentUser, super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen>
    with TickerProviderStateMixin {
  int topLeadersAmount = 50;

  late TabController leaderTypeTabControl;
  int leaderTypeTabsLength = 3;
  int leaderTypeTabIndex = 0;

  late TabController timeTabController;
  int timeTabsLength = 4;
  int timeTabIndex = 0;

  var allStreamLeaders = [];
  var pkLeaders = [];
  var pkLeadersDiamonds = [];
  var allGiftGiver = [];
  var allGiftGiverCredits = [];
  bool loading = true;
  bool giftLoading = true;

  // ─── فلتر الوقت ───────────────────────────────────────────────────────────
  DateTime? _getTimeFilter() {
    final now = DateTime.now();
    switch (timeTabIndex) {
      case 0: return now.subtract(const Duration(hours: 24));
      case 1: return now.subtract(const Duration(days: 7));
      case 2: return now.subtract(const Duration(days: 30));
      default: return null;
    }
  }

  void _refreshAll() {
    setState(() {
      allStreamLeaders.clear();
      pkLeaders.clear();
      pkLeadersDiamonds.clear();
      allGiftGiver.clear();
      allGiftGiverCredits.clear();
      loading = true;
      giftLoading = true;
    });
    getAllStreamLeaders();
    getAllGiftSenders();
    getAllSPkLeaders();
  }

  // ─── helper: تاج فوق الأفاتار ─────────────────────────────────────────────
  Widget _crownFor(int rank, double avatarSize) {
    final crowns = [
      'assets/images/crown_top_1_user.png',
      'assets/images/crown_top_2_user.png',
      'assets/images/crown_top_3_user.png',
    ];
    final sizes = [avatarSize * 0.85, avatarSize * 0.7, avatarSize * 0.65];
    if (rank < 1 || rank > 3) return const SizedBox();
    return Positioned(
      top: -(sizes[rank - 1] * 0.55),
      child: Image.asset(crowns[rank - 1], width: sizes[rank - 1]),
    );
  }

  // ─── helper: ميدالية المركز ────────────────────────────────────────────────
  Widget _medalFor(int rank) {
    final medals = [
      'assets/images/rank_1_position.png',
      'assets/images/rank_2_position.png',
      'assets/images/rank_3_position.png',
    ];
    if (rank < 1 || rank > 3) return const SizedBox();
    return Image.asset(medals[rank - 1], width: 28);
  }

  // ─── helper: رقم المركز في القائمة ────────────────────────────────────────
  Widget _rankBadge(int index) {
    if (index == 0) return Image.asset('assets/images/ic_rank_first.png', height: 28);
    if (index == 1) return Image.asset('assets/images/ic_rank_second.png', height: 28);
    if (index == 2) return Image.asset('assets/images/ic_rank_third.png', height: 28);
    return SizedBox(
      width: 28,
      child: TextWithTap(
        '${index + 1}',
        color: kIamonDarkerColor,
        fontWeight: FontWeight.bold,
        alignment: Alignment.center,
        fontSize: 13,
      ),
    );
  }

  // ─── helper: خلفية صف القائمة ─────────────────────────────────────────────
  Widget _rowCard({required Widget child, bool isGifter = false}) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            isGifter
                ? 'assets/images/rank_rose_card.png'
                : 'assets/images/rank_blue_card.png',
            fit: BoxFit.fill,
          ),
        ),
        child,
      ],
    );
  }

  // ─── helper: خلفية المنصة (أعلى 3) ─────────────────────────────────────────
  String _podiumBg() {
    // الجمعة-الأحد: rank_fri_sun_bg، باقي الأسبوع: bg_rich_mon_to_thu_ranked_users
    final day = DateTime.now().weekday;
    if (day >= 5) return 'assets/images/bg_rich_fri_to_sun_ranked_users.png';
    return 'assets/images/bg_rich_mon_to_thu_ranked_users.png';
  }

  // ─── helper: أيقونة درجة الرانك حسب النقاط ───────────────────────────────
  Widget _rankTierIcon(int diamonds) {
    String asset;
    if (diamonds >= 1000000)      asset = 'assets/images/ic_king_rank.png';
    else if (diamonds >= 500000)  asset = 'assets/images/ic_super_rank.png';
    else if (diamonds >= 100000)  asset = 'assets/images/ic_gold_rank.png';
    else if (diamonds >= 50000)   asset = 'assets/images/ic_silver_rank.png';
    else if (diamonds >= 10000)   asset = 'assets/images/ic_diamond_ranking.png';
    else                           asset = 'assets/images/ic_normal_ranking.png';
    return Image.asset(asset, height: 18);
  }

  getAllGiftSenders() async {
    QueryBuilder<LeadersModel> query =
    QueryBuilder<LeadersModel>(LeadersModel());

    query.includeObject([LeadersModel.keyAuthor]);
    query.orderByDescending(LeadersModel.keyDiamondsQuantity);
    final from = _getTimeFilter();
    if (from != null) query.whereGreaterThanOrEqualsTo('createdAt', from);

    query.setLimit(50);
    ParseResponse response = await query.query();
    if (response.success && response.results != null) {
      for (LeadersModel leader in response.results!) {
        allGiftGiver.add(leader.getAuthor);
        allGiftGiverCredits.add(leader.getDiamondsQuantity);
      }
      setState(() {
        giftLoading = false;
      });
    } else {
      setState(() {
        giftLoading = false;
      });
    }
  }

  getAllStreamLeaders() async {
    QueryBuilder<UserModel> query =
    QueryBuilder<UserModel>(UserModel.forQuery());

    query.orderByDescending(UserModel.keyDiamondsTotal);
    query.whereGreaterThan(UserModel.keyDiamondsTotal, 0);

    query.setLimit(50);
    ParseResponse response = await query.query();
    if (response.success && response.results != null) {
      for (UserModel user in response.results!) {
        allStreamLeaders.add(user);
      }
      setState(() {
        loading = false;
      });
    } else {
      setState(() {
        loading = false;
      });
    }
  }

  getAllSPkLeaders() async {
    QueryBuilder<UserModel> query =
    QueryBuilder<UserModel>(UserModel.forQuery());

    query.orderByDescending(UserModel.keyBattlePoints);
    query.whereGreaterThan(UserModel.keyBattlePoints, 0);

    query.setLimit(50);
    ParseResponse response = await query.query();
    if (response.success && response.results != null) {
      for (UserModel user in response.results!) {
        pkLeaders.add(user);
        pkLeadersDiamonds.add(user.getDiamondsTotal);
      }
      setState(() {
        loading = false;
      });
    } else {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    getAllStreamLeaders();
    getAllGiftSenders();
    getAllSPkLeaders();
    leaderTypeTabControl = TabController(
        vsync: this, length: leaderTypeTabsLength, initialIndex: 0)
      ..addListener(() {
        setState(() {
          leaderTypeTabIndex = leaderTypeTabControl.index;
        });
      });
    timeTabController = TabController(
        vsync: this, length: timeTabsLength, initialIndex: timeTabIndex)
      ..addListener(() {
        if (!timeTabController.indexIsChanging) {
          setState(() { timeTabIndex = timeTabController.index; });
          _refreshAll();
        }
      });
  }

  @override
  void dispose() {
    super.dispose();
    leaderTypeTabControl.dispose();
    timeTabController.dispose();
    allStreamLeaders.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: TextWithTap(
          "leaderboard_screen.leaderboard_".tr(),
          fontSize: 25,
          fontWeight: FontWeight.w900,
          color: kIamonDarkerColor,
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(78.0),
          child: Column(
            children: [
              // ─── تبويبات النوع ─────────────────────────────────────────────
              TabBar(
                isScrollable: false,
                enableFeedback: false,
                controller: leaderTypeTabControl,
                dividerColor: kTransparentColor,
                unselectedLabelColor: kColorsGrey,
                indicatorWeight: 2.0,
                indicatorColor: kTransparentColor,
                tabAlignment: TabAlignment.fill,
                labelColor: kIamonDarkerColor,
                indicator: UnderlineTabIndicator(
                  borderSide: BorderSide(width: 3.0, color: kIamonDarkerColor),
                  borderRadius: BorderRadius.all(Radius.circular(50)),
                  insets: EdgeInsets.symmetric(horizontal: 15.0),
                ),
                labelPadding: EdgeInsets.symmetric(horizontal: 10.0),
                splashFactory: NoSplash.splashFactory,
                overlayColor: WidgetStateProperty.resolveWith<Color?>(
                  (Set<WidgetState> states) => states.contains(WidgetState.focused)
                      ? null : Colors.transparent,
                ),
                labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                unselectedLabelStyle: TextStyle(
                  fontSize: 14, color: kIamonDarkerColor, fontWeight: FontWeight.bold),
                tabs: [
                  Tab(
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      SvgPicture.asset(
                        leaderTypeTabIndex == 0
                            ? 'assets/svg/ic_leaderboard_new.svg'
                            : 'assets/svg/ic_leaderboard_grey.svg',
                        height: 18),
                      SizedBox(width: 5),
                      TextWithTap("leaderboard_screen.streamers_".tr(), color: kIamonDarkerColor),
                    ]),
                  ),
                  Tab(
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      SvgPicture.asset(
                        leaderTypeTabIndex == 1
                            ? 'assets/svg/ic_leaderboard_new.svg'
                            : 'assets/svg/ic_leaderboard_grey.svg',
                        height: 18),
                      SizedBox(width: 5),
                      TextWithTap("leaderboard_screen.gift_giver".tr(), color: kIamonDarkerColor),
                    ]),
                  ),
                  Tab(
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      SvgPicture.asset(
                        leaderTypeTabIndex == 2
                            ? 'assets/svg/ic_leaderboard_new.svg'
                            : 'assets/svg/ic_leaderboard_grey.svg',
                        height: 18),
                      SizedBox(width: 5),
                      TextWithTap("go_live_menu.pk_title".tr(), color: kIamonDarkerColor),
                    ]),
                  ),
                ],
              ),
              // ─── فلتر الوقت ───────────────────────────────────────────────
              Container(
                height: 34,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: TabBar(
                  controller: timeTabController,
                  dividerColor: kTransparentColor,
                  indicatorColor: kTransparentColor,
                  splashFactory: NoSplash.splashFactory,
                  indicator: BoxDecoration(
                    color: kVioletColor, borderRadius: BorderRadius.circular(15)),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  unselectedLabelStyle: const TextStyle(fontSize: 11),
                  tabs: const [
                    Tab(text: 'يومي'),
                    Tab(text: 'أسبوعي'),
                    Tab(text: 'شهري'),
                    Tab(text: 'الكل'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: ContainerCorner(
        borderWidth: 0,
        imageDecoration: leaderTypeTabIndex == 0
            ? "assets/images/bg_rank_host.png"
            : leaderTypeTabIndex == 1
                ? "assets/images/bg_rank_rich.png"
                : "assets/images/trace_rank_bg.png",
        child: TabBarView(
          controller: leaderTypeTabControl,
          children: [
            getBody(),
            getGifters(),
            getPkLeader(),
          ],
        ),
      ),
    );
  }

  Widget getPkLeader() {
    Size size = MediaQuery.sizeOf(context);
    return ListView(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: 30,
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Stack(
              alignment: AlignmentDirectional.topCenter,
              clipBehavior: Clip.none,
              children: [
                if (pkLeaders.length < 3)
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      ContainerCorner(
                        height: size.width / 6,
                        width: size.width / 6,
                        borderWidth: 4,
                        borderColor: kSilverColor,
                        borderRadius: 50,
                      ),
                      _medalFor(3)
                    ],
                  ),
                if (pkLeaders.length >= 3)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: (){
                          QuickHelp.goToNavigatorScreen(
                            context,
                            UserProfileScreen(
                              currentUser: widget.currentUser,
                              mUser: pkLeaders[2],
                              isFollowing: widget.currentUser!.getFollowing!
                                  .contains(pkLeaders[2].objectId),
                            ),
                          );
                        },
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            QuickActions.avatarBorder(
                              pkLeaders[2],
                              height: size.width / 6,
                              width: size.width / 6,
                              vipFrameWidth: size.width / 5,
                              vipFrameHeight: size.width / 5.2,
                              borderColor: kSilverColor,
                              borderWidth: 4,
                            ),
                            if(pkLeaders[2].getIsUserVip! && !pkLeaders[2].getCanUseAvatarFrame!)
                              Positioned(
                                right: 8,
                                bottom: 1,
                                child: _medalFor(3)
                              ),
                            if(!(pkLeaders[2].getIsUserVip! && !pkLeaders[2].getCanUseAvatarFrame!))
                              _medalFor(3)
                          ],
                        ),
                      ),
                      SizedBox(
                        width: size.width / 4,
                        child: TextWithTap(
                          pkLeaders[2].getFullName!,
                          color: kIamonDarkerColor,
                          fontWeight: FontWeight.bold,
                          alignment: Alignment.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          TextWithTap(
                            QuickHelp.convertToK(pkLeaders[2].getBattleVictories!)+"victories_".tr(),
                            color: kIamonDarkerColor,
                            marginRight: 5,
                            fontSize: 7,
                            fontWeight: FontWeight.w900,
                          ),
                          TextWithTap(
                            QuickHelp.convertToK(pkLeaders[2].getBattlePoints!)+"Pts",
                            color: kIamonDarkerColor,
                            marginLeft: 5,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            marginRight: 10,
                          ),
                        ],
                      ),
                    ],
                  ),
                _crownFor(3, size.width / 6),
              ],
            ),
            Stack(
              alignment: AlignmentDirectional.topCenter,
              clipBehavior: Clip.none,
              children: [
                if (pkLeaders.length < 1)
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      ContainerCorner(
                        height: size.width / 4,
                        width: size.width / 4,
                        borderWidth: 5,
                        borderColor: kGoldenColor,
                        borderRadius: 50,
                      ),
                      _medalFor(1)
                    ],
                  ),
                if (pkLeaders.length >= 1)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: (){
                          QuickHelp.goToNavigatorScreen(
                            context,
                            UserProfileScreen(
                              currentUser: widget.currentUser,
                              mUser: pkLeaders[0],
                              isFollowing: widget.currentUser!.getFollowing!
                                  .contains(pkLeaders[0].objectId),
                            ),
                          );
                        },
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            QuickActions.avatarBorder(
                              pkLeaders[0],
                              height: size.width / 4,
                              width: size.width / 4,
                              vipFrameWidth: size.width / 3,
                              vipFrameHeight: size.width / 3.5,
                              borderWidth: 5,
                              borderColor: kGoldenColor,
                            ),
                            if(pkLeaders[0].getIsUserVip! && !pkLeaders[0].getCanUseAvatarFrame!)
                              Positioned(
                                right: 25,
                                bottom: 3,
                                child: _medalFor(1)
                              ),
                            if(!(pkLeaders[0].getIsUserVip! && !pkLeaders[0].getCanUseAvatarFrame!))
                              _medalFor(1)
                          ],
                        ),
                      ),
                      SizedBox(
                        width: size.width / 4,
                        child: TextWithTap(
                          pkLeaders[0].getFullName!,
                          color: kIamonDarkerColor,
                          fontWeight: FontWeight.bold,
                          alignment: Alignment.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          TextWithTap(
                            QuickHelp.convertToK(pkLeaders[0].getBattleVictories!)+"victories_".tr(),
                            color: kIamonDarkerColor,
                            marginRight: 5,
                            fontSize: 7,
                            fontWeight: FontWeight.w900,
                          ),
                          TextWithTap(
                            QuickHelp.convertToK(pkLeaders[0].getBattlePoints!)+"Pts",
                            color: kIamonDarkerColor,
                            marginLeft: 5,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            marginRight: 10,
                          ),
                        ],
                      ),
                    ],
                  ),
                _crownFor(1, size.width / 4),
              ],
            ),
            Stack(
              alignment: AlignmentDirectional.topCenter,
              clipBehavior: Clip.none,
              children: [
                if (pkLeaders.length < 2)
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      ContainerCorner(
                        height: size.width / 6,
                        width: size.width / 6,
                        borderWidth: 4,
                        borderColor: kBronzeColor,
                        borderRadius: 50,
                      ),
                      ContainerCorner(
                        borderRadius: 50,
                        color: kBronzeColor,
                        child: TextWithTap(
                          "2",
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          marginLeft: 3,
                          marginRight: 3,
                        ),
                      )
                    ],
                  ),
                if (pkLeaders.length >= 2)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: (){
                          QuickHelp.goToNavigatorScreen(
                            context,
                            UserProfileScreen(
                              currentUser: widget.currentUser,
                              mUser: pkLeaders[1],
                              isFollowing: widget.currentUser!.getFollowing!
                                  .contains(pkLeaders[1].objectId),
                            ),
                          );
                        },
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            QuickActions.avatarBorder(
                              pkLeaders[1],
                              height: size.width / 6,
                              width: size.width / 6,
                              vipFrameWidth: size.width / 5,
                              vipFrameHeight: size.width / 5.2,
                              borderColor: kBronzeColor,
                              borderWidth: 4,
                            ),
                            if(pkLeaders[1].getIsUserVip! && !pkLeaders[1].getCanUseAvatarFrame!)
                              Positioned(
                                right: 8,
                                bottom: 1,
                                child: _medalFor(2),
                              ),
                            if(!(pkLeaders[1].getIsUserVip! && !pkLeaders[1].getCanUseAvatarFrame!))
                              ContainerCorner(
                                borderRadius: 50,
                                color: kBronzeColor,
                                child: TextWithTap(
                                  "2",
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  marginLeft: 3,
                                  marginRight: 3,
                                ),
                              )
                          ],
                        ),
                      ),
                      SizedBox(
                        width: size.width / 4,
                        child: TextWithTap(
                          pkLeaders[1].getFullName!,
                          color: kIamonDarkerColor,
                          fontWeight: FontWeight.bold,
                          alignment: Alignment.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          TextWithTap(
                            QuickHelp.convertToK(pkLeaders[1].getBattleVictories!)+"victories_".tr(),
                            color: kIamonDarkerColor,
                            marginRight: 5,
                            fontSize: 7,
                            fontWeight: FontWeight.w900,
                          ),
                          TextWithTap(
                            QuickHelp.convertToK(pkLeaders[1].getBattlePoints!)+"Pts",
                            color: kIamonDarkerColor,
                            marginLeft: 5,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            marginRight: 10,
                          ),
                        ],
                      ),
                    ],
                  ),
                _crownFor(2, size.width / 6),
              ],
            ),
            //if(allStreamLeaders.length < 2)
          ],
        ),

        // ─── منصة الترتيب ─────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Image.asset(
            'assets/images/rank_cart.png',
            width: double.infinity,
            fit: BoxFit.fitWidth,
          ),
        ),
        SizedBox(height: 10),
        Visibility(
          visible: !giftLoading,
          child: ContainerCorner(
            width: size.width,
            height: size.height,
            child: ListView(
              children: List.generate(pkLeaders.length, (index) {
                if (index > 2) {
                  UserModel user = pkLeaders[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10, left: 10, right: 10),
                    child: GestureDetector(
                      onTap: () => QuickHelp.goToNavigatorScreen(
                        context,
                        UserProfileScreen(
                          currentUser: widget.currentUser,
                          mUser: user,
                          isFollowing: widget.currentUser!.getFollowing!
                              .contains(user.objectId),
                        ),
                      ),
                      child: _rowCard(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _rankBadge(index),
                                  SizedBox(width: 8),
                                  QuickActions.avatarBorder(
                                    user,
                                    height: 45,
                                    width: 45,
                                    vipFrameWidth: 50,
                                    vipFrameHeight: 52,
                                    borderWidth: 0,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(children: [
                                          TextWithTap(
                                            user.getFullName!.capitalize,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: kIamonDarkerColor,
                                            marginRight: 4,
                                          ),
                                          ClipRRect(
                                            borderRadius: BorderRadius.all(Radius.circular(15)),
                                            child: Image.asset(
                                              QuickHelp.levelImage(pointsInApp: user.getUserPoints!),
                                              width: 32,
                                            ),
                                          ),
                                        ]),
                                        TextWithTap(
                                          "face_authentication_screen.id_".tr(
                                            namedArgs: {"id": "${user.getUid!}"},
                                          ).toUpperCase(),
                                          fontSize: 11,
                                          color: kIamonDarkerColor,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _rankTierIcon(user.getBattlePoints ?? 0),
                                  SizedBox(width: 4),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      TextWithTap(
                                        QuickHelp.convertToK(user.getBattleVictories ?? 0) + "victories_".tr(),
                                        color: kIamonDarkerColor,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 9,
                                      ),
                                      TextWithTap(
                                        QuickHelp.convertToK(user.getBattlePoints ?? 0) + " Pts",
                                        color: kIamonDarkerColor,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12,
                                        marginRight: 8,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                } else {
                  return SizedBox();
                }
              }),
            ),
          ),
        ),
        Visibility(
          visible: pkLeaders.isEmpty && !giftLoading,
          child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset('assets/svg/ic_empty_leader.svg', width: 120),
                    SizedBox(height: 16),
                    TextWithTap(
                      "leaderboard_screen.no_data".tr(),
                      color: kIamonDarkerColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ],
                ),
              ),
        ),
        Visibility(
          visible: giftLoading,
          child: QuickHelp.appLoading(),
        ),
      ],
    );
  }

  Widget getGifters() {
    Size size = MediaQuery.sizeOf(context);
    return ListView(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: 30,
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Stack(
              alignment: AlignmentDirectional.topCenter,
              clipBehavior: Clip.none,
              children: [
                if (allGiftGiver.length < 3)
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      ContainerCorner(
                        height: size.width / 6,
                        width: size.width / 6,
                        borderWidth: 4,
                        borderColor: kSilverColor,
                        borderRadius: 50,
                      ),
                      _medalFor(3)
                    ],
                  ),
                if (allGiftGiver.length >= 3)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: (){
                          QuickHelp.goToNavigatorScreen(
                            context,
                            UserProfileScreen(
                              currentUser: widget.currentUser,
                              mUser: allGiftGiver[2],
                              isFollowing: widget.currentUser!.getFollowing!
                                  .contains(allGiftGiver[2].objectId),
                            ),
                          );
                        },
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            QuickActions.avatarBorder(
                              allGiftGiver[2],
                              height: size.width / 6,
                              width: size.width / 6,
                              vipFrameWidth: size.width / 5,
                              vipFrameHeight: size.width / 5.2,
                              borderColor: kSilverColor,
                              borderWidth: 4,
                            ),
                            if(allGiftGiver[2].getIsUserVip! && !allGiftGiver[2].getCanUseAvatarFrame!)
                              Positioned(
                                right: 8,
                                bottom: 1,
                                child: _medalFor(3)
                              ),
                            if(!(allGiftGiver[2].getIsUserVip! && !allGiftGiver[2].getCanUseAvatarFrame!))
                              _medalFor(3)
                          ],
                        ),
                      ),
                      SizedBox(
                        width: size.width / 4,
                        child: TextWithTap(
                          allGiftGiver[2].getFullName!,
                          color: kIamonDarkerColor,
                          fontWeight: FontWeight.bold,
                          alignment: Alignment.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            "assets/images/icon_jinbi.png",
                            height: 17,
                            width: 17,
                          ),
                          TextWithTap(
                            QuickHelp.convertToK(
                              allGiftGiverCredits[2],
                            ),
                            color: kIamonDarkerColor,
                            marginLeft: 5,
                          ),
                        ],
                      ),
                    ],
                  ),
                _crownFor(3, size.width / 6),
              ],
            ),
            Stack(
              alignment: AlignmentDirectional.topCenter,
              clipBehavior: Clip.none,
              children: [
                if (allGiftGiver.length < 1)
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      ContainerCorner(
                        height: size.width / 4,
                        width: size.width / 4,
                        borderWidth: 5,
                        borderColor: kGoldenColor,
                        borderRadius: 50,
                      ),
                      _medalFor(1)
                    ],
                  ),
                if (allGiftGiver.length >= 1)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: (){
                          QuickHelp.goToNavigatorScreen(
                            context,
                            UserProfileScreen(
                              currentUser: widget.currentUser,
                              mUser: allGiftGiver[0],
                              isFollowing: widget.currentUser!.getFollowing!
                                  .contains(allGiftGiver[0].objectId),
                            ),
                          );
                        },
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            QuickActions.avatarBorder(
                              allGiftGiver[0],
                              height: size.width / 4,
                              width: size.width / 4,
                              vipFrameWidth: size.width / 3,
                              vipFrameHeight: size.width / 3.2,
                              borderWidth: 5,
                              borderColor: kGoldenColor,
                            ),
                            if(allGiftGiver[0].getIsUserVip! && !allGiftGiver[0].getCanUseAvatarFrame!)
                              Positioned(
                                right: 25,
                                bottom: 3,
                                child: _medalFor(1)
                              ),
                            if(!(allGiftGiver[0].getIsUserVip! && !allGiftGiver[0].getCanUseAvatarFrame!))
                              _medalFor(1)
                          ],
                        ),
                      ),
                      SizedBox(
                        width: size.width / 4,
                        child: TextWithTap(
                          allGiftGiver[0].getFullName!,
                          color: kIamonDarkerColor,
                          fontWeight: FontWeight.bold,
                          alignment: Alignment.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            "assets/images/icon_jinbi.png",
                            height: 17,
                            width: 17,
                          ),
                          TextWithTap(
                            QuickHelp.convertToK(
                                allGiftGiverCredits[0]),
                            color: kIamonDarkerColor,
                            marginLeft: 5,
                          ),
                        ],
                      ),
                    ],
                  ),
                _crownFor(1, size.width / 4),
              ],
            ),
            Stack(
              alignment: AlignmentDirectional.topCenter,
              clipBehavior: Clip.none,
              children: [
                if (allGiftGiver.length < 2)
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      ContainerCorner(
                        height: size.width / 6,
                        width: size.width / 6,
                        borderWidth: 4,
                        borderColor: kBronzeColor,
                        borderRadius: 50,
                      ),
                      ContainerCorner(
                        borderRadius: 50,
                        color: kBronzeColor,
                        child: TextWithTap(
                          "2",
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          marginLeft: 3,
                          marginRight: 3,
                        ),
                      )
                    ],
                  ),
                if (allGiftGiver.length >= 2)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: (){
                          QuickHelp.goToNavigatorScreen(
                            context,
                            UserProfileScreen(
                              currentUser: widget.currentUser,
                              mUser: allGiftGiver[1],
                              isFollowing: widget.currentUser!.getFollowing!
                                  .contains(allGiftGiver[1].objectId),
                            ),
                          );
                        },
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            QuickActions.avatarBorder(
                              allGiftGiver[1],
                              height: size.width / 6,
                              width: size.width / 6,
                              vipFrameWidth: size.width / 5,
                              vipFrameHeight: size.width / 5.2,
                              borderColor: kBronzeColor,
                              borderWidth: 4,
                            ),
                            if(allGiftGiver[1].getIsUserVip! && !allGiftGiver[1].getCanUseAvatarFrame!)
                              Positioned(
                                right: 8,
                                bottom: 1,
                                child: _medalFor(2),
                              ),
                            if(!(allGiftGiver[1].getIsUserVip! && !allGiftGiver[1].getCanUseAvatarFrame!))
                              ContainerCorner(
                                borderRadius: 50,
                                color: kBronzeColor,
                                child: TextWithTap(
                                  "2",
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  marginLeft: 3,
                                  marginRight: 3,
                                ),
                              )
                          ],
                        ),
                      ),
                      SizedBox(
                        width: size.width / 4,
                        child: TextWithTap(
                          allGiftGiver[1].getFullName!,
                          color: kIamonDarkerColor,
                          fontWeight: FontWeight.bold,
                          alignment: Alignment.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            "assets/images/icon_jinbi.png",
                            height: 17,
                            width: 17,
                          ),
                          TextWithTap(
                            QuickHelp.convertToK(
                                allGiftGiverCredits[1]),
                            color: kIamonDarkerColor,
                            marginLeft: 5,
                          ),
                        ],
                      ),
                    ],
                  ),
                _crownFor(2, size.width / 6),
              ],
            ),
            //if(allStreamLeaders.length < 2)
          ],
        ),

        // ─── منصة الترتيب ─────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Image.asset(
            'assets/images/rank_cart.png',
            width: double.infinity,
            fit: BoxFit.fitWidth,
          ),
        ),
        SizedBox(height: 10),
        Visibility(
          visible: !giftLoading,
          child: ContainerCorner(
            width: size.width,
            height: size.height,
            child: ListView(
              children: List.generate(allGiftGiver.length, (index) {
                if (index > 2) {
                  UserModel? user = allGiftGiver[index];
                  if(user != null) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10, left: 10, right: 10),
                      child: GestureDetector(
                        onTap: () => QuickHelp.goToNavigatorScreen(
                          context,
                          UserProfileScreen(
                            currentUser: widget.currentUser,
                            mUser: user,
                            isFollowing: widget.currentUser!.getFollowing!
                                .contains(user.objectId),
                          ),
                        ),
                        child: _rowCard(
                          isGifter: true,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _rankBadge(index),
                                    SizedBox(width: 8),
                                    QuickActions.avatarBorder(
                                      user,
                                      height: 45,
                                      width: 45,
                                      vipFrameWidth: 50,
                                      vipFrameHeight: 52,
                                      borderWidth: 0,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(children: [
                                            TextWithTap(
                                              user.getFullName!.capitalize,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color: kIamonDarkerColor,
                                              marginRight: 4,
                                            ),
                                            ClipRRect(
                                              borderRadius: BorderRadius.all(Radius.circular(15)),
                                              child: Image.asset(
                                                QuickHelp.levelImage(pointsInApp: user.getUserPoints!),
                                                width: 32,
                                              ),
                                            ),
                                          ]),
                                          TextWithTap(
                                            "face_authentication_screen.id_".tr(
                                              namedArgs: {"id": "${user.getUid!}"},
                                            ).toUpperCase(),
                                            fontSize: 11,
                                            color: kIamonDarkerColor,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _rankTierIcon(allGiftGiverCredits[index] ?? 0),
                                    SizedBox(width: 4),
                                    Image.asset("assets/images/icon_jinbi.png", height: 17, width: 17),
                                    TextWithTap(
                                      QuickHelp.convertToK(allGiftGiverCredits[index]),
                                      color: kIamonDarkerColor,
                                      marginLeft: 5,
                                      marginRight: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }else{
                    return SizedBox();
                  }
                } else {
                  return SizedBox();
                }
              }),
            ),
          ),
        ),
        Visibility(
          visible: allGiftGiver.isEmpty && !giftLoading,
          child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset('assets/svg/ic_empty_leader.svg', width: 120),
                    SizedBox(height: 16),
                    TextWithTap(
                      "leaderboard_screen.no_data".tr(),
                      color: kIamonDarkerColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ],
                ),
              ),
        ),
        Visibility(
          visible: giftLoading,
          child: QuickHelp.appLoading(),
        ),
      ],
    );
  }

  Widget getBody() {
    Size size = MediaQuery.sizeOf(context);
    return ListView(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: 30,
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Stack(
              alignment: AlignmentDirectional.topCenter,
              clipBehavior: Clip.none,
              children: [
                if (allStreamLeaders.length < 3)
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      ContainerCorner(
                        height: size.width / 6,
                        width: size.width / 6,
                        borderWidth: 4,
                        borderColor: kSilverColor,
                        borderRadius: 50,
                      ),
                      _medalFor(3)
                    ],
                  ),
                if (allStreamLeaders.length >= 3)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: (){
                          QuickHelp.goToNavigatorScreen(
                            context,
                            UserProfileScreen(
                              currentUser: widget.currentUser,
                              mUser: allStreamLeaders[2],
                              isFollowing: widget.currentUser!.getFollowing!
                                  .contains(allStreamLeaders[2].objectId),
                            ),
                          );
                        },
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            QuickActions.avatarBorder(
                              allStreamLeaders[2],
                              height: size.width / 6,
                              width: size.width / 6,
                              vipFrameWidth: size.width / 5,
                              vipFrameHeight: size.width / 5.2,
                              borderColor: kSilverColor,
                              borderWidth: 4,
                            ),
                            if(allStreamLeaders[2].getIsUserVip! && !allStreamLeaders[2].getCanUseAvatarFrame!)
                              Positioned(
                                right: 8,
                                bottom: 1,
                                child: ContainerCorner(
                                  borderRadius: 50,
                                  color: kBronzeColor,
                                  child: TextWithTap(
                                    "3",
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    marginLeft: 4,
                                    marginRight: 4,
                                  ),
                                ),
                              ),
                            if(!(allStreamLeaders[2].getIsUserVip! && !allStreamLeaders[2].getCanUseAvatarFrame!))
                              _medalFor(3)
                          ],
                        ),
                      ),
                      SizedBox(
                        width: size.width / 4,
                        child: TextWithTap(
                          allStreamLeaders[2].getFullName!,
                          color: kIamonDarkerColor,
                          fontWeight: FontWeight.bold,
                          alignment: Alignment.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            "assets/images/grade_welfare.png",
                            height: 17,
                            width: 17,
                          ),
                          TextWithTap(
                            QuickHelp.convertToK(
                              allStreamLeaders[2].getDiamondsTotal!,
                            ),
                            color: kIamonDarkerColor,
                            marginLeft: 5,
                          ),
                        ],
                      ),
                    ],
                  ),
                _crownFor(3, size.width / 6),
              ],
            ),
            Stack(
              alignment: AlignmentDirectional.topCenter,
              clipBehavior: Clip.none,
              children: [
                if (allStreamLeaders.length < 1)
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      ContainerCorner(
                        height: size.width / 4,
                        width: size.width / 4,
                        borderWidth: 5,
                        borderColor: kGoldenColor,
                        borderRadius: 50,
                      ),
                      _medalFor(1)
                    ],
                  ),
                if (allStreamLeaders.length >= 1)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: (){
                          QuickHelp.goToNavigatorScreen(
                            context,
                            UserProfileScreen(
                              currentUser: widget.currentUser,
                              mUser: allStreamLeaders[0],
                              isFollowing: widget.currentUser!.getFollowing!
                                  .contains(allStreamLeaders[0].objectId),
                            ),
                          );
                        },
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            QuickActions.avatarBorder(
                              allStreamLeaders[0],
                              height: size.width / 4,
                              width: size.width / 4,
                              borderWidth: 5,
                              vipFrameWidth: size.width / 3,
                              vipFrameHeight: size.width / 3.2,
                              borderColor: kGoldenColor,
                            ),
                            if(allStreamLeaders[0].getIsUserVip! && !allStreamLeaders[0].getCanUseAvatarFrame!)
                              Positioned(
                                right: 25,
                                bottom: 3,
                                child: _medalFor(1)
                              ),
                            if(!(allStreamLeaders[0].getIsUserVip! && !allStreamLeaders[0].getCanUseAvatarFrame!))
                              _medalFor(1)
                          ],
                        ),
                      ),
                      SizedBox(
                        width: size.width / 4,
                        child: TextWithTap(
                          allStreamLeaders[0].getFullName!,
                          color: kIamonDarkerColor,
                          fontWeight: FontWeight.bold,
                          alignment: Alignment.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            "assets/images/grade_welfare.png",
                            height: 17,
                            width: 17,
                          ),
                          TextWithTap(
                            QuickHelp.convertToK(
                                allStreamLeaders[0].getDiamondsTotal!),
                            color: kIamonDarkerColor,
                            marginLeft: 5,
                          ),
                        ],
                      ),
                    ],
                  ),
                _crownFor(1, size.width / 4),
              ],
            ),
            Stack(
              alignment: AlignmentDirectional.topCenter,
              clipBehavior: Clip.none,
              children: [
                if (allStreamLeaders.length < 2)
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      ContainerCorner(
                        height: size.width / 6,
                        width: size.width / 6,
                        borderWidth: 4,
                        borderColor: kBronzeColor,
                        borderRadius: 50,
                      ),
                      ContainerCorner(
                        borderRadius: 50,
                        color: kBronzeColor,
                        child: TextWithTap(
                          "2",
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          marginLeft: 3,
                          marginRight: 3,
                        ),
                      )
                    ],
                  ),
                if (allStreamLeaders.length >= 2)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: (){
                          QuickHelp.goToNavigatorScreen(
                            context,
                            UserProfileScreen(
                              currentUser: widget.currentUser,
                              mUser: allStreamLeaders[1],
                              isFollowing: widget.currentUser!.getFollowing!
                                  .contains(allStreamLeaders[1].objectId),
                            ),
                          );
                        },
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            QuickActions.avatarBorder(
                              allStreamLeaders[1],
                              height: size.width / 6,
                              width: size.width / 6,
                              vipFrameWidth: size.width / 5,
                              vipFrameHeight: size.width / 5.2,
                              borderColor: kBronzeColor,
                              borderWidth: 4,
                            ),
                            if(allStreamLeaders[1].getIsUserVip! && !allStreamLeaders[1].getCanUseAvatarFrame!)
                              Positioned(
                                right: 8,
                                bottom: 1,
                                child: _medalFor(2),
                              ),
                            if(!(allStreamLeaders[1].getIsUserVip! && !allStreamLeaders[1].getCanUseAvatarFrame!))
                              ContainerCorner(
                                borderRadius: 50,
                                color: kBronzeColor,
                                child: TextWithTap(
                                  "2",
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  marginLeft: 3,
                                  marginRight: 3,
                                ),
                              )
                          ],
                        ),
                      ),
                      SizedBox(
                        width: size.width / 4,
                        child: TextWithTap(
                          allStreamLeaders[1].getFullName!,
                          color: kIamonDarkerColor,
                          fontWeight: FontWeight.bold,
                          alignment: Alignment.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            "assets/images/grade_welfare.png",
                            height: 17,
                            width: 17,
                          ),
                          TextWithTap(
                            QuickHelp.convertToK(
                                allStreamLeaders[1].getDiamondsTotal!),
                            color: kIamonDarkerColor,
                            marginLeft: 5,
                          ),
                        ],
                      ),
                    ],
                  ),
                _crownFor(2, size.width / 6),
              ],
            ),
            //if(allStreamLeaders.length < 2)
          ],
        ),

        // ─── منصة الترتيب ─────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Image.asset(
            'assets/images/rank_cart.png',
            width: double.infinity,
            fit: BoxFit.fitWidth,
          ),
        ),
        SizedBox(height: 10),
        Visibility(
          visible: !loading,
          child: ContainerCorner(
            width: size.width,
            height: size.height,
            child: ListView(
              children: List.generate(allStreamLeaders.length, (index) {
                if (index > 2) {
                  UserModel user = allStreamLeaders[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: GestureDetector(
                      onTap: () => QuickHelp.goToNavigatorScreen(
                        context,
                        UserProfileScreen(
                          currentUser: widget.currentUser,
                          mUser: user,
                          isFollowing: widget.currentUser!.getFollowing!
                              .contains(user.objectId),
                        ),
                      ),
                      child: _rowCard(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _rankBadge(index),
                                  SizedBox(width: 8),
                                  QuickActions.avatarBorder(
                                    user,
                                    height: 45,
                                    width: 45,
                                    borderWidth: 0,
                                    vipFrameWidth: 50,
                                    vipFrameHeight: 52,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(children: [
                                          TextWithTap(
                                            user.getFullName!.capitalize,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: kIamonDarkerColor,
                                            marginRight: 4,
                                          ),
                                          ClipRRect(
                                            borderRadius: BorderRadius.all(Radius.circular(15)),
                                            child: Image.asset(
                                              QuickHelp.levelImage(pointsInApp: user.getUserPoints!),
                                              width: 32,
                                            ),
                                          ),
                                        ]),
                                        TextWithTap(
                                          "face_authentication_screen.id_".tr(
                                            namedArgs: {"id": "${user.getUid!}"},
                                          ).toUpperCase(),
                                          fontSize: 11,
                                          color: kIamonDarkerColor,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _rankTierIcon(user.getDiamondsTotal ?? 0),
                                  SizedBox(width: 4),
                                  Image.asset("assets/images/grade_welfare.png", height: 17, width: 17),
                                  TextWithTap(
                                    QuickHelp.convertToK(user.getDiamondsTotal!),
                                    color: kIamonDarkerColor,
                                    marginLeft: 5,
                                    marginRight: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                } else {
                  return SizedBox();
                }
              }),
            ),
          ),
        ),
        Visibility(
          visible: allStreamLeaders.isEmpty && !loading,
          child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset('assets/svg/ic_empty_leader.svg', width: 120),
                    SizedBox(height: 16),
                    TextWithTap(
                      "leaderboard_screen.no_data".tr(),
                      color: kIamonDarkerColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ],
                ),
              ),
        ),
        Visibility(
          visible: loading,
          child: QuickHelp.appLoading(),
        ),
      ],
    );
  }
}
