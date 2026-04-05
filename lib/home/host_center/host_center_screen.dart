// ignore_for_file: must_be_immutable

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:juodylive/helpers/quick_actions.dart';
import 'package:juodylive/ui/container_with_corner.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import '../../helpers/quick_help.dart';
import '../../models/LiveStreamingModel.dart';
import '../../models/UserModel.dart';
import '../../ui/text_with_tap.dart';
import '../../utils/colors.dart';
import '../host_rules/host_rules_screen.dart';
import '../rank/rank_screen.dart';
import '../reward/reward_screen.dart';
import '../task_rules/task_rules_screen.dart';

class HostCenterScreen extends StatefulWidget {
  UserModel? currentUser;
  HostCenterScreen({this.currentUser, super.key});

  @override
  State<HostCenterScreen> createState() => _HostCenterScreenState();
}

class _HostCenterScreenState extends State<HostCenterScreen> {
  // ── بيانات البث الشهري ────────────────────────────────────────────────────
  int _monthlyDiamonds  = 0;
  String _monthlyDuration = "00:00:00";
  int _totalStreams      = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMonthlyData();
  }

  Future<void> _loadMonthlyData() async {
    try {
      final now    = DateTime.now();
      final start  = DateTime(now.year, now.month, 1);

      final q = QueryBuilder<LiveStreamingModel>(LiveStreamingModel())
        ..whereEqualTo(LiveStreamingModel.keyAuthorId, widget.currentUser!.objectId!)
        ..whereGreaterThanOrEqualsTo(LiveStreamingModel.keyCreatedAt, start)
        ..setLimit(1000);

      final r = await q.query();
      if (r.success && r.results != null) {
        int totalDiamonds = 0;
        int totalSeconds  = 0;
        for (final item in r.results!) {
          final live = item as LiveStreamingModel;
          totalDiamonds += live.getDiamonds ?? 0;
        }
        _totalStreams = r.results!.length;

        if (mounted) {
          setState(() {
            _monthlyDiamonds = totalDiamonds;
            _monthlyDuration = QuickHelp.getTimeByDate(
              date: DateTime.fromMillisecondsSinceEpoch(totalSeconds * 1000),
            );
            _loading = false;
          });
        }
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint("HostCenter load error: $e");
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = QuickHelp.isDarkMode(context);
    Size size   = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: BackButton(
          color: isDark ? Colors.white : kContentColorLightTheme,
        ),
        title: TextWithTap(
          "host_center_screen.host_center".tr(),
          fontWeight: FontWeight.bold,
        ),
        actions: [
          // ✅ زر قواعد المضيف
          IconButton(
            onPressed: () => QuickHelp.goToNavigatorScreen(
              context,
              HostRulesScreen(currentUser: widget.currentUser),
            ),
            icon: Icon(
              Icons.info_outline,
              color: isDark ? Colors.white : kContentColorLightTheme,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadMonthlyData,
        child: ContainerCorner(
          imageDecoration: "assets/images/host_center_bg.png",
          borderWidth: 0,
          height: size.height,
          width: size.width,
          child: ListView(
            padding: const EdgeInsets.only(left: 15, right: 15, top: 20),
            children: [
              // ── رأس الصفحة ──────────────────────────────────────────────
              Row(
                children: [
                  QuickActions.avatarWidget(widget.currentUser!, height: 50, width: 50),
                  TextWithTap(
                    widget.currentUser!.getFullName!,
                    fontWeight: FontWeight.bold,
                    fontSize: size.width / 18,
                    marginLeft: 10,
                  ),
                ],
              ),

              // ── بطاقة البيانات الشهرية ────────────────────────────────
              ContainerCorner(
                width: size.width,
                borderRadius: 10,
                color: Colors.white,
                marginTop: 25,
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextWithTap(
                            "host_center_screen.monthly_live_data".tr(),
                            fontWeight: FontWeight.bold,
                            color: kContentColorLightTheme,
                          ),
                          // ✅ زر المزيد → تصنيف المضيفين
                          GestureDetector(
                            onTap: () => QuickHelp.goToNavigatorScreen(
                              context,
                              RankingScreen(currentUser: widget.currentUser!),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextWithTap(
                                  "more_".tr().toLowerCase(),
                                  fontSize: 12,
                                  color: kPrimaryColor,
                                ),
                                const Icon(Icons.arrow_forward_ios,
                                    color: kPrimaryColor, size: 10),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),
                      _loading
                          ? const Center(child: CircularProgressIndicator())
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _statItem(
                                  value: QuickHelp.convertNumberToK(_monthlyDiamonds),
                                  label: "host_center_screen.u_coin_income".tr(),
                                  icon: "assets/svg/ic_diamond.svg",
                                ),
                                _statItem(
                                  value: _totalStreams.toString(),
                                  label: "host_center_screen.live_duration_this_moth".tr(),
                                  icon: "assets/svg/ht_live.svg",
                                  fallback: Icons.live_tv,
                                ),
                              ],
                            ),
                    ],
                  ),
                ),
              ),

              // ── تحدي الضوء النجمي + مهام المضيف ─────────────────────
              ContainerCorner(
                width: size.width,
                borderRadius: 10,
                color: Colors.white,
                marginTop: 20,
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // ✅ تحدي الضوء النجمي → شاشة المكافآت
                      _menuRow(
                        title: "host_center_screen.starlight_challenge".tr(),
                        onTap: () => QuickHelp.goToNavigatorScreen(
                          context,
                          RewardScreen(currentUser: widget.currentUser!),
                        ),
                      ),
                      const SizedBox(height: 15),
                      const Divider(height: 1),
                      const SizedBox(height: 15),
                      // ✅ مهام المضيف → شاشة قواعد المهام
                      _menuRow(
                        title: "host_center_screen.host_tasks".tr(),
                        onTap: () => QuickHelp.goToNavigatorScreen(
                          context,
                          TaskRulesScreen(currentUser: widget.currentUser),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── بطاقة الميزات ─────────────────────────────────────────
              ContainerCorner(
                width: size.width,
                borderRadius: 10,
                color: Colors.white,
                marginTop: 20,
                marginBottom: 20,
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextWithTap(
                        "host_center_screen.features_".tr(),
                        fontWeight: FontWeight.bold,
                        color: kContentColorLightTheme,
                        marginBottom: 18,
                      ),
                      GridView.count(
                        crossAxisCount: 4,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 0.85,
                        children: [
                          // ✅ عملاتي uCoins → المحفظة/الدخل
                          _featureItem(
                            caption: "host_center_screen.my_u_coins".tr(),
                            icon: "assets/svg/ic_diamond.svg",
                            onTap: () => QuickHelp.goToNavigatorScreen(
                              context,
                              RankingScreen(currentUser: widget.currentUser!),
                            ),
                          ),
                          // ✅ أهم المعجبين → تصنيف المعجبين
                          _featureItem(
                            caption: "host_center_screen.top_fans".tr(),
                            icon: "assets/images/ic_fans_badge.png",
                            isAsset: true,
                            onTap: () => QuickHelp.goToNavigatorScreen(
                              context,
                              RankingScreen(currentUser: widget.currentUser!),
                            ),
                          ),
                          // ✅ قواعد المضيف
                          _featureItem(
                            caption: "host_rules_screen.host_rules".tr(),
                            iconData: Icons.rule,
                            onTap: () => QuickHelp.goToNavigatorScreen(
                              context,
                              HostRulesScreen(currentUser: widget.currentUser),
                            ),
                          ),
                          // ✅ المكافآت
                          _featureItem(
                            caption: "host_center_screen.feedback_".tr(),
                            iconData: Icons.star_outline,
                            onTap: () => QuickHelp.goToNavigatorScreen(
                              context,
                              RewardScreen(currentUser: widget.currentUser!),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── ويدجت إحصائية ─────────────────────────────────────────────────────────
  Widget _statItem({
    required String value,
    required String label,
    String? icon,
    IconData? fallback,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              _svgOrIcon(icon, fallback),
            const SizedBox(width: 4),
            TextWithTap(
              value,
              color: kContentColorLightTheme.withOpacity(0.8),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ],
        ),
        TextWithTap(
          label,
          color: kGrayColor,
          fontSize: 11,
          marginTop: 8,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _svgOrIcon(String path, IconData? fallback) {
    try {
      if (path.endsWith('.svg')) {
        return SvgPicture.asset(path, width: 16, height: 16, color: kPrimaryColor);
      }
      return Image.asset(path, width: 16, height: 16);
    } catch (_) {
      return Icon(fallback ?? Icons.circle, size: 16, color: kPrimaryColor);
    }
  }

  // ── صف قائمة بزر تنقل ─────────────────────────────────────────────────────
  Widget _menuRow({required String title, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextWithTap(
            title,
            fontWeight: FontWeight.bold,
            color: kContentColorLightTheme,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextWithTap(
                "host_center_screen.view_more".tr().toLowerCase(),
                fontSize: 12,
                color: kPrimaryColor,
              ),
              const Icon(Icons.arrow_forward_ios, color: kPrimaryColor, size: 10),
            ],
          ),
        ],
      ),
    );
  }

  // ── عنصر ميزة ─────────────────────────────────────────────────────────────
  Widget _featureItem({
    required String caption,
    String? icon,
    bool isAsset = false,
    IconData? iconData,
    required VoidCallback onTap,
  }) {
    Size size = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ContainerCorner(
            borderRadius: 12,
            color: kPrimaryColor.withOpacity(0.08),
            borderWidth: 0,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: _buildIcon(icon, isAsset, iconData, size),
            ),
          ),
          const SizedBox(height: 6),
          TextWithTap(
            caption,
            fontSize: size.width / 38,
            textAlign: TextAlign.center,
            marginLeft: 2,
            marginRight: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildIcon(String? icon, bool isAsset, IconData? iconData, Size size) {
    if (iconData != null) {
      return Icon(iconData, color: kPrimaryColor, size: size.width / 14);
    }
    if (icon != null) {
      if (isAsset) {
        return Image.asset(icon, width: size.width / 14, height: size.width / 14);
      }
      try {
        return SvgPicture.asset(icon,
            width: size.width / 14, height: size.width / 14, color: kPrimaryColor);
      } catch (_) {
        return Icon(Icons.star, color: kPrimaryColor, size: size.width / 14);
      }
    }
    return Icon(Icons.circle, color: kPrimaryColor, size: size.width / 14);
  }
}
