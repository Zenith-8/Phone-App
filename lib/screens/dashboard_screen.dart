import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/workout.dart';
import '../services/nfc_login_server_client.dart';
import '../services/pairing_payload.dart';
import '../utils/workout_stats.dart';
import '../widgets/app_background.dart';
import '../widgets/frosted_panel.dart';
import '../widgets/stat_card.dart';
import 'workout_detail_screen.dart';

enum _WorkoutSort { newest, oldest, name }

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.onLogout,
    required this.onResetPairing,
    required this.onResetApp,
    required this.userEmail,
    this.pairedUid,
    required this.pairingPayload,
    required this.pairedOffline,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final VoidCallback onLogout;
  final VoidCallback onResetPairing;
  final VoidCallback onResetApp;
  final String userEmail;
  final String? pairedUid;
  final PairingPayload? pairingPayload;
  final bool pairedOffline;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Workout> _workouts = [];
  int _index = 0;
  bool _refreshing = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchWorkouts();
  }

  String get _displayName {
    final e = widget.userEmail.trim();
    final at = e.indexOf('@');
    if (at <= 0) return 'Athlete';
    return e
        .substring(0, at)
        .replaceAll('.', ' ')
        .split(' ')
        .map((w) {
          if (w.isEmpty) return w;
          return w[0].toUpperCase() + w.substring(1);
        })
        .join(' ');
  }

  Future<void> _fetchWorkouts() async {
    final uid = widget.pairedUid;
    if (uid == null || uid.isEmpty) {
      if (!mounted) return;
      setState(() {
        _workouts = [];
        _loading = false;
        _refreshing = false;
        _error = null;
      });
      return;
    }

    try {
      final workouts = await const NfcLoginServerClient().getWorkouts(uid: uid);
      if (!mounted) return;
      setState(() {
        _workouts = workouts;
        _loading = false;
        _refreshing = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _refreshing = false;
        _error = 'Could not reach server.';
      });
    }
  }

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    await _fetchWorkouts();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Workouts refreshed')));
  }

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will return to the login screen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) widget.onLogout();
  }

  Future<void> _confirmResetPairing() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset pairing?'),
        content: const Text(
          'This simulates first sign-in and shows pairing again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) widget.onResetPairing();
  }

  Future<void> _confirmResetApp() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset app?'),
        content: const Text(
          'Clears onboarding, pairing, sign-in and preferences.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset app'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) widget.onResetApp();
  }

  void _openWorkout(Workout workout) {
    final platform = Theme.of(context).platform;
    final useCupertino =
        platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
    final route = useCupertino
        ? CupertinoPageRoute<void>(
            builder: (context) => WorkoutDetailScreen(workout: workout),
          )
        : MaterialPageRoute<void>(
            builder: (context) => WorkoutDetailScreen(workout: workout),
          );
    Navigator.of(context).push(route);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final stats = WorkoutStats.fromWorkouts(_workouts);

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          PopupMenuButton<ThemeMode>(
            tooltip: 'Theme',
            icon: Icon(_themeIcon(widget.themeMode)),
            onSelected: widget.onThemeModeChanged,
            itemBuilder: (context) => const [
              PopupMenuItem(value: ThemeMode.system, child: Text('System')),
              PopupMenuItem(value: ThemeMode.light, child: Text('Light')),
              PopupMenuItem(value: ThemeMode.dark, child: Text('Dark')),
            ],
          ),
          PopupMenuButton<String>(
            tooltip: 'More',
            onSelected: (value) {
              switch (value) {
                case 'pair':
                  _confirmResetPairing();
                case 'reset':
                  _confirmResetApp();
                case 'out':
                  _confirmLogout();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'pair',
                child: Text('Simulate first sign-in'),
              ),
              PopupMenuItem(value: 'reset', child: Text('Reset app')),
              PopupMenuItem(value: 'out', child: Text('Sign out')),
            ],
          ),
        ],
      ),
      body: AppBackground(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: _index == 0
              ? _HomePanel(
                  key: const ValueKey('home'),
                  displayName: _displayName,
                  userEmail: widget.userEmail,
                  stats: stats,
                  colorScheme: scheme,
                  pairingPayload: widget.pairingPayload,
                  pairedOffline: widget.pairedOffline,
                  onSimulateFirstSignIn: _confirmResetPairing,
                )
              : _WorkoutsPanel(
                  key: const ValueKey('workouts'),
                  workouts: _workouts,
                  loading: _loading,
                  error: _error,
                  refreshing: _refreshing,
                  onRefresh: _refresh,
                  onOpenWorkout: _openWorkout,
                ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.fitness_center_outlined),
                selectedIcon: Icon(Icons.fitness_center),
                label: 'Workouts',
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _themeIcon(ThemeMode mode) => switch (mode) {
    ThemeMode.system => Icons.brightness_auto_outlined,
    ThemeMode.light => Icons.light_mode_outlined,
    ThemeMode.dark => Icons.dark_mode_outlined,
  };
}

class _HomePanel extends StatelessWidget {
  const _HomePanel({
    super.key,
    required this.displayName,
    required this.userEmail,
    required this.stats,
    required this.colorScheme,
    required this.pairingPayload,
    required this.pairedOffline,
    required this.onSimulateFirstSignIn,
  });

