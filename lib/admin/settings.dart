import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pandan_fest/constant/colors.dart';

enum CompetitionStatus { idle, running, paused, locked }

class SettingsControlsScreen extends StatefulWidget {
  const SettingsControlsScreen({super.key});

  @override
  State<SettingsControlsScreen> createState() => _SettingsControlsScreenState();
}

class _SettingsControlsScreenState extends State<SettingsControlsScreen>
    with TickerProviderStateMixin {
  CompetitionStatus _status = CompetitionStatus.idle;
  DateTime? _startTime;
  DateTime? _lockedAt;
  String? _lastBackupTime;

  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ── Status helpers ────────────────────────────────────────────
  Color get _statusColor => switch (_status) {
    CompetitionStatus.idle => Colors.grey,
    CompetitionStatus.running => AppColors.live,
    CompetitionStatus.paused => Colors.orange,
    CompetitionStatus.locked => AppColors.danger,
  };

  String get _statusLabel => switch (_status) {
    CompetitionStatus.idle => 'Idle — Not started',
    CompetitionStatus.running => 'Live — Scoring Active',
    CompetitionStatus.paused => 'Paused — Suspended',
    CompetitionStatus.locked => 'Locked — Finalized',
  };

  IconData get _statusIcon => switch (_status) {
    CompetitionStatus.idle => Icons.radio_button_unchecked_rounded,
    CompetitionStatus.running => Icons.play_circle_rounded,
    CompetitionStatus.paused => Icons.pause_circle_rounded,
    CompetitionStatus.locked => Icons.lock_rounded,
  };

  // ── Competition actions ───────────────────────────────────────
  void _startCompetition() {
    if (_status != CompetitionStatus.idle) return;
    setState(() {
      _status = CompetitionStatus.running;
      _startTime = DateTime.now();
    });
    _toast(
      'Competition started successfully!',
      Icons.play_arrow_rounded,
      AppColors.live,
    );
  }

  void _endCompetition() {
    if (_status == CompetitionStatus.locked) return;
    _confirm(
      icon: Icons.stop_rounded,
      iconColor: Colors.orange,
      title: 'End Competition?',
      message:
          'This will stop the current session and reset the competition status to idle. '
          'All entered scores will be preserved.',
      confirmLabel: 'Yes, End Session',
      confirmColor: Colors.orange,
      onConfirm: () {
        setState(() {
          _status = CompetitionStatus.idle;
          _startTime = null;
        });
        _toast('Competition session ended.', Icons.stop_rounded, Colors.orange);
      },
    );
  }

  void _togglePauseResume() {
    if (_status == CompetitionStatus.running) {
      setState(() => _status = CompetitionStatus.paused);
      _toast(
        'Scoring paused. Judges cannot submit while paused.',
        Icons.pause_rounded,
        Colors.orange,
      );
    } else if (_status == CompetitionStatus.paused) {
      setState(() => _status = CompetitionStatus.running);
      _toast(
        'Scoring resumed! Judges can now submit scores.',
        Icons.play_arrow_rounded,
        AppColors.live,
      );
    }
  }

  void _lockFinalResults() {
    if (_status == CompetitionStatus.locked) return;
    _confirm(
      icon: Icons.lock_rounded,
      iconColor: AppColors.danger,
      title: 'Lock Final Results?',
      message:
          'Once locked, no judge can submit or change scores. '
          'This action is intended for after all performances are done. '
          'You can unlock with an admin override if needed.',
      confirmLabel: 'Lock Results',
      confirmColor: AppColors.danger,
      onConfirm: () {
        setState(() {
          _status = CompetitionStatus.locked;
          _lockedAt = DateTime.now();
        });
        _toast('Results are now locked.', Icons.lock_rounded, AppColors.danger);
      },
    );
  }

  void _unlockResults() {
    if (_status != CompetitionStatus.locked) return;
    _confirm(
      icon: Icons.admin_panel_settings_rounded,
      iconColor: Colors.blueGrey,
      title: 'Admin Override — Unlock Results?',
      message:
          'This is an admin override. Unlocking will allow judges to modify scores again. '
          'Use this only if a correction is required.',
      confirmLabel: 'Unlock (Override)',
      confirmColor: Colors.blueGrey,
      onConfirm: () {
        setState(() {
          _status = CompetitionStatus.paused;
          _lockedAt = null;
        });
        _toast(
          'Results unlocked by admin override.',
          Icons.lock_open_rounded,
          Colors.blueGrey,
        );
      },
    );
  }

  void _backupData() {
    setState(() => _lastBackupTime = _formatTime(DateTime.now()));
    _toast(
      'Backup saved successfully!',
      Icons.backup_rounded,
      AppColors.accentGreen,
    );
  }

  void _restoreData() {
    _confirm(
      icon: Icons.restore_rounded,
      iconColor: Colors.blueGrey,
      title: 'Restore Last Backup?',
      message:
          'The current system state will be replaced with the most recent backup. '
          'This cannot be undone.',
      confirmLabel: 'Restore Backup',
      confirmColor: Colors.blueGrey,
      onConfirm: () => _toast(
        'Data restored from last backup.',
        Icons.restore_rounded,
        Colors.blueGrey,
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────
  String _formatTime(DateTime dt) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _toast(String msg, IconData icon, Color color) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
        elevation: 8,
      ),
    );
  }

  void _confirm({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
        titlePadding: const EdgeInsets.fromLTRB(28, 28, 28, 4),
        actionsPadding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
        icon: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: iconColor.withOpacity(0.25), width: 1.5),
          ),
          child: Icon(icon, color: iconColor, size: 28),
        ),
        iconPadding: const EdgeInsets.only(top: 8, bottom: 4),
        title: Text(
          title,
          style: GoogleFonts.dmSans(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: const Color(0xFF0F172A),
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          message,
          style: GoogleFonts.dmSans(
            fontSize: 13.5,
            color: Colors.grey[600],
            height: 1.65,
          ),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onConfirm();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: confirmColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    shadowColor: confirmColor.withOpacity(0.4),
                  ),
                  child: Text(
                    confirmLabel,
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        _buildStatusBanner(),
        const SizedBox(height: 20),
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.3,
            children: [
              _buildStartCard(),
              _buildPauseCard(),
              _buildLockCard(),
              _buildBackupCard(),
            ],
          ),
        ),
        _buildActivityLog(),
      ],
    );
  }

  // ── Header ────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'System Controls',
                style: GoogleFonts.dmSans(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage competition session, scoring state, and data backups',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        _buildStatusBadge(),
      ],
    );
  }

  Widget _buildStatusBadge() {
    final isLive = _status == CompetitionStatus.running;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: _statusColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: _statusColor.withOpacity(0.35), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLive)
            AnimatedBuilder(
              animation: _pulseController,
              builder: (_, __) => Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _statusColor.withOpacity(
                    0.5 + 0.5 * _pulseController.value,
                  ),
                ),
              ),
            )
          else
            Icon(_statusIcon, color: _statusColor, size: 14),
          const SizedBox(width: 7),
          Text(
            _statusLabel,
            style: GoogleFonts.dmMono(
              color: _statusColor,
              fontWeight: FontWeight.w500,
              fontSize: 11.5,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  // ── Status Banner ─────────────────────────────────────────────
  Widget _buildStatusBanner() {
    if (_startTime == null && _lockedAt == null) return const SizedBox.shrink();
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _statusColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _statusColor.withOpacity(0.2), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_statusIcon, color: _statusColor, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_startTime != null)
                  Text(
                    'Session started ${_formatTime(_startTime!)}',
                    style: GoogleFonts.dmSans(
                      fontSize: 12.5,
                      color: _statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (_lockedAt != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Locked at ${_formatTime(_lockedAt!)}',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: AppColors.danger,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Activity Log ──────────────────────────────────────────────
  Widget _buildActivityLog() {
    if (_startTime == null && _lastBackupTime == null && _lockedAt == null) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            color: AppColors.shadow,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SESSION ACTIVITY LOG',
            style: GoogleFonts.dmMono(
              fontSize: 10.5,
              color: Colors.grey[400],
              letterSpacing: 1.2,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          if (_startTime != null)
            _LogEntry(
              icon: Icons.rocket_launch_rounded,
              label: 'Competition session started',
              time: _formatTime(_startTime!),
              color: AppColors.live,
            ),
          if (_lastBackupTime != null) ...[
            const SizedBox(height: 10),
            _LogEntry(
              icon: Icons.save_rounded,
              label: 'Data backup saved',
              time: _lastBackupTime!,
              color: AppColors.secondary,
            ),
          ],
          if (_lockedAt != null) ...[
            const SizedBox(height: 10),
            _LogEntry(
              icon: Icons.lock_rounded,
              label: 'Results locked by admin',
              time: _formatTime(_lockedAt!),
              color: AppColors.danger,
            ),
          ],
        ],
      ),
    );
  }

  // ── Control Cards ─────────────────────────────────────────────
  Widget _buildStartCard() {
    final canStart = _status == CompetitionStatus.idle;
    final canEnd =
        _status != CompetitionStatus.idle &&
        _status != CompetitionStatus.locked;

    return _ControlCard(
      icon: Icons.flag_rounded,
      color: AppColors.live,
      title: 'Competition Session',
      showStatusChip: true,
      status: _status,
      statusColor: _statusColor,
      statusLabel: _statusLabel,
      description: switch (_status) {
        CompetitionStatus.idle =>
          'Competition hasn\'t started yet. Press Start when you\'re ready.',
        CompetitionStatus.running =>
          'Session is active. Scoring is in progress and judges can submit.',
        CompetitionStatus.paused =>
          'Session active but scoring is currently paused.',
        CompetitionStatus.locked => 'Session has been finalized and locked.',
      },
      isPulsing: _status == CompetitionStatus.running,
      pulseController: _pulseController,
      actions: [
        if (canStart)
          _Btn(
            label: 'Start Competition',
            icon: Icons.play_arrow_rounded,
            color: AppColors.live,
            onTap: _startCompetition,
          ),
        if (canEnd)
          _Btn(
            label: 'End Session',
            icon: Icons.stop_rounded,
            color: Colors.orange,
            onTap: _endCompetition,
          ),
      ],
    );
  }

  Widget _buildPauseCard() {
    final canToggle =
        _status == CompetitionStatus.running ||
        _status == CompetitionStatus.paused;

    return _ControlCard(
      icon: Icons.pause_circle_rounded,
      color: Colors.orange,
      title: 'Pause / Resume',
      description: switch (_status) {
        CompetitionStatus.running =>
          'Scoring is live. Pause to prevent judges from submitting scores.',
        CompetitionStatus.paused =>
          'Scoring is paused. Judges cannot submit scores right now.',
        CompetitionStatus.idle =>
          'Start the competition first to enable this control.',
        CompetitionStatus.locked =>
          'Scoring is permanently locked. No changes allowed.',
      },
      actions: [
        if (canToggle)
          _Btn(
            label: _status == CompetitionStatus.paused
                ? 'Resume Scoring'
                : 'Pause Scoring',
            icon: _status == CompetitionStatus.paused
                ? Icons.play_arrow_rounded
                : Icons.pause_rounded,
            color: Colors.orange,
            onTap: _togglePauseResume,
          ),
      ],
    );
  }

  Widget _buildLockCard() {
    final canLock =
        _status != CompetitionStatus.idle &&
        _status != CompetitionStatus.locked;
    final isLocked = _status == CompetitionStatus.locked;

    return _ControlCard(
      icon: Icons.lock_rounded,
      color: AppColors.danger,
      title: 'Lock Final Results',
      description: isLocked
          ? 'Results are locked. No further submissions allowed. Use Admin Override if a correction is needed.'
          : 'Lock scoring after all performances to prevent further score changes.',
      actions: [
        if (canLock)
          _Btn(
            label: 'Lock Results',
            icon: Icons.lock_rounded,
            color: AppColors.danger,
            onTap: _lockFinalResults,
          ),
        if (isLocked)
          _Btn(
            label: 'Admin Override',
            icon: Icons.lock_open_rounded,
            color: Colors.blueGrey,
            onTap: _unlockResults,
          ),
      ],
    );
  }

  Widget _buildBackupCard() {
    return _ControlCard(
      icon: Icons.backup_rounded,
      color: AppColors.secondary,
      title: 'Backup & Restore',
      description: _lastBackupTime != null
          ? 'Last backup: $_lastBackupTime\nKeep backups frequent to avoid data loss.'
          : 'No backup created yet. Back up your data regularly.',
      actions: [
        _Btn(
          label: 'Save Backup',
          icon: Icons.save_rounded,
          color: AppColors.secondary,
          onTap: _backupData,
        ),
        _Btn(
          label: 'Restore',
          icon: Icons.restore_rounded,
          color: _lastBackupTime != null ? Colors.blueGrey : Colors.grey,
          onTap: _lastBackupTime != null ? _restoreData : null,
          outline: true,
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  CONTROL CARD
// ═══════════════════════════════════════════════════════════════

class _ControlCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final List<Widget> actions;
  final bool showStatusChip;
  final CompetitionStatus? status;
  final Color? statusColor;
  final String? statusLabel;
  final bool isPulsing;
  final AnimationController? pulseController;

  const _ControlCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.actions,
    this.showStatusChip = false,
    this.status,
    this.statusColor,
    this.statusLabel,
    this.isPulsing = false,
    this.pulseController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.12), width: 1.5),
        boxShadow: [
          BoxShadow(
            blurRadius: 16,
            color: color.withOpacity(0.06),
            offset: const Offset(0, 6),
          ),
          const BoxShadow(
            blurRadius: 8,
            color: AppColors.shadow,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top accent bar
          Container(
            height: 3,
            width: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.7),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 14),

          // Icon + title row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: color.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  if (isPulsing && pulseController != null)
                    Positioned(
                      top: -3,
                      right: -3,
                      child: AnimatedBuilder(
                        animation: pulseController!,
                        builder: (_, __) => Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color.withOpacity(
                              0.5 + 0.5 * pulseController!.value,
                            ),
                            border: Border.all(
                              color: AppColors.surface,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (showStatusChip &&
                        statusColor != null &&
                        statusLabel != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor!.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: statusColor!.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: statusColor,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                statusLabel!.toUpperCase(),
                                style: GoogleFonts.dmMono(
                                  color: statusColor,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Description
          Expanded(
            child: Text(
              description,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: Colors.grey[500],
                height: 1.6,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Actions
          if (actions.isEmpty)
            Text(
              'No actions available in current state.',
              style: GoogleFonts.dmSans(
                fontSize: 11.5,
                color: Colors.grey[400],
              ),
            )
          else
            Wrap(spacing: 8, runSpacing: 8, children: actions),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  BTN
// ═══════════════════════════════════════════════════════════════

class _Btn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool outline;

  const _Btn({
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
    this.outline = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;

    if (outline && !disabled) {
      return OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 14),
        label: Text(
          label,
          style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withOpacity(0.6), width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 14),
      label: Text(
        label,
        style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: disabled ? Colors.grey[200] : color,
        foregroundColor: disabled ? Colors.grey[400] : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: disabled ? 0 : 2,
        shadowColor: disabled ? Colors.transparent : color.withOpacity(0.35),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  LOG ENTRY
// ═══════════════════════════════════════════════════════════════

class _LogEntry extends StatelessWidget {
  final IconData icon;
  final String label;
  final String time;
  final Color color;

  const _LogEntry({
    required this.icon,
    required this.label,
    required this.time,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.25), width: 1),
          ),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 12.5,
              color: const Color(0xFF374151),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          time,
          style: GoogleFonts.dmMono(fontSize: 11, color: Colors.grey[400]),
        ),
      ],
    );
  }
}
