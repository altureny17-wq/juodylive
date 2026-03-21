// ignore_for_file: must_be_immutable, use_build_context_synchronously
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:get/instance_manager.dart';
import 'package:lottie/lottie.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:zego_uikit_prebuilt_live_streaming/zego_uikit_prebuilt_live_streaming.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';

import '../../app/setup.dart';
import '../../helpers/quick_actions.dart';
import '../../helpers/quick_cloud.dart';
import '../../helpers/quick_help.dart';
import '../../home/controller/controller.dart';
import '../../models/GiftsModel.dart';
import '../../models/GiftsSentModel.dart';
import '../../models/LeadersModel.dart';
import '../../models/LiveStreamingModel.dart';
import '../../models/LiveViewersModel.dart';
import '../../models/UserModel.dart';
import '../../utils/colors.dart';
import '../coins/coins_payment_widget.dart';
import '../live_end/live_end_screen.dart';
import '../live_end/live_end_report_screen.dart';
import '../prebuild_live/gift/components/svga_player_widget.dart';
import '../prebuild_live/gift/components/mp4_player_widget.dart';
import '../prebuild_live/gift/gift_data.dart';
import '../prebuild_live/gift/gift_manager/defines.dart';
import '../prebuild_live/gift/gift_manager/gift_manager.dart';
import '../prebuild_live/gift/gift_manager/gift_extras.dart';
import '../prebuild_live/gift/components/entrance_effect_widget.dart';
import '../prebuild_live/gift/components/float_message_overlay.dart';
import '../prebuild_live/global_private_live_price_sheet.dart';
import '../prebuild_live/global_user_profil_sheet.dart';

class GameLiveScreen extends StatefulWidget {
  UserModel? currentUser;
  LiveStreamingModel? liveStreaming;
  final String liveID;
  final bool isHost;
  final String selectedGame;
  final bool enableMic;
  final bool autoStartScreenShare;

  GameLiveScreen({
    Key? key,
    required this.liveID,
    this.isHost = false,
    this.currentUser,
    this.liveStreaming,
    this.selectedGame = "PUBG Mobile",
    this.enableMic = true,
    this.autoStartScreenShare = false,
  }) : super(key: key);

  static String route = "/game/live";

  @override
  GameLiveScreenState createState() => GameLiveScreenState();
}

