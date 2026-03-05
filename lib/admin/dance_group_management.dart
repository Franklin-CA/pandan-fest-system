import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pandan_fest/constant/colors.dart';

// ================= DATA MODELS =================

class DanceGroup {
  final String id;
  String name;
  String barangay;
  String coach;
  String theme;
  int memberCount;
  List<String> members;
  String? profileImagePath;
  int performanceOrder;
  List<ScoreHistory> scoreHistory;

  DanceGroup({
    required this.id,
    required this.name,
    required this.barangay,
    required this.coach,
    required this.theme,
    required this.memberCount,
    required this.members,
    this.profileImagePath,
    required this.performanceOrder,
    this.scoreHistory = const [],
  });
}

class ScoreHistory {
  final String phase;
  final double score;
  final String date;
  final int rank;

  const ScoreHistory({
    required this.phase,
    required this.score,
    required this.date,
    required this.rank,
  });
}

// ================= SAMPLE DATA =================

final List<DanceGroup> _sampleGroups = [
  DanceGroup(
    id: '1',
    name: 'Sayaw Pandan',
    barangay: 'Brgy. Pandan',
    coach: 'Maria Santos',
    theme: 'Urban Fusion',
    memberCount: 15,
    members: ['Juan D.', 'Ana R.', 'Carlos M.', 'Lea P.', 'Rico T.'],
    performanceOrder: 1,
    scoreHistory: [
      ScoreHistory(
        phase: 'Preliminaries',
        score: 87.5,
        date: 'Feb 10, 2026',
        rank: 2,
      ),
      ScoreHistory(
        phase: 'Semi-Finals',
        score: 91.0,
        date: 'Feb 20, 2026',
        rank: 1,
      ),
    ],
  ),
  DanceGroup(
    id: '2',
    name: 'Ritmo Barangay',
    barangay: 'Brgy. San Isidro',
    coach: 'Jose Reyes',
    theme: 'Cultural Heritage',
    memberCount: 18,
    members: ['Pedro B.', 'Nina C.', 'Mark L.', 'Clara G.', 'Tony A.'],
    performanceOrder: 2,
    scoreHistory: [
      ScoreHistory(
        phase: 'Preliminaries',
        score: 83.0,
        date: 'Feb 10, 2026',
        rank: 4,
      ),
      ScoreHistory(
        phase: 'Semi-Finals',
        score: 88.5,
        date: 'Feb 20, 2026',
        rank: 3,
      ),
    ],
  ),
  DanceGroup(
    id: '3',
    name: 'Kalye Kings',
    barangay: 'Brgy. Malaya',
    coach: 'Rosa Dela Cruz',
    theme: 'Hip-Hop Street',
    memberCount: 12,
    members: ['Ben V.', 'Grace N.', 'Sonny E.', 'Myra F.', 'Dante O.'],
    performanceOrder: 3,
    scoreHistory: [
      ScoreHistory(
        phase: 'Preliminaries',
        score: 85.0,
        date: 'Feb 10, 2026',
        rank: 3,
      ),
      ScoreHistory(
        phase: 'Semi-Finals',
        score: 89.5,
        date: 'Feb 20, 2026',
        rank: 2,
      ),
    ],
  ),
  DanceGroup(
    id: '4',
    name: 'Alon Dancers',
    barangay: 'Brgy. Bagong Silang',
    coach: 'Edwin Lim',
    theme: 'Contemporary Wave',
    memberCount: 20,
    members: ['Lucy H.', 'Ralph J.', 'Vince K.', 'Pia S.', 'Jun T.'],
    performanceOrder: 4,
    scoreHistory: [
      ScoreHistory(
        phase: 'Preliminaries',
        score: 90.0,
        date: 'Feb 10, 2026',
        rank: 1,
      ),
    ],
  ),
];

// ================= MAIN SCREEN =================

class DanceGroupManagement extends StatefulWidget {
  const DanceGroupManagement({super.key});

  @override
  State<DanceGroupManagement> createState() => _DanceGroupManagementState();
}

class _DanceGroupManagementState extends State<DanceGroupManagement> {
  List<DanceGroup> groups = List.from(_sampleGroups);
  String _searchQuery = '';

  List<DanceGroup> get filteredGroups => groups
      .where(
        (g) =>
            g.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            g.barangay.toLowerCase().contains(_searchQuery.toLowerCase()),
      )
      .toList();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Dance Groups",
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _showGroupDialog(context, null),
              icon: const Icon(Icons.add_rounded),
              label: Text("Add Group", style: GoogleFonts.poppins()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Search Bar
        TextField(
          onChanged: (val) => setState(() => _searchQuery = val),
          style: GoogleFonts.poppins(),
          decoration: InputDecoration(
            hintText: "Search group or barangay...",
            hintStyle: GoogleFonts.poppins(
              color: AppColors.silverRank,
              fontSize: 14,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.silverRank,
            ),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Groups List
        Expanded(child: _buildGroupsList()),
      ],
    );
  }

