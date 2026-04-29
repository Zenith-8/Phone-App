import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/workout.dart';
import '../services/nfc_login_server_client.dart';
import '../services/pairing_payload.dart';
import '../services/rep_live_service.dart';
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
  late final RepLiveService _liveReps;

  @override
  void initState() {
    super.initState();
    _liveReps = RepLiveService();
    final uid = widget.pairedUid;
    if (uid != null && uid.isNotEmpty) {
      unawaited(_liveReps.start(uid));
    }
    _fetchWorkouts();
  }

  @override
  void didUpdateWidget(covariant DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final uid = widget.pairedUid;
    if (uid != oldWidget.pairedUid) {
      if (uid != null && uid.isNotEmpty) {
        unawaited(_liveReps.start(uid));
      } else {
        unawaited(_liveReps.stop());
      }
    }
  }

  @override
  void dispose() {
    _liveReps.dispose();
    super.dispose();
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
                  liveReps: _liveReps,
                )
              : _WorkoutsPanel(
                  key: const ValueKey('workouts'),
                  workouts: _workouts,
                  loading: _loading,
                  error: _error,
                  refreshing: _refreshing,
                  onRefresh: _refresh,
                  onOpenWorkout: _openWorkout,
                  liveReps: _liveReps,
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
    required this.liveReps,
  });

  final String displayName;
  final String userEmail;
  final WorkoutStats stats;
  final ColorScheme colorScheme;
  final PairingPayload? pairingPayload;
  final bool pairedOffline;
  final VoidCallback onSimulateFirstSignIn;
  final RepLiveService liveReps;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 102),
      children: [
        _LiveRepsCard(liveReps: liveReps, colorScheme: colorScheme),
        const SizedBox(height: 14),
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
                      ? 'No pairing on file yet.'
                      : 'Pairing code ${pairingPayload!.pretty()}',
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
    required this.liveReps,
  });

  final List<Workout> workouts;
  final bool loading;
  final String? error;
  final bool refreshing;
  final Future<void> Function() onRefresh;
  final void Function(Workout workout) onOpenWorkout;
  final RepLiveService liveReps;

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
        _ActiveWorkoutBanner(liveReps: widget.liveReps, colorScheme: scheme),
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

/// Live rep counter sourced from the persistent connection to the
/// nfc-login-server. Updates in real-time as the Pi detects each rep, and
/// implicitly drives the rep_ack the timing measurement depends on.
class _LiveRepsCard extends StatelessWidget {
  const _LiveRepsCard({required this.liveReps, required this.colorScheme});

  final RepLiveService liveReps;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: liveReps,
      builder: (context, _) {
        final connected = liveReps.isConnected;
        final repCount = liveReps.repCount;
        final last = liveReps.lastEvent;
        final hasReps = last != null && repCount > 0;

        return FrostedPanel(
          borderRadius: BorderRadius.circular(24),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: hasReps
                      ? colorScheme.primary.withValues(alpha: 0.15)
                      : colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasReps
                      ? Icons.fitness_center
                      : connected
                          ? Icons.sensors
                          : Icons.sensors_off,
                  color: hasReps
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Live reps',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 8),
                        _ConnectionDot(connected: connected),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasReps
                          ? '${last.machine.isEmpty ? 'machine' : last.machine} - rep #${last.repId}'
                          : connected
                              ? 'Waiting for next rep...'
                              : 'Reconnecting to server...',
                      style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: Text(
                  '$repCount',
                  key: ValueKey<int>(repCount),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: hasReps
                            ? colorScheme.primary
                            : colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ConnectionDot extends StatelessWidget {
  const _ConnectionDot({required this.connected});

  final bool connected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: connected ? Colors.greenAccent.shade400 : Colors.redAccent,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color:
                (connected ? Colors.greenAccent : Colors.redAccent).withValues(
              alpha: 0.5,
            ),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }
}

/// Top-of-tab banner shown on the Workouts screen while a session is in
/// progress. Features a static preview image of the machine, the live rep
/// counter (sourced from [RepLiveService]), and the active machine name.
/// Animates in/out as reps start/stop flowing so the rest of the screen
/// (workout history) remains usable when nothing is active.
class _ActiveWorkoutBanner extends StatelessWidget {
  const _ActiveWorkoutBanner({
    required this.liveReps,
    required this.colorScheme,
  });

  final RepLiveService liveReps;
  final ColorScheme colorScheme;

  // A workout is "active" if we've seen a rep recently. We keep the banner
  // visible for a short window after the last rep so it doesn't pop in/out
  // between sets - the Pi-side auto-logout fires at 5 minutes anyway.
  static const Duration _activeWindow = Duration(minutes: 5);

  bool _isActive(DateTime now) {
    final last = liveReps.lastEvent;
    if (last == null || liveReps.repCount <= 0) return false;
    return now.difference(last.receivedAt) < _activeWindow;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: liveReps,
      builder: (context, _) {
        final now = DateTime.now();
        final active = _isActive(now);
        return AnimatedSize(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: !active
                ? const SizedBox(
                    key: ValueKey('inactive'),
                    width: double.infinity,
                  )
                : Padding(
                    key: const ValueKey('active'),
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                    child: _ActiveWorkoutCard(
                      liveReps: liveReps,
                      colorScheme: colorScheme,
                    ),
                  ),
          ),
        );
      },
    );
  }
}

class _ActiveWorkoutCard extends StatelessWidget {
  const _ActiveWorkoutCard({
    required this.liveReps,
    required this.colorScheme,
  });

  final RepLiveService liveReps;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final last = liveReps.lastEvent;
    final repCount = liveReps.repCount;
    final machine = (last?.machine.isEmpty ?? true) ? 'Bench' : last!.machine;
    final theme = Theme.of(context);

    return FrostedPanel(
      borderRadius: BorderRadius.circular(24),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Static machine preview (single image; not the per-frame Pi animation).
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 96,
              height: 116,
              color: colorScheme.surfaceContainerHighest,
              alignment: Alignment.center,
              child: Image.asset(
                'assets/machine_preview.png',
                fit: BoxFit.cover,
                width: 96,
                height: 116,
                errorBuilder: (_, _, _) => Icon(
                  Icons.fitness_center,
                  size: 48,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: Colors.greenAccent.shade400,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'LIVE',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  machine,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  'Workout in progress',
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.lastBaseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      transitionBuilder: (child, anim) => ScaleTransition(
                        scale: anim,
                        child: FadeTransition(opacity: anim, child: child),
                      ),
                      child: Text(
                        '$repCount',
                        key: ValueKey<int>(repCount),
                        style: theme.textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: colorScheme.primary,
                          height: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        'reps',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
                        ),
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
}
