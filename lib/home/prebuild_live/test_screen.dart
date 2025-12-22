// Flutter imports:
// ignore_for_file: must_be_immutable

import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:fade_shimmer/fade_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lottie/lottie.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:text_scroll/text_scroll.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:zego_uikit_prebuilt_live_audio_room/zego_uikit_prebuilt_live_audio_room.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:get/get.dart' hide Trans;
import '../../app/constants.dart';
import '../../app/setup.dart';
import '../../helpers/quick_actions.dart';
import '../../helpers/quick_cloud.dart';
import '../../helpers/quick_help.dart';
import '../../helpers/users_avatars_service.dart';
import '../../models/GiftsModel.dart';
import '../../models/GiftsSentModel.dart';
import '../../models/LeadersModel.dart';
import '../../models/LiveStreamingModel.dart';
import '../../models/LiveViewersModel.dart';
import '../../models/NotificationsModel.dart';
import '../../models/UserModel.dart';
import '../../ui/container_with_corner.dart';
import '../../ui/text_with_tap.dart';
import '../../utils/colors.dart';
import '../coins/coins_payment_widget.dart';
import '../controller/controller.dart';
import '../live_end/live_end_report_screen.dart';
import '../live_end/live_end_screen.dart';
import 'gift/components/svga_player_widget.dart';
import 'gift/gift_manager/gift_manager.dart';
import 'global_private_live_price_sheet.dart';
import 'global_user_profil_sheet.dart';

class PrebuildAudioRoomScreen extends StatefulWidget {
  UserModel? currentUser;
  bool? isHost;
  LiveStreamingModel? liveStreaming;

  PrebuildAudioRoomScreen({
    this.currentUser,
    this.isHost,
    this.liveStreaming,
    super.key,
  });

  @override
  State<PrebuildAudioRoomScreen> createState() =>
      _PrebuildAudioRoomScreenState();
}