  // ================= GROUPS LIST =================

  Widget _buildGroupsList() {
    final displayed = filteredGroups;
    if (displayed.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.groups_rounded, size: 64, color: AppColors.divider),
            const SizedBox(height: 16),
            Text(
              "No groups found",
              style: GoogleFonts.poppins(
                color: AppColors.silverRank,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: displayed.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final group = displayed[index];
        return _GroupCard(
          group: group,
          onEdit: () => _showGroupDialog(context, group),
          onDelete: () => _confirmDelete(context, group),
          onViewHistory: () => _showHistoryDialog(context, group),
        );
      },
    );
  }

  // ================= DIALOGS =================

  void _showGroupDialog(BuildContext context, DanceGroup? existing) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _GroupFormDialog(
        existing: existing,
        onSave: (group) {
          setState(() {
            if (existing == null) {
              group.performanceOrder = groups.length + 1;
              groups.add(group);
            } else {
              final idx = groups.indexWhere((g) => g.id == group.id);
              if (idx != -1) groups[idx] = group;
            }
          });
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, DanceGroup group) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Remove Group",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Are you sure you want to remove \"${group.name}\"? This action cannot be undone.",
          style: GoogleFonts.poppins(fontSize: 14, color: AppColors.silverRank),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: GoogleFonts.poppins(color: AppColors.silverRank),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => groups.removeWhere((g) => g.id == group.id));
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              "Remove",
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showHistoryDialog(BuildContext context, DanceGroup group) {
    showDialog(
      context: context,
      builder: (_) => _HistoryDialog(group: group),
    );
  }
}

// ================= GROUP CARD =================

class _GroupCard extends StatelessWidget {
  final DanceGroup group;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onViewHistory;

