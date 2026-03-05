import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pandan_fest/constant/colors.dart';

// ══════════════════════════════════════════════════════════════════════════════
// THEME TOKENS
// ══════════════════════════════════════════════════════════════════════════════

const _cOnline = Color(0xFF34C759);
const _cOffline = Color(0xFFFF3B30);
const _cLocked = Color(0xFFFF9500);
const _cBlue = Color(0xFF007AFF);
const _cPurple = Color(0xFFAF52DE);
const _cText1 = Color(0xFF1C1C1E);
const _cText2 = Color(0xFF6C6C70);
const _cText3 = Color(0xFFAEAEB2);
const _cBg = Color(0xFFF2F2F7);
const _cCard = Colors.white;
const _cDivider = Color(0xFFE5E5EA);

// ══════════════════════════════════════════════════════════════════════════════
// MODELS
// ══════════════════════════════════════════════════════════════════════════════

enum DeviceStatus { online, offline }

enum JudgeRole { head, guest, technical, special }

extension JudgeRoleX on JudgeRole {
  String get label {
    switch (this) {
      case JudgeRole.head:
        return 'Head Judge';
      case JudgeRole.guest:
        return 'Guest Judge';
      case JudgeRole.technical:
        return 'Technical Judge';
      case JudgeRole.special:
        return 'Special Judge';
    }
  }

  Color get color {
    switch (this) {
      case JudgeRole.head:
        return _cLocked;
      case JudgeRole.guest:
        return _cOnline;
      case JudgeRole.technical:
        return _cBlue;
      case JudgeRole.special:
        return _cPurple;
    }
  }

  IconData get icon {
    switch (this) {
      case JudgeRole.head:
        return Icons.stars_rounded;
      case JudgeRole.guest:
        return Icons.person_rounded;
      case JudgeRole.technical:
        return Icons.settings_rounded;
      case JudgeRole.special:
        return Icons.workspace_premium_rounded;
    }
  }
}

class Judge {
  final String id;
  String name;
  JudgeRole role;
  bool isLocked;
  DeviceStatus status;
  List<String> assignedCriteria;

  Judge({
    required this.id,
    required this.name,
    required this.role,
    this.isLocked = true,
    this.status = DeviceStatus.offline,
    List<String>? assignedCriteria,
  }) : assignedCriteria = assignedCriteria ?? [];

