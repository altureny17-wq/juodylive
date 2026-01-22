import 'package:juodylive/utils/colors.dart';
import 'package:flutter/material.dart';
import 'dart:math' show min;

class AvatarInitials extends StatelessWidget {
  final String? name;
  final Color? textColor;
  final Color? backgroundColor;
  final double? textSize;
  final double? avatarRadius;
  // 1. أضفنا متغير لاستقبال رابط الإطار من لوحة التحكم
  final String? avatarFrameUrl; 

  AvatarInitials({
    this.name,
    this.textColor,
    this.backgroundColor,
    this.textSize,
    this.avatarRadius,
    this.avatarFrameUrl, // أضفناه هنا أيضاً
  });

  String _getInitials() {
    if (name == null || name!.isEmpty) return ""; // أمان إضافي لمنع الكراش
    var nameParts = name!.trim().split(" ").map((elem) {
      return elem.isNotEmpty ? elem[0] : "";
    }).where((e) => e.isNotEmpty).toList();

    if (nameParts.isEmpty) return "";

    int numberOfParts = min(2, nameParts.length);
    return nameParts.take(numberOfParts).join().toUpperCase();
  }

  // 2. قمنا بتغيير نوع الإرجاع إلى Widget بدلاً من CircleAvatar لاستخدام Stack
  Widget _makeInitialsAvatar() {
    double radius = avatarRadius ?? 10;
    
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none, // للسماح للإطار بالخروج قليلاً عن حدود الدائرة
      children: [
        // الطبقة السفلية: الدائرة والأحرف
        CircleAvatar(
          backgroundColor: backgroundColor ?? kPrimaryColor,
          radius: radius,
          child: Text(
            _getInitials(),
            style: TextStyle(
              color: textColor ?? Colors.white, 
              fontSize: textSize, 
              fontWeight: FontWeight.bold
            ),
          ),
        ),
        
        // الطبقة العلوية: الإطار القادم من لوحة التحكم (يظهر فقط إذا وجد الرابط)
        if (avatarFrameUrl != null && avatarFrameUrl!.isNotEmpty)
          Positioned(
            // نجعل الإطار أكبر من الدائرة بنسبة بسيطة (مثلاً 1.2 من القطر)
            child: Image.network(
              avatarFrameUrl!,
              width: radius * 2.5, 
              height: radius * 2.5,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const SizedBox(), // حماية في حال كان الرابط معطلاً
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return _makeInitialsAvatar();
  }
}
