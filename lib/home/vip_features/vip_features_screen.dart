// ignore_for_file: must_be_immutable

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import '../../helpers/quick_actions.dart';
import '../../helpers/quick_help.dart';
import '../../models/GiftsModel.dart';
import '../../models/ObtainedItemsModel.dart';
import '../../models/UserModel.dart';
import '../../ui/container_with_corner.dart';
import '../../ui/text_with_tap.dart';
import '../../utils/colors.dart';
import '../my_obtained_items/my_obtained_items.dart';

class VipFeaturesScreen extends StatefulWidget {
  UserModel? currentUser;

  VipFeaturesScreen({this.currentUser, Key? key}) : super(key: key);

  @override
  State<VipFeaturesScreen> createState() => _VipFeaturesScreenState();
}

class _VipFeaturesScreenState extends State<VipFeaturesScreen> {
  bool _saving = false;

  // ─── Getters helpers ───────────────────────────────────────────────────────

  bool get _avatarFrameOn =>
      widget.currentUser?.getCanUseAvatarFrame == true;

  bool get _partyThemeOn =>
      widget.currentUser?.getCanUsePartyTheme == true;

  bool get _entranceEffectOn =>
      widget.currentUser?.getCanUseEntranceEffect == true;

  bool get _invisibleModeOn =>
      widget.currentUser?.getVipInvisibleMode == true;

  bool get _showVipLevelOn =>
      widget.currentUser?.getShowVipLevel == true;

  String get _vipType {
    if (widget.currentUser?.isDiamondVip == true) {
      return "guardian_and_vip_screen.diamond_vip".tr();
    } else if (widget.currentUser?.isSuperVip == true) {
      return "guardian_and_vip_screen.super_vip".tr();
    } else if (widget.currentUser?.isNormalVip == true) {
      return "guardian_and_vip_screen.normal_vip".tr();
    }
    return "VIP";
  }

  // ─── Save helper ───────────────────────────────────────────────────────────

  Future<void> _saveUser() async {
    setState(() => _saving = true);
    final res = await widget.currentUser!.save();
    if (res.success && res.results != null) {
      setState(() {
        widget.currentUser = res.results!.first;
        _saving = false;
      });
    } else {
      setState(() => _saving = false);
      QuickHelp.showAppNotificationAdvanced(
        title: "error".tr(),
        context: context,
        message: "report_screen.report_failed_explain".tr(),
      );
    }
  }

  // ─── Toggle helpers ────────────────────────────────────────────────────────

  Future<void> _toggleAvatarFrame(bool val) async {
    widget.currentUser?.setCanUseAvatarFrame = val;
    if (!val) widget.currentUser?.setAvatarFrameId = "";
    await _saveUser();
  }

  Future<void> _togglePartyTheme(bool val) async {
    widget.currentUser?.setCanUsePartyTheme = val;
    if (!val) widget.currentUser?.setPartyThemeId = "";
    await _saveUser();
  }

  Future<void> _toggleEntranceEffect(bool val) async {
    widget.currentUser?.setCanUseEntranceEffect = val;
    if (!val) widget.currentUser?.setEntranceEffectId = "";
    await _saveUser();
  }

  Future<void> _toggleInvisibleMode(bool val) async {
    widget.currentUser?.setVipInvisibleMode = val;
    await _saveUser();
  }

  Future<void> _toggleShowVipLevel(bool val) async {
    widget.currentUser?.setShowVipLevel = val;
    await _saveUser();
  }

  // ─── Navigate to manage items ──────────────────────────────────────────────

  Future<void> _goToMyItems() async {
    final updated = await QuickHelp.goToNavigatorScreenForResult(
      context,
      MyObtainedItems(currentUser: widget.currentUser),
    );
    if (updated != null && updated is UserModel) {
      setState(() => widget.currentUser = updated);
    }
  }

