import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/database_service.dart';
import '../../../shared/utils/avatar_helper.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/challenge_model.dart';

const _templates = [
  {
    'emoji': '🏃',
    'name': '30-Day Fitness',
    'days': 30,
    'tasks': [
      '20 min cardio',
      'Strength training — upper body',
      '30 min yoga or stretching',
      '20 min HIIT',
      'Strength training — lower body',
      'Outdoor run or brisk walk',
      'Active recovery — light stretching',
    ],
  },
  {
    'emoji': '📖',
    'name': '7-Day Gratitude',
    'days': 7,
    'tasks': [
      'Write 3 things you\'re grateful for',
      'Write a thank-you note to someone',
      'Reflect on a positive memory',
      'Write about something beautiful you saw',
      'List 3 achievements you\'re proud of',
      'Write about someone who helped you',
      'Write a gratitude letter to yourself',
    ],
  },
  {
    'emoji': '💧',
    'name': 'Drink Water',
    'days': 30,
    'tasks': ['Drink 8 glasses of water'],
  },
  {
    'emoji': '🧘',
    'name': 'Mindfulness',
    'days': 21,
    'tasks': [
      '5 min morning meditation',
      'Practice deep breathing for 3 min',
      'Eat one meal without distractions',
      '5 min body scan meditation',
      'Write down 3 things you noticed today',
    ],
  },
  {
    'emoji': '📵',
    'name': 'No Social Media',
    'days': 7,
    'tasks': ['No social media today'],
  },
  {
    'emoji': '✍️',
    'name': 'Daily Writing',
    'days': 30,
    'tasks': ['Write 300 words'],
  },
];

class ChallengeEditorScreen extends StatefulWidget {
  final Challenge? challenge;
  const ChallengeEditorScreen({super.key, this.challenge});

  @override
  State<ChallengeEditorScreen> createState() => _ChallengeEditorScreenState();
}

class _ChallengeEditorScreenState extends State<ChallengeEditorScreen> {
  final _db = DatabaseService();
  final _uuid = Uuid();
  final _pageController = PageController();
  int _currentStep = 0;

  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _taskController = TextEditingController();
  List<String> _tasks = [];
  List<String> _selectedParticipants = [];
  List<Map<String, dynamic>> _allUsers = [];
  late DateTime _startDate;
  late DateTime _endDate;
  bool _isSubmitting = false;
  StreamSubscription? _usersSub;
  int? _selectedTemplate;

  bool get _isEditing => widget.challenge != null;

  @override
  void initState() {
    super.initState();
    final c = widget.challenge;
    if (c != null) {
      _titleController.text = c.title;
      _descController.text = c.description;
      _tasks = List.from(c.tasks);
      _selectedParticipants = List.from(c.participants);
      _selectedParticipants
          .removeWhere((p) => p == context.read<AuthProvider>().user?.uid);
      _startDate = c.startDate;
      _endDate = c.endDate;
    } else {
      _startDate = DateTime.now();
      _endDate = DateTime.now().add(const Duration(days: 6));
    }
    _loadUsers();
  }

  void _loadUsers() {
    final uid = context.read<AuthProvider>().user?.uid;
    if (uid == null) return;
    _usersSub = _db.allUsers(uid).listen((users) {
      if (mounted) {
        setState(() => _allUsers =
            users.map((u) => {'id': u.uid, 'name': u.name}).toList());
      }
    });
  }

  @override
  void dispose() {
    _usersSub?.cancel();
    _titleController.dispose();
    _descController.dispose();
    _taskController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  bool get _step1Valid => _titleController.text.trim().isNotEmpty;
  bool get _step2Valid => _selectedParticipants.isNotEmpty;
  bool get _step3Valid => _tasks.isNotEmpty;
  bool get _step4Valid => _endDate.isAfter(_startDate);

  void _nextStep() {
    if (_currentStep < 3) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _selectTemplate(int index) {
    final t = _templates[index];
    setState(() {
      _selectedTemplate = index;
      _titleController.text = t['name'] as String;
      _tasks = List<String>.from(t['tasks'] as List);
      _endDate = _startDate.add(Duration(days: (t['days'] as int) - 1));
    });
  }

  void _addTask() {
    final text = _taskController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _tasks.add(text);
      _taskController.clear();
    });
  }