  String get initials {
    final p = name.trim().split(' ');
    if (p.length >= 2) return '${p[0][0]}${p[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// CRITERIA DATA
// ══════════════════════════════════════════════════════════════════════════════

class _Crit {
  final String name;
  final IconData icon;
  final Color color;
  const _Crit(this.name, this.icon, this.color);
}

const _kCriteria = [
  _Crit('Choreography', Icons.directions_walk_rounded, _cLocked),
  _Crit('Costume', Icons.checkroom_rounded, _cPurple),
  _Crit('Musicality', Icons.music_note_rounded, _cBlue),
  _Crit('Showmanship', Icons.theater_comedy_rounded, Color(0xFFFF2D55)),
  _Crit('Synchronization', Icons.sync_rounded, _cOnline),
  _Crit('Concept', Icons.lightbulb_rounded, Color(0xFFFFCC00)),
];

_Crit _getCrit(String name) => _kCriteria.firstWhere(
  (k) => k.name == name,
  orElse: () => const _Crit('?', Icons.star_rounded, _cText3),
);

// ══════════════════════════════════════════════════════════════════════════════
// SCREEN
// ══════════════════════════════════════════════════════════════════════════════

class JudgesManagementScreen extends StatefulWidget {
  const JudgesManagementScreen({super.key});

  @override
  State<JudgesManagementScreen> createState() => _JudgesManagementScreenState();
}

class _JudgesManagementScreenState extends State<JudgesManagementScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final _searchCtrl = TextEditingController();
  String _query = '';

  final List<Judge> _judges = [
    Judge(
      id: 'J001',
      name: 'Maria Santos',
      role: JudgeRole.head,
      isLocked: false,
      status: DeviceStatus.online,
      assignedCriteria: ['Choreography', 'Showmanship', 'Concept'],
    ),
    Judge(
      id: 'J002',
      name: 'Juan dela Cruz',
      role: JudgeRole.guest,
      isLocked: false,
      status: DeviceStatus.online,
      assignedCriteria: ['Musicality', 'Synchronization'],
    ),
    Judge(
      id: 'J003',
      name: 'Ana Reyes',
      role: JudgeRole.technical,
      isLocked: true,
      status: DeviceStatus.offline,
      assignedCriteria: ['Costume', 'Choreography'],
    ),
    Judge(
      id: 'J004',
      name: 'Carlo Bautista',
      role: JudgeRole.guest,
      isLocked: true,
      status: DeviceStatus.offline,
      assignedCriteria: [],
    ),
    Judge(
      id: 'J005',
      name: 'Liza Mendoza',
      role: JudgeRole.special,
      isLocked: false,
      status: DeviceStatus.online,
      assignedCriteria: ['Concept', 'Showmanship'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text));
  }

  @override
  void dispose() {
    _tab.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Judge> get _filtered {
    final q = _query.toLowerCase().trim();
    if (q.isEmpty) return _judges;
    return _judges
        .where(
          (j) =>
              j.name.toLowerCase().contains(q) ||
              j.role.label.toLowerCase().contains(q) ||
              j.id.toLowerCase().contains(q),
        )
        .toList();
  }

  int get _onlineCount =>
      _judges.where((j) => j.status == DeviceStatus.online).length;
  int get _lockedCount => _judges.where((j) => j.isLocked).length;
  int get _unlockedCount => _judges.length - _lockedCount;

  // ── dialogs ──────────────────────────────────────────────────────────────

  Future<void> _addJudge() async {
    final j = await showDialog<Judge>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _AddJudgeDialog(),
    );
    if (j != null) setState(() => _judges.add(j));
  }

  Future<void> _removeJudge(Judge j) async {
    final ok = await _confirm(
      icon: Icons.person_remove_rounded,
      iconColor: _cOffline,
      title: 'Remove Judge',
      body:
          'Remove ${j.name} from the judging panel?\nThis action cannot be undone.',
      confirmLabel: 'Remove',
      confirmColor: _cOffline,
    );
    if (ok) setState(() => _judges.remove(j));
  }

  Future<void> _openCriteria(Judge j) async {
    final res = await showDialog<List<String>>(
      context: context,
      builder: (_) => _CriteriaDialog(
        judgeName: j.name,
        current: List.from(j.assignedCriteria),
      ),
    );
    if (res != null) setState(() => j.assignedCriteria = res);
  }

  void _toggleLock(Judge j) => setState(() => j.isLocked = !j.isLocked);

  Future<void> _lockAll() async {
    final ok = await _confirm(
      icon: Icons.lock_rounded,
      iconColor: _cLocked,
      title: 'Lock All Panels',
      body:
          'All ${_judges.length} judges will be prevented from submitting scores.',
      confirmLabel: 'Lock All',
      confirmColor: _cLocked,
    );
<<<<<<< HEAD
    if (ok) {
      setState(() {
        for (final j in _judges) {
          j.isLocked = true;
        }
      });
    }
=======
    if (ok)
      setState(() {
        for (final j in _judges) j.isLocked = true;
      });
>>>>>>> 70fd73382c82b226a6daba422e1b6dc23a2d4564
  }

  Future<void> _unlockAll() async {
    final ok = await _confirm(
      icon: Icons.lock_open_rounded,
      iconColor: _cOnline,
      title: 'Unlock All Panels',
      body: 'All ${_judges.length} judges will be allowed to submit scores.',
      confirmLabel: 'Unlock All',
      confirmColor: _cOnline,
    );
<<<<<<< HEAD
    if (ok) {
      setState(() {
        for (final j in _judges) {
          j.isLocked = false;
        }
      });
    }
=======
    if (ok)
      setState(() {
        for (final j in _judges) j.isLocked = false;
      });
>>>>>>> 70fd73382c82b226a6daba422e1b6dc23a2d4564
  }

  Future<bool> _confirm({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String body,
    required String confirmLabel,
    required Color confirmColor,
  }) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmDialog(
        icon: icon,
        iconColor: iconColor,
        title: title,
        body: body,
        confirmLabel: confirmLabel,
        confirmColor: confirmColor,
      ),
    );
    return r ?? false;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 20),
        _buildStats(),
        const SizedBox(height: 20),
        _buildTabBar(),
        const SizedBox(height: 16),
        Expanded(
          child: TabBarView(
            controller: _tab,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _JudgesTabView(
                judges: _filtered,
                searchCtrl: _searchCtrl,
                onRemove: _removeJudge,
                onCriteria: _openCriteria,
                onToggleLock: _toggleLock,
              ),
              _CriteriaTabView(judges: _judges, onEditJudge: _openCriteria),
              _DevicesTabView(judges: _judges, onToggleLock: _toggleLock),
            ],
          ),
        ),
      ],
    );
  }

  // ── header ───────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // count badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${_judges.length} JUDGES',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Judges Management',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _cText1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Control panel access, scoring criteria & device status',
              style: GoogleFonts.poppins(fontSize: 12.5, color: _cText2),
            ),
          ],
        ),
        const Spacer(),
        // ghost buttons
        _GhostBtn(
          icon: Icons.lock_rounded,
          label: 'Lock All',
          color: _cLocked,
          onTap: _lockAll,
        ),
        const SizedBox(width: 8),
        _GhostBtn(
          icon: Icons.lock_open_rounded,
          label: 'Unlock All',
          color: _cOnline,
          onTap: _unlockAll,
        ),
        const SizedBox(width: 10),
        // primary button — ElevatedButton, no FilledButton
        ElevatedButton.icon(
          onPressed: _addJudge,
          icon: const Icon(Icons.person_add_rounded, size: 17),
          label: Text(
            'Add Judge',
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            foregroundColor: _cCard,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  // ── stats ─────────────────────────────────────────────────────────────────

  Widget _buildStats() {
    return Row(
      children: [
        _StatCard(
          icon: Icons.gavel_rounded,
          label: 'Total Judges',
          value: '${_judges.length}',
          color: AppColors.secondary,
        ),
        const SizedBox(width: 12),
        _StatCard(
          icon: Icons.wifi_rounded,
          label: 'Online',
          value: '$_onlineCount',
          color: _cOnline,
        ),
        const SizedBox(width: 12),
        _StatCard(
          icon: Icons.wifi_off_rounded,
          label: 'Offline',
          value: '${_judges.length - _onlineCount}',
          color: _cOffline,
        ),
        const SizedBox(width: 12),
        _StatCard(
          icon: Icons.lock_rounded,
          label: 'Panels Locked',
          value: '$_lockedCount',
          color: _cLocked,
        ),
        const SizedBox(width: 12),
        _StatCard(
          icon: Icons.lock_open_rounded,
          label: 'Panels Unlocked',
          value: '$_unlockedCount',
          color: _cBlue,
        ),
      ],
    );
  }

  // ── tab bar ───────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE9E9EF),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: TabBar(
        controller: _tab,
        labelColor: _cCard,
        unselectedLabelColor: _cText2,
        indicator: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(9),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        tabs: const [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_alt_rounded, size: 16),
                SizedBox(width: 7),
                Text('Judges'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.rule_folder_rounded, size: 16),
                SizedBox(width: 7),
                Text('Criteria'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.monitor_rounded, size: 16),
                SizedBox(width: 7),
                Text('Devices & Panels'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SHARED SMALL WIDGETS
// ══════════════════════════════════════════════════════════════════════════════

class _GhostBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _GhostBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 15),
      label: Text(
        label,
        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(0.55)),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _cCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.15)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.07),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: _cText1,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.poppins(fontSize: 10.5, color: _cText2),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 1 — JUDGES
