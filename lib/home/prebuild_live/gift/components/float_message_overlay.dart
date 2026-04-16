import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../helpers/quick_actions.dart';
import '../../../../models/UserModel.dart';
import '../../../../ui/container_with_corner.dart';
import '../gift_manager/gift_manager.dart';
import '../gift_manager/gift_extras.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Overlay الرسالة العائمة — يُضاف فوق أي غرفة/بث
/// ─────────────────────────────────────────────────────────────────────────────
class FloatMessageOverlay extends StatefulWidget {
  const FloatMessageOverlay({Key? key}) : super(key: key);

  @override
  State<FloatMessageOverlay> createState() => _FloatMessageOverlayState();
}

class _FloatMessageOverlayState extends State<FloatMessageOverlay>
    with SingleTickerProviderStateMixin {
  final List<_FloatItem> _items = [];
  late AnimationController _ctrl;
  Timer? _cleanTimer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    ZegoGiftManager()
        .service
        .floatMessageNotifier
        .addListener(_onNewMessage);
  }

  @override
  void dispose() {
    _cleanTimer?.cancel();
    ZegoGiftManager()
        .service
        .floatMessageNotifier
        .removeListener(_onNewMessage);
    _ctrl.dispose();
    super.dispose();
  }

  void _onNewMessage() {
    final item = ZegoGiftManager().service.floatMessageNotifier.value;
    if (item == null || !mounted) return;

    setState(() {
      _items.add(_FloatItem(
        item: item,
        createdAt: DateTime.now(),
      ));
    });

    // أزل الرسالة بعد 4 ثوانٍ
    _cleanTimer?.cancel();
    _cleanTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      setState(() {
        _items.removeWhere((e) =>
            DateTime.now().difference(e.createdAt).inSeconds >= 4);
      });
      ZegoGiftManager().service.floatMessageNotifier.value = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return const SizedBox.shrink();
    return Positioned.fill(
      child: IgnorePointer(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _items
              .map((e) => _FloatMessageBubble(item: e.item))
              .toList(),
        ),
      ),
    );
  }
}

class _FloatItem {
  final ZegoFloatMessageItem item;
  final DateTime createdAt;
  _FloatItem({required this.item, required this.createdAt});
}

// ─────────────────────────────────────────────────────────────────────────────
// فقاعة الرسالة العائمة
// ─────────────────────────────────────────────────────────────────────────────
class _FloatMessageBubble extends StatefulWidget {
  final ZegoFloatMessageItem item;
  const _FloatMessageBubble({required this.item});

  @override
  State<_FloatMessageBubble> createState() => _FloatMessageBubbleState();
}

class _FloatMessageBubbleState extends State<_FloatMessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.7, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _ctrl.forward();

    // ابدأ التلاشي قبل 1 ثانية من الحذف
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _ctrl.reverse();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final levelColor = QuickHelp.levelColor(points: widget.item.userPoints);
    return FadeTransition(
      opacity: _opacity,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                levelColor.withOpacity(0.85),
                levelColor.withOpacity(0.4),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withOpacity(0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: levelColor.withOpacity(0.4),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // صورة المرسل
              if (widget.item.avatarUrl.isNotEmpty)
                ClipOval(
                  child: QuickActions.photosWidget(
                    widget.item.avatarUrl,
                    width: 28,
                    height: 28,
                  ),
                )
              else
                const CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.person, color: Colors.white, size: 16),
                ),
              const SizedBox(width: 8),
              // الاسم + النص
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.item.senderUserName,
                    style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.item.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// زر إرسال الرسالة العائمة — يُستخدم في جميع الغرف
// ─────────────────────────────────────────────────────────────────────────────
class FloatMessageButton extends StatelessWidget {
  final UserModel currentUser;
  final String liveID;
  final Color? color;

  const FloatMessageButton({
    Key? key,
    required this.currentUser,
    required this.liveID,
    this.color,
  }) : super(key: key);

  void _showInputDialog(BuildContext context) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E2C),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // مؤشر السحب
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'رسالة عائمة',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                maxLength: 50,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'اكتب رسالتك...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.08),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  counterStyle:
                      const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF656BF9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () async {
                    final text = controller.text.trim();
                    if (text.isEmpty) return;
                    Navigator.pop(ctx);

                    // أرسل عبر الـ signaling
                    await ZegoGiftManager().service.sendFloatMessage(
                      text: text,
                      senderUserID: currentUser.objectId!,
                      senderUserName: currentUser.getFullName ?? '',
                      avatarUrl: currentUser.getAvatar?.url ?? '',
                      userPoints: currentUser.getUserPoints ?? 0,
                    );

                    // شغّله محلياً للمرسل نفسه
                    ZegoGiftManager().service.floatMessageNotifier.value =
                        ZegoFloatMessageItem(
                      text: text,
                      senderUserID: currentUser.objectId!,
                      senderUserName: currentUser.getFullName ?? '',
                      avatarUrl: currentUser.getAvatar?.url ?? '',
                      userPoints: currentUser.getUserPoints ?? 0,
                    );
                  },
                  child: const Text(
                    'إرسال',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showInputDialog(context),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color ?? Colors.black.withOpacity(0.4),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.chat_bubble_outline_rounded,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}
