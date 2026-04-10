// ignore_for_file: must_be_immutable
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import '../../helpers/quick_actions.dart';
import '../../helpers/quick_help.dart';
import '../../models/BusinessPageModel.dart';
import '../../models/UserModel.dart';
import '../../ui/container_with_corner.dart';
import '../../ui/text_with_tap.dart';
import '../../utils/colors.dart';

class PageSettingsScreen extends StatefulWidget {
  UserModel? currentUser;
  BusinessPageModel page;
  PageSettingsScreen({this.currentUser, required this.page, Key? key}) : super(key: key);
  @override
  State<PageSettingsScreen> createState() => _PageSettingsScreenState();
}

class _PageSettingsScreenState extends State<PageSettingsScreen> {
  final _nameCtrl    = TextEditingController();
  final _bioCtrl     = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _searchCtrl  = TextEditingController();

  File? _avatarFile;
  File? _coverFile;
  String _selectedCategory = BusinessPageModel.catBusiness;
  bool _saving = false;

  List<UserModel> _admins = [];
  bool _loadingAdmins = true;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text    = widget.page.getName    ?? "";
    _bioCtrl.text     = widget.page.getBio     ?? "";
    _websiteCtrl.text = widget.page.getWebsite ?? "";
    _selectedCategory = widget.page.getCategory ?? BusinessPageModel.catBusiness;
    _loadAdmins();
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _bioCtrl.dispose();
    _websiteCtrl.dispose(); _searchCtrl.dispose();
    super.dispose();
  }

  // ── جلب المديرين الحاليين ─────────────────────────────────────────────────
  Future<void> _loadAdmins() async {
    final ids = widget.page.getAdminIds ?? [];
    if (ids.isEmpty) { setState(() => _loadingAdmins = false); return; }
    try {
      final q = QueryBuilder<UserModel>(UserModel.forQuery())
        ..whereContainedIn(UserModel.keyObjectId, ids);
      final r = await q.query();
      if (mounted) setState(() {
        _admins = r.results?.cast<UserModel>() ?? [];
        _loadingAdmins = false;
      });
    } catch (_) { if (mounted) setState(() => _loadingAdmins = false); }
  }

  // ── رفع صورة ──────────────────────────────────────────────────────────────
  Future<void> _pick({required bool isCover}) async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (x == null) return;
    setState(() { if (isCover) _coverFile = File(x.path); else _avatarFile = File(x.path); });
  }

  Future<ParseFileBase?> _upload(File f, String name) async {
    ParseFileBase pf = ParseFile(File(f.absolute.path), name: name);
    final r = await pf.save();
    return r.success ? pf : null;
  }

  // ── حفظ الإعدادات ─────────────────────────────────────────────────────────
  Future<void> _save() async {
    setState(() => _saving = true);
    QuickHelp.showLoadingDialog(context);
    try {
      widget.page.setName     = _nameCtrl.text.trim();
      widget.page.setBio      = _bioCtrl.text.trim();
      widget.page.setWebsite  = _websiteCtrl.text.trim();
      widget.page.setCategory = _selectedCategory;

      if (_avatarFile != null) {
        final f = await _upload(_avatarFile!, "page_avatar.jpg");
        if (f != null) widget.page.setAvatar = f;
      }
      if (_coverFile != null) {
        final f = await _upload(_coverFile!, "page_cover.jpg");
        if (f != null) widget.page.setCover = f;
      }

      final r = await widget.page.save();
      QuickHelp.hideLoadingDialog(context);
      if (!mounted) return;

      if (r.success && r.results != null) {
        widget.page = r.results!.first as BusinessPageModel;
        QuickHelp.showAppNotificationAdvanced(
          context: context,
          title: "page.edit_success".tr(),
          message: "page.edit_success_msg".tr(),
          isError: false,
        );
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) Navigator.pop(context, widget.page);
      } else {
        QuickHelp.showAppNotificationAdvanced(
          context: context,
          title: "error".tr(),
          message: r.error?.message ?? "page.create_failed".tr(),
        );
      }
    } catch (e) {
      QuickHelp.hideLoadingDialog(context);
    }
    if (mounted) setState(() => _saving = false);
  }

  // ── بحث وإضافة مدير ───────────────────────────────────────────────────────
  Future<void> _searchAndAddAdmin() async {
    final id = _searchCtrl.text.trim();
    if (id.isEmpty) return;

    QuickHelp.showLoadingDialog(context);
    try {
      final q = QueryBuilder<UserModel>(UserModel.forQuery())
        ..whereEqualTo(UserModel.keyUid, int.tryParse(id) ?? -1);
      final r = await q.query();
      QuickHelp.hideLoadingDialog(context);

      if (!mounted) return;
      if (r.success && r.results != null && r.results!.isNotEmpty) {
        final user = r.results!.first as UserModel;
        if (user.objectId == widget.currentUser?.objectId) {
          QuickHelp.showAppNotificationAdvanced(
            context: context,
            title: "page.admin_self_error".tr(),
            message: "page.admin_self_error_msg".tr(),
          );
          return;
        }
        if (_admins.any((a) => a.objectId == user.objectId)) {
          QuickHelp.showAppNotificationAdvanced(
            context: context,
            title: "page.already_admin".tr(),
            message: "",
          );
          return;
        }
        _showAddAdminDialog(user);
      } else {
        QuickHelp.showAppNotificationAdvanced(
          context: context,
          title: "page.user_not_found".tr(),
          message: "page.user_not_found_msg".tr(),
        );
      }
    } catch (e) {
      QuickHelp.hideLoadingDialog(context);
    }
  }

  void _showAddAdminDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: TextWithTap("page.add_admin".tr(), fontWeight: FontWeight.bold),
        content: Row(children: [
          QuickActions.avatarWidget(user, height: 44, width: 44),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            TextWithTap(user.getFullName ?? "", fontWeight: FontWeight.w600),
            TextWithTap("ID: ${user.getUid ?? ''}", color: kGrayColor, fontSize: 12),
          ]),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            QuickActions.avatarWidget(user, height: 44, width: 44),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              TextWithTap(user.getFullName ?? "", fontWeight: FontWeight.w600),
              TextWithTap("ID: ${user.getUid ?? ''}", color: kGrayColor, fontSize: 12),
            ])),
          ]),
          const SizedBox(height: 12),
          TextWithTap("page.admin_permissions_note".tr(),
              color: kGrayColor, fontSize: 12),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: TextWithTap("cancel".tr(), color: kGrayColor),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _addAdmin(user);
            },
            child: TextWithTap("page.add_admin".tr(), color: kPrimaryColor),
          ),
        ],
      ),
    );
  }

  Future<void> _addAdmin(UserModel user) async {
    QuickHelp.showLoadingDialog(context);
    widget.page.addAdminId = user.objectId!;
    final r = await widget.page.save();
    QuickHelp.hideLoadingDialog(context);
    if (!mounted) return;
    if (r.success) {
      setState(() => _admins.add(user));
      QuickHelp.showAppNotificationAdvanced(
        context: context,
        title: "page.admin_added".tr(),
        message: user.getFullName ?? "",
        isError: false,
      );
    }
    _searchCtrl.clear();
  }

  Future<void> _removeAdmin(UserModel admin) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: TextWithTap("page.remove_admin".tr(), fontWeight: FontWeight.bold),
        content: TextWithTap("page.remove_admin_confirm".tr(
            namedArgs: {"name": admin.getFullName ?? ""})),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: TextWithTap("cancel".tr(), color: kGrayColor)),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: TextWithTap("page.remove".tr(), color: earnCashColor)),
        ],
      ),
    );
    if (confirmed != true) return;

    QuickHelp.showLoadingDialog(context);
    widget.page.removeAdminId = admin.objectId!;
    final r = await widget.page.save();
    QuickHelp.hideLoadingDialog(context);
    if (r.success && mounted) {
      setState(() => _admins.removeWhere((a) => a.objectId == admin.objectId));
    }
  }

  final List<Map<String, String>> _categories = [
    {"key": BusinessPageModel.catBusiness,      "label": "page.cat_business"},
    {"key": BusinessPageModel.catEntertainment, "label": "page.cat_entertainment"},
    {"key": BusinessPageModel.catNews,          "label": "page.cat_news"},
    {"key": BusinessPageModel.catSports,        "label": "page.cat_sports"},
    {"key": BusinessPageModel.catTechnology,    "label": "page.cat_technology"},
    {"key": BusinessPageModel.catFashion,       "label": "page.cat_fashion"},
    {"key": BusinessPageModel.catFood,          "label": "page.cat_food"},
    {"key": BusinessPageModel.catHealth,        "label": "page.cat_health"},
    {"key": BusinessPageModel.catOther,         "label": "page.cat_other"},
  ];

  @override
  Widget build(BuildContext context) {
    bool isDark = QuickHelp.isDarkMode(context);
    return Scaffold(
      backgroundColor: isDark ? kContentDarkShadow : kGrayWhite,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: BackButton(color: isDark ? Colors.white : kContentColorLightTheme),
        centerTitle: true,
        title: TextWithTap("page.page_settings".tr(), fontWeight: FontWeight.bold),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: TextWithTap("page.save".tr(),
                color: kPrimaryColor, fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── صورة الغلاف ─────────────────────────────────────────────
            GestureDetector(
              onTap: () => _pick(isCover: true),
              child: SizedBox(
                height: 140,
                width: double.infinity,
                child: Stack(fit: StackFit.expand, children: [
                  if (_coverFile != null)
                    Image.file(_coverFile!, fit: BoxFit.cover)
                  else if (widget.page.getCover?.url != null)
                    Image.network(widget.page.getCover!.url!, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: kPrimaryColor.withOpacity(0.2)))
                  else
                    Container(color: kPrimaryColor.withOpacity(0.15)),
                  Container(
                    color: Colors.black.withOpacity(0.35),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.add_photo_alternate_outlined, color: Colors.white, size: 30),
                      TextWithTap("page.tap_to_change".tr(), color: Colors.white, fontSize: 12, marginTop: 4),
                    ]),
                  ),
                ]),
              ),
            ),
            // ── صورة الصفحة ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Transform.translate(
                offset: const Offset(0, -30),
                child: GestureDetector(
                  onTap: () => _pick(isCover: false),
                  child: Stack(children: [
                    ContainerCorner(
                      width: 80, height: 80, borderRadius: 12,
                      borderColor: Colors.white, borderWidth: 3,
                      color: kGrayColor.withOpacity(0.2),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _avatarFile != null
                            ? Image.file(_avatarFile!, fit: BoxFit.cover)
                            : widget.page.getAvatar?.url != null
                                ? Image.network(widget.page.getAvatar!.url!, fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        Icon(Icons.store, color: kPrimaryColor, size: 36))
                                : Icon(Icons.store, color: kPrimaryColor, size: 36),
                      ),
                    ),
                    Positioned(bottom: 0, right: 0,
                      child: ContainerCorner(
                        width: 24, height: 24, borderRadius: 50,
                        color: kPrimaryColor, borderWidth: 0,
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 13),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
            // ── الحقول ──────────────────────────────────────────────────
            _section("page.page_info".tr(), [
              _field(controller: _nameCtrl, label: "page.page_name".tr(), icon: Icons.store_outlined,
                  validator: (v) => (v?.trim().isEmpty ?? true) ? "page.name_required".tr() : null),
              _field(controller: _bioCtrl, label: "page.page_bio".tr(), icon: Icons.info_outline, maxLines: 3),
              _field(controller: _websiteCtrl, label: "page.website".tr(), icon: Icons.link),
            ]),
            // ── الفئة ────────────────────────────────────────────────────
            _section("page.category".tr(), [
              Wrap(spacing: 8, runSpacing: 8,
                children: _categories.map((cat) {
                  final sel = cat["key"] == _selectedCategory;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat["key"]!),
                    child: ContainerCorner(
                      borderRadius: 20, borderWidth: 0,
                      color: sel ? kPrimaryColor : kGrayColor.withOpacity(0.12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: TextWithTap(cat["label"]!.tr(),
                          color: sel ? Colors.white : kGrayColor, fontSize: 12,
                          fontWeight: sel ? FontWeight.w600 : FontWeight.normal),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ]),
            // ── المديرون ─────────────────────────────────────────────────
            _section("page.page_admins".tr(), [
              // بحث بالـ ID
              ContainerCorner(
                color: QuickHelp.isDarkMode(context) ? kContentColorLightTheme : Colors.white,
                borderRadius: 12, borderWidth: 0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  child: Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: "page.search_by_id".tr(),
                          hintStyle: TextStyle(color: kGrayColor, fontSize: 13),
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.person_search_outlined, color: kPrimaryColor, size: 20),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _searchAndAddAdmin,
                      child: ContainerCorner(
                        borderRadius: 20, borderWidth: 0,
                        color: kPrimaryColor,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          child: TextWithTap("page.add".tr(), color: Colors.white,
                              fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 8),
              TextWithTap("page.admin_permissions_note".tr(),
                  color: kGrayColor, fontSize: 11, marginBottom: 10),
              // قائمة المديرين الحاليين
              if (_loadingAdmins)
                const Center(child: CircularProgressIndicator())
              else if (_admins.isEmpty)
                TextWithTap("page.no_admins_yet".tr(), color: kGrayColor, fontSize: 13)
              else
                ..._admins.map((admin) => _adminItem(admin)),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    bool isDark = QuickHelp.isDarkMode(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
        child: TextWithTap(title, fontWeight: FontWeight.bold,
            fontSize: 14, color: isDark ? Colors.white70 : kContentColorLightTheme),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ContainerCorner(
          color: isDark ? kContentColorLightTheme : Colors.white,
          borderRadius: 12, borderWidth: 0,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1) const SizedBox(height: 8),
              ],
            ]),
          ),
        ),
      ),
    ]);
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    bool isDark = QuickHelp.isDarkMode(context);
    return ContainerCorner(
      color: isDark ? Colors.white.withOpacity(0.05) : kGrayWhite,
      borderRadius: 10, borderWidth: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        child: TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, color: kPrimaryColor, size: 18),
            border: InputBorder.none,
            labelStyle: TextStyle(color: kGrayColor, fontSize: 12),
          ),
        ),
      ),
    );
  }

  Widget _adminItem(UserModel admin) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        QuickActions.avatarWidget(admin, height: 40, width: 40),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextWithTap(admin.getFullName ?? "", fontWeight: FontWeight.w600, fontSize: 13),
          TextWithTap("ID: ${admin.getUid ?? ''}", color: kGrayColor, fontSize: 11),
        ])),
        TextWithTap("page.admin_role".tr(), color: kPrimaryColor, fontSize: 11,
            fontWeight: FontWeight.w600),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => _removeAdmin(admin),
          child: Icon(Icons.remove_circle_outline, color: earnCashColor, size: 20),
        ),
      ]),
    );
  }
}
