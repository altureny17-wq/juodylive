// ignore_for_file: must_be_immutable
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import '../../helpers/quick_help.dart';
import '../../models/BusinessPageModel.dart';
import '../../models/UserModel.dart';
import '../../ui/container_with_corner.dart';
import '../../ui/text_with_tap.dart';
import '../../utils/colors.dart';
import 'my_business_page_screen.dart';

class CreateBusinessPageScreen extends StatefulWidget {
  UserModel? currentUser;
  CreateBusinessPageScreen({this.currentUser, Key? key}) : super(key: key);
  @override
  State<CreateBusinessPageScreen> createState() => _CreateBusinessPageScreenState();
}

class _CreateBusinessPageScreenState extends State<CreateBusinessPageScreen> {
  final _nameCtrl     = TextEditingController();
  final _bioCtrl      = TextEditingController();
  final _websiteCtrl  = TextEditingController();
  final _formKey      = GlobalKey<FormState>();

  File? _avatarFile;
  File? _coverFile;
  String _selectedCategory = BusinessPageModel.catBusiness;
  bool _saving = false;

  final List<Map<String, String>> _categories = [
    {"key": BusinessPageModel.catBusiness,     "label": "page.cat_business".tr()},
    {"key": BusinessPageModel.catEntertainment,"label": "page.cat_entertainment".tr()},
    {"key": BusinessPageModel.catNews,         "label": "page.cat_news".tr()},
    {"key": BusinessPageModel.catSports,       "label": "page.cat_sports".tr()},
    {"key": BusinessPageModel.catTechnology,   "label": "page.cat_technology".tr()},
    {"key": BusinessPageModel.catFashion,      "label": "page.cat_fashion".tr()},
    {"key": BusinessPageModel.catFood,         "label": "page.cat_food".tr()},
    {"key": BusinessPageModel.catHealth,       "label": "page.cat_health".tr()},
    {"key": BusinessPageModel.catOther,        "label": "page.cat_other".tr()},
  ];

  @override
  void dispose() {
    _nameCtrl.dispose(); _bioCtrl.dispose(); _websiteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage({required bool isCover}) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    setState(() {
      if (isCover) _coverFile  = File(picked.path);
      else          _avatarFile = File(picked.path);
    });
  }

  Future<void> _createPage() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    QuickHelp.showLoadingDialog(context);

