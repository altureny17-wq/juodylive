import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import '../models/DailyTaskModel.dart';
import '../models/UserTaskProgressModel.dart';
import '../models/UserModel.dart';

class DailyTaskService {
  
  // 1. جلب جميع المهام النشطة
  static Future<List<DailyTaskModel>> getActiveTasks() async {
    try {
      QueryBuilder<DailyTaskModel> query = QueryBuilder<DailyTaskModel>(DailyTaskModel())
        ..whereEqualTo(DailyTaskModel.keyIsActive, true)
        ..orderByAscending(DailyTaskModel.keySortOrder);
      
      final response = await query.query();
      
      if (response.success && response.results != null) {
        // تحويل النتيجة بشكل صريح إلى List<DailyTaskModel>
        return List<DailyTaskModel>.from(response.results!);
      }
    } catch (e) {
      print('❌ خطأ في جلب المهام: $e');
    }
    
    return [];
  }

  // 2. جلب تقدم المستخدم في المهام
  static Future<List<UserTaskProgressModel>> getUserProgress(String userId) async {
    try {
      QueryBuilder<UserTaskProgressModel> query = QueryBuilder<UserTaskProgressModel>(UserTaskProgressModel())
        ..includeObject([UserTaskProgressModel.keyTask])
        ..whereEqualTo(UserTaskProgressModel.keyUserId, userId)
        ..whereGreaterThanOrEqualsTo(UserTaskProgressModel.keyCompletionDate, _getStartOfDay())
        ..orderByDescending(UserTaskProgressModel.keyUpdatedAt);
      
      final response = await query.query();
      
      if (response.success && response.results != null) {
        // تحويل النتيجة بشكل صريح إلى List<UserTaskProgressModel>
        return List<UserTaskProgressModel>.from(response.results!);
      }
    } catch (e) {
      print('❌ خطأ في جلب تقدم المستخدم: $e');
    }
    
    return [];
  }

  // 3. بدء مهمة جديدة للمستخدم
  static Future<UserTaskProgressModel?> startTask(String userId, DailyTaskModel task) async {
    try {
      final existingProgress = await _getTodayTaskProgress(userId, task.objectId!);
      
      if (existingProgress != null) {
        return existingProgress;
      }
      
      // التعديل هنا: استخدام = بدلاً من () لأنها Setters
      final progress = UserTaskProgressModel()
        ..setUserId = userId
        ..setTask = task
        ..setTaskId = task.objectId!
        ..setProgress = 0
        ..setTarget = (task.getHoursRequired ?? 0) * 60 
        ..setIsCompleted = false
        ..setCompletionDate = DateTime.now()
        ..setLastUpdated = DateTime.now();
      
      final response = await progress.save();
      
      if (response.success) {
        return progress;
      }
    } catch (e) {
      print('❌ خطأ في بدء المهمة: $e');
    }
    
    return null;
  }

  // 4. تحديث تقدم المهمة
  static Future<bool> updateProgress(String progressId, int minutes) async {
    try {
      final progress = UserTaskProgressModel()
        ..objectId = progressId
        ..incrementProgress = minutes // استخدام = للـ setter
        ..setLastUpdated = DateTime.now();
      
      final response = await progress.save();
      
      await _checkTaskCompletion(progressId);
      
      return response.success;
    } catch (e) {
      print('❌ خطأ في تحديث التقدم: $e');
      return false;
    }
  }

  // 5. المطالبة بالمكافأة
  static Future<bool> claimReward(String progressId) async {
    try {
      final query = QueryBuilder<UserTaskProgressModel>(UserTaskProgressModel())
        ..whereEqualTo('objectId', progressId);
      
      final response = await query.query();
      
      if (response.success && response.results != null && response.results!.isNotEmpty) {
        final progress = response.results!.first as UserTaskProgressModel;
        
        if (progress.getIsCompleted == true && progress.getRewardClaimed == false) {
          progress
            ..setRewardClaimed = true
            ..setClaimedAt = DateTime.now();
          
          await progress.save();
          return true;
        }
      }
    } catch (e) {
      print('❌ خطأ في المطالبة بالمكافأة: $e');
    }
    
    return false;
  }

  // 6. إحصائيات المهام
  static Future<Map<String, dynamic>> getTaskStats(String userId) async {
    final progressList = await getUserProgress(userId);
    
    int completed = 0;
    int totalRewards = 0;
    int totalMinutes = 0;
    
    for (var p in progressList) {
      if (p.getIsCompleted == true) {
        completed++;
        totalRewards += p.getTask?.getReward ?? 0;
      }
      totalMinutes += p.getProgress ?? 0;
    }
    
    return {
      'totalTasks': progressList.length,
      'completedTasks': completed,
      'totalRewards': totalRewards,
      'totalMinutes': totalMinutes,
      'completionRate': progressList.isEmpty ? 0.0 : (completed / progressList.length * 100),
    };
  }

  // Helper Methods
  static Future<UserTaskProgressModel?> _getTodayTaskProgress(String userId, String taskId) async {
    final startOfDay = _getStartOfDay();
    
    QueryBuilder<UserTaskProgressModel> query = QueryBuilder<UserTaskProgressModel>(UserTaskProgressModel())
      ..whereEqualTo(UserTaskProgressModel.keyUserId, userId)
      ..whereEqualTo(UserTaskProgressModel.keyTaskId, taskId)
      ..whereGreaterThanOrEqualsTo(UserTaskProgressModel.keyCompletionDate, startOfDay);
    
    final response = await query.query();
    
    if (response.success && response.results != null && response.results!.isNotEmpty) {
      return response.results!.first as UserTaskProgressModel;
    }
    
    return null;
  }

  static DateTime _getStartOfDay() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static Future<void> _checkTaskCompletion(String progressId) async {
    final query = QueryBuilder<UserTaskProgressModel>(UserTaskProgressModel())
      ..whereEqualTo('objectId', progressId);
    
    final response = await query.query();
    
    if (response.success && response.results != null && response.results!.isNotEmpty) {
      final progress = response.results!.first as UserTaskProgressModel;
      
      // تأكد من عدم وجود قيم null أثناء المقارنة
      int currentProgress = progress.getProgress ?? 0;
      int target = progress.getTarget ?? 0;

      if (currentProgress >= target && progress.getIsCompleted == false) {
        progress
          ..setIsCompleted = true
          ..setCompletedAt = DateTime.now();
        
        await progress.save();
        print('🎉 تهانينا! لقد أكملت المهمة!');
      }
    }
  }
}
