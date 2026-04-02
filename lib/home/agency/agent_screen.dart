// ignore_for_file: must_be_immutable

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animation_progress_bar/flutter_animation_progress_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import '../../helpers/quick_help.dart';
import '../../models/AgencyInvitationModel.dart';
import '../../models/UserModel.dart';
import '../../ui/container_with_corner.dart';
import '../../ui/text_with_tap.dart';
import '../../utils/colors.dart';
import '../rank/rank_screen.dart';
import '../reward/reward_screen.dart';
import 'add_host_screen.dart';
import 'invitation_report_screen.dart';
import 'invite_agent_screen.dart';
import 'leave_agency_screen.dart';

class AgentScreen extends StatefulWidget {
  UserModel? currentUser;
  AgentScreen({this.currentUser, Key? key}) : super(key: key);
  @override
  State<AgentScreen> createState() => _AgentScreenState();
}

class _AgentScreenState extends State<AgentScreen> {
  int invitedHosts  = 0;
  int invitedAgents = 0;
  int points        = 0;
  int coins         = 0;
  int commissionRate = 30;
  int aPercent = 30;
  int bPercent = 70;
  int currentPoints  = 0;
  int expectedPoints = 100;
  int totalEarnings  = 0;
  int myCommission   = 0;
  bool _loading = true;

  late List<String> menuIcons;
  late List<String> menuCaption;

