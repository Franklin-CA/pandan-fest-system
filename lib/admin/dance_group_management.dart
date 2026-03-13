import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pandan_fest/constant/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// ═══════════════════════════════════════════════════════════════
//  CLOUDINARY CONFIG
// ═══════════════════════════════════════════════════════════════

class _Cloudinary {
  static const String cloudName = 'dd3nlp3pp';
  static const String uploadPreset = 'festival_upload';
  static const String uploadUrl =
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

  static Future<String> uploadBytes(Uint8List bytes, String filename) async {
    final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
    request.fields['upload_preset'] = uploadPreset;
    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: filename),
    );
    final response = await request.send();
    final body = await response.stream.bytesToString();
    if (response.statusCode == 200) {
      final json = jsonDecode(body);
      return json['secure_url'] as String;
    } else {
      throw Exception(
        'Cloudinary upload failed: ${response.statusCode}\n$body',
      );
    }
  }
}

// ═══════════════════════════════════════════════════════════════
//  GENERAL GUIDELINES CONSTANTS
// ═══════════════════════════════════════════════════════════════

const int kMinDancers = 60;
const int kMaxDancers = 80;
const int kMinPropsmen = 30;
const int kMinMusicians = 30;

// ═══════════════════════════════════════════════════════════════
//  MODELS
// ═══════════════════════════════════════════════════════════════

class DanceGroup {
  final String id;
  String name;
  String community;
  String coach;
  String theme;
  int dancerCount;
  int propsmenCount;
  int musicianCount;
  List<String> members;
  String? profileImagePath;
  int performanceOrder;
  List<ScoreHistory> scoreHistory;

  DanceGroup({
    required this.id,
    required this.name,
    required this.community,
    required this.coach,
    required this.theme,
    required this.dancerCount,
    required this.propsmenCount,
    required this.musicianCount,
    required this.members,
    this.profileImagePath,
    required this.performanceOrder,
    this.scoreHistory = const [],
  });

  int get totalMemberCount => dancerCount + propsmenCount + musicianCount;

  bool get isDancerCountValid =>
      dancerCount >= kMinDancers && dancerCount <= kMaxDancers;
  bool get isPropsmenCountValid => propsmenCount >= kMinPropsmen;
  bool get isMusicianCountValid => musicianCount >= kMinMusicians;
  bool get isContingentValid =>
      isDancerCountValid && isPropsmenCountValid && isMusicianCountValid;
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

// ═══════════════════════════════════════════════════════════════
//  SCREEN
// ═══════════════════════════════════════════════════════════════

class DanceGroupManagement extends StatefulWidget {
  const DanceGroupManagement({super.key});

  @override
  State<DanceGroupManagement> createState() => _DanceGroupManagementState();
}

class _DanceGroupManagementState extends State<DanceGroupManagement> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<DanceGroup> groups = [];
  bool _loading = true;
  String _searchQuery = '';

