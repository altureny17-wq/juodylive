// ignore_for_file: must_be_immutable, use_build_context_synchronously
import 'dart:async';
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
  // Controllers
  late AnimationController _pulseController;
  Controller showGiftSendersController = Get.put(Controller());

  // Live Query
  final liveQuery = LiveQuery();
  Subscription? subscription;
  Subscription? giftSubscription;

  // State
  bool isMicOn = true;
  bool isCameraOn = true;
  int viewerCount = 0;
  bool isScreenSharingActive = false;

  // Floating button & panel
  bool _panelVisible = false;
  bool _showScreenShareGuide = false;
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
    isCameraOn = widget.showFaceCam;

    showGiftSendersController.diamondsCounter.value =
        widget.liveStreaming?.getDiamonds?.toString() ?? "0";

    _initGifts();
    _setupLiveQuery();
    
    if (!widget.isHost) {
      _addViewerToLive();
    } else {
      // للمضيف: بدء بث الشاشة تلقائياً بعد تجهيز البث
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _autoStartScreenSharing();
      });
      
      // إظهار دليل بث الشاشة للمضيف بعد ثانية
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted && !isScreenSharingActive) {
          setState(() => _showScreenShareGuide = true);
        }
      });
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // بدء بث الشاشة تلقائياً
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> _autoStartScreenSharing() async {
    try {
      // تأخير قصير للتأكد من تهيئة Zego
      await Future.delayed(const Duration(seconds: 2));
      
      if (!mounted) return;
      
      final permission = await ZegoUIKitPrebuiltLiveStreamingController()
          .screenSharing
          .requestPermission();
      
      if (permission) {
        await ZegoUIKitPrebuiltLiveStreamingController()
            .screenSharing
            .start();
        
        setState(() {
          isScreenSharingActive = true;
          _showScreenShareGuide = false;
        });
        
        print('✅ تم بدء بث الشاشة تلقائياً');
        
        QuickHelp.showAppNotificationAdvanced(
          context: context,
          title: "تم بدء بث الشاشة",
          message: "يمكنك الآن مشاركة شاشة لعبتك",
          isError: false,
        );
      } else {
        print('❌ لم يتم منح إذن تسجيل الشاشة');
        setState(() => _showScreenShareGuide = true);
      }
    } catch (e) {
      print('❌ فشل بدء بث الشاشة: $e');
      setState(() => _showScreenShareGuide = true);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Gifts
  // ═══════════════════════════════════════════════════════════════════════════
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
    
    giftSubscription = await liveQuery.client.subscribe(query);
    giftSubscription!.on(LiveQueryEvent.create, (GiftsSentModel giftSent) async {
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

  // ═══════════════════════════════════════════════════════════════════════════
  // Live Query
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> _setupLiveQuery() async {
    final query = QueryBuilder<LiveStreamingModel>(LiveStreamingModel());
    query.whereEqualTo(LiveStreamingModel.keyObjectId, widget.liveStreaming!.objectId);
    
    subscription = await liveQuery.client.subscribe(query);
    subscription!.on(LiveQueryEvent.update, (LiveStreamingModel updatedLive) async {
      await updatedLive.getAuthor!.fetch();
      
      widget.liveStreaming = updatedLive;
      
      if (!mounted) return;
      
      setState(() {
        viewerCount = updatedLive.getViewersCount ?? 0;
      });
      
      showGiftSendersController.diamondsCounter.value = 
          updatedLive.getDiamonds.toString();
      
      if (!updatedLive.getStreaming! && !widget.isHost) {
        QuickHelp.goToNavigatorScreen(context,
            LiveEndScreen(
              currentUser: widget.currentUser, 
              liveAuthor: widget.liveStreaming!.getAuthor
            ));
      }
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Viewer management
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> _addViewerToLive() async {
    try {
      final q = QueryBuilder<LiveViewersModel>(LiveViewersModel());
      q.whereEqualTo(LiveViewersModel.keyLiveId, widget.liveStreaming!.objectId);
      q.whereEqualTo(LiveViewersModel.keyAuthorId, widget.currentUser!.objectId);
      
      final r = await q.query();
      
      if (r.success && (r.results == null || r.results!.isEmpty)) {
        final v = LiveViewersModel()
          ..setAuthor = widget.currentUser!
          ..setAuthorId = widget.currentUser!.objectId!
          ..setLiveId = widget.liveStreaming!.objectId!
          ..setLiveAuthorId = widget.liveStreaming!.getAuthorId!;
        
        await v.save();
        
        widget.liveStreaming!.addViewersCount = 1;
        await widget.liveStreaming!.save();
      }
    } catch (e) {
      print('خطأ في إضافة المشاهد: $e');
    }
  }

  Future<void> _onViewerLeave() async {
    try {
      final q = QueryBuilder<LiveViewersModel>(LiveViewersModel());
      q.whereEqualTo(LiveViewersModel.keyLiveId, widget.liveStreaming!.objectId);
      q.whereEqualTo(LiveViewersModel.keyAuthorId, widget.currentUser!.objectId);
      
      final r = await q.query();
      
      if (r.success && r.results != null && r.results!.isNotEmpty) {
        await (r.results!.first as LiveViewersModel).delete();
        
        if ((widget.liveStreaming!.getViewersCount ?? 0) > 0) {
          widget.liveStreaming!.addViewersCount = -1;
          await widget.liveStreaming!.save();
        }
      }
    } catch (e) {
      print('خطأ في مغادرة المشاهد: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // End stream
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> _endStream() async {
    try {
      // إيقاف بث الشاشة أولاً
      await ZegoUIKitPrebuiltLiveStreamingController().screenSharing.stop();
      
      QuickHelp.showLoadingDialog(context, isDismissible: false);
      
      widget.liveStreaming!.setStreaming = false;
      final r = await widget.liveStreaming!.save();
      
      QuickHelp.hideLoadingDialog(context);
      
      if (r.success && mounted) {
        QuickHelp.goToNavigatorScreen(context,
            LiveEndReportScreen(
              currentUser: widget.currentUser, 
              live: widget.liveStreaming
            ));
      }
    } catch (e) {
      print('خطأ في إنهاء البث: $e');
      QuickHelp.hideLoadingDialog(context);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Send gift
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> _sendGift(GiftsModel gift, UserModel receiver) async {
    try {
      QuickHelp.showLoadingDialog(context);
      
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
      
      await QuickHelp.saveReceivedGifts(
        receiver: receiver, 
        author: widget.currentUser!, 
        gift: gift
      );
      
      await QuickHelp.saveCoinTransaction(
        receiver: receiver, 
        author: widget.currentUser!, 
        amountTransacted: gift.getCoins!
      );
      
      // تحديث قادة الهدايا
      final lQ = QueryBuilder<LeadersModel>(LeadersModel());
      lQ.whereEqualTo(LeadersModel.keyAuthorId, widget.currentUser!.objectId!);
      final lR = await lQ.query();
      
      if (lR.success) {
        if (lR.results != null && lR.results!.isNotEmpty) {
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
      
      QuickHelp.hideLoadingDialog(context);
      
      QuickHelp.showAppNotificationAdvanced(
        context: context,
        title: "تم إرسال الهدية",
        message: "شكراً لك على كرمك!",
        isError: false,
      );
    } catch (e) {
      QuickHelp.hideLoadingDialog(context);
      print('خطأ في إرسال الهدية: $e');
    }
  }

  @override
  void dispose() {
    // إيقاف بث الشاشة عند الخروج
    try {
      ZegoUIKitPrebuiltLiveStreamingController().screenSharing.stop();
    } catch (_) {}
    
    WakelockPlus.disable();
    removeGiftTimer?.cancel();
    _pulseController.dispose();
    _chatController.dispose();
    _chatScrollController.dispose();
    
    if (subscription != null) {
      liveQuery.client.unSubscribe(subscription!);
    }
    if (giftSubscription != null) {
      liveQuery.client.unSubscribe(giftSubscription!);
    }
    
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
          // 1. Zego يملأ الشاشة كاملة
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

          // 5. دليل بدء بث الشاشة
          if (_showScreenShareGuide) _buildScreenShareGuide(size),

          // 6. أنيميشن الهدايا
          ValueListenableBuilder<GiftsModel?>(
            valueListenable: ZegoGiftManager().playList.playingDataNotifier,
            builder: (context, gift, _) {
              if (gift == null) return const SizedBox.shrink();
              return _giftAnimationWidget(gift);
            },
          ),
          
          // 7. مؤشر بث الشاشة النشط
          if (isScreenSharingActive && widget.isHost)
            Positioned(
              top: 40,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.screen_share_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 5),
                    Text(
                      "بث الشاشة نشط",
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ).animate().shimmer(duration: 1500.ms).then().shake(),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SCREEN SHARE GUIDE
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
                    Column(
                      children: List.generate(
                        3,
                        (i) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: kVioletColor.withOpacity(0.4 + i * 0.2),
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kVioletColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () => _autoStartScreenSharing(),
                        child: const Text(
                          "بدء بث الشاشة الآن",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => setState(() => _showScreenShareGuide = false),
                      child: const Text(
                        "تخطي",
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 110),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ZEGO المعدل بالكامل
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildZegoLive(Size size) {
    // تكوين المضيف
    final hostConfig = ZegoUIKitPrebuiltLiveStreamingConfig.host(
      plugins: [ZegoUIKitSignalingPlugin()],
    )
      ..preview.showPreviewForHost = false
      ..layout = ZegoLayout.gallery(
        showNewScreenSharingViewInFullscreenMode: true,
        showScreenSharingFullscreenModeToggleButtonRules:
            ZegoShowFullscreenModeToggleButtonRules.alwaysShow,
        addScreenSharingViewToMainView: true, // ✅ الأهم: إضافة بث الشاشة للعرض الرئيسي
      )
      ..bottomMenuBar.hostButtons = [
        ZegoLiveStreamingMenuBarButtonName.toggleScreenSharingButton,
        ZegoLiveStreamingMenuBarButtonName.toggleCameraButton,
        ZegoLiveStreamingMenuBarButtonName.toggleMicrophoneButton,
      ]
      ..bottomMenuBar.hostExtendButtons = [_privateLiveBtn, _giftBtn]
      ..inRoomMessage.visible = false
      ..topMenuBar.showCloseButton = false
      ..topMenuBar.buttons = []
      ..audioVideoView.useVideoViewAspectFill = true
      ..audioVideoView.containerRect = () => 
          Rect.fromLTWH(0, 0, size.width, size.height - 60) // ترك مساحة للشريط
      ..screenSharing = ZegoScreenSharingConfig()
        ..enable = true
        ..soundLevel = true
        ..foregroundService = ZegoForegroundServiceConfig()
          ..enable = true
          ..channelName = "بث الشاشة"
          ..contentTitle = "مشاركة الشاشة نشطة"
          ..contentText = "يتم بث شاشتك الآن"
          ..smallIcon = "ic_notification"; // تأكد من وجود هذا الأيقونة

    hostConfig.inRoomMessage.attributes = () => _userLevelAttribs;

    // تكوين المشاهد
    final audienceConfig = ZegoUIKitPrebuiltLiveStreamingConfig.audience(
      plugins: [ZegoUIKitSignalingPlugin()],
    )
      ..layout = ZegoLayout.gallery(
        showNewScreenSharingViewInFullscreenMode: true,
        showScreenSharingFullscreenModeToggleButtonRules:
            ZegoShowFullscreenModeToggleButtonRules.alwaysShow,
        addScreenSharingViewToMainView: true,
      )
      ..inRoomMessage.visible = false
      ..topMenuBar.showCloseButton = false
      ..topMenuBar.buttons = []
      ..audioVideoView.useVideoViewAspectFill = true
      ..audioVideoView.containerRect = () => 
          Rect.fromLTWH(0, 0, size.width, size.height - 60);

    audienceConfig.inRoomMessage.attributes = () => _userLevelAttribs;

    // أحداث المضيف
    final hostEvents = ZegoUIKitPrebuiltLiveStreamingEvents(
      onStateUpdated: (state) {
        liveStateNotifier.value = state;
        if (state == ZegoLiveStreamingState.playing) {
          print('✅ البث نشط');
        }
      },
      onError: (error) {
        print('❌ خطأ Zego: $error');
        if (error.code == 1000001) {
          // خطأ في بث الشاشة - حاول مرة أخرى
          _autoStartScreenSharing();
        }
      },
      screenSharing: ZegoLiveStreamingScreenSharingEvents(
        onStart: () {
          setState(() => isScreenSharingActive = true);
          print('✅ بدأ بث الشاشة');
        },
        onStop: () {
          setState(() => isScreenSharingActive = false);
          print('⏹️ توقف بث الشاشة');
        },
        onError: (error) {
          print('❌ خطأ في بث الشاشة: $error');
          setState(() => isScreenSharingActive = false);
        },
      ),
      user: ZegoLiveStreamingUserEvents(
        onEnter: (_) {},
        onLeave: (_) {},
      ),
    );

    // أحداث المشاهد
    final audienceEvents = ZegoUIKitPrebuiltLiveStreamingEvents(
      onError: (error) => print('❌ خطأ Zego: $error'),
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

  // ═══════════════════════════════════════════════════════════════════════════
  // FLOATING DRAGGABLE ICON
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildDraggableIcon(Size size) {
    return Positioned(
      left: _floatingPos.dx,
      top: _floatingPos.dy,
      child: GestureDetector(
        onPanUpdate: (d) {
          setState(() {
            _floatingPos = Offset(
              (_floatingPos.dx + d.delta.dx).clamp(0.0, size.width - 64),
              (_floatingPos.dy + d.delta.dy).clamp(0.0, size.height - 64),
            );
          });
        },
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
          ).animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 1.0, end: 1.04, duration: 2000.ms),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SLIDE PANEL
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

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
            child: Row(
              children: [
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
                _statBadge(Icons.remove_red_eye_outlined,
                    QuickHelp.convertToK(viewerCount), Colors.white54),
                const SizedBox(width: 8),
                Obx(() => _statBadge(Icons.diamond,
                    QuickHelp.checkFundsWithString(
                        amount: showGiftSendersController.diamondsCounter.value),
                    const Color(0xFFF59E0B))),
                const SizedBox(width: 10),
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

          // Viewers
          if (showGiftSendersController.giftSenderList.isNotEmpty) ...[
            SizedBox(
              height: 56,
              child: Obx(() => ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    itemCount: showGiftSendersController.giftSenderList.length,
                    itemBuilder: (ctx, i) {
                      final user = showGiftSendersController.giftSenderList[i];
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

          // Chat messages
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

          // Chat input
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
                _roundBtn(
                  color: kVioletColor,
                  icon: Icons.send_rounded,
                  onTap: _sendChatMessage,
                ),
                if (!widget.isHost) ...[
                  const SizedBox(width: 6),
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

          // End stream button
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

  // Helper widgets
  Widget _statBadge(IconData icon, String value, Color color) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(value, style: TextStyle(color: color, fontSize: 12)),
        ],
      );

  Widget _roundBtn({
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) =>
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
    
    setState(() {
      chatMessages.add({
        'name': widget.currentUser?.getFirstName ?? 'أنت',
        'text': text,
      });
    });
    
    _chatController.clear();
    
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _confirmEndStream() {
    if (!widget.isHost) {
      try {
        ZegoUIKitPrebuiltLiveStreamingController().screenSharing.stop();
      } catch (_) {}
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
            child: const Text("إلغاء", style: TextStyle(color: Color(0xFF9CA3AF))),
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

  // Gift animation
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

  // Zego helpers
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
