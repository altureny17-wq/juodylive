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
  
  static String keyProgress = "progress";
  static String keyTarget = "target";
  static String keyIsCompleted = "isCompleted";
  static String keyCompletedAt = "completedAt";
  static String keyCompletionDate = "completionDate";
  
  static String keyRewardClaimed = "rewardClaimed";
  static String keyClaimedAt = "claimedAt";
  static String keyLastUpdated = "lastUpdated";

  // Getters
  UserModel? get getUser => get<UserModel>(keyUser);
  String? get getUserId => get<String>(keyUserId);
  DailyTaskModel? get getTask => get<DailyTaskModel>(keyTask);
  String? get getTaskId => get<String>(keyTaskId);
  int? get getProgress => get<int>(keyProgress);
  int? get getTarget => get<int>(keyTarget);
  bool? get getIsCompleted => get<bool>(keyIsCompleted);
  DateTime? get getCompletedAt => get<DateTime>(keyCompletedAt);
  DateTime? get getCompletionDate => get<DateTime>(keyCompletionDate);
  bool? get getRewardClaimed => get<bool>(keyRewardClaimed);
  DateTime? get getClaimedAt => get<DateTime>(keyClaimedAt);
  DateTime? get getLastUpdated => get<DateTime>(keyLastUpdated);

  // Setters
  set setUser(UserModel user) => set<UserModel>(keyUser, user);
  set setUserId(String id) => set<String>(keyUserId, id);
  set setTask(DailyTaskModel task) => set<DailyTaskModel>(keyTask, task);
  set setTaskId(String id) => set<String>(keyTaskId, id);
  set setProgress(int minutes) => set<int>(keyProgress, minutes);
  set incrementProgress(int minutes) => setIncrement(keyProgress, minutes);
  set setTarget(int minutes) => set<int>(keyTarget, minutes);
  set setIsCompleted(bool completed) => set<bool>(keyIsCompleted, completed);
  set setCompletedAt(DateTime date) => set<DateTime>(keyCompletedAt, date);
  set setCompletionDate(DateTime date) => set<DateTime>(keyCompletionDate, date);
  set setRewardClaimed(bool claimed) => set<bool>(keyRewardClaimed, claimed);
  set setClaimedAt(DateTime date) => set<DateTime>(keyClaimedAt, date);
  set setLastUpdated(DateTime date) => set<DateTime>(keyLastUpdated, date);
}