class _PrebuildAudioRoomScreenState extends State<PrebuildAudioRoomScreen>
    with TickerProviderStateMixin {
  int numberOfSeats = 0;
  AnimationController? _animationController;

  Subscription? subscription;
  Subscription? giftsSubscription;
  LiveQuery liveQuery = LiveQuery();
  var coHostsList = [];
  bool following = false;

  Controller showGiftSendersController = Get.find<Controller>();
  final selectedGiftItemNotifier = ValueNotifier<GiftsModel?>(null);
  Timer? removeGiftTimer;

  void startRemovingGifts() {
    removeGiftTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (showGiftSendersController.receivedGiftList.isNotEmpty) {
        showGiftSendersController.giftReceiverList.removeAt(0);
        showGiftSendersController.giftSenderList.removeAt(0);
        showGiftSendersController.receivedGiftList.removeAt(0);
      } else {
        timer.cancel();
        removeGiftTimer = null;
      }
    });
  }

  SharedPreferences? preference;

  initSharedPref() async {
    preference = await SharedPreferences.getInstance();
    Constants.queryParseConfig(preference!);
  }

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    initSharedPref();
    showGiftSendersController.isPrivateLive.value =
        widget.liveStreaming!.getPrivate!;
    Future.delayed(const Duration(minutes: 2)).then((value) {
      widget.currentUser!.addUserPoints = widget.isHost! ? 350 : 200;
      widget.currentUser!.save();
    });
    following = widget.currentUser!.getFollowing!
        .contains(widget.liveStreaming!.getAuthorId!);
    showGiftSendersController.diamondsCounter.value =
        widget.liveStreaming!.getDiamonds!.toString();
    showGiftSendersController.shareMediaFiles.value =
        widget.liveStreaming!.getSharingMedia!;

    if (widget.liveStreaming!.getNumberOfChairs == 20) {
      numberOfSeats = (widget.liveStreaming!.getNumberOfChairs! ~/ 5) + 1;
    } else if (widget.liveStreaming!.getNumberOfChairs == 24) {
      numberOfSeats = (widget.liveStreaming!.getNumberOfChairs! ~/ 6) + 1;
    } else {
      numberOfSeats = (widget.liveStreaming!.getNumberOfChairs! ~/ 4) + 1;
    }

    if (widget.isHost!) {
      addOrUpdateLiveViewers();
    }
    setupLiveGifts();
    setupStreamingLiveQuery();
    _animationController = AnimationController.unbounded(vsync: this);
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    showGiftSendersController.isPrivateLive.value = false;
    if (subscription != null) {
      liveQuery.client.unSubscribe(subscription!);
    }
    if (giftsSubscription != null) {
      liveQuery.client.unSubscribe(giftsSubscription!);
    }
    subscription = null;
    giftsSubscription = null;
    removeGiftTimer?.cancel();
    _animationController?.dispose();
    super.dispose();
  }

  final isSeatClosedNotifier = ValueNotifier<bool>(false);
  final isRequestingNotifier = ValueNotifier<bool>(false);

  @override
  Widget build(BuildContext context) {
    final AvatarService avatarService = AvatarService();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          ZegoUIKitPrebuiltLiveAudioRoom(
            appID: Setup.zegoLiveStreamAppID,
            appSign: Setup.zegoLiveStreamAppSign,
            userID: widget.currentUser!.objectId!,
            userName: widget.currentUser!.getFullName!,
            roomID: widget.liveStreaming!.getStreamingChannel!,
            config: (widget.isHost!
                ? ZegoUIKitPrebuiltLiveAudioRoomConfig.host()
                : ZegoUIKitPrebuiltLiveAudioRoomConfig.audience())
              ..bottomMenuBar.audienceExtendButtons = [giftButton]
              ..bottomMenuBar.speakerExtendButtons = [giftButton]
              ..seat.layout.rowConfigs = List.generate(numberOfSeats, (index) {
                if (index == 0) {
                  return ZegoLiveAudioRoomLayoutRowConfig(
                      count: 1,
                      alignment: ZegoLiveAudioRoomLayoutAlignment.center);
                }
                if (widget.liveStreaming!.getNumberOfChairs == 20) {
                  return ZegoLiveAudioRoomLayoutRowConfig(
                      count: 5,
                      alignment: ZegoLiveAudioRoomLayoutAlignment.start);
                }
                if (widget.liveStreaming!.getNumberOfChairs == 24) {
                  return ZegoLiveAudioRoomLayoutRowConfig(
                      count: 6,
                      alignment: ZegoLiveAudioRoomLayoutAlignment.start);
                }
                return ZegoLiveAudioRoomLayoutRowConfig(
                    count: 4,
                    alignment: ZegoLiveAudioRoomLayoutAlignment.spaceEvenly);
              })
              ..foreground = customUiComponents()
              ..inRoomMessage.visible = true
              ..inRoomMessage.showAvatar = true
              ..bottomMenuBar.hostExtendButtons = [
                Obx(() {
                  return ContainerCorner(
                    color: Colors.white,
                    borderRadius: 50,
                    height: 38,
                    width: 38,
                    onTap: () => toggleSharingMedia(),
                    child: Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: SvgPicture.asset(
                        showGiftSendersController.shareMediaFiles.value
                            ? "assets/svg/stop_sharing_media.svg"
                            : "assets/svg/start_sharing_media.svg",
                      ),
                    ),
                  );
                }),
                privateLiveBtn
              ]
              ..background = Image.asset(
                "assets/images/audio_bg_start.png",
                height: size.height,
                width: size.width,
                fit: BoxFit.fill,
              )
              ..seat.avatarBuilder = (context, seatSize, user, extraInfo) {
                if (user == null) return const SizedBox();
                return FutureBuilder<String?>(
                  future: avatarService.fetchUserAvatar(user.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return FadeShimmer(
                        width: seatSize.width,
                        height: seatSize.width,
                        radius: 200,
                        fadeTheme: QuickHelp.isDarkModeNoContext()
                            ? FadeTheme.dark
                            : FadeTheme.light,
                      );
                    }
                    final avatarUrl = snapshot.data;
                    return avatarUrl != null
                        ? QuickActions.photosWidget(
                            avatarUrl,
                            width: seatSize.width,
                            height: seatSize.width,
                            borderRadius: 200,
                          )
                        : Icon(Icons.account_circle,
                            size: seatSize.width, color: Colors.white);
                  },
                );
              },
            events: ZegoUIKitPrebuiltLiveAudioRoomEvents(
              onLeaveConfirmation: (context) async {
                if (widget.isHost!) {
                  return await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        backgroundColor: QuickHelp.isDarkMode(context)
                            ? kContentColorLightTheme
                            : kContentColorDarkTheme,
                        title: TextWithTap(
                          "account_settings.logout_user_sure".tr(),
                          fontWeight: FontWeight.bold,
                        ),
                        content: Text('live_streaming.finish_live_ask'.tr()),
                        actions: [
                          TextWithTap(
                            "cancel".tr(),
                            fontWeight: FontWeight.bold,
                            marginRight: 10,
                            marginLeft: 10,
                            marginBottom: 10,
                            onTap: () => Navigator.of(context).pop(false),
                          ),
                          TextWithTap(
                            "confirm_".tr(),
                            fontWeight: FontWeight.bold,
                            marginRight: 10,
                            marginLeft: 10,
                            marginBottom: 10,
                            onTap: () async {
                              QuickHelp.showLoadingDialog(context);
                              onViewerLeave();
                              widget.liveStreaming!.setStreaming = false;
                              ParseResponse response =
                                  await widget.liveStreaming!.save();
                              QuickHelp.hideLoadingDialog(context);
                              if (response.success) {
                                QuickHelp.goToNavigatorScreen(
                                  context,
                                  LiveEndReportScreen(
                                    currentUser: widget.currentUser,
                                    live: widget.liveStreaming,
                                  ),
                                );
                              } else {
                                QuickHelp.showAppNotificationAdvanced(
                                  title: "try_again_later".tr(),
                                  message: "not_connected".tr(),
                                  context: context,
                                );
                              }
                            },
                          ),
                        ],
                      );
                    },
                  );
                } else {
                  return true;
                }
              },
            ),
          ),
          Positioned(
            top: 30,
            left: 10,
            child: SizedBox(
              width: size.width / 1.2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ContainerCorner(
                        height: 37,
                        borderRadius: 50,
                        onTap: () {
                          if (!widget.isHost!) {
                            showUserProfileBottomSheet(
                              currentUser: widget.currentUser!,
                              userId: widget.liveStreaming!.getAuthorId!,
                              context: context,
                            );
                          }
                        },
                        colors: const [kVioletColor, kPrimaryColor],
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ContainerCorner(
                                  marginRight: 5,
                                  color: Colors.black.withOpacity(0.5),
                                  child: QuickActions.avatarWidget(
                                    widget.liveStreaming!.getAuthor!,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                  borderRadius: 50,
                                  height: 30,
                                  width: 30,
                                  borderWidth: 0,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 65,
                                      child: TextScroll(
                                        widget.liveStreaming!.getAuthor!
                                            .getFullName!,
                                        mode: TextScrollMode.endless,
                                        velocity: const Velocity(
                                            pixelsPerSecond: Offset(30, 0)),
                                        delayBefore: const Duration(seconds: 1),
                                        pauseBetween:
                                            const Duration(milliseconds: 150),
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 10),
                                        textAlign: TextAlign.left,
                                        selectable: true,
                                        intervalSpaces: 5,
                                        numberOfReps: 9999,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 65,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Padding(
                                            padding: EdgeInsets.only(left: 5),
                                            child: Image(
                                              image: AssetImage(
                                                  "assets/images/grade_welfare.png"),
                                              height: 12,
                                              width: 12,
                                            ),
                                          ),
                                          Obx(() {
                                            return TextWithTap(
                                              QuickHelp.checkFundsWithString(
                                                amount:
                                                    showGiftSendersController
                                                        .diamondsCounter.value,
                                              ),
                                              marginLeft: 5,
                                              marginRight: 5,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: Colors.white,
                                            );
                                          }),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                            ContainerCorner(
                              marginLeft: 10,
                              marginRight: 6,
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: 50,
                              height: 23,
                              width: 23,
                              child: Padding(
                                padding: const EdgeInsets.all(3.0),
                                child: Lottie.asset(
                                    "assets/lotties/ic_live_animation.json"),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!widget.isHost!)
                        ContainerCorner(
                          marginLeft: 5,
                          height: 30,
                          width: 30,
                          marginTop: 15,
                          color: following ? Colors.blueAccent : kVioletColor,
                          borderRadius: 50,
                          onTap: () {
                            if (!following) followOrUnfollow();
                          },
                          child: Center(
                            child: Icon(
                              following ? Icons.done : Icons.add,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  ContainerCorner(
                    width: 70,
                    height: 40,
                    marginRight: 5,
                    child: getTopGifters(),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget get giftButton => Container(
        decoration: const BoxDecoration(
          color: Colors.black26,
          shape: BoxShape.circle,
        ),
        child: IconButton(
          onPressed: () {
            if (showGiftSendersController.isPrivateLive.value) {
              unPrivatiseLive();
            } else {
              PrivateLivePriceWidget(
                context: context,
                onCancel: () => QuickHelp.hideLoadingDialog(context),
                onGiftSelected: (gift) {
                  QuickHelp.hideLoadingDialog(context);
                  privatiseLive(gift);
                },
              );
            }
          },
          icon: Obx(() => SvgPicture.asset(
                showGiftSendersController.isPrivateLive.value
                    ? "assets/svg/ic_unlocked_live.svg"
                    : "assets/svg/ic_locked_live.svg",
              )),
        ),
      );

  Widget get privateLiveBtn => Obx(() {
        return ContainerCorner(
          color: Colors.white,
          borderRadius: 50,
          height: 38,
          width: 38,
          onTap: () {
            if (showGiftSendersController.isPrivateLive.value) {
              unPrivatiseLive();
            } else {
              openUserToReceiveCoins();
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(5.0),
            child: SvgPicture.asset(
              showGiftSendersController.isPrivateLive.value
                  ? "assets/svg/ic_unlocked_live.svg"
                  : "assets/svg/ic_locked_live.svg",
            ),
          ),
        );
      });

  privatiseLive(GiftsModel gift) async {
    QuickHelp.showLoadingDialog(context);
    widget.liveStreaming!.setPrivate = true;
    widget.liveStreaming!.setPrivateLivePrice = gift;
    ParseResponse response = await widget.liveStreaming!.save();
    QuickHelp.hideLoadingDialog(context);
    if (response.success) {
      QuickHelp.showAppNotificationAdvanced(
        title: "privatise_live_title".tr(),
        message: "privatise_live_succeed".tr(),
        context: context,
        isError: false,
      );
      showGiftSendersController.isPrivateLive.value = true;
    } else {
      QuickHelp.showAppNotificationAdvanced(
        title: "connection_failed".tr(),
        message: "not_connected".tr(),
        context: context,
      );
    }
  }

  unPrivatiseLive() async {
    QuickHelp.showLoadingDialog(context);
    widget.liveStreaming!.setPrivate = false;
    ParseResponse response = await widget.liveStreaming!.save();
    QuickHelp.hideLoadingDialog(context);
    if (response.success) {
      QuickHelp.showAppNotificationAdvanced(
        title: "public_live_title".tr(),
        message: "public_live_succeed".tr(),
        isError: false,
        context: context,
      );
      showGiftSendersController.isPrivateLive.value = false;
    } else {
      QuickHelp.showAppNotificationAdvanced(
        title: "connection_failed".tr(),
        message: "not_connected".tr(),
        context: context,
      );
    }
  }

  onViewerLeave() async {
    QueryBuilder<LiveViewersModel> queryLiveViewers =
        QueryBuilder<LiveViewersModel>(LiveViewersModel());
    queryLiveViewers.whereEqualTo(
        LiveViewersModel.keyAuthorId, widget.currentUser!.objectId);
    queryLiveViewers.whereEqualTo(LiveViewersModel.keyLiveAuthorId,
        widget.liveStreaming!.getAuthorId!);
    queryLiveViewers.whereEqualTo(
        LiveViewersModel.keyLiveId, widget.liveStreaming!.objectId!);
    ParseResponse parseResponse = await queryLiveViewers.query();
    if (parseResponse.success && parseResponse.result != null) {
      LiveViewersModel liveViewers =
          parseResponse.results!.first! as LiveViewersModel;
      liveViewers.setWatching = false;
      await liveViewers.save();
    }
  }

  addOrUpdateLiveViewers() async {
    QueryBuilder<LiveViewersModel> queryLiveViewers =
        QueryBuilder<LiveViewersModel>(LiveViewersModel());
    queryLiveViewers.whereEqualTo(
        LiveViewersModel.keyAuthorId, widget.currentUser!.objectId);
    queryLiveViewers.whereEqualTo(
        LiveViewersModel.keyLiveId, widget.liveStreaming!.objectId!);
    queryLiveViewers.whereEqualTo(LiveViewersModel.keyLiveAuthorId,
        widget.liveStreaming!.getAuthorId!);
    ParseResponse parseResponse = await queryLiveViewers.query();
    if (parseResponse.success) {
      if (parseResponse.results != null) {
        LiveViewersModel liveViewers =
            parseResponse.results!.first! as LiveViewersModel;
        liveViewers.setWatching = true;
        await liveViewers.save();
      } else {
        LiveViewersModel liveViewersModel = LiveViewersModel();
        liveViewersModel.setAuthor = widget.currentUser!;
        liveViewersModel.setAuthorId = widget.currentUser!.objectId!;
        liveViewersModel.setWatching = true;
        liveViewersModel.setLiveAuthorId = widget.liveStreaming!.getAuthorId!;
        liveViewersModel.setLiveId = widget.liveStreaming!.objectId!;
        await liveViewersModel.save();
      }
    }
  }

  Widget getTopGifters() {
    QueryBuilder<LiveViewersModel> query =
        QueryBuilder<LiveViewersModel>(LiveViewersModel());
    query.whereEqualTo(
        LiveViewersModel.keyLiveId, widget.liveStreaming!.objectId);
    query.whereEqualTo(LiveViewersModel.keyWatching, true);
    query.orderByDescending(LiveViewersModel.keyUpdatedAt);
    query.includeObject([LiveViewersModel.keyAuthor]);
    return ParseLiveListWidget<LiveViewersModel>(
      query: query,
      scrollDirection: Axis.horizontal,
      childBuilder: (context, snapshot) {
        if (snapshot.hasData) {
          LiveViewersModel viewer = snapshot.loadedData!;
          return Stack(
            alignment: Alignment.bottomCenter,
            children: [
              ContainerCorner(
                height: 25,
                width: 25,
                borderRadius: 50,
                marginRight: 7,
                child: QuickActions.avatarWidget(viewer.getAuthor!,
                    height: 25, width: 25),
              ),
              ContainerCorner(
                color: Colors.white,
                borderRadius: 2,
                marginRight: 7,
                child: TextWithTap(
                  QuickHelp.convertToK(viewer.getAuthor!.getCreditsSent!),
                  fontSize: 5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          );
        }
        return const SizedBox();
      },
    );
  }

  void followOrUnfollow() async {
    if (following) {
      widget.currentUser!.removeFollowing = widget.liveStreaming!.getAuthorId!;
      widget.liveStreaming!.removeFollower = widget.currentUser!.objectId!;
      setState(() => following = false);
    } else {
      widget.currentUser!.setFollowing = widget.liveStreaming!.getAuthorId!;
      widget.liveStreaming!.addFollower = widget.currentUser!.objectId!;
      setState(() => following = true);
    }
    await widget.currentUser!.save();
    widget.liveStreaming!.save();
    ParseResponse parseResponse = await QuickCloudCode.followUser(
        author: widget.currentUser!,
        receiver: widget.liveStreaming!.getAuthor!);
    if (parseResponse.success) {
      sendMessage("${widget.currentUser!.getFullName!} has started following");
      QuickActions.createOrDeleteNotification(
        widget.currentUser!,
        widget.liveStreaming!.getAuthor!,
        NotificationsModel.notificationTypeFollowers,
      );
    }
  }

  setupStreamingLiveQuery() async {
    QueryBuilder<LiveStreamingModel> query =
        QueryBuilder<LiveStreamingModel>(LiveStreamingModel());
    query.whereEqualTo(
        LiveStreamingModel.keyObjectId, widget.liveStreaming!.objectId);
    query.includeObject([
      LiveStreamingModel.keyPrivateLiveGift,
      LiveStreamingModel.keyGiftSenders,
      LiveStreamingModel.keyAuthor
    ]);
    subscription = await liveQuery.client.subscribe(query);
    subscription!.on(LiveQueryEvent.update, (LiveStreamingModel updatedLive) {
      if (!mounted) return;
      showGiftSendersController.diamondsCounter.value =
          updatedLive.getDiamonds.toString();
      if (!updatedLive.getStreaming! && !widget.isHost!) {
        QuickHelp.goToNavigatorScreen(
            context,
            LiveEndScreen(
                currentUser: widget.currentUser,
                liveAuthor: updatedLive.getAuthor));
      }
    });
  }

  sendGift(GiftsModel giftsModel, UserModel mUser) async {
    GiftsSentModel giftsSentModel = GiftsSentModel();
    giftsSentModel.setAuthor = widget.currentUser!;
    giftsSentModel.setAuthorId = widget.currentUser!.objectId!;
    giftsSentModel.setReceiver = mUser;
    giftsSentModel.setReceiverId = mUser.objectId!;
    giftsSentModel.setLiveId = widget.liveStreaming!.objectId!;
    giftsSentModel.setGift = giftsModel;
    giftsSentModel.setGiftId = giftsModel.objectId!;
    giftsSentModel.setCounterDiamondsQuantity = giftsModel.getCoins!;
    await giftsSentModel.save();

    QuickHelp.saveReceivedGifts(
        receiver: mUser, author: widget.currentUser!, gift: giftsModel);
    QuickHelp.saveCoinTransaction(
        receiver: mUser,
        author: widget.currentUser!,
        amountTransacted: giftsModel.getCoins!);

    updateCurrentUser(giftsModel.getCoins!);
    await QuickCloudCode.sendGift(author: mUser, credits: giftsModel.getCoins!);
    if (mUser.objectId == widget.liveStreaming!.getAuthorId) {
      widget.liveStreaming!.addDiamonds =
          QuickHelp.getDiamondsForReceiver(giftsModel.getCoins!);
      await widget.liveStreaming!.save();
    }
    sendMessage(
        "${widget.currentUser!.getFullName!} sent a gift to ${mUser.getFullName!}");
  }

  Widget customUiComponents() {
    return Stack(
      children: [
        Obx(() {
          return Positioned(
            bottom: 100,
            child: Column(
              children: List.generate(
                  showGiftSendersController.receivedGiftList.length, (index) {
                return Row(
                  children: [
                    ContainerCorner(
                        colors: const [Colors.black26, Colors.transparent],
                        borderRadius: 50,
                        child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(children: [
                              QuickActions.avatarWidget(
                                  showGiftSendersController
                                      .giftSenderList[index],
                                  width: 35,
                                  height: 35),
                              TextWithTap("sent_gift_to".tr(),
                                  color: Colors.white, marginLeft: 5)
                            ])))
                  ],
                ).animate().slideX();
              }),
            ),
          );
        }),
        ValueListenableBuilder<GiftsModel?>(
          valueListenable: ZegoGiftManager().playList.playingDataNotifier,
          builder: (context, playData, _) {
            if (null == playData) return const SizedBox.shrink();
            return svgaWidget(playData);
          },
        ),
      ],
    );
  }

  Future<void> toggleSharingMedia() async {
    QuickHelp.showLoadingDialog(context);
    widget.liveStreaming!.setSharingMedia =
        !showGiftSendersController.shareMediaFiles.value;
    ParseResponse response = await widget.liveStreaming!.save();
    QuickHelp.hideLoadingDialog(context);
    if (response.success) {
      showGiftSendersController.shareMediaFiles.value =
          !showGiftSendersController.shareMediaFiles.value;
    }
  }

  updateCurrentUser(int coins) async {
    widget.currentUser!.removeCredit = coins;
    ParseResponse response = await widget.currentUser!.save();
    if (response.success && response.results != null) {
      widget.currentUser = response.results!.first as UserModel;
    }
  }

  Widget svgaWidget(GiftsModel giftItem) {
    return ZegoSvgaPlayerWidget(
      key: UniqueKey(),
      giftItem: giftItem,
      onPlayEnd: () => ZegoGiftManager().playList.next(),
      count: 1,
    );
  }

  setupLiveGifts() async {
    QueryBuilder<GiftsSentModel> queryBuilder =
        QueryBuilder<GiftsSentModel>(GiftsSentModel());
    queryBuilder.whereEqualTo(
        GiftsSentModel.keyLiveId, widget.liveStreaming!.objectId);
    queryBuilder.includeObject([GiftsSentModel.keyGift]);
    giftsSubscription = await liveQuery.client.subscribe(queryBuilder);
    giftsSubscription!.on(LiveQueryEvent.create, (giftSent) async {
      await giftSent.getGift!.fetch();
      showGiftSendersController.receivedGiftList.add(giftSent.getGift!);
      if (removeGiftTimer == null) startRemovingGifts();
      ZegoGiftManager().playList.add(giftSent.getGift!);
    });
  }

  void openUserToReceiveCoins() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _showUserToReceiveCoins(),
    );
  }

  Widget _showUserToReceiveCoins() {
    if (!coHostsList.contains(widget.liveStreaming!.getAuthorId)) {
      coHostsList.add(widget.liveStreaming!.getAuthorId);
    }
    QueryBuilder<UserModel> coHostQuery =
        QueryBuilder<UserModel>(UserModel.forQuery());
    coHostQuery.whereContainedIn(UserModel.keyObjectId, coHostsList);

    return ContainerCorner(
      color: kPrimaryColor.withOpacity(.9),
      radiusTopLeft: 10,
      radiusTopRight: 10,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextWithTap("choose_gift_receiver".tr(),
              color: Colors.white, marginTop: 15),
          Flexible(
            child: ParseLiveGridWidget<UserModel>(
              query: coHostQuery,
              crossAxisCount: 4,
              childBuilder: (context, snapshot) {
                if (snapshot.hasData) {
                  UserModel user = snapshot.loadedData!;
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      CoinsFlowPayment(
                        context: context,
                        currentUser: widget.currentUser!,
                        onCoinsPurchased: (coins) {},
                        onGiftSelected: (gift) {
                          sendGift(gift, user);
                          QuickHelp.showAppNotificationAdvanced(
                            context: context,
                            title: "live_streaming.gift_sent_title".tr(),
                            message: "live_streaming.gift_sent_explain"
                                .tr(namedArgs: {"name": user.getFirstName!}),
                            isError: false,
                          );
                        },
                      );
                    },
                    child: Column(
                      children: [
                        QuickActions.avatarWidget(user, width: 50, height: 50),
                        TextWithTap(user.getFullName!, color: Colors.white)
                      ],
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }

  void sendMessage(String message) => debugPrint("Message: $message");

  void showUserProfileBottomSheet(
          {required UserModel currentUser,
          required String userId,
          required BuildContext context}) =>
      debugPrint("Show Profile: $userId");
}
