import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'UserModel.dart';

class BusinessPageModel extends ParseObject implements ParseCloneable {
  static const String keyTableName = "BusinessPage";

  BusinessPageModel() : super(keyTableName);
  BusinessPageModel.clone() : this();

  @override
  BusinessPageModel clone(Map<String, dynamic> map) =>
      BusinessPageModel.clone()..fromJson(map);

  // ── مفاتيح الجدول ─────────────────────────────────────────────────────────
  static const String keyObjectId   = "objectId";
  static const String keyCreatedAt  = "createdAt";
  static const String keyOwner      = "owner";
  static const String keyOwnerId    = "ownerId";
  static const String keyName       = "pageName";
  static const String keyBio        = "pageBio";
  static const String keyCategory   = "category";
  static const String keyAvatar     = "pageAvatar";
  static const String keyCover      = "pageCover";
  static const String keyFollowers  = "followers";
  static const String keyFollowerIds= "followerIds";
  static const String keyIsVerified = "isVerified";
  static const String keyPostCount  = "postCount";
  static const String keyWebsite    = "website";
  static const String keyIsActive   = "isActive";
  static const String keyAdminIds   = "adminIds";   // ✅ مديرو الصفحة

  // ── الفئات ────────────────────────────────────────────────────────────────
  static const String catBusiness    = "business";
  static const String catEntertainment = "entertainment";
  static const String catNews        = "news";
  static const String catSports      = "sports";
  static const String catTechnology  = "technology";
  static const String catFashion     = "fashion";
  static const String catFood        = "food";
  static const String catHealth      = "health";
  static const String catOther       = "other";

  // ── Getters / Setters ──────────────────────────────────────────────────────
  UserModel? get getOwner  => get<UserModel>(keyOwner);
  set setOwner(UserModel owner) => set<UserModel>(keyOwner, owner);

  String? get getOwnerId   => get<String>(keyOwnerId);
  set setOwnerId(String id) => set<String>(keyOwnerId, id);

  String? get getName      => get<String>(keyName);
  set setName(String name)  => set<String>(keyName, name);

  String? get getBio       => get<String>(keyBio);
  set setBio(String bio)    => set<String>(keyBio, bio);

  String? get getCategory  => get<String>(keyCategory);
  set setCategory(String cat) => set<String>(keyCategory, cat);

  ParseFileBase? get getAvatar => get<ParseFileBase>(keyAvatar);
  set setAvatar(ParseFileBase file) => set<ParseFileBase>(keyAvatar, file);

  ParseFileBase? get getCover  => get<ParseFileBase>(keyCover);
  set setCover(ParseFileBase file) => set<ParseFileBase>(keyCover, file);

  List<dynamic>? get getFollowers => get<List<dynamic>>(keyFollowers);
  set setFollower(String uid) => setAddUnique(keyFollowers, uid);
  set removeFollower(String uid) => setRemove(keyFollowers, uid);

  List<dynamic>? get getFollowerIds => get<List<dynamic>>(keyFollowerIds);
  set setFollowerId(String id) => setAddUnique(keyFollowerIds, id);
  set removeFollowerId(String id) => setRemove(keyFollowerIds, id);

  bool get getIsVerified {
    return get<bool>(keyIsVerified) ?? false;
  }
  set setIsVerified(bool v) => set<bool>(keyIsVerified, v);

  int get getPostCount {
    return get<int>(keyPostCount) ?? 0;
  }
  set addPostCount(int n) => setIncrement(keyPostCount, n);

  String? get getWebsite   => get<String>(keyWebsite);
  set setWebsite(String w)  => set<String>(keyWebsite, w);

  bool get getIsActive {
    return get<bool>(keyIsActive) ?? true;
  }
  set setIsActive(bool v) => set<bool>(keyIsActive, v);

  int get followersCount => getFollowers?.length ?? 0;

  // ── مديرو الصفحة ──────────────────────────────────────────────────────────
  List<dynamic>? get getAdminIds => get<List<dynamic>>(keyAdminIds);
  set addAdminId(String id) => setAddUnique(keyAdminIds, id);
  set removeAdminId(String id) => setRemove(keyAdminIds, id);

  /// هل المستخدم مالك أو مدير؟
  bool isManagerOrOwner(String userId) {
    if (getOwnerId == userId) return true;
    return getAdminIds?.contains(userId) ?? false;
  }

  /// هل المستخدم مدير فقط (ليس مالكاً)؟
  bool isAdminOnly(String userId) {
    return (getAdminIds?.contains(userId) ?? false) && getOwnerId != userId;
  }
}
