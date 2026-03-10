// ignore_for_file: must_be_immutable, use_build_context_synchronously
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:juodylive/helpers/quick_actions.dart';
import 'package:juodylive/helpers/quick_help.dart';
import 'package:juodylive/models/LiveStreamingModel.dart';
import 'package:juodylive/models/UserModel.dart';
import 'package:juodylive/models/GiftsModel.dart';
import 'package:juodylive/ui/container_with_corner.dart';
import 'package:juodylive/ui/text_with_tap.dart';
import 'package:juodylive/utils/colors.dart';
import 'package:juodylive/home/prebuild_live/global_private_live_price_sheet.dart';
import 'game_live_screen.dart';

class GameLivePreviewScreen extends StatefulWidget {
  UserModel? currentUser;

  GameLivePreviewScreen({Key? key, this.currentUser}) : super(key: key);

  static String route = "/game/live/preview";

  @override
  _GameLivePreviewScreenState createState() => _GameLivePreviewScreenState();
}

class _GameLivePreviewScreenState extends State<GameLivePreviewScreen>
    with TickerProviderStateMixin {

  // ─── Game categories ───────────────────────────────────────────────────────
  final List<Map<String, dynamic>> gameCategories = [
    {'name': 'PUBG Mobile',      'icon': '🎮', 'color': Color(0xFFF9A825)},
    {'name': 'Free Fire',        'icon': '🔥', 'color': Color(0xFFE53935)},
    {'name': 'COD Mobile',       'icon': '💀', 'color': Color(0xFF37474F)},
    {'name': 'Fortnite',         'icon': '⚡', 'color': Color(0xFF1565C0)},
    {'name': 'Mobile Legends',   'icon': '⚔️', 'color': Color(0xFF6A1B9A)},
    {'name': 'Clash of Clans',   'icon': '🏰', 'color': Color(0xFF2E7D32)},
    {'name': 'Genshin Impact',   'icon': '🌸', 'color': Color(0xFF00838F)},
    {'name': 'Honor of Kings',   'icon': '👑', 'color': Color(0xFFAD1457)},
    {'name': 'Valorant',         'icon': '🎯', 'color': Color(0xFFD50000)},
    {'name': 'FIFA Mobile',      'icon': '⚽', 'color': Color(0xFF1B5E20)},
    {'name': 'Roblox',           'icon': '🧱', 'color': Color(0xFFBF360C)},
    {'name': 'أخرى',            'icon': '🕹️', 'color': Color(0xFF455A64)},
  ];

  // ─── Stream quality options ─────────────────────────────────────────────────
  final List<Map<String, dynamic>> qualityOptions = [
    {'label': 'HD 720p',  'sub': '3 Mbps',   'value': '720p'},
    {'label': 'FHD 1080p','sub': '6 Mbps',   'value': '1080p'},
    {'label': 'SD 480p',  'sub': '1.5 Mbps', 'value': '480p'},
  ];

  // ─── State ──────────────────────────────────────────────────────────────────
  int selectedGameIndex = 0;
  int selectedQualityIndex = 0;
  bool enableMic = true;
  bool privateLive = false;
  GiftsModel? privateLiveGiftPrice;
  TextEditingController titleController = TextEditingController();
  File? thumbnailFile;
  bool isStarting = false;

  // Tags
  List<String> selectedTags = [];

  @override
  void initState() {
    super.initState();
    titleController.text =
        "يلعب ${widget.currentUser?.getFirstName ?? ''} ${gameCategories[0]['name']} 🎮";
    selectedTags = [LiveStreamingModel.liveSubGame];
  }

  @override
  void dispose() {
    titleController.dispose();
    super.dispose();
  }

  // ─── Pick thumbnail ─────────────────────────────────────────────────────────
  Future<void> pickThumbnail() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() => thumbnailFile = File(picked.path));
    }
  }

  // ─── Start stream ───────────────────────────────────────────────────────────
  void startGameStream({bool isScreenShare = false, bool isLandscape = false}) async {
    if (titleController.text.trim().isEmpty) {
      QuickHelp.showAppNotificationAdvanced(
        title: "يرجى إدخال عنوان البث",
        context: context,
        isError: true,
      );
      return;
    }

    setState(() => isStarting = true);
    QuickHelp.showLoadingDialog(context, isDismissible: false);

    // Close any existing live
    final checkQuery = QueryBuilder<LiveStreamingModel>(LiveStreamingModel());
    checkQuery.whereEqualTo(LiveStreamingModel.keyAuthorId, widget.currentUser!.objectId);
    checkQuery.whereEqualTo(LiveStreamingModel.keyStreaming, true);
    final checkResponse = await checkQuery.query();
    if (checkResponse.success && checkResponse.results != null) {
      final oldLive = checkResponse.results!.first as LiveStreamingModel;
      oldLive.setStreaming = false;
      await oldLive.save();
    }

    // Create new game live
    final liveModel = LiveStreamingModel();
    liveModel.setStreamingChannel = widget.currentUser!.objectId! +
        widget.currentUser!.getUid!.toString() +
        "_game_live";
    liveModel.setAuthor = widget.currentUser!;
    liveModel.setAuthorId = widget.currentUser!.objectId!;
    liveModel.setAuthorUid = widget.currentUser!.getUid!;
    liveModel.setAuthorUserName = widget.currentUser!.getUsername!;
    liveModel.setLiveTitle = titleController.text.trim();
    liveModel.setLiveType = LiveStreamingModel.liveVideo;
    liveModel.setLiveSubType = LiveStreamingModel.liveSubGame;
    liveModel.setHashtags = selectedTags;
    liveModel.addAuthorTotalDiamonds = widget.currentUser!.getDiamondsTotal!;
    liveModel.setFirstLive = widget.currentUser!.isFirstLive!;
    liveModel.setStreaming = true;
    liveModel.addViewersCount = 0;
    liveModel.addDiamonds = 0;

    if (widget.currentUser!.getLiveCover != null) {
      liveModel.setImage = widget.currentUser!.getLiveCover!;
    } else if (widget.currentUser!.getAvatar != null) {
      liveModel.setImage = widget.currentUser!.getAvatar!;
    }

    if (widget.currentUser!.getGeoPoint != null) {
      liveModel.setStreamingGeoPoint = widget.currentUser!.getGeoPoint!;
    }

    if (privateLive && privateLiveGiftPrice != null) {
      liveModel.setPrivate = true;
      liveModel.setPrivateLivePrice = privateLiveGiftPrice!;
    }

    final saveResponse = await liveModel.save();

    if (saveResponse.success && saveResponse.results != null) {
      final createdLive = saveResponse.results!.first as LiveStreamingModel;
      QuickHelp.hideLoadingDialog(context);
      setState(() => isStarting = false);

      // ضبط اتجاه الشاشة قبل الانتقال
      if (isScreenShare) {
        if (isLandscape) {
          await SystemChrome.setPreferredOrientations([
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ]);
        } else {
          await SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp,
          ]);
        }
      }

      QuickHelp.goToNavigatorScreen(
        context,
        GameLiveScreen(
          currentUser: widget.currentUser,
          liveStreaming: createdLive,
          liveID: createdLive.getStreamingChannel!,
          isHost: true,
          selectedGame: gameCategories[selectedGameIndex]['name'],
          enableMic: enableMic,
          autoStartScreenShare: isScreenShare,
        ),
      );
    } else {
      QuickHelp.hideLoadingDialog(context);
      setState(() => isStarting = false);
      QuickHelp.showAppNotificationAdvanced(
        title: "فشل إنشاء البث",
        context: context,
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: Stack(
        children: [
          // Gradient BG
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0A0A1A), Color(0xFF0D1B2A), Color(0xFF0A0A1A)],
              ),
            ),
          ),

          // Glow effect
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF7C3AED).withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        _buildProfileRow(),
                        const SizedBox(height: 20),
                        _buildTitleField(),
                        const SizedBox(height: 20),
                        _buildGameSelector(),
                        const SizedBox(height: 20),
                        // ─── قسم بث الشاشة ───────────────────────────────
                        _buildScreenShareSection(),
                        const SizedBox(height: 20),
                        _buildQualitySelector(),
                        const SizedBox(height: 20),
                        _buildStreamOptions(),
                        const SizedBox(height: 20),
                        _buildPrivacyRow(),
                        const SizedBox(height: 30),
                        _buildStartButton(size),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 16),
            ),
          ),
          const Expanded(
            child: Text(
              "بث الألعاب 🎮",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Live indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, color: Colors.white, size: 8),
                SizedBox(width: 4),
                Text("LIVE",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Profile row ─────────────────────────────────────────────────────────────
  Widget _buildProfileRow() {
    return Row(
      children: [
        // Avatar
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF7C3AED), width: 2),
          ),
          child: ClipOval(
            child: QuickActions.avatarWidget(
              widget.currentUser!,
              width: 52,
              height: 52,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.currentUser?.getFullName ?? "",
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.people_outline, color: Color(0xFF9CA3AF), size: 13),
                  const SizedBox(width: 4),
                  Text(
                    "${QuickHelp.convertToK(widget.currentUser?.getFollowers?.length ?? 0)} متابع",
                    style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.diamond_outlined, color: Color(0xFFF59E0B), size: 13),
                  const SizedBox(width: 4),
                  Text(
                    QuickHelp.checkFundsWithString(amount: (widget.currentUser?.getDiamondsTotal ?? 0).toString()),
                    style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Thumbnail picker
        GestureDetector(
          onTap: pickThumbnail,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: thumbnailFile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(thumbnailFile!, fit: BoxFit.cover),
                  )
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined,
                          color: Color(0xFF9CA3AF), size: 20),
                      SizedBox(height: 2),
                      Text("غلاف",
                          style:
                              TextStyle(color: Color(0xFF9CA3AF), fontSize: 9)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  // ─── Title field ─────────────────────────────────────────────────────────────
  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("عنوان البث",
            style: TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 12,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 14),
                child: Text("🎮", style: TextStyle(fontSize: 18)),
              ),
              Expanded(
                child: TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  maxLength: 60,
                  decoration: InputDecoration(
                    hintText: "أخبر المشاهدين بماذا تلعب...",
                    hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.3), fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 14),
                    counterText: "",
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      titleController.text =
                          "يلعب ${widget.currentUser?.getFirstName ?? ''} ${gameCategories[selectedGameIndex]['name']} 🎮";
                    });
                  },
                  child: const Icon(Icons.refresh_rounded,
                      color: Color(0xFF7C3AED), size: 18),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Game selector ─────────────────────────────────────────────────────────
  Widget _buildGameSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("اختر اللعبة",
            style: TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 12,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: gameCategories.length,
            itemBuilder: (context, index) {
              final game = gameCategories[index];
              final isSelected = selectedGameIndex == index;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedGameIndex = index;
                    titleController.text =
                        "يلعب ${widget.currentUser?.getFirstName ?? ''} ${game['name']} ${game['icon']}";
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 10),
                  width: 72,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (game['color'] as Color).withOpacity(0.2)
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? (game['color'] as Color)
                          : Colors.white.withOpacity(0.08),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(game['icon'], style: const TextStyle(fontSize: 26)),
                      const SizedBox(height: 4),
                      Text(
                        game['name'],
                        style: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
                          fontSize: 9,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ─── Quality selector ────────────────────────────────────────────────────────
  Widget _buildQualitySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("جودة البث",
            style: TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 12,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Row(
          children: List.generate(qualityOptions.length, (index) {
            final q = qualityOptions[index];
            final isSelected = selectedQualityIndex == index;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => selectedQualityIndex = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(colors: [
                            Color(0xFF7C3AED),
                            Color(0xFF5B21B6)
                          ])
                        : null,
                    color: isSelected ? null : Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : Colors.white.withOpacity(0.08),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(q['label'],
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF9CA3AF),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          )),
                      const SizedBox(height: 2),
                      Text(q['sub'],
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white70
                                : const Color(0xFF6B7280),
                            fontSize: 10,
                          )),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  // ─── Screen Share Section ────────────────────────────────────────────────────
  Widget _buildScreenShareSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "بث الشاشة 📱",
          style: TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            // ─ خيار طولي Portrait ─────────────────────────────────────────
            Expanded(
              child: GestureDetector(
                onTap: isStarting
                    ? null
                    : () => startGameStream(
                        isScreenShare: true, isLandscape: false),
                child: Container(
                  height: 110,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF1D4ED8).withOpacity(0.9),
                        const Color(0xFF3B82F6).withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF3B82F6).withOpacity(0.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withOpacity(0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // أيقونة الهاتف الطولي
                      Container(
                        width: 28,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.6),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(bottom: 3),
                              width: 8,
                              height: 2,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "طولي",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Portrait",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // ─ خيار عرضي Landscape ────────────────────────────────────────
            Expanded(
              child: GestureDetector(
                onTap: isStarting
                    ? null
                    : () => startGameStream(
                        isScreenShare: true, isLandscape: true),
                child: Container(
                  height: 110,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF065F46).withOpacity(0.9),
                        const Color(0xFF10B981).withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF10B981).withOpacity(0.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // أيقونة الهاتف العرضي
                      Container(
                        width: 46,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.6),
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(right: 3),
                              width: 2,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "عرضي",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Landscape",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // تلميح
        Row(
          children: [
            Icon(Icons.touch_app_outlined,
                color: Colors.white.withOpacity(0.35), size: 13),
            const SizedBox(width: 5),
            Text(
              "اضغط على أحدهما → سيبدأ البث ويذهب التطبيق للخلفية تلقائياً",
              style: TextStyle(
                  color: Colors.white.withOpacity(0.35), fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Stream options ──────────────────────────────────────────────────────────
  Widget _buildStreamOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("إعدادات البث",
            style: TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 12,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            children: [
              _buildToggleRow(
                icon: Icons.mic_outlined,
                iconColor: const Color(0xFF10B981),
                title: "الميكروفون",
                subtitle: "يسمع المشاهدون صوتك",
                value: enableMic,
                onChanged: (v) => setState(() => enableMic = v),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToggleRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                Text(subtitle,
                    style: const TextStyle(
                        color: Color(0xFF6B7280), fontSize: 11)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF7C3AED),
            activeTrackColor: const Color(0xFF7C3AED).withOpacity(0.3),
            inactiveThumbColor: const Color(0xFF6B7280),
            inactiveTrackColor: Colors.white.withOpacity(0.1),
          ),
        ],
      ),
    );
  }

  // ─── Privacy row ─────────────────────────────────────────────────────────────
  Widget _buildPrivacyRow() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          _buildToggleRow(
            icon: Icons.lock_outline_rounded,
            iconColor: const Color(0xFFF59E0B),
            title: "بث خاص (مدفوع)",
            subtitle: "يشاهده فقط من يدفع",
            value: privateLive,
            onChanged: (v) {
              setState(() => privateLive = v);
              if (v) {
                PrivateLivePriceWidget(
                  context: context,
                  onCancel: () {
                    QuickHelp.hideLoadingDialog(context);
                    setState(() {
                      privateLive = false;
                      privateLiveGiftPrice = null;
                    });
                  },
                  onGiftSelected: (gift) {
                    QuickHelp.hideLoadingDialog(context);
                    setState(() => privateLiveGiftPrice = gift);
                  },
                );
              } else {
                setState(() => privateLiveGiftPrice = null);
              }
            },
          ),
          if (privateLive && privateLiveGiftPrice != null)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFFF59E0B).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.diamond, color: Color(0xFFF59E0B), size: 16),
                    const SizedBox(width: 8),
                    Text(
                      "السعر: ${privateLiveGiftPrice!.getCoins} كوين",
                      style: const TextStyle(
                          color: Color(0xFFF59E0B),
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Start button ─────────────────────────────────────────────────────────────
  Widget _buildStartButton(Size size) {
    return GestureDetector(
      onTap: isStarting ? null : startGameStream,
      child: Container(
        width: size.width,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFFDB2777)],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C3AED).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("🎮", style: TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Text(
              isStarting ? "جاري البدء..." : "ابدأ بث اللعبة",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