  const _GroupCard({
    required this.group,
    required this.onEdit,
    required this.onDelete,
    required this.onViewHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            blurRadius: 12,
            color: AppColors.shadow,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: group.profileImagePath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      group.profileImagePath!,
                      fit: BoxFit.cover,
                    ),
                  )
                : Icon(
                    Icons.groups_rounded,
                    color: AppColors.secondary,
                    size: 30,
                  ),
          ),
          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.name,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 16,
                  children: [
                    _infoChip(Icons.location_on_outlined, group.barangay),
                    _infoChip(Icons.person_outline_rounded, group.coach),
                    _infoChip(Icons.palette_outlined, group.theme),
                    _infoChip(
                      Icons.people_outline_rounded,
                      "${group.memberCount} members",
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Actions
          Row(
            children: [
              _ActionButton(
                icon: Icons.history_rounded,
                tooltip: "View History",
                color: AppColors.accentGreen,
                onTap: onViewHistory,
              ),
              const SizedBox(width: 8),
              _ActionButton(
                icon: Icons.edit_rounded,
                tooltip: "Edit Group",
                color: AppColors.secondary,
                onTap: onEdit,
              ),
              const SizedBox(width: 8),
              _ActionButton(
                icon: Icons.delete_outline_rounded,
                tooltip: "Remove Group",
                color: AppColors.danger,
                onTap: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.silverRank),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, color: AppColors.silverRank),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }
}

// ================= GROUP FORM DIALOG =================

class _GroupFormDialog extends StatefulWidget {
  final DanceGroup? existing;
  final Function(DanceGroup) onSave;

  const _GroupFormDialog({this.existing, required this.onSave});

  @override
  State<_GroupFormDialog> createState() => _GroupFormDialogState();
}

class _GroupFormDialogState extends State<_GroupFormDialog> {
  late TextEditingController _nameCtrl;
  late TextEditingController _barangayCtrl;
  late TextEditingController _coachCtrl;
  late TextEditingController _themeCtrl;
  late TextEditingController _memberCountCtrl;
  final TextEditingController _memberInputCtrl = TextEditingController();
  late List<String> _members;

  @override
  void initState() {
    super.initState();
    final g = widget.existing;
    _nameCtrl = TextEditingController(text: g?.name ?? '');
    _barangayCtrl = TextEditingController(text: g?.barangay ?? '');
    _coachCtrl = TextEditingController(text: g?.coach ?? '');
    _themeCtrl = TextEditingController(text: g?.theme ?? '');
    _memberCountCtrl = TextEditingController(
      text: g?.memberCount.toString() ?? '',
    );
    _members = List.from(g?.members ?? []);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _barangayCtrl.dispose();
    _coachCtrl.dispose();
    _themeCtrl.dispose();
    _memberCountCtrl.dispose();
    _memberInputCtrl.dispose();
    super.dispose();
  }

  void _addMember() {
    final name = _memberInputCtrl.text.trim();
    if (name.isNotEmpty) {
      setState(() => _members.add(name));
      _memberInputCtrl.clear();
    }
  }

  void _save() {
    if (_nameCtrl.text.trim().isEmpty || _barangayCtrl.text.trim().isEmpty) {
      return;
    }
    final group = DanceGroup(
      id:
          widget.existing?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text.trim(),
      barangay: _barangayCtrl.text.trim(),
      coach: _coachCtrl.text.trim(),
      theme: _themeCtrl.text.trim(),
      memberCount: int.tryParse(_memberCountCtrl.text) ?? _members.length,
      members: _members,
      performanceOrder: widget.existing?.performanceOrder ?? 0,
      scoreHistory: widget.existing?.scoreHistory ?? [],
    );
    widget.onSave(group);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.groups_rounded,
                      color: AppColors.secondary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    isEdit ? "Edit Dance Group" : "Add Dance Group",
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Upload Profile Row
              Row(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.secondary.withOpacity(0.3),
                      ),
                    ),
                    child: Icon(
                      Icons.add_a_photo_rounded,
                      color: AppColors.secondary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Group Profile Photo",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      OutlinedButton.icon(
                        onPressed: () {}, // Hook up image picker
                        icon: const Icon(Icons.upload_rounded, size: 16),
                        label: Text(
                          "Upload Image",
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.secondary,
                          side: BorderSide(color: AppColors.secondary),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Fields
              _buildField("Group Name *", _nameCtrl, "e.g. Sayaw Pandan"),
              _buildField("Barangay *", _barangayCtrl, "e.g. Brgy. Pandan"),
              _buildField("Coach / Trainer", _coachCtrl, "e.g. Maria Santos"),
              _buildField("Theme / Style", _themeCtrl, "e.g. Urban Fusion"),
              _buildField(
                "Total Members",
                _memberCountCtrl,
                "e.g. 15",
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 8),

              // Members List
              Text(
                "Members",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _memberInputCtrl,
                      style: GoogleFonts.poppins(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: "Add member name",
                        hintStyle: GoogleFonts.poppins(
                          color: AppColors.silverRank,
                          fontSize: 13,
                        ),
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _addMember(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _addMember,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Icon(Icons.add_rounded, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_members.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _members
                      .map(
                        (m) => Chip(
                          label: Text(
                            m,
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                          deleteIcon: const Icon(Icons.close, size: 14),
                          onDeleted: () => setState(() => _members.remove(m)),
                          backgroundColor: AppColors.secondary.withOpacity(0.1),
                          deleteIconColor: AppColors.danger,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: AppColors.secondary.withOpacity(0.2),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),

              const SizedBox(height: 28),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "Cancel",
                      style: GoogleFonts.poppins(color: AppColors.silverRank),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _save,
                    icon: Icon(
                      isEdit ? Icons.save_rounded : Icons.add_rounded,
                      size: 18,
                    ),
                    label: Text(
                      isEdit ? "Save Changes" : "Add Group",
                      style: GoogleFonts.poppins(),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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

  Widget _buildField(
    String label,
    TextEditingController ctrl,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: ctrl,
            keyboardType: keyboardType,
            style: GoogleFonts.poppins(fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(
                color: AppColors.silverRank,
                fontSize: 13,
              ),
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================= HISTORY DIALOG =================

class _HistoryDialog extends StatelessWidget {
  final DanceGroup group;

  const _HistoryDialog({required this.group});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 480,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.history_rounded,
                      color: AppColors.accentGreen,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.name,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Performance History",
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AppColors.silverRank,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.silverRank,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (group.scoreHistory.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: Text(
                      "No history available.",
                      style: GoogleFonts.poppins(color: AppColors.silverRank),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  itemCount: group.scoreHistory.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final h = group.scoreHistory[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: _rankColor(h.rank).withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                "#${h.rank}",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  color: _rankColor(h.rank),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  h.phase,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  h.date,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: AppColors.silverRank,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "${h.score.toStringAsFixed(1)} pts",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: AppColors.secondary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Close",
                    style: GoogleFonts.poppins(color: AppColors.silverRank),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  } 

  Color _rankColor(int rank) {
    switch (rank) {
      case 1:
        return AppColors.goldRank;
      case 2:
        return AppColors.silverRank;
      case 3:
        return AppColors.bronzeRank;
      default:
        return AppColors.secondary;
    }
  }
}