// ══════════════════════════════════════════════════════════════════════════════

class _JudgesTabView extends StatelessWidget {
  final List<Judge> judges;
  final TextEditingController searchCtrl;
  final Future<void> Function(Judge) onRemove;
  final Future<void> Function(Judge) onCriteria;
  final void Function(Judge) onToggleLock;

  const _JudgesTabView({
    required this.judges,
    required this.searchCtrl,
    required this.onRemove,
    required this.onCriteria,
    required this.onToggleLock,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // search bar
        TextField(
          controller: searchCtrl,
          style: GoogleFonts.poppins(fontSize: 13.5, color: _cText1),
          decoration: InputDecoration(
            hintText: 'Search by name, role, or ID…',
            hintStyle: GoogleFonts.poppins(color: _cText3, fontSize: 13),
            prefixIcon: Icon(Icons.search_rounded, color: _cText3, size: 20),
            suffixIcon: searchCtrl.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.close_rounded, size: 17, color: _cText3),
                    splashRadius: 16,
                    onPressed: searchCtrl.clear,
                  )
                : null,
            filled: true,
            fillColor: _cCard,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _cDivider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _cDivider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.secondary, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 4),
        // results hint
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: searchCtrl.text.trim().isNotEmpty
              ? Padding(
                  key: const ValueKey('hint'),
                  padding: const EdgeInsets.only(top: 6, bottom: 2, left: 2),
                  child: Text(
                    '${judges.length} result${judges.length != 1 ? 's' : ''} for "${searchCtrl.text.trim()}"',
                    style: GoogleFonts.poppins(fontSize: 11.5, color: _cText2),
                  ),
                )
              : const SizedBox(key: ValueKey('empty'), height: 10),
        ),
        // list
        Expanded(
          child: judges.isEmpty
              ? _EmptyState(query: searchCtrl.text.trim())
              : ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: judges.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _JudgeCard(
                    judge: judges[i],
                    onRemove: () => onRemove(judges[i]),
                    onCriteria: () => onCriteria(judges[i]),
                    onToggleLock: () => onToggleLock(judges[i]),
                  ),
                ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String query;
  const _EmptyState({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F7),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.manage_search_rounded, size: 34, color: _cText3),
          ),
          const SizedBox(height: 14),
          Text(
            query.isEmpty ? 'No judges added yet' : 'No results for "$query"',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _cText2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            query.isEmpty
                ? 'Press "Add Judge" to get started'
                : 'Try a different name, role, or ID',
            style: GoogleFonts.poppins(fontSize: 12.5, color: _cText3),
          ),
        ],
      ),
    );
  }
}

