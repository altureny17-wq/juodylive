// ignore_for_file: must_be_immutable

import 'package:auto_size_text/auto_size_text.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../helpers/quick_help.dart';
import '../../models/UserModel.dart';
import '../../ui/container_with_corner.dart';
import '../../ui/text_with_tap.dart';
import '../../utils/colors.dart';
import '../guardian_vip/guardian_and_vip_store_screen.dart';
import '../home_screen.dart';
import '../host_rules/host_rules_screen.dart';
import '../task_rules/task_rules_screen.dart';

class RewardScreen extends StatefulWidget {
  UserModel? currentUser;

  RewardScreen({this.currentUser, Key? key})
      : super(key: key);

  @override
  State<RewardScreen> createState() => _RewardScreenState();
}

class _RewardScreenState extends State<RewardScreen>
    with TickerProviderStateMixin {
  int tabsLength = 2;
  int tabIndex = 0;

  late TabController _tabController;
  final CarouselController _controller = CarouselController();

  var slideBanner = [
    "assets/images/img_host_rules.png",
    "assets/images/img_live_task.png"
  ];

  var screensToGo = [];

  int current = 0;
  int vipRewardAmount = 35000;
  int partyRewardAmount = 200;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(vsync: this, length: tabsLength, initialIndex: tabIndex)
          ..addListener(() {
            setState(() {
              tabIndex = _tabController.index;
            });
          });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    screensToGo = [
      HostRulesScreen(currentUser: widget.currentUser),
      TaskRulesScreen(currentUser: widget.currentUser),
    ];

    bool isDark = QuickHelp.isDarkMode(context);
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: isDark ? kContentDarkShadow : kGrayWhite,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        leading: BackButton(
          color: isDark ? Colors.white : kContentColorLightTheme,
        ),
        title: TextWithTap(
          "reward_screen.reward_".tr(),
          fontWeight: FontWeight.bold,
        ),
        actions: [
          IconButton(
            onPressed: () => confirmToRedeem(),
            icon: Icon(
              Icons.help_outline,
              color: isDark ? Colors.white : kContentColorLightTheme,
            ),
          ),
        ],
      ),
      body: ListView(
        children: [
          ContainerCorner(
            color: isDark ? kContentColorLightTheme : Colors.white,
            borderWidth: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                sliders(),
                const SizedBox(height: 10),
                ContainerCorner(
                  height: 40,
                  width: size.width,
                  child: TabBar(
                    isScrollable: true,
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.label,
                    dividerColor: kTransparentColor,
                    unselectedLabelColor: kTabIconDefaultColor,
                    indicatorWeight: 3.0,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 20),
                    indicator: UnderlineTabIndicator(
                      borderSide: BorderSide(
                        width: 3.0,
                        color: isDark ? Colors.white : kPrimaryColor,
                      ),
                      borderRadius: const BorderRadius.all(Radius.circular(50)),
                    ),
                    onTap: (index) {
                      setState(() {
                        tabIndex = index;
                      });
                    },
                    labelColor: isDark ? Colors.white : Colors.black,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    tabs: [
                      Tab(text: "reward_screen.live_".tr()),
                      Tab(text: "reward_screen.daily_".tr()),
                    ],
                  ),
                ),
                const SizedBox(height: 10), // بديل لـ paddingBottom
              ],
            ),
          ),
          
          ContainerCorner(
            borderWidth: 0,
            marginLeft: 15,
            marginRight: 15,
            color: isDark ? kContentColorLightTheme : Colors.white,
            borderRadius: 10,
            marginTop: 20,
            child: Padding(
              padding: const EdgeInsets.all(10.0), // بديل لـ paddingAll
              child: Column(
                children: [
                  buildVipReward(size, isDark),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(),
                  ),
                  buildPartyReward(size, isDark),
                ],
              ),
            ),
          ),
          
          // عرض محتوى المهام (Daily & Live)
          if(tabIndex == 0) 
             _emptyTaskState("No Live Tasks")
          else
             _emptyTaskState("No Daily Tasks"),
        ],
      ),
    );
  }

  Widget sliders() {
    Size size = MediaQuery.of(context).size;
    return ContainerCorner(
      marginTop: 10,
      height: 160,
      width: size.width,
      child: CarouselView(
        controller: _controller,
        itemExtent: size.width - 40,
        shrinkExtent: size.width - 80,
        children: List.generate(slideBanner.length, (index) {
          return GestureDetector(
            onTap: () {
              if (screensToGo.length > index) {
                QuickHelp.goToNavigatorScreen(context, screensToGo[index]);
              }
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                slideBanner[index],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.broken_image),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget buildVipReward(Size size, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Image.asset("assets/images/img_bg_reward_vip.png", height: 50, width: 50),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text("reward_screen.VIP_daily_rewards".tr(), 
                      style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                    const SizedBox(width: 5),
                    vipIconType(),
                  ],
                ),
                pointsBadge(vipRewardAmount),
              ],
            )
          ],
        ),
        ElevatedButton(
          onPressed: () => QuickHelp.goToNavigatorScreen(context, GuardianAndVipStoreScreen(currentUser: widget.currentUser)),
          style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor, shape: const StadiumBorder()),
          child: Text("reward_screen.vip_".tr(), style: const TextStyle(color: Colors.white)),
        )
      ],
    );
  }

  Widget buildPartyReward(Size size, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const CircleAvatar(radius: 20, backgroundColor: Colors.blueAccent, child: Icon(Icons.mic, color: Colors.white, size: 20)),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("reward_screen.party_reward".tr(), 
                  style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                pointsBadge(partyRewardAmount),
              ],
            )
          ],
        ),
        TextButton(
          onPressed: () => QuickHelp.goToNavigatorScreen(context, HomeScreen(currentUser: widget.currentUser, initialTabIndex: 1)),
          child: Text("reward_screen.go_".tr(), style: const TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold)),
        )
      ],
    );
  }

  Widget pointsBadge(int amount) {
    return ContainerCorner(
      color: earnPointColor.withOpacity(0.1),
      borderRadius: 20,
      marginTop: 5,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // بديل لـ paddingAll
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset("assets/images/icon_jinbi.png", height: 12, width: 12),
            Text(" +$amount", style: const TextStyle(color: earnPointColor, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _emptyTaskState(String message) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Center(child: Text(message, style: const TextStyle(color: Colors.grey))),
    );
  }

  Widget vipIconType() {
    return Image.asset("assets/images/icon_vip_3.webp", height: 15);
  }

  void confirmToRedeem() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("reward_screen.reward_rule".tr()),
        content: Text("reward_screen.reward_rule_explain".tr()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("confirm_".tr())),
        ],
      ),
    );
  }
}