  Future<void> _submit() async {
    if (!_step1Valid || !_step2Valid || !_step3Valid || !_step4Valid) return;
    setState(() => _isSubmitting = true);
    try {
      final auth = context.read<AuthProvider>();
      final user = auth.user;
      if (user == null) return;
      final uid = user.uid;
      final name = auth.chatUser?.name ?? 'Me';

      final participantIds = [uid, ..._selectedParticipants];
      final participantNames = <String, String>{};
      participantNames[uid] = name;
      for (final u in _allUsers) {
        if (_selectedParticipants.contains(u['id'])) {
          participantNames[u['id'] as String] = u['name'] as String;
        }
      }

      if (_isEditing) {
        await _db.updateChallenge(widget.challenge!.id, {
          'title': _titleController.text.trim(),
          'description': _descController.text.trim(),
          'participants': participantIds,
          'participantNames': participantNames,
          'startDate': _startDate,
          'endDate': _endDate,
          'tasks': _tasks,
        });
        if (context.mounted) Navigator.pop(context);
      } else {
        final challenge = Challenge(
          id: _uuid.v4(),
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          createdBy: uid,
          participants: participantIds,
          participantNames: participantNames,
          startDate: _startDate,
          endDate: _endDate,
          tasks: _tasks,
          createdAt: DateTime.now(),
        );
        await _db.createChallenge(challenge);
        if (context.mounted) Navigator.pop(context, challenge);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final uid = context.watch<AuthProvider>().user?.uid;
    final currentName = context.watch<AuthProvider>().chatUser?.name ?? 'Me';

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Challenge' : 'New Challenge'),
        actions: [
          if (_currentStep == 3)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton(
                onPressed: _step1Valid &&
                        _step2Valid &&
                        _step3Valid &&
                        _step4Valid &&
                        !_isSubmitting
                    ? _submit
                    : null,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEditing ? 'Save' : 'Create'),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: _nextStep,
                child: const Text('Next'),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _StepIndicator(currentStep: _currentStep, totalSteps: 4),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _currentStep = i),
              children: [
                _Step1Name(
                  titleController: _titleController,
                  descController: _descController,
                  selectedTemplate: _selectedTemplate,
                  onSelectTemplate: _selectTemplate,
                  theme: theme,
                  colorScheme: colorScheme,
                  onChanged: () => setState(() {}),
                ),
                _Step2Friends(
                  uid: uid,
                  currentName: currentName,
                  allUsers: _allUsers,
                  selectedParticipants: _selectedParticipants,
                  colorScheme: colorScheme,
                  onToggle: (id) => setState(() {
                    if (_selectedParticipants.contains(id)) {
                      _selectedParticipants.remove(id);
                    } else {
                      _selectedParticipants.add(id);
                    }
                  }),
                ),
                _Step3Tasks(
                  tasks: _tasks,
                  taskController: _taskController,
                  onAdd: _addTask,
                  onRemove: (i) => setState(() => _tasks.removeAt(i)),
                  theme: theme,
                  colorScheme: colorScheme,
                ),
                _Step4Dates(
                  startDate: _startDate,
                  endDate: _endDate,
                  title: _titleController.text,
                  tasks: _tasks,
                  participantCount:
                      _selectedParticipants.length + (uid != null ? 1 : 0),
                  theme: theme,
                  colorScheme: colorScheme,
                  onStartDateChanged: (d) => setState(() => _startDate = d),
                  onEndDateChanged: (d) => setState(() => _endDate = d),
                ),
              ],
            ),
          ),
          _Footer(
            currentStep: _currentStep,
            canGoNext: _currentStep == 0
                ? _step1Valid
                : _currentStep == 1
                    ? _step2Valid
                    : _currentStep == 2
                        ? _step3Valid
                        : _step4Valid,
            onBack: _currentStep > 0 ? _prevStep : null,
            onNext: _currentStep < 3 ? _nextStep : null,
          ),
        ],
      ),
    );
  }
}

// ── Step Indicator ──
class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  const _StepIndicator({required this.currentStep, required this.totalSteps});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
      child: Row(
        children: List.generate(totalSteps, (i) {
          final isActive = i == currentStep;
          final isDone = i < currentStep;
          return Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: isActive || isDone
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Step 1: Name + Template ──
class _Step1Name extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController descController;
  final int? selectedTemplate;
  final void Function(int) onSelectTemplate;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final VoidCallback onChanged;

  const _Step1Name({
    required this.titleController,
    required this.descController,
    required this.selectedTemplate,
    required this.onSelectTemplate,
    required this.theme,
    required this.colorScheme,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: titleController,
            style: theme.textTheme.titleLarge,
            decoration: InputDecoration(
              labelText: 'Challenge name',
              hintText: 'e.g. 7-Day Gratitude',
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (_) => onChanged(),
          ),
          const SizedBox(height: 20),
          Text('Or pick a template',
              style: theme.textTheme.labelLarge
                  ?.copyWith(color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.1,
            ),
            itemCount: _templates.length,
            itemBuilder: (context, i) {
              final t = _templates[i];
              final isSelected = selectedTemplate == i;
              return InkWell(
                onTap: () => onSelectTemplate(i),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primary.withAlpha(15)
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(color: colorScheme.primary, width: 1.5)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(t['emoji'] as String,
                          style: const TextStyle(fontSize: 28)),
                      const SizedBox(height: 6),
                      Text(t['name'] as String,
                          style: theme.textTheme.labelSmall
                              ?.copyWith(fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: descController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Description (optional)',
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step 2: Friends ──
class _Step2Friends extends StatefulWidget {
  final String? uid;
  final String currentName;
  final List<Map<String, dynamic>> allUsers;
  final List<String> selectedParticipants;
  final ColorScheme colorScheme;
  final void Function(String) onToggle;

  const _Step2Friends({
    required this.uid,
    required this.currentName,
    required this.allUsers,
    required this.selectedParticipants,
    required this.colorScheme,
    required this.onToggle,
  });

  @override
  State<_Step2Friends> createState() => _Step2FriendsState();
}

class _Step2FriendsState extends State<_Step2Friends> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _query.isEmpty
        ? widget.allUsers
        : widget.allUsers
            .where((u) => (u['name'] as String)
                .toLowerCase()
                .contains(_query.toLowerCase()))
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search friends...',
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('Invite friends',
              style: theme.textTheme.labelLarge
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _FriendTile(
                name: '${widget.currentName} (you)',
                isSelected: true,
                enabled: false,
                colorScheme: widget.colorScheme,
              ),
              ...filtered.map((u) => _FriendTile(
                    name: u['name'] as String,
                    isSelected: widget.selectedParticipants.contains(u['id']),
                    enabled: true,
                    colorScheme: widget.colorScheme,
                    onTap: () => widget.onToggle(u['id'] as String),
                  )),
            ],
          ),
        ),
      ],
    );
  }
}

class _FriendTile extends StatelessWidget {
  final String name;
  final bool isSelected;
  final bool enabled;
  final ColorScheme colorScheme;
  final VoidCallback? onTap;

  const _FriendTile({
    required this.name,
    required this.isSelected,
    required this.enabled,
    required this.colorScheme,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            avatarWidget(radius: 16, photoUrl: null, name: name),
            const SizedBox(width: 10),
            Expanded(
              child: Text(name,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w500)),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: colorScheme.primary, size: 22)
            else if (enabled)
              Icon(Icons.circle_outlined, color: colorScheme.outline, size: 22),
          ],
        ),
      ),
    );
  }
}

