
import 'package:juodylive/models/UserModel.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

class AvatarService {
  final Map<String, String?> _avatarCache = {};
  final Map<String, UserModel> _userModelCache = {}; // ✅ cache للـ UserModel كامل

  Future<void> loadAllAvatars() async {
    final query = QueryBuilder<UserModel>(UserModel.forQuery());
    final response = await query.query();

    if (response.success && response.results != null) {
      for (UserModel user in response.results!) {
        final userID = user.objectId;
        String? avatarUrl = user.getAvatar?.url;
        if (userID != null) {
          _avatarCache[userID] = avatarUrl ?? 'NO_AVATAR';
          _userModelCache[userID] = user;
        }
      }
    }
  }

  String? getAvatarUrl(String userID) {
    return _avatarCache[userID] != 'NO_AVATAR' ? _avatarCache[userID] : null;
  }

  Future<String?> fetchUserAvatar(String userID) async {
    // ✅ إصلاح: استخدم الـ cache الصحيح (كان يُنشئ cache محلي جديد في كل مرة!)
    if (_avatarCache.containsKey(userID)) {
      return _avatarCache[userID];
    }

    final query = QueryBuilder<UserModel>(UserModel.forQuery())
      ..whereEqualTo(UserModel.keyObjectId, userID);

    final response = await query.query();
    if (response.success && response.results != null && response.results!.isNotEmpty) {
      UserModel user = response.results!.first;
      _avatarCache[userID] = user.getAvatar?.url;
      _userModelCache[userID] = user;
      return user.getAvatar?.url;
    }

    _avatarCache[userID] = null;
    return null;
  }

  // ✅ دالة جديدة: جلب UserModel كامل مع الإطار
  Future<UserModel?> fetchUserModel(String userID) async {
    if (_userModelCache.containsKey(userID)) {
      return _userModelCache[userID];
    }

    final query = QueryBuilder<UserModel>(UserModel.forQuery())
      ..whereEqualTo(UserModel.keyObjectId, userID)
      ..includeObject([UserModel.keyAvatarFrame]); // ✅ جلب الإطار مع البيانات

    final response = await query.query();
    if (response.success && response.results != null && response.results!.isNotEmpty) {
      UserModel user = response.results!.first;
      _userModelCache[userID] = user;
      _avatarCache[userID] = user.getAvatar?.url;
      return user;
    }

    return null;
  }
}
