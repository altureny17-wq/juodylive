import 'package:flutter/material.dart';

/// بيانات تأثير الدخول المستقبَل
class ZegoEntranceEffectItem {
  final String fileUrl;
  final String senderUserID;
  final String senderUserName;

  ZegoEntranceEffectItem({
    required this.fileUrl,
    required this.senderUserID,
    required this.senderUserName,
  });
}

/// بيانات الرسالة العائمة المستقبَلة
class ZegoFloatMessageItem {
  final String text;
  final String senderUserID;
  final String senderUserName;
  final String avatarUrl;
  final int userPoints;

  ZegoFloatMessageItem({
    required this.text,
    required this.senderUserID,
    required this.senderUserName,
    required this.avatarUrl,
    this.userPoints = 0,
  });
}