// ── Step 3: Tasks ──
class _Step3Tasks extends StatelessWidget {
  final List<String> tasks;
  final TextEditingController taskController;
  final VoidCallback onAdd;
  final void Function(int) onRemove;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _Step3Tasks({
    required this.tasks,
    required this.taskController,
    required this.onAdd,
    required this.onRemove,
    required this.theme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Daily tasks — one for each day',
              style: theme.textTheme.labelLarge
                  ?.copyWith(color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: taskController,
                  decoration: InputDecoration(
                    hintText: 'e.g. 20 min cardio',
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (_) => onAdd(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: onAdd,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  padding: EdgeInsets.zero,
                ),
                child: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (tasks.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Center(
                child: Text('Add at least one task',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: colorScheme.onSurfaceVariant)),
              ),
            )
          else
            ...tasks.asMap().entries.map((entry) {
              final i = entry.key;
              final task = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 6),
                elevation: 0,
                color: colorScheme.surfaceContainerHighest,
                child: ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    child: Text('${i + 1}',
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                  title: Text(task, style: theme.textTheme.bodyMedium),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => onRemove(i),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ── Step 4: Dates + Summary ──
class _Step4Dates extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final String title;
  final List<String> tasks;
  final int participantCount;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final void Function(DateTime) onStartDateChanged;
  final void Function(DateTime) onEndDateChanged;

  const _Step4Dates({
    required this.startDate,
    required this.endDate,
    required this.title,
    required this.tasks,
    required this.participantCount,
    required this.theme,
    required this.colorScheme,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final days = endDate.difference(startDate).inDays + 1;
    final now = DateTime.now();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Duration',
              style: theme.textTheme.labelLarge
                  ?.copyWith(color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DateField(
                  label: 'Start date',
                  date: startDate,
                  theme: theme,
                  colorScheme: colorScheme,
                  firstDate: now,
                  onChanged: onStartDateChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DateField(
                  label: 'End date',
                  date: endDate,
                  theme: theme,
                  colorScheme: colorScheme,
                  firstDate: startDate.add(const Duration(days: 1)),
                  onChanged: onEndDateChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Summary',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                _SummaryRow(label: 'Challenge', value: title),
                _SummaryRow(label: 'Duration', value: '$days days'),
                _SummaryRow(
                    label: 'Friends', value: '$participantCount people'),
                _SummaryRow(
                    label: 'Tasks', value: '${tasks.length} (1 per day)'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime date;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final DateTime? firstDate;
  final void Function(DateTime) onChanged;

  const _DateField({
    required this.label,
    required this.date,
    required this.theme,
    required this.colorScheme,
    this.firstDate,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: colorScheme.onSurfaceVariant)),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date,
              firstDate: firstDate ?? DateTime(2020),
              lastDate: DateTime(2035),
            );
            if (picked != null) onChanged(picked);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 16, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ── Footer ──
class _Footer extends StatelessWidget {
  final int currentStep;
  final bool canGoNext;
  final VoidCallback? onBack;
  final VoidCallback? onNext;

  const _Footer({
    required this.currentStep,
    required this.canGoNext,
    this.onBack,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
            top: BorderSide(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withAlpha(150))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Step ${currentStep + 1} of 4',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          Row(
            children: [
              if (onBack != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child:
                      TextButton(onPressed: onBack, child: const Text('Back')),
                ),
              if (onNext != null)
                FilledButton(
                  onPressed: canGoNext ? onNext : null,
                  child: const Text('Next'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
