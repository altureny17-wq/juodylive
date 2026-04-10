// ignore_for_file: must_be_immutable
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import '../../helpers/quick_actions.dart';
import 'create_page_screen.dart';
import 'page_settings_screen.dart';
import '../../helpers/quick_help.dart';
import '../../models/BusinessPageModel.dart';
import '../../models/PostsModel.dart';
import '../../models/UserModel.dart';
import '../../ui/container_with_corner.dart';
import '../../ui/text_with_tap.dart';
import '../../utils/colors.dart';
import '../feed/create_pictures_post_screen.dart';
import '../feed/create_text_post_screen.dart';
import '../feed/create_video_post_screen.dart';

class MyBusinessPageScreen extends StatefulWidget {
  UserModel? currentUser;
  BusinessPageModel? page;
  MyBusinessPageScreen({this.currentUser, this.page, Key? key}) : super(key: key);
  @override
  State<MyBusinessPageScreen> createState() => _MyBusinessPageScreenState();
}

class _MyBusinessPageScreenState extends State<MyBusinessPageScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<PostsModel> _posts = [];
  bool _loadingPosts = true;
  bool _isOwner = false;
  bool _isActualOwner = false; // المالك الأصلي فقط

  @override
  void initState() {
    super.initState();
    _tabs     = TabController(length: 2, vsync: this);
    // ✅ المالك أو المدير يمكنه إدارة الصفحة
    _isOwner = widget.page?.isManagerOrOwner(widget.currentUser?.objectId ?? "") ?? false;
    _isActualOwner = widget.page?.getOwnerId == widget.currentUser?.objectId;
    _loadPosts();
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _loadPosts() async {
    try {
      final q = QueryBuilder<PostsModel>(PostsModel())
        ..whereEqualTo(PostsModel.keyIsPagePost, true)
        ..whereEqualTo(PostsModel.keyPageId, widget.page!.objectId!)
        ..orderByDescending(PostsModel.keyCreatedAt)
        ..includeObject([PostsModel.keyAuthor]);
      final r = await q.query();
      if (r.success && r.results != null && mounted) {
        setState(() {
          _posts = r.results!.cast<PostsModel>();
          _loadingPosts = false;
        });
      } else {
        if (mounted) setState(() => _loadingPosts = false);
      }
    } catch (e) {
      debugPrint("LoadPosts error: $e");
      if (mounted) setState(() => _loadingPosts = false);
    }
  }

  Future<void> _followPage() async {
    final uid = widget.currentUser?.objectId ?? "";
    final isFollowing = widget.page?.getFollowerIds?.contains(uid) ?? false;

    setState(() {
      if (isFollowing) {
        widget.page?.removeFollowerId = uid;
      } else {
        widget.page?.setFollowerId = uid;
      }
    });
    await widget.page?.save();
  }

  void _openCreatePost(String type) {
    Widget screen;
    switch (type) {
      case "text":
        screen = CreateTextPostScreen(
          currentUser: widget.currentUser,
          pageId: widget.page?.objectId,
          pageName: widget.page?.getName,
        );
        break;
      case "photo":
        screen = CreatePicturesPostScreen(
          currentUser: widget.currentUser,
          pageId: widget.page?.objectId,
          pageName: widget.page?.getName,
        );
        break;
      default:
        screen = CreateVideoPostScreen(
          currentUser: widget.currentUser,
          pageId: widget.page?.objectId,
          pageName: widget.page?.getName,
        );
    }
    QuickHelp.goToNavigatorScreen(context, screen);
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = QuickHelp.isDarkMode(context);
    Size size   = MediaQuery.of(context).size;
    final bool isFollowing =
        widget.page?.getFollowerIds?.contains(widget.currentUser?.objectId) ?? false;

    return Scaffold(
      backgroundColor: isDark ? kContentDarkShadow : kGrayWhite,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            automaticallyImplyLeading: true,
            leading: BackButton(color: Colors.white),
            actions: [
              // ✅ زر الإعدادات (للمالك والمديرين)
            if (_isOwner)
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.white),
                onPressed: () => _openSettings(),
              ),
              if (_isOwner)
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                  onPressed: () => _showCreatePostSheet(),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // غلاف الصفحة
                  widget.page?.getCover != null
                      ? Image.network(widget.page!.getCover!.url!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(color: kPrimaryColor))
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [kPrimaryColor, kSecondaryColor ?? kPrimaryColor],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                  // تدرج شفاف في الأسفل
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.5)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── معلومات الصفحة ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: ContainerCorner(
              color: isDark ? kContentColorLightTheme : Colors.white,
              borderWidth: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // صورة الصفحة
                        Stack(children: [
                          ContainerCorner(
                            width: 75, height: 75,
                            borderRadius: 12,
                            color: kPrimaryColor.withOpacity(0.15),
                            borderColor: Colors.white,
                            borderWidth: 2,
                            child: widget.page?.getAvatar != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      widget.page!.getAvatar!.url!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Icon(Icons.store, color: kPrimaryColor, size: 36),
                          ),
                          if (widget.page?.getIsVerified == true)
                            Positioned(
                              bottom: 0, right: 0,
                              child: ContainerCorner(
                                width: 20, height: 20,
                                borderRadius: 50,
                                color: Colors.blue,
                                borderWidth: 0,
                                child: const Icon(Icons.verified, color: Colors.white, size: 12),
                              ),
                            ),
                        ]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Flexible(
                                  child: TextWithTap(
                                    widget.page?.getName ?? "",
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ]),
                              TextWithTap(
                                _categoryLabel(widget.page?.getCategory),
                                color: kPrimaryColor,
                                fontSize: 12,
                                marginTop: 2,
                              ),
                              TextWithTap(
                                "page.followers_count".tr(namedArgs: {
                                  "count": "${widget.page?.followersCount ?? 0}"
                                }),
                                color: kGrayColor,
                                fontSize: 12,
                                marginTop: 2,
                              ),
                            ],
                          ),
                        ),
                        // زر المتابعة / التعديل
                        if (!_isOwner)
                          GestureDetector(
                            onTap: _followPage,
                            child: ContainerCorner(
                              borderRadius: 20,
                              borderWidth: 0,
                              color: isFollowing
                                  ? kGrayColor.withOpacity(0.15)
                                  : kPrimaryColor,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                child: TextWithTap(
                                  isFollowing
                                      ? "page.following".tr()
                                      : "page.follow".tr(),
                                  color: isFollowing ? kGrayColor : Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    if ((widget.page?.getBio ?? "").isNotEmpty) ...[
                      const SizedBox(height: 10),
                      TextWithTap(
                        widget.page?.getBio ?? "",
                        color: kGrayColor,
                        fontSize: 13,
                      ),
                    ],
                    if ((widget.page?.getWebsite ?? "").isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(children: [
                        Icon(Icons.link, size: 14, color: kPrimaryColor),
                        TextWithTap(
                          widget.page?.getWebsite ?? "",
                          color: kPrimaryColor,
                          fontSize: 12,
                          marginLeft: 4,
                        ),
                      ]),
                    ],

                    // ── إحصاءات ─────────────────────────────────────────
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _statItem("${_posts.length}", "page.posts".tr()),
                        _statItem(
                          "${widget.page?.followersCount ?? 0}",
                          "page.followers".tr(),
                        ),
                        _statItem(
                          "${widget.page?.getPostCount ?? 0}",
                          "page.total_posts".tr(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── أزرار إنشاء المنشور (للمالك فقط) ───────────────────────────
          if (_isOwner)
            SliverToBoxAdapter(
              child: ContainerCorner(
                color: isDark ? kContentColorLightTheme : Colors.white,
                marginTop: 8,
                borderWidth: 0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      QuickActions.avatarWidget(widget.currentUser!, height: 36, width: 36),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _openCreatePost("text"),
                          child: ContainerCorner(
                            borderRadius: 20,
                            color: kGrayColor.withOpacity(0.1),
                            borderWidth: 0,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              child: TextWithTap(
                                "page.whats_on_your_mind".tr(),
                                color: kGrayColor,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── تبويبات ──────────────────────────────────────────────────────
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyTabBar(
              TabBar(
                controller: _tabs,
                indicatorColor: kPrimaryColor,
                labelColor: kPrimaryColor,
                unselectedLabelColor: kGrayColor,
                tabs: [
                  Tab(text: "page.posts".tr()),
                  Tab(text: "page.about".tr()),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabs,
          children: [
            _postsTab(),
            _aboutTab(),
          ],
        ),
      ),
    );
  }

  // ── تبويب المنشورات ──────────────────────────────────────────────────────
  Widget _postsTab() {
    if (_loadingPosts) return const Center(child: CircularProgressIndicator());
    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.post_add, size: 60, color: kGrayColor.withOpacity(0.4)),
            TextWithTap(
              "page.no_posts_yet".tr(),
              color: kGrayColor,
              marginTop: 12,
              fontSize: 15,
            ),
            if (_isOwner) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _showCreatePostSheet(),
                child: ContainerCorner(
                  borderRadius: 20,
                  borderWidth: 0,
                  color: kPrimaryColor,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    child: TextWithTap("page.create_first_post".tr(),
                        color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPosts,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _posts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _postCard(_posts[i]),
      ),
    );
  }

  Widget _postCard(PostsModel post) {
    bool isDark = QuickHelp.isDarkMode(context);
    return ContainerCorner(
      color: isDark ? kContentColorLightTheme : Colors.white,
      borderRadius: 12,
      borderWidth: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ رأس المنشور — يعرض اسم وصورة الصفحة التجارية
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              // صورة الصفحة
              ContainerCorner(
                width: 42, height: 42,
                borderRadius: 10,
                borderWidth: 0,
                color: kPrimaryColor.withOpacity(0.12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: widget.page?.getAvatar?.url != null
                      ? Image.network(widget.page!.getAvatar!.url!, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Icon(Icons.store, color: kPrimaryColor, size: 22))
                      : Icon(Icons.store, color: kPrimaryColor, size: 22),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    TextWithTap(
                      widget.page?.getName ?? "",
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    if (widget.page?.getIsVerified == true) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified, color: Colors.blue, size: 14),
                    ],
                  ]),
                  TextWithTap(
                    post.createdAt != null
                        ? QuickHelp.getMessageListTime(post.createdAt!)
                        : "",
                    color: kGrayColor,
                    fontSize: 11,
                  ),
                ],
              ),
              const Spacer(),
              if (_isOwner)
                IconButton(
                  icon: Icon(Icons.more_vert, color: kGrayColor, size: 18),
                  onPressed: () => _showPostOptions(post),
                ),
            ]),
          ),
          // نص المنشور
          if ((post.getText ?? "").isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextWithTap(post.getText ?? "",
                  fontSize: 14, marginBottom: 8),
            ),
          // صورة المنشور
          if (post.getImage != null)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(12)),
              child: Image.network(
                post.getImage!.url!,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),
          // تفاعلات
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(children: [
              Icon(Icons.favorite_border, size: 18, color: kGrayColor),
              TextWithTap("${post.getLikes?.length ?? 0}",
                  color: kGrayColor, fontSize: 12, marginLeft: 4),
              const SizedBox(width: 16),
              Icon(Icons.comment_outlined, size: 18, color: kGrayColor),
              TextWithTap("${post.getCommentCount ?? 0}",
                  color: kGrayColor, fontSize: 12, marginLeft: 4),
              const SizedBox(width: 16),
              Icon(Icons.remove_red_eye_outlined, size: 18, color: kGrayColor),
              TextWithTap("${post.getViews}",
                  color: kGrayColor, fontSize: 12, marginLeft: 4),
            ]),
          ),
        ],
      ),
    );
  }

  // ── تبويب عن الصفحة ─────────────────────────────────────────────────────
  Widget _aboutTab() {
    bool isDark = QuickHelp.isDarkMode(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ContainerCorner(
          color: isDark ? kContentColorLightTheme : Colors.white,
          borderRadius: 12,
          borderWidth: 0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _aboutRow(Icons.category_outlined,
                    "page.category".tr(),
                    _categoryLabel(widget.page?.getCategory)),
                if ((widget.page?.getBio ?? "").isNotEmpty)
                  _aboutRow(Icons.info_outline,
                      "page.page_bio".tr(),
                      widget.page?.getBio ?? ""),
                if ((widget.page?.getWebsite ?? "").isNotEmpty)
                  _aboutRow(Icons.link,
                      "page.website".tr(),
                      widget.page?.getWebsite ?? ""),
                _aboutRow(Icons.calendar_today_outlined,
                    "page.created_at".tr(),
                    widget.page?.createdAt != null
                        ? QuickHelp.getMessageListTime(widget.page!.createdAt!)
                        : ""),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _aboutRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: kPrimaryColor, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextWithTap(label, color: kGrayColor, fontSize: 11),
            TextWithTap(value, fontWeight: FontWeight.w500, fontSize: 13),
          ]),
        ),
      ]),
    );
  }

  // ── مساعدات ──────────────────────────────────────────────────────────────
  Widget _statItem(String value, String label) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      TextWithTap(value, fontWeight: FontWeight.bold, fontSize: 18),
      TextWithTap(label, color: kGrayColor, fontSize: 11, marginTop: 2),
    ]);
  }

  String _categoryLabel(String? cat) {
    switch (cat) {
      case BusinessPageModel.catBusiness:     return "page.cat_business".tr();
      case BusinessPageModel.catEntertainment:return "page.cat_entertainment".tr();
      case BusinessPageModel.catNews:         return "page.cat_news".tr();
      case BusinessPageModel.catSports:       return "page.cat_sports".tr();
      case BusinessPageModel.catTechnology:   return "page.cat_technology".tr();
      case BusinessPageModel.catFashion:      return "page.cat_fashion".tr();
      case BusinessPageModel.catFood:         return "page.cat_food".tr();
      case BusinessPageModel.catHealth:       return "page.cat_health".tr();
      default: return "page.cat_other".tr();
    }
  }

  void _showCreatePostSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: QuickHelp.isDarkMode(context)
              ? kContentColorLightTheme
              : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextWithTap("page.create_post_for".tr(
                namedArgs: {"name": widget.page?.getName ?? ""}),
                fontWeight: FontWeight.bold, fontSize: 15, marginBottom: 20),
            _createPostOption(Icons.text_fields, "page.text_post".tr(),
                kPrimaryColor, () { Navigator.pop(context); _openCreatePost("text"); }),
            _createPostOption(Icons.photo_library_outlined, "page.photo_post".tr(),
                kOrangeColor, () { Navigator.pop(context); _openCreatePost("photo"); }),
            _createPostOption(Icons.videocam_outlined, "page.video_post".tr(),
                earnCashColor, () { Navigator.pop(context); _openCreatePost("video"); }),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _createPostOption(IconData icon, String label, Color color, VoidCallback onTap) {
    return ListTile(
      leading: ContainerCorner(
        width: 44, height: 44,
        borderRadius: 12,
        borderWidth: 0,
        color: color.withOpacity(0.12),
        child: Icon(icon, color: color, size: 22),
      ),
      title: TextWithTap(label, fontWeight: FontWeight.w500),
      onTap: onTap,
    );
  }

  void _showPostOptions(PostsModel post) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ✅ المالك والمديرون يمكنهم الحذف
          if (_isOwner)
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: TextWithTap("delete_".tr(), color: Colors.red),
              onTap: () async {
                Navigator.pop(context);
                QuickHelp.showLoadingDialog(context);
                await post.delete();
                QuickHelp.hideLoadingDialog(context);
                _loadPosts();
              },
            ),
        ],
      ),
    );
  }

  Future<void> _openSettings() async {
    final updated = await QuickHelp.goToNavigatorScreenForResult(
      context,
      PageSettingsScreen(
        currentUser: widget.currentUser,
        page: widget.page!,
      ),
    );
    if (updated != null && updated is BusinessPageModel && mounted) {
      setState(() => widget.page = updated);
    }
  }
}

// ── Sticky Tab Bar ────────────────────────────────────────────────────────────
class _StickyTabBar extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _StickyTabBar(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(_, __, ___) => Container(
    color: Colors.white,
    child: tabBar,
  );

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}
