import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:intl/intl.dart';
import 'package:note_app/layers/domain/entities/task_entity.dart';
import 'package:note_app/layers/presentation/tasks/controller/tasks_controller.dart';
import 'package:note_app/layers/presentation/tasks/widgets/coin_burst.dart';
import 'package:note_app/layers/presentation/widgets/coin_badge.dart';
import 'package:note_app/layers/presentation/widgets/empty_state.dart';
import 'package:note_app/utils/date_utils.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key, required this.controller});

  final TasksController controller;

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> with WidgetsBindingObserver {
  TasksController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller.load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      controller.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) => Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              Row(
                children: [
                  Expanded(child: _DateQuestHeader(controller: controller)),
                  const SizedBox(width: 12),
                  CoinBadge(coins: controller.coins.value),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _showTaskDialog(),
                icon: const Icon(Icons.add_task),
                label: const Text('Thêm công việc'),
              ),
              const SizedBox(height: 16),
              if (controller.isLoading.value)
                const Center(child: CircularProgressIndicator())
              else if (controller.selectedTasks.value.isEmpty)
                const EmptyState(
                  icon: Icons.flag_outlined,
                  title: 'Chưa có nhiệm vụ',
                  body: 'Thêm task cho ngày này để bắt đầu thu thập xu.',
                )
              else
                ...controller.selectedTasks.value.map(
                  (task) => _TaskTile(
                    task: task,
                    onChanged: (value) => controller.setTaskDone(task, value),
                    onEdit: () => _showTaskDialog(task),
                    onCopy: () => _copyTaskToAnotherDate(task),
                    onDelete: () => controller.deleteTask(task),
                  ),
                ),
            ],
          ),
          if (controller.rewardBurst.value != null)
            Positioned.fill(
              child: IgnorePointer(
                child: CoinBurst(
                  key: ValueKey(controller.rewardBurst.value),
                  amount: controller.rewardBurst.value!,
                  onDone: controller.clearRewardBurst,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showTaskDialog([TaskEntity? task]) async {
    final title = TextEditingController(text: task?.title ?? '');
    final reward = TextEditingController(text: '${task?.reward ?? 20}');
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(task == null ? 'Thêm công việc' : 'Sửa công việc'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: title,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Tên công việc',
                prefixIcon: Icon(Icons.task_alt),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reward,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Xu thưởng',
                prefixIcon: Icon(Icons.monetization_on_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    if (result == true) {
      final parsedReward = int.tryParse(reward.text) ?? 20;
      if (task == null) {
        await controller.addTask(title.text, parsedReward);
      } else {
        await controller.updateTask(task, title.text, parsedReward);
      }
    }
  }

  Future<void> _copyTaskToAnotherDate(TaskEntity task) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: controller.selectedDate.value.add(const Duration(days: 1)),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    await controller.copyTaskToDate(task, picked);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Đã sao chép "${task.title}" sang ngày ${DateFormat('dd/MM/yyyy').format(picked)}.',
        ),
      ),
    );
  }
}

class _DateQuestHeader extends StatelessWidget {
  const _DateQuestHeader({required this.controller});

  final TasksController controller;

