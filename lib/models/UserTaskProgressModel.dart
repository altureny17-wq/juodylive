// lib/models/UserTaskProgressModel.dart
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'UserModel.dart';
import 'DailyTaskModel.dart';

class UserTaskProgressModel extends ParseObject implements ParseCloneable {
  static final String keyTableName = "UserTaskProgress";

  UserTaskProgressModel() : super(keyTableName);
  UserTaskProgressModel.clone() : this();

  @override
  UserTaskProgressModel clone(Map<String, dynamic> map) => UserTaskProgressModel.clone()..fromJson(map);

  // Keys
  static String keyObjectId = "objectId";
  static String keyCreatedAt = "createdAt";
  static String keyUpdatedAt = "updatedAt";
  
  static String keyUser = "user";
  static String keyUserId = "userId";
  static String keyTask = "task";
  static String keyTaskId = "taskId";
  
  static String keyProgress = "progress"; // الدقائق المنجزة
  static String keyTarget = "target"; // الهدف بالدقائق
  static String keyIsCompleted = "isCompleted";
  static String keyCompletedAt = "completedAt";
  static String keyCompletionDate = "completionDate"; // تاريخ الإكمال
  
  static String keyRewardClaimed = "rewardClaimed";
  static String keyClaimedAt = "claimedAt";
  
  static String keyLastUpdated = "lastUpdated";

  // Getters & Setters
  UserModel? get getUser => get<UserModel>(keyUser);
  set setUser(UserModel user) => set<UserModel>(keyUser, user);

  String? get getUserId => get<String>(keyUserId);
  set setUserId(String id) => set<String>(keyUserId, id);

  DailyTaskModel? get getTask => get<DailyTaskModel>(keyTask);
  set setTask(DailyTaskModel task) => set<DailyTaskModel>(keyTask, task);

  String? get getTaskId => get<String>(keyTaskId);
  set setTaskId(String id) => set<String>(keyTaskId, id);

  int? get getProgress => get<int>(keyProgress);
  set setProgress(int minutes) => set<int>(keyProgress, minutes);
  set incrementProgress(int minutes) => setIncrement(keyProgress, minutes);

  int? get getTarget => get<int>(keyTarget);
  set setTarget(int minutes) => set<int>(keyTarget, minutes);

  bool? get getIsCompleted => get<bool>(keyIsCompleted);
  set setIsCompleted(bool completed) => set<bool>(keyIsCompleted, completed);

  DateTime? get getCompletedAt => get<DateTime>(keyCompletedAt);
  set setCompletedAt(DateTime date) => set<DateTime>(keyCompletedAt, date);

  DateTime? get getCompletionDate => get<DateTime>(keyCompletionDate);
  set setCompletionDate(DateTime date) => set<DateTime>(keyCompletionDate, date);

  bool? get getRewardClaimed => get<bool>(keyRewardClaimed);
  set setRewardClaimed(bool claimed) => set<bool>(keyRewardClaimed, claimed);

  DateTime? get getClaimedAt => get<DateTime>(keyClaimedAt);
  set setClaimedAt(DateTime date) => set<DateTime>(keyClaimedAt, date);

  DateTime? get getLastUpdated => get<DateTime>(keyLastUpdated);
  set setLastUpdated(DateTime date) => set<DateTime>(keyLastUpdated, date);
}