import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8010/api',
);

void main() {
  runApp(const MiniTeamFlowApp());
}

class MiniTeamFlowApp extends StatelessWidget {
  const MiniTeamFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mini TeamFlow',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF635BFF)),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _api = ApiClient();
  bool _loading = true;
  AppUser? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final token = await TokenStore.getToken();
    if (token == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final user = await _api.me(token);
      setState(() {
        _user = user;
        _loading = false;
      });
    } catch (_) {
      await TokenStore.clear();
      setState(() => _loading = false);
    }
  }

  void _onLogin(AppUser user) {
    setState(() => _user = user);
  }

  Future<void> _logout() async {
    final token = await TokenStore.getToken();
    if (token != null) {
      await _api.logout(token);
    }
    await TokenStore.clear();
    setState(() => _user = null);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_user == null) {
      return LoginScreen(onLogin: _onLogin);
    }

    return HomeScreen(user: _user!, onLogout: _logout);
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onLogin});

  final ValueChanged<AppUser> onLogin;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(
    text: 'admin@miniteamflow.local',
  );
  final _passwordController = TextEditingController(text: 'password');
  final _api = ApiClient();
  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final result = await _api.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      await TokenStore.saveToken(result.token);
      widget.onLogin(result.user);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.task_alt_rounded, size: 72),
                    const SizedBox(height: 20),
                    Text(
                      'Mini TeamFlow',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Şirket içi görev ve verimlilik takibi',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'E-posta',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'E-posta zorunlu.';
                        }
                        if (!value.contains('@')) return 'Geçerli e-posta gir.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Şifre',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Şifre zorunlu.'
                          : null,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _loading ? null : _login,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Giriş Yap'),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'API: $apiBaseUrl',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.user, required this.onLogout});

  final AppUser user;
  final Future<void> Function() onLogout;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardTab(user: widget.user),
      TasksTab(user: widget.user),
      CalendarTab(user: widget.user),
      CheckInsTab(user: widget.user),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mini TeamFlow'),
        actions: [
          IconButton(
            tooltip: 'Bildirimler',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
            icon: const Icon(Icons.notifications_outlined),
          ),
          IconButton(
            tooltip: 'Çıkış yap',
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Panel',
          ),
          NavigationDestination(
            icon: Icon(Icons.task_alt_outlined),
            label: 'Görevler',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_outlined),
            label: 'Takvim',
          ),
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            label: 'Check-in',
          ),
        ],
      ),
    );
  }
}

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key, required this.user});

  final AppUser user;

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  final _api = ApiClient();
  DashboardSummary? _summary;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    final token = await TokenStore.getToken();
    if (token == null) return;
    setState(() => _loading = true);
    try {
      final summary = await _api.getDashboardSummary(token);
      setState(() => _summary = summary);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.user.role == 'admin';
    final summary = _summary;

    return RefreshIndicator(
      onRefresh: _loadSummary,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF635BFF), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hoş geldin, ${widget.user.name}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(isAdmin ? 'Admin rapor paneli' : 'Kişisel özet paneli', style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (summary != null) ...[
            Row(
              children: [
                Expanded(child: _MetricCard(title: 'Toplam görev', value: '${summary.totalTasks}', icon: Icons.task_alt_outlined)),
                const SizedBox(width: 12),
                Expanded(child: _MetricCard(title: 'Tamamlanan', value: '${summary.completedTasks}', icon: Icons.check_circle_outline)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _MetricCard(title: 'Acil/Yakın', value: '${summary.dueSoonTasks}', icon: Icons.priority_high_outlined)),
                const SizedBox(width: 12),
                Expanded(child: _MetricCard(title: 'Bugün etkinlik', value: '${summary.todayEvents}', icon: Icons.event_outlined)),
              ],
            ),
            const SizedBox(height: 12),
            _InfoTile(
              icon: Icons.fact_check_outlined,
              title: 'Bugünkü check-in',
              subtitle: isAdmin ? '${summary.todayCheckIns} kişi check-in yaptı.' : (summary.todayCheckIns > 0 ? 'Bugün check-in yaptın.' : 'Bugün check-in yapmadın.'),
            ),
          ],
        ],
      ),
    );
  }
}

