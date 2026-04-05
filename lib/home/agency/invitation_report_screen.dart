// ignore_for_file: must_be_immutable

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import '../../helpers/quick_actions.dart';
import '../../helpers/quick_help.dart';
import '../../models/AgencyInvitationModel.dart';
import '../../models/UserModel.dart';
import '../../ui/container_with_corner.dart';
import '../../ui/text_with_tap.dart';
import '../../utils/colors.dart';

class InvitationReportScreen extends StatefulWidget {
  UserModel? currentUser;
  InvitationReportScreen({this.currentUser, Key? key}) : super(key: key);

  @override
  State<InvitationReportScreen> createState() => _InvitationReportScreenState();
}

class _InvitationReportScreenState extends State<InvitationReportScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool showCopied = false;

  // فلتر الحالة
  String _statusFilter = "all"; // all | pending | accepted | declined

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showCopied() {
    setState(() => showCopied = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => showCopied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size   = MediaQuery.of(context).size;
    bool isDark = QuickHelp.isDarkMode(context);

    return Stack(
      alignment: AlignmentDirectional.center,
      children: [
        Scaffold(
          backgroundColor: isDark ? kContentDarkShadow : kGrayWhite,
          appBar: AppBar(
            elevation: 0.5,
            automaticallyImplyLeading: false,
            leading: BackButton(
                color: isDark ? Colors.white : kContentColorLightTheme),
            centerTitle: true,
            title: TextWithTap(
              "invitation_report.report_title".tr(),
              fontWeight: FontWeight.w600,
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: earnCashColor,
              labelColor: earnCashColor,
              unselectedLabelColor: kGrayColor,
              tabs: [
                Tab(text: "invitation_report.hosts_tab".tr()),
                Tab(text: "invitation_report.agents_tab".tr()),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _hostsTab(size, isDark),
              _agentsTab(size, isDark),
            ],
          ),
        ),
        // ── إشعار نسخ ─────────────────────────────────────────────────────
        Visibility(
          visible: showCopied,
          child: ContainerCorner(
            color: Colors.black.withOpacity(0.6),
            height: 45,
            borderRadius: 50,
            marginLeft: 60,
            marginRight: 60,
            child: TextWithTap(
              "copied_".tr(),
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              alignment: Alignment.center,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 1 — قائمة المضيفين مع أدائهم
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _hostsTab(Size size, bool isDark) {
    final qHosts = QueryBuilder<AgencyInvitationModel>(AgencyInvitationModel())
      ..whereEqualTo(AgencyInvitationModel.keyAgentId, widget.currentUser!.objectId!)
      ..includeObject([AgencyInvitationModel.keyHost, AgencyInvitationModel.keyAgent])
      ..orderByDescending(AgencyInvitationModel.keyCreatedAt);

    if (_statusFilter != "all") {
      qHosts.whereEqualTo(AgencyInvitationModel.keyInvitationStatus, _statusFilter);
    }

    return Column(
      children: [
        // ── فلتر الحالة ─────────────────────────────────────────────────
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              _filterChip("all",     "invitation_report.all".tr()),
              _filterChip(AgencyInvitationModel.keyStatusAccepted,  "invitation_report.accepted".tr()),
              _filterChip(AgencyInvitationModel.keyStatusPending,   "invitation_report.pending".tr()),
              _filterChip(AgencyInvitationModel.keyStatusDeclined,  "invitation_report.declined".tr()),
            ],
          ),
        ),
        // ── رأس الجدول ──────────────────────────────────────────────────
        _tableHeader(isDark, [
          "invitation_report.user_".tr(),
          "invitation_report.level".tr(),
          "invitation_report.status_".tr(),
          "invitation_report.add_time".tr(),
        ], [2.5, 1, 1, 1.5]),
        // ── القائمة ─────────────────────────────────────────────────────
        Flexible(
          child: ParseLiveListWidget<AgencyInvitationModel>(
            query: qHosts,
            reverse: false,
            lazyLoading: false,
            shrinkWrap: true,
            scrollDirection: Axis.vertical,
            duration: const Duration(milliseconds: 200),
            listeningIncludes: [AgencyInvitationModel.keyHost],
            childBuilder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              final inv  = snapshot.loadedData!;
              final host = inv.getHost;
              if (host == null) return const SizedBox();
              return _hostRow(inv, host, isDark);
            },
            listLoadingElement: QuickHelp.appLoading(),
            queryEmptyElement: _emptyView(),
          ),
        ),
      ],
    );
  }

  Widget _hostRow(AgencyInvitationModel inv, UserModel host, bool isDark) {
    final statusColor = inv.getInvitationStatus == AgencyInvitationModel.keyStatusAccepted
        ? Colors.green
        : inv.getInvitationStatus == AgencyInvitationModel.keyStatusDeclined
            ? earnCashColor
            : kGrayColor;

    return InkWell(
      onTap: () => _showHostPerformance(host),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: kGrayColor.withOpacity(0.15)),
          ),
        ),
        child: Row(
          children: [
            // صورة + اسم + ID
            Expanded(
              flex: 25,
              child: Row(
                children: [
                  QuickActions.avatarWidget(host, height: 38, width: 38),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextWithTap(
                          host.getFullName ?? "",
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          maxLine: 1,
                        ),
                        GestureDetector(
                          onTap: () {
                            QuickHelp.copyText(textToCopy: "${host.getUid ?? ''}");
                            _showCopied();
                          },
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            TextWithTap(
                              "ID:${host.getUid ?? ''}",
                              fontSize: 10,
                              color: kGrayColor,
                            ),
                            const Icon(Icons.copy, size: 10, color: kGrayColor),
                          ]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // المستوى
            Expanded(
              flex: 10,
              child: TextWithTap(
                QuickHelp.levelUser(
                  0,
                  currentCredit: (host.getCredits ?? 0).toDouble(),
                ),
                alignment: Alignment.center,
                fontSize: 10,
                textAlign: TextAlign.center,
              ),
            ),
            // الحالة
            Expanded(
              flex: 10,
              child: ContainerCorner(
                borderRadius: 10,
                borderWidth: 0,
                color: statusColor.withOpacity(0.15),
                marginLeft: 2,
                marginRight: 2,
                child: TextWithTap(
                  _statusLabel(inv.getInvitationStatus),
                  alignment: Alignment.center,
                  fontSize: 9,
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                  marginTop: 3,
                  marginBottom: 3,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            // تاريخ الإضافة
            Expanded(
              flex: 15,
              child: TextWithTap(
                inv.createdAt != null
                    ? QuickHelp.getMessageListTime(inv.createdAt!)
                    : "-",
                alignment: Alignment.center,
                fontSize: 10,
                color: kGrayColor,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── نافذة تفاصيل أداء المضيف ───────────────────────────────────────────────
  void _showHostPerformance(UserModel host) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HostPerformanceSheet(host: host),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 2 — الوكلاء المدعوون
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _agentsTab(Size size, bool isDark) {
    final qAgents = QueryBuilder<AgencyInvitationModel>(AgencyInvitationModel())
      ..whereEqualTo(AgencyInvitationModel.keyHostId, widget.currentUser!.objectId!)
      ..includeObject([AgencyInvitationModel.keyAgent])
      ..orderByDescending(AgencyInvitationModel.keyCreatedAt);

    return Column(
      children: [
        _tableHeader(isDark, [
          "invitation_report.user_".tr(),
          "invitation_report.add_time".tr(),
          "invitation_report.status_".tr(),
        ], [2.5, 1.5, 1]),
        Flexible(
          child: ParseLiveListWidget<AgencyInvitationModel>(
            query: qAgents,
            reverse: false,
            lazyLoading: false,
            shrinkWrap: true,
            scrollDirection: Axis.vertical,
            duration: const Duration(milliseconds: 200),
            childBuilder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              final inv   = snapshot.loadedData!;
              final agent = inv.getAgent;
              if (agent == null) return const SizedBox();
              return _agentRow(inv, agent, isDark);
            },
            listLoadingElement: QuickHelp.appLoading(),
            queryEmptyElement: _emptyView(),
          ),
        ),
      ],
    );
  }

  Widget _agentRow(AgencyInvitationModel inv, UserModel agent, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: kGrayColor.withOpacity(0.15))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 25,
            child: Row(children: [
              QuickActions.avatarWidget(agent, height: 36, width: 36),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextWithTap(agent.getFullName ?? "", fontWeight: FontWeight.w600, fontSize: 12),
                    TextWithTap("ID:${agent.getUid ?? ''}", fontSize: 10, color: kGrayColor),
                  ],
                ),
              ),
            ]),
          ),
          Expanded(
            flex: 15,
            child: TextWithTap(
              inv.createdAt != null ? QuickHelp.getMessageListTime(inv.createdAt!) : "-",
              alignment: Alignment.center, fontSize: 10, color: kGrayColor, textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 10,
            child: TextWithTap(
              _statusLabel(inv.getInvitationStatus),
              alignment: Alignment.center, fontSize: 10,
              color: inv.getInvitationStatus == AgencyInvitationModel.keyStatusAccepted
                  ? Colors.green : kGrayColor,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // ── مساعدات ───────────────────────────────────────────────────────────────
  String _statusLabel(String? status) {
    switch (status) {
      case "accepted": return "invitation_report.accepted".tr();
      case "pending":  return "invitation_report.pending".tr();
      case "declined": return "invitation_report.declined".tr();
      default:         return status ?? "-";
    }
  }

  Widget _filterChip(String value, String label) {
    final bool selected = _statusFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _statusFilter = value),
      child: ContainerCorner(
        borderRadius: 20,
        borderWidth: 0,
        color: selected ? earnCashColor : kGrayColor.withOpacity(0.1),
        marginRight: 8,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: TextWithTap(
            label,
            fontSize: 12,
            color: selected ? Colors.white : kGrayColor,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _tableHeader(bool isDark, List<String> titles, List<double> flex) {
    return Container(
      color: isDark ? kContentColorLightTheme.withOpacity(0.05) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: List.generate(titles.length, (i) {
          return Expanded(
            flex: flex[i].toInt(),
            child: TextWithTap(
              titles[i],
              alignment: i == 0 ? Alignment.centerLeft : Alignment.center,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: kGrayColor,
            ),
          );
        }),
      ),
    );
  }

  Widget _emptyView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 60),
          Image.asset("assets/images/szy_kong_icon.png", height: 80),
          TextWithTap("no_data_found_".tr(), color: kGrayColor, marginTop: 12),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Bottom Sheet — تفاصيل أداء المضيف
// ═══════════════════════════════════════════════════════════════════════════
class _HostPerformanceSheet extends StatelessWidget {
  final UserModel host;
  const _HostPerformanceSheet({required this.host});

  @override
  Widget build(BuildContext context) {
    bool isDark = QuickHelp.isDarkMode(context);
    Size size   = MediaQuery.of(context).size;

    return Container(
      height: size.height * 0.75,
      decoration: BoxDecoration(
        color: isDark ? kContentColorLightTheme : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // ── مقبض السحب ──────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: kGrayColor.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // ── رأس الشيت ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                QuickActions.avatarWidget(host, height: 48, width: 48),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWithTap(host.getFullName ?? "", fontWeight: FontWeight.bold, fontSize: 15),
                    TextWithTap("ID:${host.getUid ?? ''}", fontSize: 12, color: kGrayColor),
                  ],
                ),
              ],
            ),
          ),
          Divider(color: kGrayColor.withOpacity(0.2)),
          // ── بيانات الأداء ───────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _sectionTitle("host_center_screen.monthly_live_data".tr()),
                _dataRow("host_center_screen.u_coin_income".tr(),
                    QuickHelp.convertNumberToK(host.getDiamonds ?? 0), showCoin: true),
                _dataRow("invitation_report.total_lives".tr(),
                    "${host.getDiamondsTotal ?? 0}", showCoin: false),
                const SizedBox(height: 16),
                _sectionTitle("invitation_report.host_stats".tr()),
                _dataRow("invitation_report.points_earned".tr(),
                    QuickHelp.convertNumberToK(host.getDiamondsTotal ?? 0), showCoin: true),
                _dataRow("invitation_report.level".tr(),
                    QuickHelp.levelUser(0, currentCredit: (host.getCredits ?? 0).toDouble()),
                    showCoin: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 8),
    child: TextWithTap(title, fontWeight: FontWeight.bold, fontSize: 14),
  );

  Widget _dataRow(String label, String value, {bool showCoin = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextWithTap(label, color: kGrayColor, fontSize: 13),
          Row(mainAxisSize: MainAxisSize.min, children: [
            if (showCoin) ...[
              Image.asset("assets/images/ic_jifen_wode.webp", height: 14, width: 14),
              const SizedBox(width: 4),
            ],
            TextWithTap(value, fontWeight: FontWeight.w600, fontSize: 13),
          ]),
        ],
      ),
    );
  }
}
