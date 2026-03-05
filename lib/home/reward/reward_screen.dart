// ignore_for_file: must_be_immutable

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

class _RewardScreenState extends State<RewardScreen> with TickerProviderStateMixin {
  int tabsLength = 2;
  int tabIndex = 0;

  late TabController _tabController;
  final ScrollController _carouselController = ScrollController();

  var slideBanner = [
    "assets/images/img_host_rules.png",
    "assets/images/img_live_task.png"
  ];

  var screensToGo = [];

  int vipRewardAmount = 35000;
  int partyRewardAmount = 200;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: tabsLength, initialIndex: tabIndex)
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
          // Header Section: Sliders and Tabs
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
                    labelColor: isDark ? Colors.white : Colors.black,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    tabs: [
                      Tab(text: "reward_screen.live_".tr()),
                      Tab(text: "reward_screen.daily_".tr()),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
          
          // Fixed Rewards Section (VIP & Party)
          ContainerCorner(
            borderWidth: 0,
            marginLeft: 15,
            marginRight: 15,
            color: isDark ? kContentColorLightTheme : Colors.white,
            borderRadius: 10,
            marginTop: 20,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                children: [
                  buildVipReward(size, isDark),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 5), child: Divider()),
                  buildPartyReward(size, isDark),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 10),

          // Dynamic Task List based on Tab Selection
          Column(
            children: tabIndex == 0 
              ? buildLiveTasksList(isDark) 
              : buildDailyTasksList(isDark),
          ),
          
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // دالة بناء كافة مستويات مهام البث (من S إلى I) كما في ملف القواعد
  List<Widget> buildLiveTasksList(bool isDark) {
    var liveTasks = [
      {"level": "S", "reward": "70,000", "hours": "4", "req": "50M"},
      {"level": "A", "reward": "50,000", "hours": "4", "req": "22M"},
      {"level": "B", "reward": "40,000", "hours": "3", "req": "10M"},
      {"level": "C", "reward": "35,000", "hours": "3", "req": "7M"},
      {"level": "D", "reward": "28,000", "hours": "3", "req": "4M"},
      {"level": "E", "reward": "18,000", "hours": "3", "req": "2M"},
      {"level": "F", "reward": "12,000", "hours": "3", "req": "1.2M"},
      {"level": "G", "reward": "9,000", "hours": "3", "req": "900K"},
      {"level": "H", "reward": "5,000", "hours": "2", "req": "300K"},
      {"level": "I", "reward": "3,000", "hours": "2", "req": "150K"},
    ];

    return liveTasks.map((task) => taskItem(
      title: "مهمة المضيف مستوى ${task['level']}",
      subtitle: "هدف الأسبوع: ${task['req']} | بث ${task['hours']} ساعات",
      reward: task['reward']!,
      icon: _getIconForLevel(task['level']!),
      isDark: isDark,
      btnText: "بث الآن",
      onTap: () => QuickHelp.goToNavigatorScreen(context, HomeScreen(currentUser: widget.currentUser, initialTabIndex: 0)),
    )).toList();
  }

  // أيقونة متغيرة حسب قيمة المستوى
  IconData _getIconForLevel(String level) {
    if (level == "S" || level == "A") return Icons.workspace_premium;
    if (level == "B" || level == "C" || level == "D") return Icons.stars;
    return Icons.live_tv;
  }

  // دالة بناء المهام اليومية العامة
  List<Widget> buildDailyTasksList(bool isDark) {
    var dailyTasks = [
      {"title": "شاهد البث المباشر", "desc": "شاهد لمدة 5 دقائق", "reward": "100", "icon": Icons.remove_red_eye},
      {"title": "مهمة الحفلة اليومية", "desc": "تحدث في الميكروفون لمدة 10 دقائق", "reward": "200", "icon": Icons.mic_external_on},
      {"title": "أرسل هدايا", "desc": "أرسل أي هدية لمضيف", "reward": "500", "icon": Icons.card_giftcard},
    ];

    return dailyTasks.map((task) => taskItem(
      title: task['title'] as String,
      subtitle: task['desc'] as String,
      reward: task['reward'] as String,
      icon: task['icon'] as IconData,
      isDark: isDark,
      btnText: "تنفيذ",
      onTap: () => QuickHelp.goBackToPreviousPage(context),
    )).toList();
  }

  // الـ Widget الموحد لعرض كل مهمة في القائمة
  Widget taskItem({
    required String title,
    required String subtitle,
    required String reward,
    required IconData icon,
    required bool isDark,
    required String btnText,
    required VoidCallback onTap,
  }) {
    return ContainerCorner(
      marginTop: 10,
      marginLeft: 15,
      marginRight: 15,
      borderRadius: 12,
      color: isDark ? kContentColorLightTheme : Colors.white,
      child: ListTile(
        leading: ContainerCorner(
          paddingAll: 8,
          color: kPrimaryColor.withOpacity(0.1),
          borderRadius: 8,
          child: Icon(icon, color: kPrimaryColor, size: 24),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : Colors.black)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            pointsBadge(int.parse(reward.replaceAll(',', ''))),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: onTap,
              child: ContainerCorner(
                color: kPrimaryColor,
                borderRadius: 20,
                paddingLeft: 10,
                paddingRight: 10,
                paddingTop: 4,
                paddingBottom: 4,
                child: Text(btnText, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
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
          style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor, shape: const StadiumBorder(), elevation: 0),
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset("assets/images/icon_jinbi.png", height: 10, width: 10),
            Text(" +$amount", style: const TextStyle(color: earnPointColor, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
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