// ── Judge card ────────────────────────────────────────────────────────────────

class _JudgeCard extends StatelessWidget {
  final Judge judge;
  final VoidCallback onRemove, onCriteria, onToggleLock;

  const _JudgeCard({
    required this.judge,
    required this.onRemove,
    required this.onCriteria,
    required this.onToggleLock,
  });

  @override
  Widget build(BuildContext context) {
    final isOnline = judge.status == DeviceStatus.online;
    final isLocked = judge.isLocked;

    return Container(
      decoration: BoxDecoration(
        color: _cCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cDivider),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── main row ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 15, 12, 13),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // avatar
                _Avatar(
                  initials: judge.initials,
                  roleColor: judge.role.color,
                  isOnline: isOnline,
                ),
                const SizedBox(width: 14),
                // name + meta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              judge.name,
                              style: GoogleFonts.poppins(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: _cText1,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 7),
                          _RolePill(role: judge.role),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            judge.id,
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              color: _cText3,
                            ),
                          ),
                          _dot(),
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: isOnline
                                  ? _cOnline
                                  : const Color(0xFFD1D1D6),
                              shape: BoxShape.circle,
                              boxShadow: isOnline
                                  ? [
                                      const BoxShadow(
                                        color: Color(0x5034C759),
                                        blurRadius: 4,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isOnline ? 'Online' : 'Offline',
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: isOnline
                                  ? const Color(0xFF27AE60)
                                  : _cText3,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // right controls
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _LockBadge(isLocked: isLocked),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ActionBtn(
                          icon: Icons.rule_rounded,
                          label: 'Assign Criteria',
                          color: _cBlue,
                          onTap: onCriteria,
                        ),
                        const SizedBox(width: 5),
                        _ActionBtn(
                          icon: isLocked
                              ? Icons.lock_open_rounded
                              : Icons.lock_rounded,
                          label: isLocked ? 'Unlock Panel' : 'Lock Panel',
                          color: isLocked ? _cOnline : _cLocked,
                          onTap: onToggleLock,
                        ),
                        const SizedBox(width: 5),
                        _ActionBtn(
                          icon: Icons.person_remove_rounded,
                          label: 'Remove Judge',
                          color: _cOffline,
                          onTap: onRemove,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          // ── criteria footer ──────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _cBg,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
              border: const Border(top: BorderSide(color: _cDivider)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.label_outline_rounded, size: 13, color: _cText3),
                const SizedBox(width: 6),
                Text(
                  'Criteria:',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: _cText2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: judge.assignedCriteria.isEmpty
                      ? GestureDetector(
                          onTap: onCriteria,
                          child: Row(
                            children: [
                              Icon(
                                Icons.add_circle_outline_rounded,
                                size: 14,
                                color: AppColors.secondary.withOpacity(0.7),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Tap to assign criteria',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.secondary.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Wrap(
                          spacing: 5,
                          runSpacing: 4,
                          children: judge.assignedCriteria.map((c) {
                            final cr = _getCrit(c);
                            return _CritChip(
                              label: c,
                              icon: cr.icon,
                              color: cr.color,
                            );
                          }).toList(),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6),
    child: Container(
      width: 3,
      height: 3,
      decoration: const BoxDecoration(color: _cDivider, shape: BoxShape.circle),
    ),
  );
}

// ── judge card sub-widgets ────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String initials;
  final Color roleColor;
  final bool isOnline;

  const _Avatar({
    required this.initials,
    required this.roleColor,
    required this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: roleColor.withOpacity(0.13),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              initials,
              style: GoogleFonts.poppins(
                color: roleColor,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            width: 13,
            height: 13,
            decoration: BoxDecoration(
              color: isOnline ? _cOnline : const Color(0xFFD1D1D6),
              shape: BoxShape.circle,
              border: Border.all(color: _cCard, width: 2),
              boxShadow: isOnline
                  ? [const BoxShadow(color: Color(0x5034C759), blurRadius: 5)]
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _RolePill extends StatelessWidget {
  final JudgeRole role;
  const _RolePill({required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: role.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(role.icon, size: 10, color: role.color),
          const SizedBox(width: 4),
          Text(
            role.label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: role.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _LockBadge extends StatelessWidget {
  final bool isLocked;
  const _LockBadge({required this.isLocked});

  @override
  Widget build(BuildContext context) {
    final color = isLocked ? _cLocked : _cOnline;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            isLocked ? 'Locked' : 'Unlocked',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      preferBelow: false,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}

class _CritChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _CritChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10.5,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 2 — CRITERIA
// ══════════════════════════════════════════════════════════════════════════════

class _CriteriaTabView extends StatelessWidget {
  final List<Judge> judges;
  final Future<void> Function(Judge) onEditJudge;

  const _CriteriaTabView({required this.judges, required this.onEditJudge});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // banner
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.secondary.withOpacity(0.09),
                AppColors.secondary.withOpacity(0.01),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.secondary.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.rule_folder_rounded,
                  color: AppColors.secondary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Criteria Assignment Overview',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _cText1,
                    ),
                  ),
                  Text(
                    '${_kCriteria.length} scoring categories  ·  ${judges.length} judges',
                    style: GoogleFonts.poppins(fontSize: 12, color: _cText2),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ..._kCriteria.map((c) {
          final assigned = judges
              .where((j) => j.assignedCriteria.contains(c.name))
              .toList();
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _CriteriaCard(
              crit: c,
              assigned: assigned,
              total: judges.length,
              onEditJudge: onEditJudge,
            ),
          );
        }),
      ],
    );
  }
}

class _CriteriaCard extends StatelessWidget {
  final _Crit crit;
  final List<Judge> assigned;
  final int total;
  final Future<void> Function(Judge) onEditJudge;

  const _CriteriaCard({
    required this.crit,
    required this.assigned,
    required this.total,
    required this.onEditJudge,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : assigned.length / total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cDivider),
        boxShadow: const [
          BoxShadow(
            color: Color(0x07000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: crit.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(crit.icon, color: crit.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      crit.name,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _cText1,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${assigned.length} / $total',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: _cText2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 5,
                    backgroundColor: const Color(0xFFF2F2F7),
                    valueColor: AlwaysStoppedAnimation<Color>(crit.color),
                  ),
                ),
                const SizedBox(height: 10),
                assigned.isEmpty
                    ? Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 13,
                            color: _cText3,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'No judges assigned yet',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: _cText3,
                            ),
                          ),
                        ],
                      )
                    : Wrap(
                        spacing: 5,
                        runSpacing: 5,
                        children: assigned
                            .map(
                              (j) => GestureDetector(
                                onTap: () => onEditJudge(j),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: j.role.color.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: j.role.color.withOpacity(0.22),
                                    ),
                                  ),
                                  child: Text(
                                    j.name.split(' ').first,
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: j.role.color,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 3 — DEVICES & PANELS
// ══════════════════════════════════════════════════════════════════════════════

class _DevicesTabView extends StatelessWidget {
  final List<Judge> judges;
  final void Function(Judge) onToggleLock;

  const _DevicesTabView({required this.judges, required this.onToggleLock});

  @override
  Widget build(BuildContext context) {
    final online = judges
        .where((j) => j.status == DeviceStatus.online)
        .toList();
    final offline = judges
        .where((j) => j.status == DeviceStatus.offline)
        .toList();

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _DeviceSection(
          title: 'Online Devices',
          icon: Icons.wifi_rounded,
          color: _cOnline,
          judges: online,
          emptyMsg: 'No devices are currently online',
        ),
        const SizedBox(height: 20),
        _DeviceSection(
          title: 'Offline Devices',
          icon: Icons.wifi_off_rounded,
          color: _cOffline,
          judges: offline,
          emptyMsg: 'All devices are connected ✓',
        ),
        const SizedBox(height: 20),
        _PanelSection(judges: judges, onToggle: onToggleLock),
      ],
    );
  }
}

class _DeviceSection extends StatelessWidget {
  final String title, emptyMsg;
  final IconData icon;
  final Color color;
  final List<Judge> judges;

  const _DeviceSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.judges,
    required this.emptyMsg,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 7),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _cText1,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${judges.length}',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        judges.isEmpty
            ? Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: _cBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _cDivider),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      color: _cText3,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      emptyMsg,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        color: _cText3,
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                children: judges
                    .map(
                      (j) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _DeviceTile(judge: j),
                      ),
                    )
                    .toList(),
              ),
      ],
    );
  }
}

class _DeviceTile extends StatelessWidget {
  final Judge judge;
  const _DeviceTile({required this.judge});

  @override
  Widget build(BuildContext context) {
    final isOnline = judge.status == DeviceStatus.online;
    final color = isOnline ? _cOnline : _cOffline;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: _cCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.laptop_rounded, color: color, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  judge.name,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _cText1,
                  ),
                ),
                Text(
                  'PANDAN-${judge.id}',
                  style: GoogleFonts.poppins(fontSize: 11, color: _cText2),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  isOnline ? 'Online' : 'Offline',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelSection extends StatelessWidget {
  final List<Judge> judges;
  final void Function(Judge) onToggle;

  const _PanelSection({required this.judges, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.lock_rounded, color: _cLocked, size: 16),
            const SizedBox(width: 7),
            Text(
              'Scoring Panel Controls',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _cText1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          'Enable or prevent each judge from submitting scores',
          style: GoogleFonts.poppins(fontSize: 12, color: _cText2),
        ),
        const SizedBox(height: 12),
        ...judges.map(
          (j) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _PanelTile(judge: j, onToggle: () => onToggle(j)),
          ),
        ),
      ],
    );
  }
}