class TasksTab extends StatefulWidget {
  const TasksTab({super.key, required this.user});

  final AppUser user;

  @override
  State<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<TasksTab> {
  final _api = ApiClient();
  List<TeamTask> _tasks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final token = await TokenStore.getToken();
    if (token == null) return;
    setState(() => _loading = true);
    try {
      final tasks = await _api.getTasks(token);
      setState(() => _tasks = tasks);
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openCreateTask() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => CreateTaskSheet(currentUser: widget.user),
    );
    if (created == true) _loadTasks();
  }

  Future<void> _updateStatus(TeamTask task, String status) async {
    final token = await TokenStore.getToken();
    if (token == null) return;
    try {
      await _api.updateTaskStatus(token, task.id, status);
      await _loadTasks();
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadTasks,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _tasks.isEmpty
            ? ListView(
                padding: const EdgeInsets.all(24),
                children: const [
                  SizedBox(height: 120),
                  Icon(Icons.task_alt_outlined, size: 64),
                  SizedBox(height: 16),
                  Text('Henüz görev yok.', textAlign: TextAlign.center),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _tasks.length,
                separatorBuilder: (_, childIndex) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final task = _tasks[index];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  task.title,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              _StatusChip(status: task.status),
                            ],
                          ),
                          if (task.description?.isNotEmpty == true) ...[
                            const SizedBox(height: 8),
                            Text(task.description!),
                          ],
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Chip(
                                label: Text('Öncelik: ${task.priorityLabel}'),
                              ),
                              if (task.assigneeName != null)
                                Chip(
                                  label: Text('Atanan: ${task.assigneeName}'),
                                ),
                              if (task.dueDate != null)
                                Chip(label: Text('Termin: ${task.dueDate}')),
                            ],
                          ),
                          const SizedBox(height: 8),
                          DropdownButton<String>(
                            value: task.status,
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(
                                value: 'pending',
                                child: Text('Bekliyor'),
                              ),
                              DropdownMenuItem(
                                value: 'in_progress',
                                child: Text('Devam ediyor'),
                              ),
                              DropdownMenuItem(
                                value: 'completed',
                                child: Text('Tamamlandı'),
                              ),
                              DropdownMenuItem(
                                value: 'cancelled',
                                child: Text('İptal edildi'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) _updateStatus(task, value);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateTask,
        icon: const Icon(Icons.add),
        label: const Text('Görev'),
      ),
    );
  }
}

class CreateTaskSheet extends StatefulWidget {
  const CreateTaskSheet({super.key, required this.currentUser});

  final AppUser currentUser;

  @override
  State<CreateTaskSheet> createState() => _CreateTaskSheetState();
}