  // ─── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = QuickHelp.isDarkMode(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: isDark ? kContentDarkShadow : kGrayWhite,
      appBar: AppBar(
        backgroundColor: isDark ? kContentDarkShadow : Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: BackButton(
          color: isDark ? Colors.white : Colors.black,
          onPressed: () =>
              QuickHelp.goBackToPreviousPage(context, result: widget.currentUser),
        ),
        centerTitle: true,
        title: TextWithTap(
          "vip_features_screen.title".tr(),
          fontWeight: FontWeight.w700,
          fontSize: 17,
        ),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // ── VIP badge header ────────────────────────────────────────────
          _buildVipHeader(isDark, size),
          const SizedBox(height: 20),

          // ── Section: cosmetics ──────────────────────────────────────────
          _sectionTitle("vip_features_screen.my_cosmetics".tr(), isDark),
          const SizedBox(height: 10),
          _buildCosmeticRow(isDark, size),
          const SizedBox(height: 8),
          _buildManageButton(isDark),
          const SizedBox(height: 24),

          // ── Section: cosmetic toggles ───────────────────────────────────
          _sectionTitle("vip_features_screen.cosmetic_settings".tr(), isDark),
          const SizedBox(height: 10),
          _buildToggleTile(
            isDark: isDark,
            icon: Icons.portrait_rounded,
            iconColor: kOrangeColorVip,
            title: "store_screen.avatar_frame".tr(),
            subtitle: _avatarFrameOn
                ? "vip_features_screen.active".tr()
                : "vip_features_screen.inactive".tr(),
            value: _avatarFrameOn,
            hasItem: widget.currentUser?.getAvatarFrameId?.isNotEmpty == true,
            onChanged: _toggleAvatarFrame,
          ),
          _buildToggleTile(
            isDark: isDark,
            icon: Icons.celebration_rounded,
            iconColor: Colors.pinkAccent,
            title: "store_screen.party_theme".tr(),
            subtitle: _partyThemeOn
                ? "vip_features_screen.active".tr()
                : "vip_features_screen.inactive".tr(),
            value: _partyThemeOn,
            hasItem: widget.currentUser?.getPartyThemeId?.isNotEmpty == true,
            onChanged: _togglePartyTheme,
          ),
          _buildToggleTile(
            isDark: isDark,
            icon: Icons.directions_run_rounded,
            iconColor: Colors.purpleAccent,
            title: "store_screen.entrance_effect".tr(),
            subtitle: _entranceEffectOn
                ? "vip_features_screen.active".tr()
                : "vip_features_screen.inactive".tr(),
            value: _entranceEffectOn,
            hasItem: widget.currentUser?.getEntranceEffectId?.isNotEmpty == true,
            onChanged: _toggleEntranceEffect,
          ),
          const SizedBox(height: 24),

          // ── Section: VIP perks ──────────────────────────────────────────
          _sectionTitle("vip_features_screen.vip_perks".tr(), isDark),
          const SizedBox(height: 10),
          _buildToggleTile(
            isDark: isDark,
            icon: Icons.visibility_off_rounded,
            iconColor: kPrimaryColor,
            title: "vip_features_screen.invisible_mode".tr(),
            subtitle: "vip_features_screen.invisible_mode_desc".tr(),
            value: _invisibleModeOn,
            hasItem: true,
            onChanged: _toggleInvisibleMode,
          ),
          _buildToggleTile(
            isDark: isDark,
            icon: Icons.workspace_premium_rounded,
            iconColor: kWarninngColor,
            title: "vip_features_screen.show_vip_level".tr(),
            subtitle: "vip_features_screen.show_vip_level_desc".tr(),
            value: _showVipLevelOn,
            hasItem: true,
            onChanged: _toggleShowVipLevel,
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ─── VIP Header ────────────────────────────────────────────────────────────

  Widget _buildVipHeader(bool isDark, Size size) {
    return ContainerCorner(
      borderRadius: 16,
      borderWidth: 0,
      colors: [kRoseVip300.withOpacity(0.6), kRoseVip.withOpacity(0.4)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                QuickActions.avatarWidget(
                  widget.currentUser!,
                  width: size.width / 6,
                  height: size.width / 6,
                ),
              ],
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextWithTap(
                  widget.currentUser?.getFullName ?? "",
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: isDark ? Colors.white : kContentDarkShadow,
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [kRoseVip500, kOrangeColorVip],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _vipType,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Cosmetics row preview ─────────────────────────────────────────────────

  Widget _buildCosmeticRow(bool isDark, Size size) {
    return Row(
      children: [
        _buildCosmeticPreviewCard(
          isDark: isDark,
          label: "store_screen.avatar_frame".tr(),
          isActive: _avatarFrameOn,
          child: widget.currentUser?.getAvatarFrame != null
              ? Stack(
                  alignment: Alignment.center,
                  children: [
                    QuickActions.avatarWidget(widget.currentUser!,
                        width: 40, height: 40, hideAvatarFrame: true),
                    QuickActions.photosWidget(
                      widget.currentUser!.getAvatarFrame!.url!,
                      width: 52,
                      height: 52,
                    ),
                  ],
                )
              : Icon(Icons.portrait_rounded,
                  size: 36, color: Colors.grey.shade400),
        ),
        const SizedBox(width: 10),
        _buildCosmeticPreviewCard(
          isDark: isDark,
          label: "store_screen.party_theme".tr(),
          isActive: _partyThemeOn,
          child: widget.currentUser?.getPartyTheme != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: QuickActions.photosWidget(
                    widget.currentUser!.getPartyTheme!.url!,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                  ),
                )
              : Icon(Icons.celebration_rounded,
                  size: 36, color: Colors.grey.shade400),
        ),
        const SizedBox(width: 10),
        _buildCosmeticPreviewCard(
          isDark: isDark,
          label: "store_screen.entrance_effect".tr(),
          isActive: _entranceEffectOn,
          child: widget.currentUser?.getEntranceEffect != null
              ? Icon(Icons.directions_run_rounded,
                  size: 36, color: kPrimaryColor)
              : Icon(Icons.directions_run_rounded,
                  size: 36, color: Colors.grey.shade400),
        ),
      ],
    );
  }

  Widget _buildCosmeticPreviewCard({
    required bool isDark,
    required String label,
    required bool isActive,
    required Widget child,
  }) {
    return Expanded(
      child: ContainerCorner(
        borderRadius: 12,
        borderWidth: isActive ? 1.5 : 0.5,
        borderColor: isActive ? kOrangeColorVip : Colors.grey.shade300,
        color: isDark
            ? kContentDarkShadow.withOpacity(0.6)
            : Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          child: Column(
            children: [
              child,
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isActive
                      ? earnCashColor.withOpacity(0.15)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isActive
                      ? "vip_features_screen.on".tr()
                      : "vip_features_screen.off".tr(),
                  style: TextStyle(
                    fontSize: 9,
                    color: isActive ? earnCashColor : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManageButton(bool isDark) {
    return GestureDetector(
      onTap: _goToMyItems,
      child: ContainerCorner(
        borderRadius: 10,
        borderWidth: 0,
        color: kPrimaryColor.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.storefront_rounded,
                  color: kPrimaryColor, size: 18),
              const SizedBox(width: 8),
              Text(
                "vip_features_screen.manage_my_items".tr(),
                style: const TextStyle(
                  color: kPrimaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: kPrimaryColor, size: 13),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Toggle tile ───────────────────────────────────────────────────────────

  Widget _buildToggleTile({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required bool hasItem,
    required Future<void> Function(bool) onChanged,
  }) {
    final disabled = !hasItem;

    return ContainerCorner(
      borderRadius: 12,
      borderWidth: 0,
      color: isDark ? kContentDarkShadow.withOpacity(0.6) : Colors.white,
      marginBottom: 10,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // icon circle
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),

            // text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    disabled
                        ? "vip_features_screen.no_item_purchased".tr()
                        : subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: disabled
                          ? Colors.grey
                          : (value ? earnCashColor : Colors.grey),
                    ),
                  ),
                ],
              ),
            ),

            // switch
            Switch(
              value: value && !disabled,
              onChanged: disabled || _saving
                  ? null
                  : (v) => onChanged(v),
              activeColor: kPrimaryColor,
              inactiveThumbColor: Colors.grey.shade400,
              inactiveTrackColor: Colors.grey.shade200,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Section title ─────────────────────────────────────────────────────────

  Widget _sectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 13,
        color: isDark ? Colors.white54 : Colors.black45,
        letterSpacing: 0.5,
      ),
    );
  }
}
