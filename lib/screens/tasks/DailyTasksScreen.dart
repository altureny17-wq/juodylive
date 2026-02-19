import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../models/UserModel.dart';
import '../../models/DailyTaskModel.dart';
import '../../models/UserTaskProgressModel.dart';
import '../../services/DailyTaskService.dart';
import '../../ui/container_with_corner.dart';
import '../../ui/text_with_tap.dart';
import '../../utils/colors.dart';
import '../../helpers/quick_actions.dart';

class DailyTasksScreen extends StatefulWidget {
  final UserModel currentUser;
  
  const DailyTasksScreen({Key? key, required this.currentUser}) : super(key: key);
  
  @override
  _DailyTasksScreenState createState() => _DailyTasksScreenState();
}

class _DailyTasksScreenState extends State<DailyTasksScreen> with SingleTickerProviderStateMixin {
  List<DailyTaskModel> tasks = [];
  Map<String, UserTaskProgressModel> userProgress = {};
  Map<String, dynamic> stats = {};
  bool isLoading = true;
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    
    try {
      // تنفيذ الطلبات بالتوازي
      final results = await Future.wait([
        DailyTaskService.getActiveTasks(),
        DailyTaskService.getUserProgress(widget.currentUser.objectId!),
        DailyTaskService.getTaskStats(widget.currentUser.objectId!),
      ]);
      
      // عمل Casting يدوي لكل نتيجة لضمان توافق الأنواع
      final loadedTasks = results[0] as List<DailyTaskModel>;
      final loadedProgress = results[1] as List<UserTaskProgressModel>;
      final loadedStats = results[2] as Map<String, dynamic>;
      
      final progressMap = <String, UserTaskProgressModel>{};
      for (var p in loadedProgress) {
        if (p.getTaskId != null) {
          progressMap[p.getTaskId!] = p;
        }
      }
      
      if (mounted) {
        setState(() {
          tasks = loadedTasks;
          userProgress = progressMap;
          stats = loadedStats;
          isLoading = false;
        });
      }
    } catch (e) {
      print('❌ خطأ في تحميل البيانات: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('daily_tasks.title').tr(),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'daily_tasks.today_tasks'.tr()),
            Tab(text: 'daily_tasks.statistics'.tr()),
          ],
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTasksTab(),
                _buildStatsTab(),
              ],
            ),
    );
  }

  Widget _buildTasksTab() {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_late, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('daily_tasks.no_tasks').tr(),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: EdgeInsets.all(12),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          final progress = userProgress[task.objectId];
          return _buildTaskCard(task, progress);
        },
      ),
    );
  }

  Widget _buildTaskCard(DailyTaskModel task, UserTaskProgressModel? progress) {
    final bool isStarted = progress != null;
    final bool isCompleted = progress?.getIsCompleted ?? false;
    final int targetMinutes = (task.getHoursRequired ?? 0) * 60;
    final int currentProgress = progress?.getProgress ?? 0;
    final double progressPercentage = targetMinutes > 0 ? (currentProgress / targetMinutes).clamp(0.0, 1.0) : 0;
    
    Color taskColor = _getTaskColor(task.getTaskId ?? 'A');
    
    return ContainerCorner(
      marginBottom: 12,
      borderRadius: 12,
      color: Colors.white,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: taskColor.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: taskColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: TextWithTap(
                      task.getTaskId ?? '',
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextWithTap(
                        task.getTaskName ?? '',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      TextWithTap(
                        '${task.getHoursRequired} ${'daily_tasks.hours'.tr()}',
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.diamond, color: Colors.amber, size: 16),
                      SizedBox(width: 4),
                      TextWithTap(
                        '${task.getReward}',
                        fontWeight: FontWeight.bold,
                        color: Colors.amber[800],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              children: [
                if (task.getDescription != null && task.getDescription!.isNotEmpty)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextWithTap(
                      task.getDescription!,
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                SizedBox(height: 8),
                if (isStarted) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextWithTap(
                        '${_formatMinutes(currentProgress)} / ${_formatMinutes(targetMinutes)}',
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                      TextWithTap(
                        '${(progressPercentage * 100).toStringAsFixed(0)}%',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: taskColor,
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: progressPercentage,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(taskColor),
                  ),
                  SizedBox(height: 8),
                ],
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isCompleted
                            ? null
                            : () => _handleTaskAction(task, progress),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isCompleted ? Colors.green : taskColor,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          isCompleted
                              ? 'daily_tasks.completed'.tr()
                              : isStarted
                                  ? 'daily_tasks.continue'.tr()
                                  : 'daily_tasks.start'.tr(),
                        ).tr(),
                      ),
                    ),
                    if (isCompleted && !(progress?.getRewardClaimed ?? true))
                      SizedBox(width: 8),
                    if (isCompleted && !(progress?.getRewardClaimed ?? true))
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(Icons.card_giftcard, color: Colors.white),
                          onPressed: () => _claimReward(progress!),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        ContainerCorner(
          borderRadius: 16,
          color: Colors.blue.withOpacity(0.1),
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatCircle('${stats['completedTasks'] ?? 0}', 'daily_tasks.completed', Colors.green),
                  _buildStatCircle('${stats['totalTasks'] ?? 0}', 'daily_tasks.total', Colors.blue),
                  _buildStatCircle('${((stats['completionRate'] ?? 0) as num).toStringAsFixed(0)}%', 'daily_tasks.rate', Colors.orange),
                ],
              ),
              SizedBox(height: 16),
              Divider(),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(Icons.timer, _formatMinutes(stats['totalMinutes'] ?? 0), 'daily_tasks.total_time'),
                  _buildStatItem(Icons.diamond, '${stats['totalRewards'] ?? 0}', 'daily_tasks.total_rewards'),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 20),
        TextWithTap('daily_tasks.rewards_table', fontSize: 18, fontWeight: FontWeight.bold),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
          ),
          child: Row(
            children: [
              Expanded(flex: 2, child: Text('daily_tasks.task'.tr(), style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(child: Text('daily_tasks.hours'.tr(), style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
              Expanded(child: Text('daily_tasks.reward'.tr(), style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
            ],
          ),
        ),
        ...List.generate(tasks.length, (index) {
          final task = tasks[index];
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[300]!))),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(color: _getTaskColor(task.getTaskId ?? 'A'), shape: BoxShape.circle),
                        child: Center(child: Text(task.getTaskId ?? '', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                      ),
                      SizedBox(width: 8),
                      Expanded(child: Text(task.getTaskName ?? '', maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ),
                Expanded(child: Text('${task.getHoursRequired}H', textAlign: TextAlign.center)),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.diamond, color: Colors.amber, size: 14),
                      SizedBox(width: 4),
                      Text('${task.getReward}'),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStatCircle(String value, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
          child: Center(child: Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color))),
        ),
        SizedBox(height: 8),
        Text(label.tr(), style: TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue, size: 24),
        SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(label.tr(), style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ],
    );
  }

  void _handleTaskAction(DailyTaskModel task, UserTaskProgressModel? progress) async {
    if (progress == null) {
      final newProgress = await DailyTaskService.startTask(widget.currentUser.objectId!, task);
      if (newProgress != null) {
        setState(() => userProgress[task.objectId!] = newProgress);
        _showNotification('daily_tasks.task_started'.tr());
      }
    } else {
      _showAddProgressDialog(progress);
    }
  }

  void _showAddProgressDialog(UserTaskProgressModel progress) {
    final TextEditingController minutesController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('daily_tasks.add_progress'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${'daily_tasks.current_progress'.tr()}: ${_formatMinutes(progress.getProgress ?? 0)}'),
            Text('${'daily_tasks.target'.tr()}: ${_formatMinutes(progress.getTarget ?? 0)}'),
            SizedBox(height: 16),
            TextField(
              controller: minutesController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'daily_tasks.minutes'.tr(), border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('cancel'.tr())),
          ElevatedButton(
            onPressed: () async {
              final minutes = int.tryParse(minutesController.text) ?? 0;
              if (minutes > 0) {
                Navigator.pop(context);
                final success = await DailyTaskService.updateProgress(progress.objectId!, minutes);
                if (success) {
                  await _loadData();
                  _showNotification('daily_tasks.progress_updated'.tr());
                }
              }
            },
            child: Text('save'.tr()),
          ),
        ],
      ),
    );
  }

  void _claimReward(UserTaskProgressModel progress) async {
    final success = await DailyTaskService.claimReward(progress.objectId!);
    if (success) {
      _showNotification('daily_tasks.reward_claimed'.tr());
      await _loadData();
    }
  }

  // دالة مساعدة لتجنب أخطاء عدم تعريف QuickHelp
  void _showNotification(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Color _getTaskColor(String taskId) {
    switch (taskId) {
      case 'S': return Colors.purple;
      case 'A': return Colors.red;
      case 'B': return Colors.orange;
      case 'C': return Colors.amber;
      case 'D': return Colors.green;
      default: return Colors.blue;
    }
  }

  String _formatMinutes(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return hours > 0 ? '${hours}H ${mins}M' : '${mins}M';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