  @override
  void initState() {
    super.initState();
    menuIcons = [
      "assets/images/ic_agent_rank.png",
      "assets/images/ic_activity_center.png",
      "assets/images/ic_host_application.png",
      "assets/images/ic_reward.png",
    ];
    menuCaption = [
      "agent_screen.agent_raking".tr(),
      "agent_screen.activity_centre".tr(),
      "agent_screen.host_application".tr(),
      "agent_screen.reward_".tr(),
    ];
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final qHosts = QueryBuilder<AgencyInvitationModel>(AgencyInvitationModel())
        ..whereEqualTo(AgencyInvitationModel.keyAgentId, widget.currentUser!.objectId!)
        ..whereEqualTo(AgencyInvitationModel.keyInvitationStatus, AgencyInvitationModel.keyStatusAccepted);
      final rHosts = await qHosts.count();
      if (rHosts.success) invitedHosts = rHosts.count ?? 0;

      final qAgents = QueryBuilder<AgencyInvitationModel>(AgencyInvitationModel())
        ..whereEqualTo(AgencyInvitationModel.keyHostId, widget.currentUser!.objectId!);
      final rAgents = await qAgents.count();
      if (rAgents.success) invitedAgents = rAgents.count ?? 0;

      coins  = widget.currentUser?.getCredits ?? 0;
      points = widget.currentUser?.getDiamondsTotal ?? 0;
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      debugPrint("AgentScreen _loadData error: $e");
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onMenuTap(int index) {
    switch (index) {
      case 0:
        QuickHelp.goToNavigatorScreen(context, RankingScreen(currentUser: widget.currentUser!));
        break;
      case 1:
        QuickHelp.goToNavigatorScreen(context, InvitationReportScreen(currentUser: widget.currentUser));
        break;
      case 2:
        QuickHelp.goToNavigatorScreen(context, AddHostScreen(currentUser: widget.currentUser));
        break;
      case 3:
        QuickHelp.goToNavigatorScreen(context, RewardScreen(currentUser: widget.currentUser!));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = QuickHelp.isDarkMode(context);
    return Scaffold(
      backgroundColor: isDark ? kContentDarkShadow : kGrayWhite,
      appBar: AppBar(
        elevation: 0.5,
        automaticallyImplyLeading: false,
        leading: BackButton(color: isDark ? Colors.white : kContentColorLightTheme),
        centerTitle: true,
        title: TextWithTap("agent_screen.agent_".tr(), fontWeight: FontWeight.w600),
        actions: [
          IconButton(
            onPressed: () => QuickHelp.goToNavigatorScreen(
              context, InvitationReportScreen(currentUser: widget.currentUser)),
            icon: Icon(Icons.notifications_none,
                color: isDark ? Colors.white : kContentColorLightTheme),
          ),
          IconButton(
            onPressed: () => QuickHelp.goToNavigatorScreen(
              context, LeaveAgencyScreen(currentUser: widget.currentUser)),
            icon: Icon(Icons.exit_to_app,
                color: isDark ? Colors.white : kContentColorLightTheme),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.only(top: 15, left: 15, right: 15),
                children: [
                  _hostAndAgentNumbers(),
                  _coinsAndPointsNumbers(),
                  _menus(),
                  _details(),
                ],
              ),
            ),
    );
  }

  Widget _hostAndAgentNumbers() {
    Size size = MediaQuery.of(context).size;
    bool isDark = QuickHelp.isDarkMode(context);
    return ContainerCorner(
      color: isDark ? kContentColorLightTheme : Colors.white,
      width: size.width,
      borderRadius: 8,
      child: Padding(
        padding: const EdgeInsets.only(top: 15, bottom: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(mainAxisSize: MainAxisSize.min, children: [
              TextWithTap("$invitedHosts", fontWeight: FontWeight.w900, fontSize: 22, marginBottom: 5),
              TextWithTap("agent_screen.host_".tr()),
              ContainerCorner(
                height: 30, borderRadius: 50, marginTop: 8,
                color: earnCashColor.withOpacity(0.2),
                onTap: () => QuickHelp.goToNavigatorScreen(context, AddHostScreen(currentUser: widget.currentUser)),
                child: TextWithTap("agent_screen.add_host".tr(),
                    alignment: Alignment.center, color: earnCashColor,
                    fontWeight: FontWeight.w700, fontSize: 10,
                    marginLeft: 15, marginRight: 15),
              ),
            ]),
            ContainerCorner(color: kGrayColor, width: 0.5, height: 40),
            Column(mainAxisSize: MainAxisSize.min, children: [
              TextWithTap("$invitedAgents", fontWeight: FontWeight.w900, fontSize: 22, marginBottom: 5),
              TextWithTap("agent_screen.invite_agent".tr()),
              ContainerCorner(
                height: 30, borderRadius: 50, marginTop: 8,
                color: kPrimaryColor.withOpacity(0.2),
                onTap: () => QuickHelp.goToNavigatorScreen(context, InviteAgentScreen(currentUser: widget.currentUser)),
                child: TextWithTap("agent_screen.invite_agent".tr(),
                    alignment: Alignment.center, color: kPrimaryColor,
                    fontWeight: FontWeight.w700, fontSize: 10,
                    marginLeft: 15, marginRight: 15),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _coinsAndPointsNumbers() {
    Size size = MediaQuery.of(context).size;
    bool isDark = QuickHelp.isDarkMode(context);
    return ContainerCorner(
      color: isDark ? kContentColorLightTheme : Colors.white,
      width: size.width, borderRadius: 8, marginTop: 10, marginBottom: 10,
      child: Padding(
        padding: const EdgeInsets.only(top: 15, bottom: 25),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(mainAxisSize: MainAxisSize.min, children: [
              TextWithTap("$points", fontWeight: FontWeight.w900, fontSize: 22, marginBottom: 5),
              Row(mainAxisSize: MainAxisSize.min, children: [
                Image.asset("assets/images/ic_jifen_wode.webp", height: 15, width: 15),
                TextWithTap("agent_screen.remaining_points".tr(), marginLeft: 2),
              ]),
            ]),
            ContainerCorner(color: kGrayColor, width: 0.5, height: 40),
            Column(mainAxisSize: MainAxisSize.min, children: [
              TextWithTap("$coins", fontWeight: FontWeight.w900, fontSize: 22, marginBottom: 5),
              Row(mainAxisSize: MainAxisSize.min, children: [
                Image.asset("assets/images/icon_jinbi.png", height: 15, width: 15),
                TextWithTap("agent_screen.coins_trading".tr(), marginLeft: 2),
              ]),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _menus() {
    Size size = MediaQuery.of(context).size;
    bool isDark = QuickHelp.isDarkMode(context);
    return ContainerCorner(
      width: size.width, borderWidth: 0, height: 107, marginTop: 10,
      child: GridView.count(
        crossAxisCount: 2, childAspectRatio: 4.6,
        crossAxisSpacing: 10, mainAxisSpacing: 10,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(menuCaption.length, (index) {
          return GestureDetector(
            onTap: () => _onMenuTap(index),
            child: Stack(
              alignment: AlignmentDirectional.topEnd,
              children: [
                ContainerCorner(
                  borderRadius: 8, borderWidth: 0,
                  color: isDark ? kContentColorLightTheme : Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(menuIcons[index], height: 18, width: 18),
                        TextWithTap(menuCaption[index], marginLeft: 8),
                      ],
                    ),
                  ),
                ),
                Visibility(
                  visible: index == 0 || index == 3,
                  child: ContainerCorner(
                    radiusTopRight: 10, radiusBottomLeft: 10, borderWidth: 0,
                    colors: [earnPointColor, kSendGiftColor],
                    height: 15, width: 38,
                    child: TextWithTap(
                      index == 0 ? "agent_screen.hot_".tr() : "agent_screen.new_".tr(),
                      fontSize: 8, alignment: Alignment.center,
                      color: Colors.white, fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _details() {
    Size size = MediaQuery.of(context).size;
    bool isDark = QuickHelp.isDarkMode(context);
    return ContainerCorner(
      color: isDark ? kContentColorLightTheme : Colors.white,
      width: size.width, borderRadius: 8, marginBottom: 10,
      child: Padding(
        padding: const EdgeInsets.only(left: 15, right: 15),
        child: Column(children: [
          TextWithTap("agent_screen.earnings_in_recent_days".tr(), marginTop: 15),
          TextWithTap(QuickHelp.getDateFormatted(DateTime.now())),
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 10),
            child: Divider(color: kGrayColor.withOpacity(0.2), height: 3),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                TextWithTap("agent_screen.commission_rate".tr(), marginRight: 5),
                const Icon(Icons.info_outline, size: 15),
              ]),
              TextWithTap("$commissionRate%", color: kPrimaryColor),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextWithTap("B$bPercent%", marginRight: 5),
              TextWithTap("A$aPercent%"),
            ],
          ),
          const SizedBox(height: 10),
          FAProgressBar(
            currentValue: currentPoints + 0.0, size: 5,
            maxValue: expectedPoints + 0.0, changeColorValue: 0,
            changeProgressColor: kPrimaryColor,
            backgroundColor: kPrimaryColor.withOpacity(0.2),
            progressColor: Colors.lightBlue,
            animatedDuration: const Duration(seconds: 2),
            direction: Axis.horizontal, verticalDirection: VerticalDirection.up,
            displayText: "%",
            displayTextStyle: GoogleFonts.roboto(color: kRoseVip, fontSize: 1),
            formatValueFixed: 0,
          ),
          TextWithTap(
            "agent_screen.points_away_from_level".tr(
                namedArgs: {"number": "${expectedPoints - currentPoints}"}),
            marginTop: 10, marginBottom: 20,
          ),
          GestureDetector(
            onTap: () => QuickHelp.goToNavigatorScreen(
              context, InvitationReportScreen(currentUser: widget.currentUser)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextWithTap("agent_screen.earnings_".tr(), marginRight: 5),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  TextWithTap("agent_screen.check_details".tr(),
                      color: kPrimaryColor, fontSize: 12),
                  const Icon(Icons.arrow_forward_ios, color: kPrimaryColor, size: 9),
                ]),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 10),
            child: Divider(color: kGrayColor.withOpacity(0.2), height: 3),
          ),
          _pointsDetails(caption: "agent_screen.earnings_in_recent_days".tr(), amount: totalEarnings),
          const SizedBox(height: 10),
          _pointsDetails(caption: "agent_screen.mmy_commission".tr(), amount: myCommission),
          ContainerCorner(
            color: kGrayColor.withOpacity(0.1),
            marginLeft: 10, marginRight: 10, marginTop: 15, borderRadius: 4,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(children: [
                _detailOptionWithInfo(caption: "agent_screen.host_earnings".tr(), amount: totalEarnings),
                const SizedBox(height: 10),
                _pointsDetails(caption: "agent_screen.mmy_commission".tr(), amount: myCommission),
                const SizedBox(height: 10),
                _simpleDetail(caption: "agent_screen.earnings_host_no".tr(), amount: invitedHosts),
                const SizedBox(height: 10),
                _simpleDetail(caption: "agent_screen.active_hosts_number".tr(), amount: invitedHosts),
              ]),
            ),
          ),
          ContainerCorner(
            color: kGrayColor.withOpacity(0.1),
            marginLeft: 10, marginRight: 10, marginTop: 15,
            borderRadius: 4, marginBottom: 10,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(children: [
                _detailOptionWithInfo(caption: "agent_screen.invite_agent_earning".tr(), amount: 0),
                const SizedBox(height: 10),
                _pointsDetails(caption: "agent_screen.mmy_commission".tr(), amount: 0),
                const SizedBox(height: 10),
                _simpleDetail(caption: "agent_screen.invite_agent_income".tr(), amount: invitedAgents),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _simpleDetail({required String caption, required int amount}) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        TextWithTap(caption),
        TextWithTap("$amount", marginLeft: 2),
      ]);

  Widget _pointsDetails({required String caption, required int amount}) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        TextWithTap(caption),
        Row(mainAxisSize: MainAxisSize.min, children: [
          Image.asset("assets/images/ic_jifen_wode.webp", height: 15, width: 15),
          TextWithTap(QuickHelp.checkFundsWithString(amount: "$amount"), marginLeft: 2),
        ]),
      ]);

  Widget _detailOptionWithInfo({required String caption, required int amount}) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          TextWithTap(caption, marginRight: 5),
          const Icon(Icons.info_outline, size: 15),
        ]),
        Row(mainAxisSize: MainAxisSize.min, children: [
          Image.asset("assets/images/ic_jifen_wode.webp", height: 15, width: 15),
          TextWithTap(QuickHelp.checkFundsWithString(amount: "$amount"), marginLeft: 2),
        ]),
      ]);
}