class _PanelTile extends StatelessWidget {
  final Judge judge;
  final VoidCallback onToggle;

  const _PanelTile({required this.judge, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final isLocked = judge.isLocked;
    final toggleColor = isLocked ? _cLocked : _cOnline;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: _cCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cDivider),
        boxShadow: const [
          BoxShadow(
            color: Color(0x07000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: judge.role.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Center(
              child: Text(
                judge.initials,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: judge.role.color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      judge.name,
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: _cText1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _RolePill(role: judge.role),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  isLocked
                      ? 'Panel locked — judge cannot submit scores'
                      : 'Panel open — judge can submit scores',
                  style: GoogleFonts.poppins(fontSize: 11, color: _cText2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // animated toggle
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              width: 52,
              height: 28,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: toggleColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: toggleColor.withOpacity(0.4)),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                alignment: isLocked
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: toggleColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: toggleColor.withOpacity(0.4),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                    size: 11,
                    color: _cCard,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// DIALOG: ADD JUDGE
// ══════════════════════════════════════════════════════════════════════════════

class _AddJudgeDialog extends StatefulWidget {
  const _AddJudgeDialog();

  @override
  State<_AddJudgeDialog> createState() => _AddJudgeDialogState();
}

class _AddJudgeDialogState extends State<_AddJudgeDialog> {
  final _nameCtrl = TextEditingController();
  JudgeRole _role = JudgeRole.guest;
  bool _showError = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _showError = true);
      return;
    }
    Navigator.pop(
      context,
      Judge(
        id: 'J${(DateTime.now().millisecondsSinceEpoch % 9000) + 100}',
        name: name,
        role: _role,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _cCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 440,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // header
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      Icons.person_add_rounded,
                      color: AppColors.secondary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add New Judge',
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: _cText1,
                        ),
                      ),
                      Text(
                        'Enter the judge\'s information below',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: _cText2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Divider(color: _cDivider),
              const SizedBox(height: 18),

              // full name
              _FLabel('Full Name'),
              const SizedBox(height: 7),
              TextField(
                controller: _nameCtrl,
                style: GoogleFonts.poppins(fontSize: 13.5, color: _cText1),
                onChanged: (_) {
                  if (_showError) setState(() => _showError = false);
                },
                decoration: _inputDeco(
                  hint: 'e.g. Maria Santos',
                  icon: Icons.person_outline_rounded,
                  error: _showError ? 'Full name is required' : null,
                ),
              ),
              const SizedBox(height: 20),

              // role chips
              _FLabel('Judge Role'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: JudgeRole.values.map((r) {
                  final sel = _role == r;
                  return GestureDetector(
                    onTap: () => setState(() => _role = r),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: sel ? r.color.withOpacity(0.1) : _cBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: sel ? r.color : _cDivider,
                          width: sel ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            r.icon,
                            size: 14,
                            color: sel ? r.color : _cText3,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            r.label,
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              fontWeight: sel
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: sel ? r.color : _cText2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),

              // action row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _cText2,
                        side: const BorderSide(color: _cDivider),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: _cCard,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Add Judge',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// DIALOG: ASSIGN CRITERIA
// ══════════════════════════════════════════════════════════════════════════════

class _CriteriaDialog extends StatefulWidget {
  final String judgeName;
  final List<String> current;

  const _CriteriaDialog({required this.judgeName, required this.current});

  @override
  State<_CriteriaDialog> createState() => _CriteriaDialogState();
}

class _CriteriaDialogState extends State<_CriteriaDialog> {
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.current);
  }

  void _toggle(String c) => setState(() {
    _selected.contains(c) ? _selected.remove(c) : _selected.add(c);
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _cCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 460,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // header
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: _cBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.rule_folder_rounded,
                      color: _cBlue,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Assign Criteria',
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: _cText1,
                          ),
                        ),
                        Text(
                          widget.judgeName,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: _cText2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // live counter
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _cBlue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _cBlue.withOpacity(0.2)),
                    ),
                    child: Text(
                      '${_selected.length} selected',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: _cBlue,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Divider(color: _cDivider),
              const SizedBox(height: 6),
              Text(
                'Tap a criterion to assign or remove it',
                style: GoogleFonts.poppins(fontSize: 12, color: _cText2),
              ),
              const SizedBox(height: 14),

              // criteria rows
              ..._kCriteria.map((c) {
                final isActive = _selected.contains(c.name);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () => _toggle(c.name),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: isActive ? c.color.withOpacity(0.06) : _cBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isActive ? c.color : _cDivider,
                          width: isActive ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: c.color.withOpacity(
                                isActive ? 0.15 : 0.07,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(c.icon, color: c.color, size: 17),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              c.name,
                              style: GoogleFonts.poppins(
                                fontSize: 13.5,
                                fontWeight: isActive
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isActive ? c.color : _cText1,
                              ),
                            ),
                          ),
                          // animated checkbox
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: isActive ? c.color : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isActive ? c.color : _cDivider,
                              ),
                            ),
                            child: isActive
                                ? const Icon(
                                    Icons.check_rounded,
                                    size: 14,
                                    color: _cCard,
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 20),

              // action row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _cText2,
                        side: const BorderSide(color: _cDivider),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, _selected),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _cBlue,
                        foregroundColor: _cCard,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Save Changes',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// DIALOG: CONFIRM
// ══════════════════════════════════════════════════════════════════════════════

class _ConfirmDialog extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, body, confirmLabel;
  final Color confirmColor;

  const _ConfirmDialog({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.confirmLabel,
    required this.confirmColor,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _cCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 370,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: _cText1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                body,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  color: _cText2,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 26),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _cText2,
                        side: const BorderSide(color: _cDivider),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: confirmColor,
                        foregroundColor: _cCard,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        confirmLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// HELPERS
// ══════════════════════════════════════════════════════════════════════════════

class _FLabel extends StatelessWidget {
  final String text;
  const _FLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: _cText1,
      ),
    );
  }
}

InputDecoration _inputDeco({
  required String hint,
  required IconData icon,
  String? error,
}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.poppins(color: _cText3, fontSize: 13),
    prefixIcon: Icon(icon, color: _cText3, size: 19),
    errorText: error,
    filled: true,
    fillColor: _cBg,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _cDivider),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _cDivider),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _cBlue, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _cOffline),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _cOffline, width: 1.5),
    ),
  );
}