class GameLiveScreenState extends State<GameLiveScreen>
    with TickerProviderStateMixin {

  // Controllers
  late AnimationController _pulseController;
  Controller showGiftSendersController = Get.put(Controller());

  // Live Query
  final liveQuery = LiveQuery();
  Subscription? subscription;

  // State
  bool isMicOn = true;
  int viewerCount = 0;

  // Floating button & panel
  bool _panelVisible = false;
  bool _showScreenShareGuide = false;
  bool _screenSharingActive = false;
  bool _showGoToAppBtn = true; // تلميح الانتقال لأي تطبيق
  Offset _floatingPos = const Offset(16, 140);

  final liveStateNotifier =
      ValueNotifier<ZegoLiveStreamingState>(ZegoLiveStreamingState.idle);
  Timer? removeGiftTimer;

  // Chat
  List<Map<String, dynamic>> chatMessages = [];
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    isMicOn = widget.enableMic;

    showGiftSendersController.diamondsCounter.value =
        widget.liveStreaming?.getDiamonds?.toString() ?? "0";

    _initGifts();
    _setupLiveQuery();
    if (!widget.isHost) _addViewerToLive();

    // أظهر دليل بث الشاشة للمضيف بعد ثانية
    if (widget.isHost) {
      if (widget.autoStartScreenShare) {
        // بث الشاشة التلقائي — ابدأ الزر مباشرة بعد تحميل Zego
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            // اضغط زر بث الشاشة في Zego تلقائياً
            ZegoUIKitPrebuiltLiveStreamingController()
                .screenSharing
                .showViewInFullscreenMode(
                    ZegoUIKit().getAllUsers().first.id, true);
            // التطبيق سيذهب للخلفية تلقائياً عبر MainActivity بعد موافقة المستخدم
          }
        });
      } else {
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (mounted) setState(() => _showScreenShareGuide = true);
        });
      }
    }
  }

  // ─── Gifts ─────────────────────────────────────────────────────────────────
  Future<void> _initGifts() async {
    await loadGiftsFromServer();
    ZegoGiftManager().cache.cacheAllFiles(giftItemList);
    ZegoGiftManager().service.recvNotifier.addListener(_onGiftReceived);
    ZegoGiftManager().service.init(
      appID: Setup.zegoLiveStreamAppID,
      liveID: widget.liveID,
      localUserID: widget.currentUser!.objectId!,
      localUserName: widget.currentUser!.getFullName!,
    );
    _setupLiveGifts();
  }

  void _onGiftReceived() {
    final received = ZegoGiftManager().service.recvNotifier.value ??
        ZegoGiftProtocolItem.empty();
    queryGiftInItemList(received.name);
  }

  Future<void> _setupLiveGifts() async {
    final query = QueryBuilder<GiftsSentModel>(GiftsSentModel());
    query.whereEqualTo(GiftsSentModel.keyLiveId, widget.liveStreaming!.objectId);
    query.includeObject([GiftsSentModel.keyGift]);
    subscription = await liveQuery.client.subscribe(query);
    subscription!.on(LiveQueryEvent.create, (GiftsSentModel giftSent) async {
      await giftSent.getGift!.fetch();
      await giftSent.getReceiver!.fetch();
      await giftSent.getAuthor!.fetch();
      final receivedGift = giftSent.getGift!;
      showGiftSendersController.giftSenderList.add(giftSent.getAuthor!);
      showGiftSendersController.giftReceiverList.add(giftSent.getReceiver!);
      showGiftSendersController.receivedGiftList.add(receivedGift);
      ZegoGiftManager().playList.add(receivedGift);
      final coins = receivedGift.getCoins ?? 0;
      final current = int.tryParse(showGiftSendersController.diamondsCounter.value) ?? 0;
      showGiftSendersController.diamondsCounter.value =
          (current + QuickHelp.getDiamondsForReceiver(coins)).toString();
    });
  }

  // ─── Live Query ─────────────────────────────────────────────────────────────
  Future<void> _setupLiveQuery() async {
    final query = QueryBuilder<LiveStreamingModel>(LiveStreamingModel());
    query.whereEqualTo(LiveStreamingModel.keyObjectId, widget.liveStreaming!.objectId);
    subscription = await liveQuery.client.subscribe(query);
    subscription!.on(LiveQueryEvent.update, (LiveStreamingModel updatedLive) async {
      await updatedLive.getAuthor!.fetch();
      widget.liveStreaming = updatedLive;
      if (!mounted) return;
      setState(() => viewerCount = updatedLive.getViewersCount ?? 0);
      showGiftSendersController.diamondsCounter.value = updatedLive.getDiamonds.toString();
      if (!updatedLive.getStreaming! && !widget.isHost) {
        QuickHelp.goToNavigatorScreen(context,
            LiveEndScreen(currentUser: widget.currentUser, liveAuthor: widget.liveStreaming!.getAuthor));
      }
    });
  }

  // ─── Viewer management ──────────────────────────────────────────────────────
  Future<void> _addViewerToLive() async {
    final q = QueryBuilder<LiveViewersModel>(LiveViewersModel());
    q.whereEqualTo(LiveViewersModel.keyLiveId, widget.liveStreaming!.objectId);
    q.whereEqualTo(LiveViewersModel.keyAuthorId, widget.currentUser!.objectId);
    final r = await q.query();
    if (r.success && r.results == null) {
      final v = LiveViewersModel()
        ..setAuthor = widget.currentUser!
        ..setAuthorId = widget.currentUser!.objectId!
        ..setLiveId = widget.liveStreaming!.objectId!
        ..setLiveAuthorId = widget.liveStreaming!.getAuthorId!
        // ✅ الوضع المخفي
        ..setIsInvisible = (widget.currentUser!.getVipInvisibleMode == true);
      await v.save();
      widget.liveStreaming!.addViewersCount = 1;
      await widget.liveStreaming!.save();
    }
  }

  Future<void> _onViewerLeave() async {
    final q = QueryBuilder<LiveViewersModel>(LiveViewersModel());
    q.whereEqualTo(LiveViewersModel.keyLiveId, widget.liveStreaming!.objectId);
    q.whereEqualTo(LiveViewersModel.keyAuthorId, widget.currentUser!.objectId);
    final r = await q.query();
    if (r.success && r.results != null) {
      await (r.results!.first as LiveViewersModel).delete();
    }
    if ((widget.liveStreaming!.getViewersCount ?? 0) > 0) {
      widget.liveStreaming!.addViewersCount = -1;
      await widget.liveStreaming!.save();
    }
  }

  // ─── End stream ─────────────────────────────────────────────────────────────
  Future<void> _endStream() async {
    // أوقف بث الشاشة أولاً لإيقاف الـ foreground service
    QuickHelp.showLoadingDialog(context, isDismissible: false);
    widget.liveStreaming!.setStreaming = false;
    final r = await widget.liveStreaming!.save();
    QuickHelp.hideLoadingDialog(context);
    if (r.success) {
      QuickHelp.goToNavigatorScreen(context,
          LiveEndReportScreen(currentUser: widget.currentUser, live: widget.liveStreaming));
    }
  }

  // ─── Send gift ───────────────────────────────────────────────────────────────
  Future<void> _sendGift(GiftsModel gift, UserModel receiver) async {
    ZegoGiftManager().playList.add(gift);
    final giftSent = GiftsSentModel()
      ..setAuthor = widget.currentUser!
      ..setAuthorId = widget.currentUser!.objectId!
      ..setReceiver = receiver
      ..setReceiverId = receiver.objectId!
      ..setLiveId = widget.liveStreaming!.objectId!
      ..setGift = gift
      ..setGiftId = gift.objectId!
      ..setCounterDiamondsQuantity = gift.getCoins!;
    await giftSent.save();
    QuickHelp.saveReceivedGifts(receiver: receiver, author: widget.currentUser!, gift: gift);
    QuickHelp.saveCoinTransaction(receiver: receiver, author: widget.currentUser!, amountTransacted: gift.getCoins!);
    final lQ = QueryBuilder<LeadersModel>(LeadersModel());
    lQ.whereEqualTo(LeadersModel.keyAuthorId, widget.currentUser!.objectId!);
    final lR = await lQ.query();
    if (lR.success) {
      if (lR.results != null) {
        final l = lR.results!.first as LeadersModel;
        l.incrementDiamondsQuantity = giftSent.getDiamondsQuantity!;
        l.setGiftsSent = giftSent;
        await l.save();
      } else {
        final l = LeadersModel()
          ..setAuthor = widget.currentUser!
          ..setAuthorId = widget.currentUser!.objectId!
          ..incrementDiamondsQuantity = giftSent.getDiamondsQuantity!
          ..setGiftsSent = giftSent;
        await l.save();
      }
    }
    await QuickCloudCode.sendGift(author: receiver, credits: gift.getCoins!);
    widget.liveStreaming!.addDiamonds = QuickHelp.getDiamondsForReceiver(gift.getCoins!);
    await widget.liveStreaming!.save();
    widget.currentUser!.removeCredit = gift.getCoins!;
    await widget.currentUser!.save();
  }

  @override
  void dispose() {
    // أوقف بث الشاشة لإنهاء الـ foreground service وإخفاء الإشعار
    WakelockPlus.disable();
    removeGiftTimer?.cancel();
    _pulseController.dispose();
    _chatController.dispose();
    _chatScrollController.dispose();
    liveQuery.client.unSubscribe(subscription!);
    ZegoGiftManager().service.recvNotifier.removeListener(_onGiftReceived);
    ZegoGiftManager().service.uninit();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Zego يملأ الشاشة كاملة — بث الشاشة تلقائي
          Positioned.fill(child: _buildZegoLive(size)),

          // 2. طبقة داكنة عند فتح الـ panel
          if (_panelVisible)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _panelVisible = false),
                child: Container(color: Colors.black.withOpacity(0.5)),
              ),
            ),

          // 3. Panel المنزلق من الأسفل
          AnimatedPositioned(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            left: 0,
            right: 0,
            bottom: _panelVisible ? 0 : -(size.height * 0.68),
            child: _buildSlidePanel(size),
          ),

          // 4. أيقونة التطبيق العائمة القابلة للسحب
          _buildDraggableIcon(size),

          // 5. زر "افتح اللعبة" ثابت في الأسفل — مرئي دائماً للمضيف
          if (widget.isHost) _buildGoToGameBtn(),

          // 6. دليل بدء بث الشاشة (يظهر مرة واحدة)
          if (_showScreenShareGuide) _buildScreenShareGuide(size),

          // 5. أنيميشن الهدايا
          ValueListenableBuilder<GiftsModel?>(
            valueListenable: ZegoGiftManager().playList.playingDataNotifier,
            builder: (context, gift, _) {
              if (gift == null) return const SizedBox.shrink();
              return _giftAnimationWidget(gift);
            },
          ),
          // ✅ تأثير الدخول
          const EntranceEffectOverlay(),
          // ✅ الرسائل العائمة
          const FloatMessageOverlay(),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // شريط تلميح بسيط
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildGoToGameBtn() {
    if (!_showGoToAppBtn) return const SizedBox.shrink();
    return Positioned(
      bottom: 90,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.75),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white54, size: 16),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                "اضغط ⬆️ ثم وافق → سينتقل التطبيق للخلفية تلقائياً وتبدأ البث",
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _showGoToAppBtn = false),
              child: const Icon(Icons.close, color: Colors.white38, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  // تحريك التطبيق للخلفية
  Future<void> _moveAppToBackground() async {
    try {
      await const MethodChannel('com.juodylive.app/background')
          .invokeMethod('moveToBackground');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '👆 اضغط زر الهوم الآن وافتح لعبتك',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Color(0xFF1A1A2E),
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GO TO GAME OVERLAY — يظهر عند بدء بث الشاشة
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildGoToGameOverlay(Size size) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF1A1A2E).withOpacity(0.97),
                kVioletColor.withOpacity(0.85),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kVioletColor.withOpacity(0.6)),
            boxShadow: [
              BoxShadow(
                color: kVioletColor.withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            children: [
              // أيقونة البث النشط
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.withOpacity(0.2),
                  border: Border.all(color: Colors.greenAccent, width: 2),
                ),
                child: const Icon(Icons.screen_share_rounded,
                    color: Colors.greenAccent, size: 22),
              ),
              const SizedBox(width: 12),
              // النص
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "🎮 البث نشط الآن!",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "اضغط الهوم ثم افتح لعبتك",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // زر الهوم — يخرج للخلفية
              GestureDetector(
                onTap: () async {
                  setState(() => _panelVisible = false);
                  await Future.delayed(const Duration(milliseconds: 200));
                  _moveAppToBackground();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.greenAccent.withOpacity(0.5)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sports_esports_rounded,
                          color: Colors.greenAccent, size: 16),
                      SizedBox(width: 5),
                      Text(
                        "افتح اللعبة",
                        style: TextStyle(
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().slideY(begin: -1, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SCREEN SHARE GUIDE — دليل لمرة واحدة عند الدخول
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildScreenShareGuide(Size size) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () => setState(() => _showScreenShareGuide = false),
        child: Container(
          color: Colors.black.withOpacity(0.75),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // بطاقة التوجيه
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: kVioletColor.withOpacity(0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: kVioletColor.withOpacity(0.3),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // أيقونة
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: kVioletColor.withOpacity(0.2),
                        border: Border.all(color: kVioletColor, width: 2),
                      ),
                      child: const Icon(Icons.screen_share_rounded,
                          color: Colors.white, size: 32),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "ابدأ بث الشاشة",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "اضغط على زر مشاركة الشاشة\nفي الشريط السفلي لبدء البث",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white60,
                          fontSize: 14,
                          height: 1.5),
                    ),
                    const SizedBox(height: 20),
                    // سهم يشير للأسفل
                    Column(
                      children: [
                        ...List.generate(
                          3,
                          (i) => Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 2),
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: kVioletColor
                                  .withOpacity(0.4 + i * 0.2),
                              size: 28,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // زر فهمت
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kVioletColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () =>
                            setState(() {
                              _showScreenShareGuide = false;
                              // المستخدم فهم — ينتظر بدء بث الشاشة
                            }),
                        child: const Text(
                          "فهمت، سأضغط الزر ✓",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // مسافة فوق الشريط السفلي
              const SizedBox(height: 110),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ZEGO — ملء شاشة + بث الشاشة مباشرة
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildZegoLive(Size size) {
    final hostConfig = ZegoUIKitPrebuiltLiveStreamingConfig.host(
      plugins: [ZegoUIKitSignalingPlugin()],
    )
      ..preview.showPreviewForHost = false
      ..turnOnCameraWhenJoining = false   // الكاميرا مغلقة تماماً
      ..layout = ZegoLayout.gallery(
        showNewScreenSharingViewInFullscreenMode: true,
        showScreenSharingFullscreenModeToggleButtonRules:
            ZegoShowFullscreenModeToggleButtonRules.alwaysShow,
      )
      ..bottomMenuBar.hostButtons = [
        ZegoLiveStreamingMenuBarButtonName.toggleScreenSharingButton,
        ZegoLiveStreamingMenuBarButtonName.toggleMicrophoneButton,
      ]
      ..bottomMenuBar.hostExtendButtons = [_privateLiveBtn, _giftBtn]
      ..inRoomMessage.visible = false   // الرسائل في الـ panel المخصص
      ..topMenuBar.showCloseButton = false
      ..topMenuBar.buttons = []
      ..audioVideoView.useVideoViewAspectFill = true
      ..audioVideoView.containerRect = () =>
          Rect.fromLTWH(0, 0, size.width, size.height);
    hostConfig.inRoomMessage.attributes = () => _userLevelAttribs;

    final audienceConfig = ZegoUIKitPrebuiltLiveStreamingConfig.audience(
      plugins: [ZegoUIKitSignalingPlugin()],
    )
      ..layout = ZegoLayout.gallery(
        showNewScreenSharingViewInFullscreenMode: true,
        showScreenSharingFullscreenModeToggleButtonRules:
            ZegoShowFullscreenModeToggleButtonRules.alwaysShow,
      )
      ..inRoomMessage.visible = false
      ..topMenuBar.showCloseButton = false
      ..topMenuBar.buttons = []
      ..audioVideoView.useVideoViewAspectFill = true
      ..audioVideoView.containerRect = () =>
          Rect.fromLTWH(0, 0, size.width, size.height);
    audienceConfig.inRoomMessage.attributes = () => _userLevelAttribs;

    return ZegoUIKitPrebuiltLiveStreaming(
      appID: Setup.zegoLiveStreamAppID,
      appSign: Setup.zegoLiveStreamAppSign,
      userID: widget.currentUser!.objectId!,
      userName: widget.currentUser!.getFullName!,
      liveID: widget.liveID,
      events: widget.isHost
          ? ZegoUIKitPrebuiltLiveStreamingEvents(
              onStateUpdated: (s) {
                liveStateNotifier.value = s;
                // كشف بث الشاشة عبر الحالة
                if (mounted) {
                  setState(() {
                    _screenSharingActive =
                        s == ZegoLiveStreamingState.living &&
                        _screenSharingActive;
                  });
                }
              },
              onError: (e) => debugPrint('Zego: $e'),
              user: ZegoLiveStreamingUserEvents(onEnter: (_) {}, onLeave: (_) {}),
            )
          : ZegoUIKitPrebuiltLiveStreamingEvents(
              onError: (e) => debugPrint('Zego: $e'),
              inRoomMessage: ZegoLiveStreamingInRoomMessageEvents(
                onClicked: (msg) {
                  if (msg.user.id != widget.currentUser!.objectId) {
                    showUserProfileBottomSheet(
                      currentUser: widget.currentUser!,
                      userId: msg.user.id,
                      context: context,
                    );
                  }
                },
              ),
              user: ZegoLiveStreamingUserEvents(
                onEnter: (zegoUser) async {
                  _addViewerToLive();
                  // ✅ تأثير الدخول
                  if (zegoUser.id == widget.currentUser!.objectId &&
                      widget.currentUser!.getCanUseEntranceEffect == true &&
                      widget.currentUser!.getEntranceEffect != null) {
                    final fileUrl = widget.currentUser!.getEntranceEffect!.url!;
                    await ZegoGiftManager().service.sendEntranceEffect(
                      fileUrl: fileUrl,
                      senderUserID: widget.currentUser!.objectId!,
                      senderUserName: widget.currentUser!.getFullName ?? '',
                    );
                    ZegoGiftManager().service.entranceEffectNotifier.value =
                        ZegoEntranceEffectItem(
                          fileUrl: fileUrl,
                          senderUserID: widget.currentUser!.objectId!,
                          senderUserName: widget.currentUser!.getFullName ?? '',
                        );
                  }
                },
                onLeave: (_) => _onViewerLeave(),
              ),
            ),
      config: widget.isHost ? hostConfig : audienceConfig,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FLOATING DRAGGABLE ICON — أيقونة التطبيق الشفافة القابلة للسحب
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildDraggableIcon(Size size) {
    return Positioned(
      left: _floatingPos.dx,
      top: _floatingPos.dy,
      child: GestureDetector(
        // السحب
        onPanUpdate: (d) {
          setState(() {
            _floatingPos = Offset(
              (_floatingPos.dx + d.delta.dx).clamp(0.0, size.width - 64),
              (_floatingPos.dy + d.delta.dy).clamp(0.0, size.height - 64),
            );
          });
        },
        // الضغط → فتح / إغلاق الـ panel
        onTap: () => setState(() => _panelVisible = !_panelVisible),
        child: Opacity(
          opacity: 0.78,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  kVioletColor.withOpacity(0.85),
                  const Color(0xFF1A1A2E).withOpacity(0.9),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: kVioletColor.withOpacity(0.5),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // شعار التطبيق
                ClipOval(
                  child: Image.asset(
                    'assets/images/juody_logo.png',
                    width: 42,
                    height: 42,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.live_tv_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
                // نبضة LIVE
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (_, __) => Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color.lerp(
                          Colors.red.shade400,
                          Colors.red.shade700,
                          _pulseController.value,
                        ),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scaleXY(begin: 1.0, end: 1.04, duration: 2000.ms),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SLIDE PANEL — المشاهدون + الرسائل + زر الإنهاء
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildSlidePanel(Size size) {
    return Container(
      height: size.height * 0.68,
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D1A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // ── Header: عنوان + إحصائيات ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
            child: Row(
              children: [
                // شارة اللعبة
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: kVioletColor.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: kVioletColor.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("🎮 ", style: TextStyle(fontSize: 13)),
                      Text(
                        widget.selectedGame,
                        style: const TextStyle(
                          color: Color(0xFFA78BFA),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // مشاهدون
                _statBadge(Icons.remove_red_eye_outlined,
                    QuickHelp.convertToK(viewerCount), Colors.white54),
                const SizedBox(width: 8),
                // ألماس
                Obx(() => _statBadge(Icons.diamond,
                    QuickHelp.checkFundsWithString(
                        amount: showGiftSendersController.diamondsCounter.value),
                    const Color(0xFFF59E0B))),
                const SizedBox(width: 10),
                // زر إغلاق الـ panel
                GestureDetector(
                  onTap: () => setState(() => _panelVisible = false),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.keyboard_arrow_down,
                        color: Colors.white60, size: 20),
                  ),
                ),
              ],
            ),
          ),

          // ── Viewers row ──────────────────────────────────────────────────────
          if (showGiftSendersController.giftSenderList.isNotEmpty) ...[
            SizedBox(
              height: 56,
              child: Obx(() => ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    itemCount: showGiftSendersController.giftSenderList.length,
                    itemBuilder: (ctx, i) {
                      final user =
                          showGiftSendersController.giftSenderList[i];
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ClipOval(
                              child: QuickActions.avatarWidget(user,
                                  width: 36, height: 36),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              user.getFirstName ?? '',
                              style: const TextStyle(
                                  color: Colors.white60, fontSize: 10),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  )),
            ),
            const Divider(color: Colors.white10, height: 1),
          ],

          // ── Chat messages ────────────────────────────────────────────────────
          Expanded(
            child: chatMessages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            color: Colors.white.withOpacity(0.15), size: 36),
                        const SizedBox(height: 8),
                        Text(
                          "لا توجد رسائل بعد",
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.25),
                              fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _chatScrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    itemCount: chatMessages.length,
                    itemBuilder: (ctx, i) {
                      final m = chatMessages[i];
                      return _chatBubble(m['name'] ?? '', m['text'] ?? '');
                    },
                  ),
          ),

          const Divider(color: Colors.white10, height: 1),

          // ── Chat input ───────────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(
                12, 8, 12, MediaQuery.of(context).viewInsets.bottom + 6),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(21),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: TextField(
                      controller: _chatController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: "اكتب رسالة...",
                        hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.3), fontSize: 13),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onSubmitted: (_) => _sendChatMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // إرسال
                _roundBtn(
                  color: kVioletColor,
                  icon: Icons.send_rounded,
                  onTap: _sendChatMessage,
                ),
                if (!widget.isHost) ...[
                  const SizedBox(width: 6),
                  // هدية
                  GestureDetector(
                    onTap: _openGiftSheet,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.amber.withOpacity(0.35)),
                      ),
                      child: Lottie.asset("assets/lotties/ic_gift.json",
                          height: 26),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── زر إنهاء / مغادرة البث ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade800,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
                icon: Icon(
                  widget.isHost
                      ? Icons.stop_circle_outlined
                      : Icons.exit_to_app_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                label: Text(
                  widget.isHost ? "إنهاء البث" : "مغادرة البث",
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15),
                ),
                onPressed: _confirmEndStream,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────
  Widget _statBadge(IconData icon, String value, Color color) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(value, style: TextStyle(color: color, fontSize: 12)),
        ],
      );

  Widget _roundBtn(
          {required Color color,
          required IconData icon,
          required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      );

  Widget _chatBubble(String name, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: kVioletColor.withOpacity(0.25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(name,
                  style: const TextStyle(
                      color: Color(0xFFA78BFA),
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(text,
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ),
          ],
        ),
      );

  void _sendChatMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    ZegoUIKitPrebuiltLiveStreamingController().message.send(text);
    setState(() => chatMessages.add({
          'name': widget.currentUser?.getFirstName ?? 'أنت',
          'text': text,
        }));
    _chatController.clear();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_chatScrollController.hasClients) {
        _chatScrollController.jumpTo(
            _chatScrollController.position.maxScrollExtent);
      }
    });
  }

  void _confirmEndStream() {
    if (!widget.isHost) {
      _onViewerLeave();
      Navigator.of(context).pop();
      return;
    }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("إنهاء البث؟",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text("سيتم إيقاف بث الشاشة وإنهاء البث المباشر.",
            style: TextStyle(color: Color(0xFF9CA3AF))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text("إلغاء", style: TextStyle(color: Color(0xFF9CA3AF))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context);
              _endStream();
            },
            child: const Text("إنهاء البث",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ─── Gift animation ──────────────────────────────────────────────────────────
  Widget _giftAnimationWidget(GiftsModel gift) {
    final url = gift.getFile?.url ?? '';
    final name = gift.getFile?.name ?? '';
    if (name.toLowerCase().endsWith('.svga') || url.contains('.svga')) {
      return Positioned(
        bottom: 120,
        left: 0,
        right: 0,
        child: Center(
          child: ZegoSvgaPlayerWidget(
            key: UniqueKey(),
            giftItem: gift,
            onPlayEnd: () => ZegoGiftManager().playList.next(),
            count: 1,
          ),
        ),
      );
    } else if (name.toLowerCase().endsWith('.mp4') || url.contains('.mp4')) {
      return Positioned(
        bottom: 120,
        left: 0,
        right: 0,
        child: ZegoMp4PlayerWidget(
          key: UniqueKey(),
          playData: PlayData(giftItem: gift, count: 1),
          onPlayEnd: () => ZegoGiftManager().playList.next(),
        ),
      );
    }
    return Positioned(
      bottom: 160,
      left: 0,
      right: 0,
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(seconds: 3),
          onEnd: () => ZegoGiftManager().playList.next(),
          builder: (_, v, child) => Opacity(
            opacity: (v > 0.8 ? 1.0 - ((v - 0.8) * 5) : 1.0).clamp(0, 1),
            child: Transform.scale(scale: v, child: child),
          ),
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: kVioletColor.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 4)
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(gift.getPreview?.url ?? '',
                  fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Zego helpers ─────────────────────────────────────────────────────────────
  Map<String, String> get _userLevelAttribs {
    final level = QuickHelp.wealthLevelNumber(
        creditSent: widget.currentUser?.getCreditsSent ?? 0);
    final coins = widget.currentUser?.getCredits?.toDouble() ?? 0;
    final vip = QuickHelp.levelVipBanner(currentCredit: coins);
    return {'lv': level.toString(), 'vip': vip};
  }

  ZegoLiveStreamingMenuBarExtendButton get _privateLiveBtn =>
      ZegoLiveStreamingMenuBarExtendButton(
        child: IconButton(
          style: IconButton.styleFrom(
              shape: const CircleBorder(), backgroundColor: Colors.black26),
          onPressed: _togglePrivate,
          icon: SvgPicture.asset(
            widget.liveStreaming?.getPrivate == true
                ? "assets/svg/ic_unlocked_live.svg"
                : "assets/svg/ic_locked_live.svg",
          ),
        ),
      );

  ZegoLiveStreamingMenuBarExtendButton get _giftBtn =>
      ZegoLiveStreamingMenuBarExtendButton(
        index: 0,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
              shape: const CircleBorder(), backgroundColor: Colors.black26),
          onPressed: _openGiftSheet,
          child: Padding(
            padding: const EdgeInsets.all(3.0),
            child: Lottie.asset("assets/lotties/ic_gift.json", height: 29),
          ),
        ),
      );

  void _openGiftSheet() {
    CoinsFlowPayment(
      context: context,
      currentUser: widget.currentUser!,
      onCoinsPurchased: (_) {},
      onGiftSelected: (gift) => _sendGift(gift, widget.liveStreaming!.getAuthor!),
    );
  }

  void _togglePrivate() {
    if (widget.liveStreaming!.getPrivate == true) {
      widget.liveStreaming!.setPrivate = false;
      widget.liveStreaming!.save();
      QuickHelp.showAppNotificationAdvanced(
          context: context, title: "البث أصبح عاماً", isError: false);
    } else {
      PrivateLivePriceWidget(
        context: context,
        onCancel: () => QuickHelp.hideLoadingDialog(context),
        onGiftSelected: (gift) {
          QuickHelp.hideLoadingDialog(context);
          widget.liveStreaming!.setPrivate = true;
          widget.liveStreaming!.setPrivateLivePrice = gift;
          widget.liveStreaming!.save();
        },
      );
    }
  }
}