    try {
      final page = BusinessPageModel()
        ..setOwner    = widget.currentUser!
        ..setOwnerId  = widget.currentUser!.objectId!
        ..setName     = _nameCtrl.text.trim()
        ..setBio      = _bioCtrl.text.trim()
        ..setCategory = _selectedCategory
        ..setWebsite  = _websiteCtrl.text.trim()
        ..setIsActive = true;

      // رفع صورة الملف الشخصي
      if (_avatarFile != null) {
        final avatarParse = ParseWebFile(
          _avatarFile!.readAsBytesSync(),
          name: "page_avatar.jpg",
          url: "",
        );
        await avatarParse.save();
        page.setAvatar = avatarParse;
      }

      // رفع صورة الغلاف
      if (_coverFile != null) {
        final coverParse = ParseWebFile(
          _coverFile!.readAsBytesSync(),
          name: "page_cover.jpg",
          url: "",
        );
        await coverParse.save();
        page.setCover = coverParse;
      }

      final response = await page.save();
      QuickHelp.hideLoadingDialog(context);

      if (response.success && response.results != null) {
        final savedPage = response.results!.first as BusinessPageModel;
        QuickHelp.showAppNotificationAdvanced(
          context: context,
          title: "page.created_success".tr(),
          message: "page.created_success_msg".tr(namedArgs: {"name": savedPage.getName ?? ""}),
          isError: false,
        );
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) {
          QuickHelp.goToNavigatorScreen(
            context,
            MyBusinessPageScreen(
              currentUser: widget.currentUser,
              page: savedPage,
            ),
          );
        }
      } else {
        QuickHelp.showAppNotificationAdvanced(
          context: context,
          title: "error".tr(),
          message: response.error?.message ?? "page.create_failed".tr(),
        );
      }
    } catch (e) {
      QuickHelp.hideLoadingDialog(context);
      debugPrint("CreatePage error: $e");
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = QuickHelp.isDarkMode(context);
    Size size   = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: isDark ? kContentDarkShadow : kGrayWhite,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: BackButton(color: isDark ? Colors.white : kContentColorLightTheme),
        centerTitle: true,
        title: TextWithTap("page.create_page".tr(), fontWeight: FontWeight.bold),
        actions: [
          TextButton(
            onPressed: _saving ? null : _createPage,
            child: TextWithTap(
              "page.publish".tr(),
              color: kPrimaryColor,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ── صورة الغلاف ───────────────────────────────────────────
              GestureDetector(
                onTap: () => _pickImage(isCover: true),
                child: Container(
                  height: 160,
                  width: double.infinity,
                  color: kPrimaryColor.withOpacity(0.15),
                  child: _coverFile != null
                      ? Image.file(_coverFile!, fit: BoxFit.cover)
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined,
                                color: kPrimaryColor, size: 40),
                            TextWithTap("page.add_cover".tr(),
                                color: kPrimaryColor, marginTop: 8),
                          ],
                        ),
                ),
              ),

              // ── صورة الملف الشخصي ─────────────────────────────────────
              Transform.translate(
                offset: const Offset(0, -40),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => _pickImage(isCover: false),
                      child: Stack(
                        children: [
                          ContainerCorner(
                            width: 90, height: 90,
                            borderRadius: 50,
                            color: kGrayColor.withOpacity(0.2),
                            borderColor: Colors.white,
                            borderWidth: 3,
                            child: _avatarFile != null
                                ? ClipOval(child: Image.file(_avatarFile!, fit: BoxFit.cover))
                                : Icon(Icons.store, color: kPrimaryColor, size: 40),
                          ),
                          Positioned(
                            bottom: 0, right: 0,
                            child: ContainerCorner(
                              width: 26, height: 26,
                              borderRadius: 50,
                              color: kPrimaryColor,
                              borderWidth: 0,
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextWithTap("page.page_avatar".tr(),
                        color: kGrayColor, fontSize: 12, marginTop: 4),
                  ],
                ),
              ),

              // ── نموذج المعلومات ───────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _inputField(
                      controller: _nameCtrl,
                      label: "page.page_name".tr(),
                      hint: "page.page_name_hint".tr(),
                      icon: Icons.store_outlined,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? "page.name_required".tr() : null,
                    ),
                    const SizedBox(height: 12),
                    _inputField(
                      controller: _bioCtrl,
                      label: "page.page_bio".tr(),
                      hint: "page.page_bio_hint".tr(),
                      icon: Icons.info_outline,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    _inputField(
                      controller: _websiteCtrl,
                      label: "page.website".tr(),
                      hint: "https://",
                      icon: Icons.link,
                    ),
                    const SizedBox(height: 12),

                    // ── الفئة ──────────────────────────────────────────
                    ContainerCorner(
                      color: isDark ? kContentColorLightTheme : Colors.white,
                      borderRadius: 12,
                      borderWidth: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextWithTap(
                              "page.category".tr(),
                              fontWeight: FontWeight.w600,
                              marginBottom: 10,
                            ),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _categories.map((cat) {
                                final bool selected = cat["key"] == _selectedCategory;
                                return GestureDetector(
                                  onTap: () => setState(() => _selectedCategory = cat["key"]!),
                                  child: ContainerCorner(
                                    borderRadius: 20,
                                    borderWidth: 0,
                                    color: selected
                                        ? kPrimaryColor
                                        : kGrayColor.withOpacity(0.12),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      child: TextWithTap(
                                        cat["label"]!,
                                        color: selected ? Colors.white : kGrayColor,
                                        fontSize: 12,
                                        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    bool isDark = QuickHelp.isDarkMode(context);
    return ContainerCorner(
      color: isDark ? kContentColorLightTheme : Colors.white,
      borderRadius: 12,
      borderWidth: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            prefixIcon: Icon(icon, color: kPrimaryColor, size: 20),
            border: InputBorder.none,
            labelStyle: TextStyle(color: kGrayColor, fontSize: 13),
          ),
        ),
      ),
    );
  }
}
