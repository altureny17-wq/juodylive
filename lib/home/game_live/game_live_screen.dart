// ignore_for_file: must_be_immutable, use_build_context_synchronously
import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
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
import '../../ui/container_with_corner.dart';
import '../../ui/text_with_tap.dart';
import '../../utils/colors.dart';
import '../coins/coins_payment_widget.dart';
import '../live_end/live_end_screen.dart';
import '../live_end/live_end_report_screen.dart';
import '../prebuild_live/gift/components/svga_player_widget.dart';
import '../prebuild_live/gift/components/mp4_player_widget.dart';
import '../prebuild_live/gift/gift_data.dart';
import '../prebuild_live/gift/gift_manager/defines.dart';
import '../prebuild_live/gift/gift_manager/gift_manager.dart';
import '../prebuild_live/global_private_live_price_sheet.dart';
import '../prebuild_live/global_user_profil_sheet.dart';

class GameLiveScreen extends StatefulWidget {
  UserModel? currentUser;
  LiveStreamingModel? liveStreaming;
  final String liveID;
  final bool isHost;
  final String selectedGame;
  final bool showFaceCam;
  final bool enableMic;

  GameLiveScreen({
    Key? key,
    required this.liveID,
    this.isHost = false,
    this.currentUser,
    this.liveStreaming,
    this.selectedGame = "PUBG Mobile",
    this.showFaceCam = true,
    this.enableMic = true,
  }) : super(key: key);

  static String route = "/game/live";

  @override
  GameLiveScreenState createState() => GameLiveScreenState();
}