  @override
  Widget build(BuildContext context) {
    final selected = controller.selectedDate.value;
    final total = controller.selectedTasks.value.length;
    final completed = controller.completedCount.value;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xff12352f),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton.filledTonal(
                onPressed: () => controller.shiftDate(-1),
                tooltip: 'Ngày trước',
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => _pickDate(context),
                  child: Column(
                    children: [
                      Text(
                        weekdayVi(selected),
                        style: const TextStyle(
                          color: Color(0xff9be0c8),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        DateFormat('dd/MM/yyyy').format(selected),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton.filledTonal(
                onPressed: () => controller.shiftDate(1),
                tooltip: 'Ngày sau',
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: controller.progress.value,
            minHeight: 7,
            backgroundColor: Colors.white24,
            color: const Color(0xffffcf4a),
            borderRadius: BorderRadius.circular(99),
          ),
          const SizedBox(height: 6),
          Text(
            'Hoàn thành $completed/$total nhiệm vụ',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: controller.selectedDate.value,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) controller.setDate(picked);
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.task,
    required this.onChanged,
    required this.onEdit,
    required this.onCopy,
    required this.onDelete,
  });

  final TaskEntity task;
  final ValueChanged<bool> onChanged;
  final VoidCallback onEdit;
  final VoidCallback onCopy;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final background = task.done
        ? const [Color(0xffd7ead7), Color(0xffeff8ef)]
        : const [Color(0xff12352f), Color(0xff1d7a66)];
    final foreground = task.done ? const Color(0xff12352f) : Colors.white;
    final muted = task.done ? const Color(0xff326b55) : const Color(0xffbce8d9);

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.96, end: 1),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: background,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: task.done
                  ? const Color(0xff7fbe93)
                  : const Color(0xffffcf4a),
              width: 1.4,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1f000000),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(11),
            child: Row(
              children: [
                InkWell(
                  onTap: () => onChanged(!task.done),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: task.done
                          ? const Color(0xff12352f)
                          : const Color(0xffffcf4a),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      task.done ? Icons.verified : Icons.flag,
                      color: task.done
                          ? const Color(0xff9be0c8)
                          : const Color(0xff3d2a00),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _QuestPill(
                            text: task.done ? 'CLEARED' : 'QUEST',
                            foreground: task.done
                                ? const Color(0xff12352f)
                                : const Color(0xffffcf4a),
                            background: task.done
                                ? const Color(0xffbfe8c8)
                                : Colors.white12,
                          ),
                          _RewardPill(reward: task.reward),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        task.title,
                        style: TextStyle(
                          color: foreground,
                          decoration: task.done
                              ? TextDecoration.lineThrough
                              : null,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        task.done
                            ? 'Phần thưởng đã nhận'
                            : 'Hoàn thành để thu thập xu',
                        style: TextStyle(color: muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<_TaskMenuAction>(
                  tooltip: 'Thao tác',
                  color: Colors.white,
                  onSelected: (action) {
                    switch (action) {
                      case _TaskMenuAction.edit:
                        onEdit();
                      case _TaskMenuAction.copy:
                        onCopy();
                      case _TaskMenuAction.delete:
                        onDelete();
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: _TaskMenuAction.edit,
                      child: ListTile(
                        dense: true,
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Sửa'),
                      ),
                    ),
                    PopupMenuItem(
                      value: _TaskMenuAction.copy,
                      child: ListTile(
                        dense: true,
                        leading: Icon(Icons.copy_all_outlined),
                        title: Text('Sao chép sang ngày khác'),
                      ),
                    ),
                    PopupMenuItem(
                      value: _TaskMenuAction.delete,
                      child: ListTile(
                        dense: true,
                        leading: Icon(Icons.delete_outline),
                        title: Text('Xóa'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuestPill extends StatelessWidget {
  const _QuestPill({
    required this.text,
    required this.foreground,
    required this.background,
  });

  final String text;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foreground,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _RewardPill extends StatelessWidget {
  const _RewardPill({required this.reward});

  final int reward;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xffffcf4a),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monetization_on, size: 13, color: Color(0xff3d2a00)),
          const SizedBox(width: 2),
          Text(
            '$reward',
            style: const TextStyle(
              color: Color(0xff3d2a00),
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class TaskTileLegacy extends StatelessWidget {
  const TaskTileLegacy({
    super.key,
    required this.task,
    required this.onChanged,
    required this.onEdit,
    required this.onCopy,
    required this.onDelete,
  });

  final TaskEntity task;
  final ValueChanged<bool> onChanged;
  final VoidCallback onEdit;
  final VoidCallback onCopy;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final tileColor = task.done ? const Color(0xffd7ead7) : Colors.white;
    final borderColor = task.done
        ? const Color(0xff7fbe93)
        : Colors.transparent;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        color: tileColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: borderColor),
        ),
        child: ListTile(
          leading: Checkbox(
            value: task.done,
            onChanged: (value) => onChanged(value ?? false),
          ),
          title: Text(
            task.title,
            style: TextStyle(
              decoration: task.done ? TextDecoration.lineThrough : null,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            task.done
                ? 'Đã nhận ${task.reward} xu'
                : 'Thưởng ${task.reward} xu',
          ),
          trailing: PopupMenuButton<_TaskMenuAction>(
            tooltip: 'Thao tác',
            onSelected: (action) {
              switch (action) {
                case _TaskMenuAction.edit:
                  onEdit();
                case _TaskMenuAction.copy:
                  onCopy();
                case _TaskMenuAction.delete:
                  onDelete();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _TaskMenuAction.edit,
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.edit_outlined),
                  title: Text('Sửa'),
                ),
              ),
              PopupMenuItem(
                value: _TaskMenuAction.copy,
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.copy_all_outlined),
                  title: Text('Sao chép sang ngày khác'),
                ),
              ),
              PopupMenuItem(
                value: _TaskMenuAction.delete,
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.delete_outline),
                  title: Text('Xóa'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _TaskMenuAction { edit, copy, delete }