class _CreateTaskSheetState extends State<CreateTaskSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _api = ApiClient();
  String _priority = 'medium';
  int? _assignedTo;
  List<AppUser> _users = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _assignedTo = widget.currentUser.id;
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    if (widget.currentUser.role != 'admin') return;
    final token = await TokenStore.getToken();
    if (token == null) return;
    try {
      final users = await _api.getUsers(token);
      setState(() {
        _users = users;
        _assignedTo = users.isNotEmpty ? users.first.id : widget.currentUser.id;
      });
    } catch (_) {}
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    final token = await TokenStore.getToken();
    if (token == null) return;
    setState(() => _loading = true);
    try {
      await _api.createTask(
        token,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        priority: _priority,
        assignedTo: _assignedTo,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Yeni görev', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Başlık'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Başlık zorunlu.'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Açıklama'),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _priority,
              decoration: const InputDecoration(labelText: 'Öncelik'),
              items: const [
                DropdownMenuItem(value: 'low', child: Text('Düşük')),
                DropdownMenuItem(value: 'medium', child: Text('Orta')),
                DropdownMenuItem(value: 'high', child: Text('Yüksek')),
              ],
              onChanged: (value) =>
                  setState(() => _priority = value ?? 'medium'),
            ),
            if (widget.currentUser.role == 'admin') ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _assignedTo,
                decoration: const InputDecoration(labelText: 'Atanacak kişi'),
                items: _users
                    .map(
                      (user) => DropdownMenuItem(
                        value: user.id,
                        child: Text(user.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _assignedTo = value),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loading ? null : _create,
              child: Text(_loading ? 'Oluşturuluyor...' : 'Oluştur'),
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _api = ApiClient();
  List<AppNotificationItem> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final token = await TokenStore.getToken();
    if (token == null) return;
    setState(() => _loading = true);
    try {
      final notifications = await _api.getNotifications(token);
      setState(() => _notifications = notifications);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markAsRead(AppNotificationItem item) async {
    if (item.isRead) return;
    final token = await TokenStore.getToken();
    if (token == null) return;
    await _api.markNotificationAsRead(token, item.id);
    await _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bildirimler')),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _notifications.isEmpty
            ? ListView(
                padding: const EdgeInsets.all(24),
                children: const [
                  SizedBox(height: 120),
                  Icon(Icons.notifications_none_outlined, size: 64),
                  SizedBox(height: 16),
                  Text('Henüz bildirim yok.', textAlign: TextAlign.center),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _notifications.length,
                separatorBuilder: (_, childIndex) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = _notifications[index];
                  return Card(
                    color: item.isRead ? null : Theme.of(context).colorScheme.primaryContainer,
                    child: ListTile(
                      leading: const Icon(Icons.notifications_outlined),
                      title: Text(item.title),
                      subtitle: item.body == null ? null : Text(item.body!),
                      trailing: item.isRead ? null : const Text('Yeni'),
                      onTap: () => _markAsRead(item),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class CalendarTab extends StatefulWidget {
  const CalendarTab({super.key, required this.user});

  final AppUser user;

  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> {
  final _api = ApiClient();
  List<TeamEvent> _events = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final token = await TokenStore.getToken();
    if (token == null) return;
    setState(() => _loading = true);
    try {
      final events = await _api.getEvents(token);
      setState(() => _events = events);
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openCreateEvent() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const CreateEventSheet(),
    );
    if (created == true) _loadEvents();
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadEvents,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _events.isEmpty
            ? ListView(
                padding: const EdgeInsets.all(24),
                children: const [
                  SizedBox(height: 120),
                  Icon(Icons.event_outlined, size: 64),
                  SizedBox(height: 16),
                  Text('Henüz etkinlik yok.', textAlign: TextAlign.center),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _events.length,
                separatorBuilder: (_, childIndex) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final event = _events[index];
                  return Card(
                    child: ListTile(
                      leading: Icon(event.isPrivate ? Icons.lock_outline : Icons.event_outlined),
                      title: Text(event.title),
                      subtitle: Text('${event.startsAtLabel}\n${event.userName ?? ''}'),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateEvent,
        icon: const Icon(Icons.add),
        label: const Text('Etkinlik'),
      ),
    );
  }
}

class CreateEventSheet extends StatefulWidget {
  const CreateEventSheet({super.key});

  @override
  State<CreateEventSheet> createState() => _CreateEventSheetState();
}

class _CreateEventSheetState extends State<CreateEventSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _api = ApiClient();
  DateTime _startsAt = DateTime.now().add(const Duration(hours: 1));
  bool _isPrivate = false;
  bool _loading = false;

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startsAt,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_startsAt));
    if (time == null) return;
    setState(() {
      _startsAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    final token = await TokenStore.getToken();
    if (token == null) return;
    setState(() => _loading = true);
    try {
      await _api.createEvent(
        token,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        startsAt: _startsAt,
        isPrivate: _isPrivate,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Yeni etkinlik', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Başlık'),
              validator: (value) => value == null || value.trim().isEmpty ? 'Başlık zorunlu.' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Açıklama'), maxLines: 2),
            const SizedBox(height: 12),
            OutlinedButton.icon(onPressed: _pickDate, icon: const Icon(Icons.schedule), label: Text(TeamEvent.formatDate(_startsAt))),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Özel etkinlik'),
              value: _isPrivate,
              onChanged: (value) => setState(() => _isPrivate = value),
            ),
            FilledButton(onPressed: _loading ? null : _create, child: Text(_loading ? 'Oluşturuluyor...' : 'Oluştur')),
          ],
        ),
      ),
    );
  }
}

class CheckInsTab extends StatefulWidget {
  const CheckInsTab({super.key, required this.user});

  final AppUser user;

  @override
  State<CheckInsTab> createState() => _CheckInsTabState();
}

class _CheckInsTabState extends State<CheckInsTab> {
  final _api = ApiClient();
  List<DailyCheckIn> _checkIns = [];
  List<AppUser> _missingUsers = [];
  String? _myStatus;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCheckIns();
  }

  Future<void> _loadCheckIns() async {
    final token = await TokenStore.getToken();
    if (token == null) return;
    setState(() => _loading = true);
    try {
      final result = await _api.getCheckIns(token);
      setState(() {
        _checkIns = result.checkIns;
        _missingUsers = result.missingUsers;
        _myStatus = result.checkIns
            .where((item) => item.userId == widget.user.id)
            .firstOrNull
            ?.status;
      });
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _checkIn(String status) async {
    final token = await TokenStore.getToken();
    if (token == null) return;
    try {
      await _api.checkInToday(token, status: status);
      await _loadCheckIns();
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.user.role == 'admin';

    return RefreshIndicator(
      onRefresh: _loadCheckIns,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bugünkü durumun',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(_myStatus == null
                            ? 'Henüz check-in yapmadın.'
                            : 'Durum: ${DailyCheckIn.statusText(_myStatus!)}'),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          children: [
                            FilledButton.tonal(
                              onPressed: () => _checkIn('available'),
                              child: const Text('Ofisteyim'),
                            ),
                            FilledButton.tonal(
                              onPressed: () => _checkIn('remote'),
                              child: const Text('Uzaktan'),
                            ),
                            FilledButton.tonal(
                              onPressed: () => _checkIn('leave'),
                              child: const Text('İzinli'),
                            ),
                            FilledButton.tonal(
                              onPressed: () => _checkIn('sick'),
                              child: const Text('Raporlu'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Check-in yapanlar', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (_checkIns.isEmpty)
                  const Card(child: ListTile(title: Text('Henüz kayıt yok.')))
                else
                  ..._checkIns.map(
                    (item) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.fact_check_outlined),
                        title: Text(item.userName ?? 'Kullanıcı #${item.userId}'),
                        subtitle: Text(DailyCheckIn.statusText(item.status)),
                      ),
                    ),
                  ),
                if (isAdmin) ...[
                  const SizedBox(height: 12),
                  Text('Check-in yapmayanlar', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (_missingUsers.isEmpty)
                    const Card(child: ListTile(title: Text('Eksik kullanıcı yok.')))
                  else
                    ..._missingUsers.map(
                      (user) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.person_off_outlined),
                          title: Text(user.name),
                          subtitle: Text(user.email),
                        ),
                      ),
                    ),
                ],
              ],
            ),
    );
  }
}

class PlaceholderTab extends StatelessWidget {
  const PlaceholderTab({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.construction_rounded, size: 56),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.title, required this.value, required this.icon});

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const SizedBox(height: 12),
            Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
            Text(title),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text(TeamTask.statusText(status)));
  }
}