class GameLiveScreenState extends State<GameLiveScreen>
    with TickerProviderStateMixin {

  // ─── Controllers ─────────────────────────────────────────────────────────────
  late AnimationController _pulseController;
  late AnimationController _chatSlideController;
  ShowGiftSendersController showGiftSendersController =
      Get.put(ShowGiftSendersController());

  // ─── Live Query ───────────────────────────────────────────────────────────────
  final liveQuery = LiveQuery();
  Subscription? subscription;

  // ─── State ────────────────────────────────────────────────────────────────────
  bool isMicOn = true;
  bool isCameraOn = true;
  bool isScreenSharing = false;
  bool showChat = true;
  bool showGiftPanel = false;
  bool following = false;
  int viewerCount = 0;
  int likeCount = 0;
  String diamondsCount = "0";

  // Gift tracking
  final selectedGiftItemNotifier = ValueNotifier<GiftsModel?>(null);
  Timer? removeGiftTimer;
  final liveStateNotifier =
      ValueNotifier<ZegoLiveStreamingState>(ZegoLiveStreamingState.idle);

  // Chat messages (local simulation for overlay)
  List<Map<String, dynamic>> chatMessages = [];
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();

  // Like burst animation
  List<_LikeBubble> likeBubbles = [];

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _chatSlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();

    isMicOn = widget.enableMic;
    isCameraOn = widget.showFaceCam;

    following = widget.currentUser?.getFollowing
            ?.contains(widget.liveStreaming?.getAuthorId) ??
        false;

    showGiftSendersController.diamondsCounter.value =
        widget.liveStreaming?.getDiamonds?.toString() ?? "0";

    _initGifts();
    _setupLiveQuery();

    if (!widget.isHost) {
      _addViewerToLive();
    }
  }

  // ─── Init Gifts ───────────────────────────────────────────────────────────────
  Future<void> _initGifts() async {
    await loadGiftsFromServer();
    ZegoGiftManager().cache.cacheAllFiles(giftItemList);
    ZegoGiftManager().service.recvNotifier.addListener(_onGiftReceived);
    ZegoGiftManager().service.init(
      appID: Setup.zegoLiveStreamAppID,
      liveID: widget.liveID,
      userID: widget.currentUser!.objectId!,
      userName: widget.currentUser!.getFullName!,
    );
    _setupLiveGifts();
  }

  void _onGiftReceived() {
    final received = ZegoGiftManager().service.recvNotifier.value ??
        ZegoGiftProtocolItem.empty();
    final giftData = queryGiftInItemList(received.name);
    if (giftData != null) {
      ZegoGiftManager().playList.add(giftData);
    }
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
      final sender = giftSent.getAuthor!;
      final receiver = giftSent.getReceiver!;
      showGiftSendersController.giftSenderList.add(sender);
      showGiftSendersController.giftReceiverList.add(receiver);
      showGiftSendersController.receivedGiftList.add(receivedGift);
      selectedGiftItemNotifier.value = receivedGift;
      ZegoGiftManager().playList.add(receivedGift);
      if (removeGiftTimer == null) _startRemovingGifts();
    });
  }

  void _startRemovingGifts() {
    removeGiftTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) return;
      if (showGiftSendersController.receivedGiftList.isNotEmpty) {
        showGiftSendersController.receivedGiftList.removeAt(0);
        showGiftSendersController.giftSenderList.removeAt(0);
        showGiftSendersController.giftReceiverList.removeAt(0);
      } else {
        timer.cancel();
        removeGiftTimer = null;
      }
    });
  }

  // ─── Live Query for streaming ─────────────────────────────────────────────────
  Future<void> _setupLiveQuery() async {
    final query = QueryBuilder<LiveStreamingModel>(LiveStreamingModel());
    query.whereEqualTo(
        LiveStreamingModel.keyObjectId, widget.liveStreaming!.objectId);
    subscription = await liveQuery.client.subscribe(query);
    subscription!.on(LiveQueryEvent.update,
        (LiveStreamingModel updatedLive) async {
      await updatedLive.getAuthor!.fetch();
      widget.liveStreaming = updatedLive;
      if (!mounted) return;
      setState(() {
        diamondsCount = updatedLive.getDiamonds.toString();
        viewerCount = updatedLive.getViewersCount ?? 0;
      });
      showGiftSendersController.diamondsCounter.value =
          updatedLive.getDiamonds.toString();
      if (!updatedLive.getStreaming! && !widget.isHost) {
        QuickHelp.goToNavigatorScreen(
            context,
            LiveEndScreen(
              currentUser: widget.currentUser,
              liveAuthor: widget.liveStreaming!.getAuthor,
            ));
      }
    });
  }

  Future<void> _addViewerToLive() async {
    final existing = QueryBuilder<LiveViewersModel>(LiveViewersModel());
    existing.whereEqualTo(LiveViewersModel.keyLiveId, widget.liveStreaming!.objectId);
    existing.whereEqualTo(LiveViewersModel.keyAuthorId, widget.currentUser!.objectId);
    final r = await existing.query();
    if (r.success && r.results == null) {
      final viewer = LiveViewersModel();
      viewer.setAuthor = widget.currentUser!;
      viewer.setAuthorId = widget.currentUser!.objectId!;
      viewer.setLiveId = widget.liveStreaming!.objectId!;
      viewer.setLiveAuthorId = widget.liveStreaming!.getAuthorId!;
      await viewer.save();
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
      final v = r.results!.first as LiveViewersModel;
      await v.delete();
    }
    if ((widget.liveStreaming!.getViewersCount ?? 0) > 0) {
      widget.liveStreaming!.addViewersCount = -1;
      await widget.liveStreaming!.save();
    }
  }

  // ─── End stream (host) ────────────────────────────────────────────────────────
  Future<void> _endStream() async {
    QuickHelp.showLoadingDialog(context, isDismissible: false);
    widget.liveStreaming!.setStreaming = false;
    final r = await widget.liveStreaming!.save();
    QuickHelp.hideLoadingDialog(context);
    if (r.success) {
      QuickHelp.goToNavigatorScreen(
        context,
        LiveEndReportScreen(
          currentUser: widget.currentUser,
          live: widget.liveStreaming,
        ),
      );
    }
  }

  // ─── Send gift ────────────────────────────────────────────────────────────────
  Future<void> _sendGift(GiftsModel gift, UserModel receiver) async {
    ZegoGiftManager().playList.add(gift);
    final giftSent = GiftsSentModel();
    giftSent.setAuthor = widget.currentUser!;
    giftSent.setAuthorId = widget.currentUser!.objectId!;
    giftSent.setReceiver = receiver;
    giftSent.setReceiverId = receiver.objectId!;
    giftSent.setLiveId = widget.liveStreaming!.objectId!;
    giftSent.setGift = gift;
    giftSent.setGiftId = gift.objectId!;
    giftSent.setCounterDiamondsQuantity = gift.getCoins!;
    await giftSent.save();
    QuickHelp.saveReceivedGifts(
        receiver: receiver, author: widget.currentUser!, gift: gift);
    QuickHelp.saveCoinTransaction(
      receiver: receiver,
      author: widget.currentUser!,
      amountTransacted: gift.getCoins!,
    );
    final leaderQ = QueryBuilder<LeadersModel>(LeadersModel());
    leaderQ.whereEqualTo(
        LeadersModel.keyAuthorId, widget.currentUser!.objectId!);
    final leaderR = await leaderQ.query();
    if (leaderR.success) {
      if (leaderR.results != null) {
        final l = leaderR.results!.first as LeadersModel;
        l.incrementDiamondsQuantity = giftSent.getDiamondsQuantity!;
        l.setGiftsSent = giftSent;
        await l.save();
      } else {
        final l = LeadersModel();
        l.setAuthor = widget.currentUser!;
        l.setAuthorId = widget.currentUser!.objectId!;
        l.incrementDiamondsQuantity = giftSent.getDiamondsQuantity!;
        l.setGiftsSent = giftSent;
        await l.save();
      }
    }
    await QuickCloudCode.sendGift(
      author: receiver,
      credits: gift.getCoins!,
    );
    widget.liveStreaming!.addDiamonds =
        QuickHelp.getDiamondsForReceiver(gift.getCoins!);
    await widget.liveStreaming!.save();
    widget.currentUser!.removeCredit = gift.getCoins!;
    await widget.currentUser!.save();
  }

  // ─── Like burst ───────────────────────────────────────────────────────────────
  void _sendLike() {
    setState(() {
      likeCount++;
      likeBubbles.add(_LikeBubble(
        id: DateTime.now().millisecondsSinceEpoch,
        emoji: ['❤️', '🔥', '👑', '⚡', '💎'][likeCount % 5],
      ));
    });
    Timer(const Duration(seconds: 2), () {
      if (mounted && likeBubbles.isNotEmpty) {
        setState(() => likeBubbles.removeAt(0));
      }
    });
  }

  // ─── Gift widget ──────────────────────────────────────────────────────────────
  Widget _giftAnimationWidget(GiftsModel gift) {
    final url = gift.getFile?.url ?? '';
    final name = gift.getFile?.name ?? '';
    if (name.toLowerCase().endsWith('.svga') || url.contains('.svga')) {
      return Positioned(
        bottom: 150,
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
        bottom: 150,
        left: 0,
        right: 0,
        child: ZegoMp4PlayerWidget(
          key: UniqueKey(),
          playData: PlayData(giftItem: gift, count: 1),
          onPlayEnd: () => ZegoGiftManager().playList.next(),
        ),
      );
    } else {
      return Positioned(
        bottom: 200,
        left: 0,
        right: 0,
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(seconds: 3),
            onEnd: () => ZegoGiftManager().playList.next(),
            builder: (context, v, child) {
              double opacity = v > 0.8 ? 1.0 - ((v - 0.8) * 5) : 1.0;
              return Opacity(
                opacity: opacity.clamp(0, 1),
                child: Transform.scale(scale: v, child: child),
              );
            },
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: kVioletColor.withOpacity(0.6),
                      blurRadius: 25,
                      spreadRadius: 5)
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
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    removeGiftTimer?.cancel();
    _pulseController.dispose();
    _chatSlideController.dispose();
    _chatController.dispose();
    _chatScrollController.dispose();
    liveQuery.client.unSubscribe(subscription!);
    ZegoGiftManager().service.recvNotifier.removeListener(_onGiftReceived);
    ZegoGiftManager().service.uninit();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Zego Live Streaming Core ───────────────────────────────────────────
          _buildZegoLive(size),

          // ── Game Overlay UI ───────────────────────────────────────────────────
          SafeArea(child: _buildGameOverlay(size)),

          // ── Gift animations ───────────────────────────────────────────────────
          ValueListenableBuilder<GiftsModel?>(
            valueListenable: ZegoGiftManager().playList.playingDataNotifier,
            builder: (context, gift, _) {
              if (gift == null) return const SizedBox.shrink();
              return _giftAnimationWidget(gift);
            },
          ),

          // ── Gift sender row ────────────────────────────────────────────────────
          _buildGiftSenderRow(),

          // ── Like bubbles ───────────────────────────────────────────────────────
          ..._buildLikeBubbles(size),
        ],
      ),
    );
  }

  // ─── Zego Live widget ─────────────────────────────────────────────────────────
  Widget _buildZegoLive(Size size) {
    final hostConfig = ZegoUIKitPrebuiltLiveStreamingConfig.host(
      plugins: [ZegoUIKitSignalingPlugin()],
    )
      ..preview.showPreviewForHost = false
      ..bottomMenuBar.hostExtendButtons = [_privateLiveBtn, _giftBtn]
      ..inRoomMessage.visible = true
      ..inRoomMessage.showAvatar = true
      ..inRoomMessage.attributes = _userLevelAttribs
      ..inRoomMessage.avatarLeadingBuilder = _levelBadgeBuilder
      ..topMenuBar.isVisible = false  // we draw our own top bar
      ..bottomMenuBar.isVisible = false  // we draw our own bottom bar
      ..audioVideoView.useVideoViewAspectFill = true;

    final audienceConfig = ZegoUIKitPrebuiltLiveStreamingConfig.audience(
      plugins: [ZegoUIKitSignalingPlugin()],
    )
      ..inRoomMessage.visible = true
      ..inRoomMessage.showAvatar = true
      ..inRoomMessage.attributes = _userLevelAttribs
      ..inRoomMessage.avatarLeadingBuilder = _levelBadgeBuilder
      ..topMenuBar.isVisible = false
      ..bottomMenuBar.isVisible = false
      ..audioVideoView.useVideoViewAspectFill = true;

    final hostEvents = ZegoUIKitPrebuiltLiveStreamingEvents(
      onStateUpdated: (state) {
        liveStateNotifier.value = state;
      },
      user: ZegoLiveStreamingUserEvents(
        onEnter: (user) {},
        onLeave: (user) {},
      ),
      onError: (e) => debugPrint('Zego error: $e'),
    );

    final audienceEvents = ZegoUIKitPrebuiltLiveStreamingEvents(
      inRoomMessage: ZegoLiveStreamingInRoomMessageEvents(
        onClicked: (message) {
          if (message.user.id != widget.currentUser!.objectId) {
            showUserProfileBottomSheet(
              currentUser: widget.currentUser!,
              userId: message.user.id,
              context: context,
            );
          }
        },
      ),
      onError: (e) => debugPrint('Zego error: $e'),
      user: ZegoLiveStreamingUserEvents(
        onEnter: (_) => _addViewerToLive(),
        onLeave: (_) => _onViewerLeave(),
      ),
    );

    return ZegoUIKitPrebuiltLiveStreaming(
      appID: Setup.zegoLiveStreamAppID,
      appSign: Setup.zegoLiveStreamAppSign,
      userID: widget.currentUser!.objectId!,
      userName: widget.currentUser!.getFullName!,
      liveID: widget.liveID,
      events: widget.isHost ? hostEvents : audienceEvents,
      config: widget.isHost ? hostConfig : audienceConfig,
    );
  }

  // ─── Level badge builder ──────────────────────────────────────────────────────
  Map<String, String> get _userLevelAttribs {
    final level = QuickHelp.wealthLevelNumber(creditSent: widget.currentUser?.getCreditsSent ?? 0);
    final coins = widget.currentUser?.getCredits?.toDouble() ?? 0;
    final vip = QuickHelp.levelVipBanner(currentCredit: coins);
    return {'lv': level.toString(), 'vip': vip};
  }

  Widget _levelBadgeBuilder(BuildContext ctx, ZegoInRoomMessage message,
      Map<String, dynamic> extra) {
    final lv = message.attributes['lv'] ?? '1';
    final vip = message.attributes['vip'] ?? '';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (vip.isNotEmpty)
          Image.asset(vip, width: 28, height: 14, fit: BoxFit.contain),
        const SizedBox(width: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)]),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            "LV $lv",
            style: const TextStyle(
                fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  // ─── Game Overlay ─────────────────────────────────────────────────────────────
  Widget _buildGameOverlay(Size size) {
    return Column(
      children: [
        // TOP BAR
        _buildTopBar(size),

        // MIDDLE AREA (flexible)
        Expanded(
          child: Stack(
            children: [
              // Left: chat + gift senders
              Positioned(
                left: 0,
                bottom: 0,
                width: size.width * 0.72,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showChat) _buildChatOverlay(size),
                    const SizedBox(height: 8),
                    _buildChatInput(size),
                    const SizedBox(height: 12),
                  ],
                ),
              ),

              // Right: action buttons
              Positioned(
                right: 12,
                bottom: 12,
                child: _buildRightActions(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Top bar ─────────────────────────────────────────────────────────────────
  Widget _buildTopBar(Size size) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Host avatar + info
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (!widget.isHost) {
                  showUserProfileBottomSheet(
                    currentUser: widget.currentUser!,
                    userId: widget.liveStreaming!.getAuthorId!,
                    context: context,
                  );
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Avatar
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: const Color(0xFF7C3AED), width: 2),
                      ),
                      child: ClipOval(
                        child: QuickActions.avatarWidget(
                          widget.liveStreaming!.getAuthor!,
                          width: 32,
                          height: 32,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.liveStreaming!.getAuthor?.getFullName ?? "",
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Row(
                            children: [
                              const Text("🎮 ",
                                  style: TextStyle(fontSize: 9)),
                              Flexible(
                                child: Text(
                                  widget.selectedGame,
                                  style: const TextStyle(
                                      color: Color(0xFFA78BFA), fontSize: 9),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Follow btn (audience only)
                    if (!widget.isHost)
                      GestureDetector(
                        onTap: () {
                          if (!following) {
                            setState(() => following = true);
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: following
                                ? Colors.white.withOpacity(0.15)
                                : kVioletColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            following ? "متابَع" : "+ تابع",
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Viewer count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.remove_red_eye_outlined,
                    color: Colors.white70, size: 13),
                const SizedBox(width: 4),
                Obx(() => Text(
                      QuickHelp.convertToK(viewerCount),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    )),
              ],
            ),
          ),

          const SizedBox(width: 6),

          // Diamond counter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.diamond, color: Color(0xFFF59E0B), size: 13),
                const SizedBox(width: 4),
                Obx(() => Text(
                      QuickHelp.checkFundsWithString(
                          amount: showGiftSendersController
                              .diamondsCounter.value),
                      style: const TextStyle(
                          color: Color(0xFFF59E0B),
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    )),
              ],
            ),
          ),

          const SizedBox(width: 6),

          // LIVE badge (pulsing)
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Color.lerp(const Color(0xFFE53935), const Color(0xFFB71C1C),
                        _pulseController.value)!,
                    const Color(0xFFB71C1C),
                  ]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text("● LIVE",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              );
            },
          ),

          const SizedBox(width: 6),

          // Close button
          GestureDetector(
            onTap: () => _showEndStreamDialog(),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Chat overlay ─────────────────────────────────────────────────────────────
  Widget _buildChatOverlay(Size size) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: size.height * 0.28),
      child: ValueListenableBuilder<ZegoLiveStreamingState>(
        valueListenable: liveStateNotifier,
        builder: (context, state, _) {
          // Messages come from Zego's inRoomMessage natively
          // This area shows gift sender notifications
          return Obx(() {
            if (showGiftSendersController.receivedGiftList.isEmpty) {
              return const SizedBox.shrink();
            }
            return ListView.builder(
              shrinkWrap: true,
              controller: _chatScrollController,
              padding: const EdgeInsets.only(left: 8, bottom: 4),
              itemCount:
                  showGiftSendersController.receivedGiftList.length,
              itemBuilder: (context, i) {
                final sender =
                    showGiftSendersController.giftSenderList[i];
                final gift =
                    showGiftSendersController.receivedGiftList[i];
                return _buildGiftNotificationRow(sender, gift)
                    .animate()
                    .slideX(begin: -1, end: 0, duration: 400.ms);
              },
            );
          });
        },
      ),
    );
  }

  Widget _buildGiftNotificationRow(UserModel sender, GiftsModel gift) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          QuickActions.avatarWidget(sender, width: 24, height: 24),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              "${sender.getFirstName ?? ''} أرسل هدية",
              style: const TextStyle(color: Colors.white, fontSize: 10),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 24,
            height: 24,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                gift.getPreview?.url ?? '',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.card_giftcard, color: Colors.white, size: 16),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            "×1",
            style: TextStyle(
                color: Colors.yellow.shade300,
                fontWeight: FontWeight.bold,
                fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ─── Chat input ───────────────────────────────────────────────────────────────
  Widget _buildChatInput(Size size) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _showChatInputSheet(),
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                alignment: Alignment.centerLeft,
                child: const Text("قل شيئاً...",
                    style:
                        TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Share button
          _iconBtn(
            Icons.share_outlined,
            Colors.white,
            Colors.black45,
            () {},
          ),
        ],
      ),
    );
  }

  void _showChatInputSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A2E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "اكتب رسالتك...",
                    hintStyle: const TextStyle(color: Color(0xFF6B7280)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.08),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () {
                  if (_chatController.text.trim().isNotEmpty) {
                    ZegoUIKitPrebuiltLiveStreamingController()
                        .message
                        .send(_chatController.text.trim());
                    _chatController.clear();
                    Navigator.pop(context);
                  }
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.send_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Right action buttons ─────────────────────────────────────────────────────
  Widget _buildRightActions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Gift
        _iconBtn(
          Icons.card_giftcard_rounded,
          Colors.white,
          Colors.transparent,
          () => _openGiftSheet(),
          isLottie: true,
          lottiePath: "assets/lotties/ic_gift.json",
          gradient: const LinearGradient(
              colors: [Color(0xFFDB2777), Color(0xFF9D174D)]),
        ),
        const SizedBox(height: 10),

        // Like
        GestureDetector(
          onTap: _sendLike,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFFE53935), Color(0xFFB71C1C)]),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                    color: Colors.red.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ],
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("❤️", style: TextStyle(fontSize: 18)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Mic (host only)
        if (widget.isHost) ...[
          _iconBtn(
            isMicOn ? Icons.mic_rounded : Icons.mic_off_rounded,
            isMicOn ? Colors.white : Colors.red,
            isMicOn
                ? const Color(0xFF10B981).withOpacity(0.8)
                : Colors.red.withOpacity(0.2),
            () {
              setState(() => isMicOn = !isMicOn);
              ZegoUIKit().turnMicrophoneOn(isMicOn,
                  userID: widget.currentUser!.objectId!);
            },
          ),
          const SizedBox(height: 10),

          // Camera toggle
          _iconBtn(
            isCameraOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
            isCameraOn ? Colors.white : Colors.red,
            isCameraOn
                ? const Color(0xFF3B82F6).withOpacity(0.8)
                : Colors.red.withOpacity(0.2),
            () {
              setState(() => isCameraOn = !isCameraOn);
              ZegoUIKit().turnCameraOn(isCameraOn,
                  userID: widget.currentUser!.objectId!);
            },
          ),
          const SizedBox(height: 10),

          // Screen share
          _iconBtn(
            Icons.screen_share_rounded,
            Colors.white,
            isScreenSharing
                ? const Color(0xFFF59E0B).withOpacity(0.8)
                : Colors.black45,
            () => _toggleScreenShare(),
            label: isScreenSharing ? "إيقاف" : "شاشة",
          ),
          const SizedBox(height: 10),

          // Private
          _iconBtn(
            Icons.lock_outline_rounded,
            Colors.white,
            Colors.black45,
            () => _togglePrivate(),
          ),
          const SizedBox(height: 10),
        ],

        // Members
        _iconBtn(
          Icons.people_outline_rounded,
          Colors.white,
          Colors.black45,
          () {},
        ),
      ],
    );
  }

  Widget _iconBtn(
    IconData icon,
    Color iconColor,
    Color bgColor,
    VoidCallback onTap, {
    Gradient? gradient,
    String? label,
    bool isLottie = false,
    String? lottiePath,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: gradient == null ? bgColor : null,
              gradient: gradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2))
              ],
            ),
            child: isLottie && lottiePath != null
                ? Padding(
                    padding: const EdgeInsets.all(8),
                    child: Lottie.asset(lottiePath),
                  )
                : Icon(icon, color: iconColor, size: 22),
          ),
          if (label != null) ...[
            const SizedBox(height: 2),
            Text(label,
                style:
                    const TextStyle(color: Colors.white70, fontSize: 9)),
          ]
        ],
      ),
    );
  }

  // ─── Gift sender row (above chat) ─────────────────────────────────────────────
  Widget _buildGiftSenderRow() {
    return Positioned(
      bottom: 100,
      left: 8,
      right: 80,
      child: Obx(() {
        if (showGiftSendersController.receivedGiftList.isEmpty) {
          return const SizedBox.shrink();
        }
        return SizedBox(
          height: 70,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: showGiftSendersController.receivedGiftList.length,
            itemBuilder: (context, i) {
              final sender = showGiftSendersController.giftSenderList[i];
              final gift = showGiftSendersController.receivedGiftList[i];
              return _buildCompactGiftCard(sender, gift);
            },
          ),
        );
      }),
    );
  }

  Widget _buildCompactGiftCard(UserModel sender, GiftsModel gift) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kVioletColor.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          QuickActions.avatarWidget(sender, width: 30, height: 30),
          const SizedBox(width: 6),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(sender.getFirstName ?? '',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold)),
              Text("أهدى",
                  style: const TextStyle(
                      color: Color(0xFF9CA3AF), fontSize: 8)),
            ],
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 30,
            height: 30,
            child: Image.network(
              gift.getPreview?.url ?? '',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.card_giftcard, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    ).animate().slideX(begin: -1, end: 0, duration: 400.ms);
  }

  // ─── Like bubbles ─────────────────────────────────────────────────────────────
  List<Widget> _buildLikeBubbles(Size size) {
    return likeBubbles.map((b) {
      return Positioned(
        right: 16 + (b.id % 40).toDouble(),
        bottom: 200,
        child: Text(b.emoji, style: const TextStyle(fontSize: 28))
            .animate()
            .slideY(begin: 0, end: -3, duration: 1800.ms, curve: Curves.easeOut)
            .fadeOut(delay: 1200.ms, duration: 600.ms),
      );
    }).toList();
  }

  // ─── Gift sheet ───────────────────────────────────────────────────────────────
  void _openGiftSheet() {
    CoinsFlowPayment(
      context: context,
      currentUser: widget.currentUser!,
      onCoinsPurchased: (coins) {},
      onGiftSelected: (gift) {
        _sendGift(gift, widget.liveStreaming!.getAuthor!);
        QuickHelp.showAppNotificationAdvanced(
          context: context,
          user: widget.currentUser,
          title: "تم إرسال الهدية 🎁",
          message: "أرسلت هدية لـ ${widget.liveStreaming!.getAuthor!.getFirstName}",
          isError: false,
        );
      },
    );
  }

  // ─── Screen share ─────────────────────────────────────────────────────────────
  void _toggleScreenShare() {
    setState(() => isScreenSharing = !isScreenSharing);
    QuickHelp.showAppNotificationAdvanced(
      context: context,
      title: isScreenSharing ? "مشاركة الشاشة مفعّلة 📱" : "إيقاف مشاركة الشاشة",
      isError: false,
    );
  }

  // ─── Private/Unlock ───────────────────────────────────────────────────────────
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
          QuickHelp.showAppNotificationAdvanced(
              context: context, title: "البث أصبح خاصاً 🔒", isError: false);
        },
      );
    }
  }

  // ─── Private live button ──────────────────────────────────────────────────────
  ZegoLiveStreamingMenuBarExtendButton get _privateLiveBtn =>
      ZegoLiveStreamingMenuBarExtendButton(
        child: IconButton(
          style: IconButton.styleFrom(
            shape: const CircleBorder(),
            backgroundColor: Colors.black26,
          ),
          onPressed: _togglePrivate,
          icon: SvgPicture.asset(
            widget.liveStreaming?.getPrivate == true
                ? "assets/svg/ic_unlocked_live.svg"
                : "assets/svg/ic_locked_live.svg",
          ),
        ),
      );

  // ─── Gift button ──────────────────────────────────────────────────────────────
  ZegoLiveStreamingMenuBarExtendButton get _giftBtn =>
      ZegoLiveStreamingMenuBarExtendButton(
        index: 0,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            backgroundColor: Colors.black26,
          ),
          onPressed: _openGiftSheet,
          child: Padding(
            padding: const EdgeInsets.all(3.0),
            child: Lottie.asset("assets/lotties/ic_gift.json", height: 29),
          ),
        ),
      );

  // ─── End stream dialog ────────────────────────────────────────────────────────
  void _showEndStreamDialog() {
    if (widget.isHost) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("إنهاء البث؟",
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          content: const Text("هل تريد إنهاء بث اللعبة؟",
              style: TextStyle(color: Color(0xFF9CA3AF))),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("إلغاء",
                  style: TextStyle(color: Color(0xFF9CA3AF))),
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
    } else {
      _onViewerLeave();
      Navigator.of(context).pop();
    }
  }
}

// ─── Like bubble model ────────────────────────────────────────────────────────
class _LikeBubble {
  final int id;
  final String emoji;
  _LikeBubble({required this.id, required this.emoji});
}
