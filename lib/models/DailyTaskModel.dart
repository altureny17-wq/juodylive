// lib/models/DailyTaskModel.dart
import 'package:parse_server_sdk/parse_server_sdk.dart';

class DailyTaskModel extends ParseObject implements ParseCloneable {
  static final String keyTableName = "DailyTasks";

  DailyTaskModel() : super(keyTableName);
  DailyTaskModel.clone() : this();

  @override
  DailyTaskModel clone(Map<String, dynamic> map) => DailyTaskModel.clone()..fromJson(map);

  // Keys
  static String keyObjectId = "objectId";
  static String keyCreatedAt = "createdAt";
  static String keyUpdatedAt = "updatedAt";
  
  static String keyTaskId = "taskId";
  static String keyTaskName = "taskName";
  static String keyDescription = "description";
  static String keyHoursRequired = "hoursRequired";
  static String keyReward = "reward";
  static String keyRewardType = "rewardType";
  static String keyIcon = "icon";
  static String keyColor = "color";
  static String keyIsActive = "isActive";
  static String keySortOrder = "sortOrder";
  static String keyRequiredLevel = "requiredLevel";
  static String keyDailyLimit = "dailyLimit";

  // Getters & Setters
  String? get getTaskId => get<String>(keyTaskId);
  set setTaskId(String id) => set<String>(keyTaskId, id);

  String? get getTaskName => get<String>(keyTaskName);
  set setTaskName(String name) => set<String>(keyTaskName, name);

  String? get getDescription => get<String>(keyDescription);
  set setDescription(String desc) => set<String>(keyDescription, desc);

  int? get getHoursRequired => get<int>(keyHoursRequired);
  set setHoursRequired(int hours) => set<int>(keyHoursRequired, hours);

  int? get getReward => get<int>(keyReward);
  set setReward(int reward) => set<int>(keyReward, reward);

  String? get getRewardType => get<String>(keyRewardType);
  set setRewardType(String type) => set<String>(keyRewardType, type);

  ParseFileBase? get getIcon => get<ParseFileBase>(keyIcon);
  set setIcon(ParseFileBase file) => set<ParseFileBase>(keyIcon, file);

  String? get getColor => get<String>(keyColor);
  set setColor(String color) => set<String>(keyColor, color);

  bool? get getIsActive => get<bool>(keyIsActive);
  set setIsActive(bool active) => set<bool>(keyIsActive, active);

  int? get getSortOrder => get<int>(keySortOrder);
  set setSortOrder(int order) => set<int>(keySortOrder, order);

  int? get getRequiredLevel => get<int>(keyRequiredLevel);
  set setRequiredLevel(int level) => set<int>(keyRequiredLevel, level);

  int? get getDailyLimit => get<int>(keyDailyLimit);
  set setDailyLimit(int limit) => set<int>(keyDailyLimit, limit);
}