class ApiClient {
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final json = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(json['message'] ?? 'Giriş başarısız.');
    }

    return AuthResult.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<AppUser> me(String token) async {
    final response = await http.get(
      Uri.parse('$apiBaseUrl/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final json = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(json['message'] ?? 'Oturum doğrulanamadı.');
    }

    return AppUser.fromJson(json['data']['user'] as Map<String, dynamic>);
  }

  Future<List<AppNotificationItem>> getNotifications(String token) async {
    final response = await http.get(
      Uri.parse('$apiBaseUrl/notifications'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final json = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(json['message'] ?? 'Bildirimler alınamadı.');
    }
    return (json['data']['notifications'] as List)
        .map((item) => AppNotificationItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> markNotificationAsRead(String token, int notificationId) async {
    final response = await http.patch(
      Uri.parse('$apiBaseUrl/notifications/$notificationId/read'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final json = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(json['message'] ?? 'Bildirim güncellenemedi.');
    }
  }

  Future<DashboardSummary> getDashboardSummary(String token) async {
    final response = await http.get(
      Uri.parse('$apiBaseUrl/dashboard/summary'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final json = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(json['message'] ?? 'Dashboard özeti alınamadı.');
    }
    return DashboardSummary.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<List<AppUser>> getUsers(String token) async {
    final response = await http.get(
      Uri.parse('$apiBaseUrl/users'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final json = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(json['message'] ?? 'Kullanıcılar alınamadı.');
    }
    return (json['data']['users'] as List)
        .map((item) => AppUser.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<TeamTask>> getTasks(String token) async {
    final response = await http.get(
      Uri.parse('$apiBaseUrl/tasks'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final json = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(json['message'] ?? 'Görevler alınamadı.');
    }
    return (json['data']['tasks'] as List)
        .map((item) => TeamTask.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<TeamEvent>> getEvents(String token) async {
    final response = await http.get(
      Uri.parse('$apiBaseUrl/events'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final json = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(json['message'] ?? 'Etkinlikler alınamadı.');
    }
    return (json['data']['events'] as List)
        .map((item) => TeamEvent.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> createEvent(
    String token, {
    required String title,
    required String description,
    required DateTime startsAt,
    required bool isPrivate,
  }) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl/events'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'title': title,
        'description': description.isEmpty ? null : description,
        'starts_at': startsAt.toIso8601String(),
        'is_private': isPrivate,
      }),
    );
    final json = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(json['message'] ?? 'Etkinlik oluşturulamadı.');
    }
  }

  Future<CheckInResult> getCheckIns(String token) async {
    final response = await http.get(
      Uri.parse('$apiBaseUrl/check-ins'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final json = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(json['message'] ?? 'Check-in kayıtları alınamadı.');
    }
    return CheckInResult.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<void> checkInToday(String token, {required String status}) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl/check-ins/today'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'status': status}),
    );
    final json = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(json['message'] ?? 'Check-in kaydedilemedi.');
    }
  }

  Future<void> createTask(
    String token, {
    required String title,
    required String description,
    required String priority,
    int? assignedTo,
  }) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl/tasks'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'title': title,
        'description': description.isEmpty ? null : description,
        'priority': priority,
        'assigned_to': ?assignedTo,
      }),
    );
    final json = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(json['message'] ?? 'Görev oluşturulamadı.');
    }
  }

  Future<void> updateTaskStatus(String token, int taskId, String status) async {
    final response = await http.patch(
      Uri.parse('$apiBaseUrl/tasks/$taskId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'status': status}),
    );
    final json = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(json['message'] ?? 'Görev güncellenemedi.');
    }
  }

  Future<void> logout(String token) async {
    await http.post(
      Uri.parse('$apiBaseUrl/logout'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  Map<String, dynamic> _decode(http.Response response) {
    try {
      return jsonDecode(utf8.decode(response.bodyBytes))
          as Map<String, dynamic>;
    } catch (_) {
      throw Exception('Sunucudan geçersiz cevap geldi.');
    }
  }
}

class TokenStore {
  static const _key = 'auth_token';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, token);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

class AuthResult {
  const AuthResult({required this.token, required this.user});

  final String token;
  final AppUser user;

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      token: json['token'] as String,
      user: AppUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.position,
  });

  final int id;
  final String name;
  final String email;
  final String role;
  final String? position;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      position: json['position'] as String?,
    );
  }
}

class AppNotificationItem {
  const AppNotificationItem({
    required this.id,
    required this.title,
    this.body,
    this.readAt,
  });

  final int id;
  final String title;
  final String? body;
  final String? readAt;

  bool get isRead => readAt != null;

  factory AppNotificationItem.fromJson(Map<String, dynamic> json) {
    return AppNotificationItem(
      id: json['id'] as int,
      title: json['title'] as String,
      body: json['body'] as String?,
      readAt: json['read_at'] as String?,
    );
  }
}

class DashboardSummary {
  const DashboardSummary({
    required this.totalTasks,
    required this.completedTasks,
    required this.dueSoonTasks,
    required this.todayCheckIns,
    required this.todayEvents,
  });

  final int totalTasks;
  final int completedTasks;
  final int dueSoonTasks;
  final int todayCheckIns;
  final int todayEvents;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    final tasks = json['tasks'] as Map<String, dynamic>;
    final checkIns = json['check_ins'] as Map<String, dynamic>;
    final events = json['events'] as Map<String, dynamic>;
    return DashboardSummary(
      totalTasks: tasks['total'] as int,
      completedTasks: tasks['completed'] as int,
      dueSoonTasks: tasks['due_soon'] as int,
      todayCheckIns: checkIns['today_count'] as int,
      todayEvents: events['today_count'] as int,
    );
  }
}

class TeamEvent {
  const TeamEvent({
    required this.id,
    required this.title,
    required this.startsAt,
    required this.isPrivate,
    this.userName,
  });

  final int id;
  final String title;
  final DateTime startsAt;
  final bool isPrivate;
  final String? userName;

  String get startsAtLabel => formatDate(startsAt);

  static String formatDate(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(date.day)}.${two(date.month)}.${date.year} ${two(date.hour)}:${two(date.minute)}';
  }

  factory TeamEvent.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    return TeamEvent(
      id: json['id'] as int,
      title: json['title'] as String,
      startsAt: DateTime.parse(json['starts_at'] as String),
      isPrivate: json['is_private'] as bool,
      userName: user is Map<String, dynamic> ? user['name'] as String? : null,
    );
  }
}

