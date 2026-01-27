import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'gift_manager/defines.dart';

// هذه القائمة ستبدأ فارغة وتتم تعبئتها من السيرفر
List<ZegoGiftItem> giftItemList = [];

// دالة لجلب الهدايا من Back4app وتحويلها لتنسيق ZegoCloud
Future<void> loadGiftsFromServer() async {
  QueryBuilder<ParseObject> queryGifts = QueryBuilder<ParseObject>(ParseObject('Gifts'));
  
  final ParseResponse response = await queryGifts.query();

  if (response.success && response.results != null) {
    giftItemList = response.results!.map((gift) {
      // تحديد نوع الملف بناءً على الامتداد
      String fileUrl = gift.get<ParseFileBase>('file')?.url ?? '';
      ZegoGiftType giftType = fileUrl.endsWith('.svga') 
          ? ZegoGiftType.svga 
          : ZegoGiftType.mp4;

      return ZegoGiftItem(
        name: gift.get<String>('name') ?? 'Gift',
        icon: gift.get<ParseFileBase>('preview')?.url ?? '', 
        sourceURL: fileUrl,
        source: ZegoGiftSource.url,
        type: giftType,
        weight: gift.get<int>('coins') ?? 1,
      );
    }).toList();
  } else {
    print("خطأ في جلب الهدايا من السيرفر: ${response.error?.message}");
  }
}

ZegoGiftItem? queryGiftInItemList(String name) {
  final index = giftItemList.indexWhere((item) => item.name == name);
  return -1 != index ? giftItemList.elementAt(index) : null;
}
