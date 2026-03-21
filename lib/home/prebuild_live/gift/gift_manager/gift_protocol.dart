part of 'gift_manager.dart';

mixin GiftProtocol {
  final _giftProtocolImpll = GiftProtocolImpll();
  GiftProtocolImpll get service => _giftProtocolImpll;
}

class GiftProtocolImpll {
  late int _appID;
  late String _liveID;
  late String _localUserID;
  late String _localUserName;

  final List<StreamSubscription<dynamic>?> _subscriptions = [];

  final recvNotifier = ValueNotifier<ZegoGiftProtocolItem?>(null);

  // ── تأثير الدخول ──────────────────────────────────────────────────────────
  final entranceEffectNotifier = ValueNotifier<ZegoEntranceEffectItem?>(null);

  // ── رسالة عائمة ───────────────────────────────────────────────────────────
  final floatMessageNotifier = ValueNotifier<ZegoFloatMessageItem?>(null);

  Future<bool> sendFloatMessage({
    required String text,
    required String senderUserID,
    required String senderUserName,
    String? avatarUrl,
  }) async {
    final data = json.encode({
      'msg_type': 'float_message',
      'room_id': _liveID,
      'user_id': senderUserID,
      'user_name': senderUserName,
      'avatar_url': avatarUrl ?? '',
      'text': text,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    ZegoUIKit()
        .getSignalingPlugin()
        .sendInRoomCommandMessage(
          roomID: _liveID,
          message: _stringToUint8List(data),
        )
        .then((r) => debugPrint('sendFloatMessage result:$r'));
    return true;
  }

  /// يُرسَل فور دخول المستخدم الغرفة إذا كان لديه تأثير دخول مفعَّل
  Future<bool> sendEntranceEffect({
    required String fileUrl,
    required String senderUserID,
    required String senderUserName,
  }) async {
    final data = json.encode({
      'msg_type': 'entrance_effect',
      'room_id': _liveID,
      'user_id': senderUserID,
      'user_name': senderUserName,
      'file_url': fileUrl,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    ZegoUIKit()
        .getSignalingPlugin()
        .sendInRoomCommandMessage(
          roomID: _liveID,
          message: _stringToUint8List(data),
        )
        .then((result) {
      debugPrint('sendEntranceEffect result:$result');
    });
    return true;
  }

  void init({required int appID, required String liveID, required String localUserID, required String localUserName}) {
    _appID = appID;
    _liveID = liveID;
    _localUserID = localUserID;
    _localUserName = localUserName;

    _subscriptions.add(ZegoUIKit().getSignalingPlugin().getInRoomCommandMessageReceivedEventStream().listen((event) {
      onInRoomCommandMessageReceived(event);
    }));
  }

  void uninit() {
    for (final subscription in _subscriptions) {
      subscription?.cancel();
    }
    GiftMp4Player().destroyMediaPlayer();
  }

  Future<bool> sendGift({
    required String name,
    required int count,
  }) async {
    final data = ZegoGiftProtocol(
      appID: _appID,
      liveID: _liveID,
      localUserID: _localUserID,
      localUserName: _localUserName,
      giftItem: ZegoGiftProtocolItem(
        name: name,
        count: count,
      ),
    ).toJson();

    ///! This is just a demo for synchronous display effects.
    ///!
    ///! If it involves billing or your business logic,
    ///! please use the SERVER API to send a Message of type ZIMCommandMessage.
    ///!
    ///! https://docs.zegocloud.com/article/16201
    debugPrint('! ${'*' * 80}');
    debugPrint('! ** Warning: This is just a demo for synchronous display effects.');
    debugPrint('! ** ');
    debugPrint('! ** If it involves billing or your business logic,');
    debugPrint('! ** please use the SERVER API to send a Message of type ZIMCommandMessage.');
    debugPrint('! ${'*' * 80}');

    debugPrint('try send gift, name:$name, count:$count, data:$data');
    ZegoUIKit()
        .getSignalingPlugin()
        .sendInRoomCommandMessage(
          roomID: _liveID,
          message: _stringToUint8List(data),
        )
        .then((result) {
      debugPrint('send gift result:$result');
    });

    return true;
  }

  Uint8List _stringToUint8List(String input) {
    List<int> utf8Bytes = utf8.encode(input);
    Uint8List uint8List = Uint8List.fromList(utf8Bytes);
    return uint8List;
  }

  void onInRoomCommandMessageReceived(ZegoSignalingPluginInRoomCommandMessageReceivedEvent event) {
    final messages = event.messages;
    for (final commandMessage in messages) {
      final senderUserID = commandMessage.senderUserID;
      final message = utf8.decode(commandMessage.message);
      debugPrint('onInRoomCommandMessageReceived: $message');

      Map<String, dynamic> parsed = {};
      try { parsed = jsonDecode(message) as Map<String, dynamic>? ?? {}; } catch (_) {}

      final msgType = parsed['msg_type'] as String?;

      if (msgType == 'entrance_effect') {
        entranceEffectNotifier.value = ZegoEntranceEffectItem(
          fileUrl: parsed['file_url'] ?? '',
          senderUserID: parsed['user_id'] ?? '',
          senderUserName: parsed['user_name'] ?? '',
        );
      } else if (msgType == 'float_message') {
        floatMessageNotifier.value = ZegoFloatMessageItem(
          text: parsed['text'] ?? '',
          senderUserID: parsed['user_id'] ?? '',
          senderUserName: parsed['user_name'] ?? '',
          avatarUrl: parsed['avatar_url'] ?? '',
        );
      } else {
        if (senderUserID != _localUserID) {
          final gift = ZegoGiftProtocol.fromJson(message);
          recvNotifier.value = gift.giftItem;
        }
      }
    }
  }
}

class ZegoGiftProtocolItem {
  String name = '';
  int count = 0;

  ZegoGiftProtocolItem({required this.name, required this.count});
  ZegoGiftProtocolItem.empty();
}

class ZegoGiftProtocol {
  int appID = 0;
  String liveID = '';
  String localUserID = '';
  String localUserName = '';
  ZegoGiftProtocolItem giftItem;

  ZegoGiftProtocol({
    required this.appID,
    required this.liveID,
    required this.localUserID,
    required this.localUserName,
    required this.giftItem,
  });

  String toJson() => json.encode({
        'app_id': appID,
        'room_id': liveID,
        'user_id': localUserID,
        'user_name': localUserName,
        'gift_name': giftItem.name,
        'gift_count': giftItem.count,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

  factory ZegoGiftProtocol.fromJson(String jsonData) {
    Map<String, dynamic> json = {};
    try {
      json = jsonDecode(jsonData) as Map<String, dynamic>? ?? {};
    } catch (e) {
      debugPrint('protocol data is not json:$jsonData');
    }
    return ZegoGiftProtocol(
      appID: json['app_id'] ?? 0,
      liveID: json['room_id'] ?? '',
      localUserID: json['user_id'] ?? '',
      localUserName: json['user_name'] ?? '',
      giftItem: ZegoGiftProtocolItem(
        name: json['gift_name'] ?? '',
        count: json['gift_count'] ?? 0,
      ),
    );
  }
}