  final String displayName;
  final String userEmail;
  final WorkoutStats stats;
  final ColorScheme colorScheme;
  final PairingPayload? pairingPayload;
  final bool pairedOffline;
  final VoidCallback onSimulateFirstSignIn;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 102),
      children: [
        FrostedPanel(
          borderRadius: BorderRadius.circular(24),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: colorScheme.primaryContainer,
                child: Text(
                  displayName.isNotEmpty
                      ? displayName.characters.first.toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hi, $displayName',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      userEmail,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Overview',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 520;
            final a = StatCard(
              icon: Icons.calendar_today_outlined,
              label: 'Sessions (7d)',
              value: '${stats.sessionsLast7Days}',
              subtitle: '${stats.totalSessions} total sessions',
            );
            final b = StatCard(
              icon: Icons.trending_up,
              label: 'Volume (7d)',
              value: '${(stats.volumeLast7DaysKg / 1000).toStringAsFixed(2)} t',
              subtitle:
                  '${stats.volumeLast7DaysKg.toStringAsFixed(0)} kg total',
            );
            if (wide) {
              return Row(
                children: [
                  Expanded(child: a),
                  const SizedBox(width: 10),
                  Expanded(child: b),
                ],
              );
            }
            return Column(children: [a, const SizedBox(height: 10), b]);
          },
        ),
        const SizedBox(height: 16),
        Text(
          'Pairing',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        FrostedPanel(
          borderRadius: BorderRadius.circular(24),
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.nfc, color: colorScheme.primary),
                title: const Text('Bench link'),
                subtitle: Text(
                  pairingPayload == null
                      ? 'No payload saved yet.'
                      : 'NFC ${pairingPayload!.maskedNfcId()} - token ${pairingPayload!.maskedToken()}',
                ),
                trailing: pairedOffline
                    ? const Chip(label: Text('Demo'))
                    : const Chip(label: Text('Paired')),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.restart_alt),
                title: const Text('Simulate first sign-in'),
                subtitle: const Text('Go back through pairing flow.'),
                onTap: onSimulateFirstSignIn,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WorkoutsPanel extends StatefulWidget {
  const _WorkoutsPanel({
    super.key,
    required this.workouts,
    required this.loading,
    this.error,
    required this.refreshing,
    required this.onRefresh,
    required this.onOpenWorkout,
  });

  final List<Workout> workouts;
  final bool loading;
  final String? error;
  final bool refreshing;
  final Future<void> Function() onRefresh;
  final void Function(Workout workout) onOpenWorkout;

  @override
  State<_WorkoutsPanel> createState() => _WorkoutsPanelState();
}

class _WorkoutsPanelState extends State<_WorkoutsPanel> {
  final _searchController = TextEditingController();
  _WorkoutSort _sort = _WorkoutSort.newest;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Workout> _visibleWorkouts() {
    final q = _query.trim().toLowerCase();
    final list = widget.workouts.where((w) {
      if (q.isEmpty) return true;
      return w.title.toLowerCase().contains(q) ||
          w.notes.toLowerCase().contains(q);
    }).toList();

    switch (_sort) {
      case _WorkoutSort.newest:
        list.sort((a, b) => b.completedAt.compareTo(a.completedAt));
      case _WorkoutSort.oldest:
        list.sort((a, b) => a.completedAt.compareTo(b.completedAt));
      case _WorkoutSort.name:
        list.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dateFmt = DateFormat.yMMMd().add_jm();
    final visible = _visibleWorkouts();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
          child: SearchBar(
            controller: _searchController,
            hintText: 'Search workouts',
            leading: const Icon(Icons.search),
            trailing: _query.isEmpty
                ? null
                : [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    ),
                  ],
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
          child: SegmentedButton<_WorkoutSort>(
            segments: const [
              ButtonSegment(value: _WorkoutSort.newest, label: Text('Newest')),
              ButtonSegment(value: _WorkoutSort.oldest, label: Text('Oldest')),
              ButtonSegment(value: _WorkoutSort.name, label: Text('A-Z')),
            ],
            selected: {_sort},
            onSelectionChanged: (s) => setState(() => _sort = s.first),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: widget.onRefresh,
            child: widget.loading
                ? const Center(child: CircularProgressIndicator())
                : widget.error != null && visible.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 120),
                      Center(
                        child: Column(
                          children: [
                            Icon(Icons.cloud_off_rounded, size: 40, color: scheme.outline),
                            const SizedBox(height: 8),
                            Text(widget.error!, style: TextStyle(color: scheme.outline)),
                            const SizedBox(height: 8),
                            TextButton(onPressed: widget.onRefresh, child: const Text('Retry')),
                          ],
                        ),
                      ),
                    ],
                  )
                : visible.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 120),
                      Center(child: Text('No workouts yet. Complete a session on the bench!')),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 102),
                    itemCount: visible.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final workout = visible[index];
                      return FrostedPanel(
                        borderRadius: BorderRadius.circular(20),
                        padding: EdgeInsets.zero,
                        child: ListTile(
                          onTap: () => widget.onOpenWorkout(workout),
                          leading: CircleAvatar(
                            backgroundColor: scheme.primaryContainer,
                            child: Icon(
                              Icons.fitness_center,
                              color: scheme.onPrimaryContainer,
                            ),
                          ),
                          title: Hero(
                            tag: 'workout-title-${workout.id}',
                            child: Material(
                              color: Colors.transparent,
                              child: Text(
                                workout.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          subtitle: Text(
                            '${dateFmt.format(workout.completedAt)} - ${workout.durationMinutes} min - ${(workout.volumeKg / 1000).toStringAsFixed(2)} t',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