class CheckInResult {
  const CheckInResult({required this.checkIns, required this.missingUsers});

  final List<DailyCheckIn> checkIns;
  final List<AppUser> missingUsers;

  factory CheckInResult.fromJson(Map<String, dynamic> json) {
    return CheckInResult(
      checkIns: (json['check_ins'] as List)
          .map((item) => DailyCheckIn.fromJson(item as Map<String, dynamic>))
          .toList(),
      missingUsers: (json['missing_users'] as List)
          .map((item) => AppUser.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DailyCheckIn {
  const DailyCheckIn({
    required this.id,
    required this.userId,
    required this.status,
    this.userName,
  });

  final int id;
  final int userId;
  final String status;
  final String? userName;

  static String statusText(String status) {
    return switch (status) {
      'available' => 'Ofiste',
      'remote' => 'Uzaktan',
      'leave' => 'İzinli',
      'sick' => 'Raporlu',
      _ => status,
    };
  }

  factory DailyCheckIn.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    return DailyCheckIn(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      status: json['status'] as String,
      userName: user is Map<String, dynamic> ? user['name'] as String? : null,
    );
  }
}

class TeamTask {
  const TeamTask({
    required this.id,
    required this.title,
    required this.status,
    required this.priority,
    this.description,
    this.dueDate,
    this.assigneeName,
  });

  final int id;
  final String title;
  final String? description;
  final String status;
  final String priority;
  final String? dueDate;
  final String? assigneeName;

  String get priorityLabel {
    return switch (priority) {
      'low' => 'Düşük',
      'high' => 'Yüksek',
      _ => 'Orta',
    };
  }

  static String statusText(String status) {
    return switch (status) {
      'pending' => 'Bekliyor',
      'in_progress' => 'Devam ediyor',
      'completed' => 'Tamamlandı',
      'cancelled' => 'İptal edildi',
      _ => status,
    };
  }

  factory TeamTask.fromJson(Map<String, dynamic> json) {
    final assignee = json['assignee'];
    return TeamTask(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: json['status'] as String,
      priority: json['priority'] as String,
      dueDate: json['due_date'] as String?,
      assigneeName: assignee is Map<String, dynamic>
          ? assignee['name'] as String?
          : null,
    );
  }
}