  List<DanceGroup> get _filtered {
    if (_searchQuery.isEmpty) return groups;
    final q = _searchQuery.toLowerCase();
    return groups.where((g) {
      return g.name.toLowerCase().contains(q) ||
          g.community.toLowerCase().contains(q) ||
          g.coach.toLowerCase().contains(q);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _listenGroups();
  }

  void _listenGroups() {
    _db
        .collection('dance_groups')
        .orderBy('performanceOrder')
        .snapshots()
        .listen((snapshot) {
          final loadedGroups = snapshot.docs.map((doc) {
            final data = doc.data();
            final rawHistory = List<Map<String, dynamic>>.from(
              data['scoreHistory'] ?? [],
            );
            final scoreHistory = rawHistory.map((h) {
              return ScoreHistory(
                phase: h['phase'] ?? '',
                score: (h['score'] as num?)?.toDouble() ?? 0.0,
                date: h['date'] ?? '',
                rank: h['rank'] ?? 0,
              );
            }).toList();

            return DanceGroup(
              id: doc.id,
              name: data['name'] ?? '',
              community: data['community'] ?? '',
              coach: data['coach'] ?? '',
              theme: data['theme'] ?? '',
              dancerCount: data['dancerCount'] ?? 0,
              propsmenCount: data['propsmenCount'] ?? 0,
              musicianCount: data['musicianCount'] ?? 0,
              members: List<String>.from(data['members'] ?? []),
              profileImagePath: data['imageUrl'],
              performanceOrder: data['performanceOrder'] ?? 0,
              scoreHistory: scoreHistory,
            );
          }).toList();

          setState(() {
            groups = loadedGroups;
            _loading = false;
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        _buildGuidelinesCard(),
        const SizedBox(height: 16),
        _buildStatsRow(),
        const SizedBox(height: 16),
        _buildSearchBar(),
        const SizedBox(height: 6),
        _buildResultsHint(),
        const SizedBox(height: 10),
        Expanded(child: _buildGroupsList()),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dance Groups',
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Manage all registered contingents for PandanFest 2026',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => _showGroupDialog(context, null),
          icon: const Icon(Icons.add_rounded),
          label: Text('Add New Group', style: GoogleFonts.poppins()),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  // ── General Guidelines Card ───────────────────────────────────
  Widget _buildGuidelinesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.secondary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.rule_rounded, color: AppColors.secondary, size: 16),
              const SizedBox(width: 8),
              Text(
                'General Guidelines — Contingent Size Requirements',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _GuidelineChip(
                icon: Icons.directions_walk_rounded,
                label: 'Dancers',
                value: '$kMinDancers–$kMaxDancers',
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              _GuidelineChip(
                icon: Icons.construction_rounded,
                label: 'Propsmen (min)',
                value: '$kMinPropsmen',
                color: AppColors.secondary,
              ),
              const SizedBox(width: 10),
              _GuidelineChip(
                icon: Icons.music_note_rounded,
                label: 'Musicians (min)',
                value: '$kMinMusicians',
                color: AppColors.accentGreen,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final validGroups = groups.where((g) => g.isContingentValid).length;
    final invalidGroups = groups.length - validGroups;

    return Row(
      children: [
        _StatBadge(
          icon: Icons.groups_rounded,
          label: 'Total Groups',
          value: '${groups.length}',
          color: AppColors.secondary,
        ),
        const SizedBox(width: 12),
        _StatBadge(
          icon: Icons.check_circle_outline_rounded,
          label: 'Valid Contingents',
          value: '$validGroups',
          color: AppColors.accentGreen,
        ),
        const SizedBox(width: 12),
        _StatBadge(
          icon: invalidGroups > 0
              ? Icons.warning_amber_rounded
              : Icons.verified_rounded,
          label: invalidGroups > 0 ? 'Need Review' : 'All Compliant',
          value: invalidGroups > 0 ? '$invalidGroups' : '✓',
          color: invalidGroups > 0 ? AppColors.warning : AppColors.accentGreen,
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      cursorColor: AppColors.secondary,
      onChanged: (val) => setState(() => _searchQuery = val),
      style: GoogleFonts.poppins(),
      decoration: InputDecoration(
        hintText: 'Search by group name, community, or coach…',
        hintStyle: GoogleFonts.poppins(
          color: AppColors.silverRank,
          fontSize: 13,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AppColors.silverRank,
        ),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppColors.silverRank,
                  size: 18,
                ),
                onPressed: () => setState(() => _searchQuery = ''),
                tooltip: 'Clear search',
              )
            : null,
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.secondary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildResultsHint() {
    if (_searchQuery.isEmpty) return const SizedBox.shrink();
    final count = _filtered.length;
    return Text(
      count == 0
          ? 'No groups match "$_searchQuery"'
          : '$count group${count != 1 ? 's' : ''} found for "$_searchQuery"',
      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500]),
    );
  }

  Widget _buildGroupsList() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.secondary),
      );
    }

    final displayed = _filtered;

    if (displayed.isEmpty && groups.isEmpty) {
      return _EmptyState(
        icon: Icons.groups_rounded,
        title: 'No dance groups yet',
        subtitle:
            'Tap "Add New Group" to register the first contingent for the competition.',
        actionLabel: 'Add First Group',
        onAction: () => _showGroupDialog(context, null),
      );
    }

    if (displayed.isEmpty) {
      return _EmptyState(
        icon: Icons.search_off_rounded,
        title: 'No groups found',
        subtitle: 'Try a different name, community, or coach name.',
        actionLabel: 'Clear Search',
        onAction: () => setState(() => _searchQuery = ''),
      );
    }

    return ListView.separated(
      itemCount: displayed.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
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

  void _showGroupDialog(BuildContext context, DanceGroup? existing) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _GroupFormDialog(
        existing: existing,
        onSave: (group) async {
          if (existing == null) {
            await _db.collection('dance_groups').add({
              'name': group.name,
              'community': group.community,
              'coach': group.coach,
              'theme': group.theme,
              'dancerCount': group.dancerCount,
              'propsmenCount': group.propsmenCount,
              'musicianCount': group.musicianCount,
              'members': group.members,
              'performanceOrder': groups.length + 1,
              'imageUrl': group.profileImagePath,
              'scoreHistory': [],
              'createdAt': FieldValue.serverTimestamp(),
            });
          } else {
            await _db.collection('dance_groups').doc(group.id).update({
              'name': group.name,
              'community': group.community,
              'coach': group.coach,
              'theme': group.theme,
              'dancerCount': group.dancerCount,
              'propsmenCount': group.propsmenCount,
              'musicianCount': group.musicianCount,
              'members': group.members,
              'imageUrl': group.profileImagePath,
            });
          }
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, DanceGroup group) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        icon: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.danger.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.delete_outline_rounded,
            color: AppColors.danger,
            size: 28,
          ),
        ),
        title: Text(
          'Remove "${group.name}"?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'This will permanently remove the group and all their score history. This action cannot be undone.',
          style: GoogleFonts.poppins(fontSize: 13, color: AppColors.silverRank),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.silverRank,
              side: const BorderSide(color: AppColors.divider),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () async {
              await _db.collection('dance_groups').doc(group.id).delete();
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${group.name} has been removed.',
                    style: GoogleFonts.poppins(),
                  ),
                  backgroundColor: AppColors.danger,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'Yes, Remove',
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

// ═══════════════════════════════════════════════════════════════
//  GUIDELINE CHIP
// ═══════════════════════════════════════════════════════════════

class _GuidelineChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _GuidelineChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: AppColors.silverRank,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  GROUP CARD
// ═══════════════════════════════════════════════════════════════

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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: group.isContingentValid
            ? null
            : Border.all(color: AppColors.warning.withOpacity(0.4), width: 1.5),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            color: AppColors.shadow,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${group.performanceOrder}',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: group.profileImagePath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              group.profileImagePath!,
                              fit: BoxFit.cover,
                              loadingBuilder: (_, child, progress) =>
                                  progress == null
                                  ? child
                                  : const Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: AppColors.secondary,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.groups_rounded,
                                color: AppColors.secondary,
                                size: 28,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.groups_rounded,
                            color: AppColors.secondary,
                            size: 28,
                          ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          group.name,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (!group.isContingentValid)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Needs Review',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: AppColors.warning,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accentGreen.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Compliant',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: AppColors.accentGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        if (group.scoreHistory.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accentGreen.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${group.scoreHistory.length} scores',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: AppColors.accentGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 14,
                      runSpacing: 4,
                      children: [
                        _InfoChip(Icons.location_on_outlined, group.community),
                        _InfoChip(
                          Icons.person_outline_rounded,
                          'Coach: ${group.coach}',
                        ),
                        _InfoChip(Icons.palette_outlined, group.theme),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  _ActionButton(
                    icon: Icons.history_rounded,
                    label: 'History',
                    tooltip: 'View score history',
                    color: AppColors.accentGreen,
                    onTap: onViewHistory,
                  ),
                  const SizedBox(width: 8),
                  _ActionButton(
                    icon: Icons.edit_rounded,
                    label: 'Edit',
                    tooltip: 'Edit group details',
                    color: AppColors.secondary,
                    onTap: onEdit,
                  ),
                  const SizedBox(width: 8),
                  _ActionButton(
                    icon: Icons.delete_outline_rounded,
                    label: 'Remove',
                    tooltip: 'Remove this group',
                    color: AppColors.danger,
                    onTap: onDelete,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 10),
          // Contingent size row
          Row(
            children: [
              _ContingentBadge(
                icon: Icons.directions_walk_rounded,
                label: 'Dancers',
                count: group.dancerCount,
                isValid: group.isDancerCountValid,
                rangeLabel: '$kMinDancers–$kMaxDancers',
              ),
              const SizedBox(width: 10),
              _ContingentBadge(
                icon: Icons.construction_rounded,
                label: 'Propsmen',
                count: group.propsmenCount,
                isValid: group.isPropsmenCountValid,
                rangeLabel: 'min $kMinPropsmen',
              ),
              const SizedBox(width: 10),
              _ContingentBadge(
                icon: Icons.music_note_rounded,
                label: 'Musicians',
                count: group.musicianCount,
                isValid: group.isMusicianCountValid,
                rangeLabel: 'min $kMinMusicians',
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${group.totalMemberCount}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Total contingent',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: AppColors.silverRank,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _InfoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.silverRank),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, color: AppColors.silverRank),
        ),
      ],
    );
  }
}

class _ContingentBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final bool isValid;
  final String rangeLabel;

  const _ContingentBadge({
    required this.icon,
    required this.label,
    required this.count,
    required this.isValid,
    required this.rangeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final color = isValid ? AppColors.accentGreen : AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '$count',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    isValid
                        ? Icons.check_circle_rounded
                        : Icons.warning_amber_rounded,
                    size: 12,
                    color: color,
                  ),
                ],
              ),
              Text(
                '$label ($rangeLabel)',
                style: GoogleFonts.poppins(
                  fontSize: 9.5,
                  color: AppColors.silverRank,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  EMPTY STATE
// ═══════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.divider.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 38, color: AppColors.silverRank),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 340,
            child: Text(
              subtitle,
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(actionLabel!, style: GoogleFonts.poppins()),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  STAT BADGE
// ═══════════════════════════════════════════════════════════════

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatBadge({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.15)),
          boxShadow: const [
            BoxShadow(
              blurRadius: 8,
              color: AppColors.shadow,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  GROUP FORM DIALOG
// ═══════════════════════════════════════════════════════════════

class _GroupFormDialog extends StatefulWidget {
  final DanceGroup? existing;
  final Function(DanceGroup) onSave;

  const _GroupFormDialog({this.existing, required this.onSave});

  @override
  State<_GroupFormDialog> createState() => _GroupFormDialogState();
}

class _GroupFormDialogState extends State<_GroupFormDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _communityCtrl;
  late final TextEditingController _coachCtrl;
  late final TextEditingController _themeCtrl;
  late final TextEditingController _dancerCtrl;
  late final TextEditingController _propsmenCtrl;
  late final TextEditingController _musicianCtrl;
  final TextEditingController _memberInputCtrl = TextEditingController();
  late List<String> _members;

  String? _nameError;
  String? _communityError;
  String? _dancerError;
  String? _propsmenError;
  String? _musicianError;

  Uint8List? _pickedImageBytes;
  String? _uploadedImageUrl;
  bool _isUploading = false;
  bool _showUploadSuccess = false;

  @override
  void initState() {
    super.initState();
    final g = widget.existing;
    _nameCtrl = TextEditingController(text: g?.name ?? '');
    _communityCtrl = TextEditingController(text: g?.community ?? '');
    _coachCtrl = TextEditingController(text: g?.coach ?? '');
    _themeCtrl = TextEditingController(text: g?.theme ?? '');
    _dancerCtrl = TextEditingController(
      text: g != null ? '${g.dancerCount}' : '',
    );
    _propsmenCtrl = TextEditingController(
      text: g != null ? '${g.propsmenCount}' : '',
    );
    _musicianCtrl = TextEditingController(
      text: g != null ? '${g.musicianCount}' : '',
    );
    _members = List.from(g?.members ?? []);
    _uploadedImageUrl = g?.profileImagePath;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _communityCtrl.dispose();
    _coachCtrl.dispose();
    _themeCtrl.dispose();
    _dancerCtrl.dispose();
    _propsmenCtrl.dispose();
    _musicianCtrl.dispose();
    _memberInputCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _pickedImageBytes = bytes;
      _isUploading = true;
      _showUploadSuccess = false;
    });
    try {
      final url = await _Cloudinary.uploadBytes(bytes, picked.name);
      setState(() {
        _uploadedImageUrl = url;
        _isUploading = false;
        _showUploadSuccess = true;
      });
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Image upload failed. Please try again.',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _addMember() {
    final name = _memberInputCtrl.text.trim();
    if (name.isNotEmpty) {
      setState(() => _members.add(name));
      _memberInputCtrl.clear();
    }
  }

  bool _validate() {
    bool ok = true;
    final dancers = int.tryParse(_dancerCtrl.text);
    final propsmen = int.tryParse(_propsmenCtrl.text);
    final musicians = int.tryParse(_musicianCtrl.text);

    setState(() {
      _nameError = _nameCtrl.text.trim().isEmpty
          ? 'Group name is required.'
          : null;
      _communityError = _communityCtrl.text.trim().isEmpty
          ? 'Community is required.'
          : null;

      if (dancers == null) {
        _dancerError = 'Please enter a valid number.';
      } else if (dancers < kMinDancers || dancers > kMaxDancers) {
        _dancerError = 'Dancers must be between $kMinDancers and $kMaxDancers.';
      } else {
        _dancerError = null;
      }

      if (propsmen == null) {
        _propsmenError = 'Please enter a valid number.';
      } else if (propsmen < kMinPropsmen) {
        _propsmenError = 'Minimum $kMinPropsmen propsmen required.';
      } else {
        _propsmenError = null;
      }

      if (musicians == null) {
        _musicianError = 'Please enter a valid number.';
      } else if (musicians < kMinMusicians) {
        _musicianError = 'Minimum $kMinMusicians musicians required.';
      } else {
        _musicianError = null;
      }

      if (_nameError != null ||
          _communityError != null ||
          _dancerError != null ||
          _propsmenError != null ||
          _musicianError != null) {
        ok = false;
      }
    });
    return ok;
  }

  void _save() {
    if (!_validate()) return;
    if (_isUploading) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please wait for the image to finish uploading.',
            style: GoogleFonts.poppins(),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final group = DanceGroup(
      id:
          widget.existing?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text.trim(),
      community: _communityCtrl.text.trim(),
      coach: _coachCtrl.text.trim(),
      theme: _themeCtrl.text.trim(),
      dancerCount: int.parse(_dancerCtrl.text),
      propsmenCount: int.parse(_propsmenCtrl.text),
      musicianCount: int.parse(_musicianCtrl.text),
      members: _members,
      profileImagePath: _uploadedImageUrl,
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
        width: 580,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ──
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEdit ? 'Edit Dance Group' : 'Add New Dance Group',
                        style: GoogleFonts.poppins(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isEdit
                            ? 'Update the contingent\'s information below'
                            : 'Fill in the details to register a new contingent',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Guidelines reminder ──
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.secondary.withOpacity(0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 15,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Guidelines: Dancers $kMinDancers–$kMaxDancers • Propsmen min $kMinPropsmen • Musicians min $kMinMusicians',
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Photo upload ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.secondary.withOpacity(0.25),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: _isUploading
                          ? const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: AppColors.secondary,
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : _pickedImageBytes != null
                          ? Image.memory(_pickedImageBytes!, fit: BoxFit.cover)
                          : _uploadedImageUrl != null
                          ? Image.network(
                              _uploadedImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.groups_rounded,
                                color: AppColors.secondary,
                                size: 28,
                              ),
                            )
                          : Icon(
                              Icons.add_a_photo_rounded,
                              color: AppColors.secondary,
                              size: 28,
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Group Profile Photo',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Optional — JPG or PNG, max 2 MB',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: _isUploading
                                ? null
                                : _pickAndUploadImage,
                            icon: Icon(
                              _isUploading
                                  ? Icons.hourglass_top_rounded
                                  : Icons.upload_rounded,
                              size: 15,
                            ),
                            label: Text(
                              _isUploading
                                  ? 'Uploading…'
                                  : _uploadedImageUrl != null
                                  ? 'Change Photo'
                                  : 'Upload Photo',
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
                          if (_uploadedImageUrl != null && !_isUploading) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () => setState(() {
                                _pickedImageBytes = null;
                                _uploadedImageUrl = null;
                                _showUploadSuccess = false;
                              }),
                              icon: const Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: AppColors.danger,
                              ),
                              tooltip: 'Remove photo',
                            ),
                          ],
                        ],
                      ),
                      if (_showUploadSuccess)
                        Row(
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 13,
                              color: AppColors.accentGreen,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Uploaded successfully',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: AppColors.accentGreen,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Basic fields ──
              _buildField(
                'Group Name *',
                _nameCtrl,
                'e.g. Sayaw Pandan',
                errorText: _nameError,
                onChanged: (_) => setState(() => _nameError = null),
              ),
              _buildField(
                'Community *',
                _communityCtrl,
                'e.g. Pandan Community',
                errorText: _communityError,
                onChanged: (_) => setState(() => _communityError = null),
              ),
              _buildField('Coach / Trainer', _coachCtrl, 'e.g. Maria Santos'),
              _buildField(
                'Dance Theme / Style',
                _themeCtrl,
                'e.g. Urban Fusion, Hip-Hop',
              ),

              // ── Contingent Size Section ──
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  'Contingent Size *',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _buildCountField(
                      label: 'Dancers',
                      ctrl: _dancerCtrl,
                      hint: '$kMinDancers–$kMaxDancers',
                      icon: Icons.directions_walk_rounded,
                      color: AppColors.primary,
                      errorText: _dancerError,
                      onChanged: (_) => setState(() => _dancerError = null),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCountField(
                      label: 'Propsmen',
                      ctrl: _propsmenCtrl,
                      hint: 'min $kMinPropsmen',
                      icon: Icons.construction_rounded,
                      color: AppColors.secondary,
                      errorText: _propsmenError,
                      onChanged: (_) => setState(() => _propsmenError = null),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCountField(
                      label: 'Musicians',
                      ctrl: _musicianCtrl,
                      hint: 'min $kMinMusicians',
                      icon: Icons.music_note_rounded,
                      color: AppColors.accentGreen,
                      errorText: _musicianError,
                      onChanged: (_) => setState(() => _musicianError = null),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Members ──
              Text(
                'Members List',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Add individual member names (optional)',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      cursorColor: AppColors.secondary,
                      controller: _memberInputCtrl,
                      style: GoogleFonts.poppins(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Type member name and press Add…',
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
                      onSubmitted: (_) => _addMember(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _addMember,
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: Text('Add', style: GoogleFonts.poppins()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
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
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 14,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'No members added yet. You can add them later.',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 28),

              // ── Save / Cancel ──
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.silverRank,
                      side: const BorderSide(color: AppColors.divider),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text('Cancel', style: GoogleFonts.poppins()),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _save,
                    icon: Icon(
                      isEdit ? Icons.save_rounded : Icons.add_rounded,
                      size: 18,
                    ),
                    label: Text(
                      isEdit ? 'Save Changes' : 'Register Group',
                      style: GoogleFonts.poppins(),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 13,
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
    String? errorText,
    ValueChanged<String>? onChanged,
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
            cursorColor: AppColors.secondary,
            controller: ctrl,
            keyboardType: keyboardType,
            style: GoogleFonts.poppins(fontSize: 14),
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(
                color: AppColors.silverRank,
                fontSize: 13,
              ),
              errorText: errorText,
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
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.danger),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.secondary, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountField({
    required String label,
    required TextEditingController ctrl,
    required String hint,
    required IconData icon,
    required Color color,
    String? errorText,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          cursorColor: color,
          controller: ctrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: GoogleFonts.poppins(fontSize: 14),
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              color: AppColors.silverRank,
              fontSize: 12,
            ),
            errorText: errorText,
            errorStyle: GoogleFonts.poppins(
              fontSize: 10,
              color: AppColors.danger,
            ),
            filled: true,
            fillColor: AppColors.background,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.danger),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: color, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  HISTORY DIALOG
// ═══════════════════════════════════════════════════════════════

class _HistoryDialog extends StatelessWidget {
  final DanceGroup group;
  const _HistoryDialog({required this.group});

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
                          'Score History — ${group.community}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
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
                    tooltip: 'Close',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (group.scoreHistory.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.history_toggle_off_rounded,
                          size: 40,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No score history yet',
                          style: GoogleFonts.poppins(
                            color: AppColors.silverRank,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Scores will appear here after each phase.',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
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
                    final rc = _rankColor(h.rank);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: rc.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '#${h.rank}',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  color: rc,
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
                              '${h.score.toStringAsFixed(1)} pts',
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
                    'Close',
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
}
