import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pandan_fest/constant/colors.dart';

enum CompetitionStatus { idle, running, paused, locked }

class SettingsControlsScreen extends StatefulWidget {
  const SettingsControlsScreen({super.key});

  @override
  State<SettingsControlsScreen> createState() => _SettingsControlsScreenState();
}

class _SettingsControlsScreenState extends State<SettingsControlsScreen> {
  CompetitionStatus _status = CompetitionStatus.idle;
  DateTime? _startTime;
  DateTime? _lockedAt;
  String? _lastBackupTime;

  // ─────────────────────────────────────────
  // 1. START COMPETITION
  // ─────────────────────────────────────────

  void _startCompetition() {
    if (_status != CompetitionStatus.idle) return;
    setState(() {
      _status = CompetitionStatus.running;
      _startTime = DateTime.now();
    });
    _showSnack("Competition started!", Icons.play_arrow_rounded, Colors.green);
  }

  void _endCompetition() {
    if (_status == CompetitionStatus.locked) return;
    _showConfirmDialog(
      title: "End Competition?",
      message: "This will reset the competition to idle state.",
      onConfirm: () {
        setState(() {
          _status = CompetitionStatus.idle;
          _startTime = null;
        });
        _showSnack("Competition ended.", Icons.stop_rounded, Colors.orange);
      },
    );
  }

  // ─────────────────────────────────────────
  // 2. PAUSE / RESUME SCORING
  // ─────────────────────────────────────────

  void _togglePauseResume() {
    if (_status == CompetitionStatus.running) {
      setState(() => _status = CompetitionStatus.paused);
      _showSnack("Scoring paused.", Icons.pause_rounded, Colors.orange);
    } else if (_status == CompetitionStatus.paused) {
      setState(() => _status = CompetitionStatus.running);
      _showSnack("Scoring resumed!", Icons.play_arrow_rounded, Colors.green);
    }
  }

  // ─────────────────────────────────────────
  // 3. LOCK FINAL RESULTS
  // ─────────────────────────────────────────

  void _lockFinalResults() {
    if (_status == CompetitionStatus.locked) return;
    _showConfirmDialog(
      title: "Lock Final Results?",
      message:
          "No scores can be changed after locking. This cannot be undone easily.",
      onConfirm: () {
        setState(() {
          _status = CompetitionStatus.locked;
          _lockedAt = DateTime.now();
        });
        _showSnack("Results locked!", Icons.lock_rounded, Colors.red);
      },
    );
  }

  void _unlockResults() {
    if (_status != CompetitionStatus.locked) return;
    _showConfirmDialog(
      title: "Unlock Results?",
      message: "Admin override: this will allow score edits again.",
      onConfirm: () {
        setState(() {
          _status = CompetitionStatus.paused;
          _lockedAt = null;
        });
        _showSnack("Results unlocked.", Icons.lock_open_rounded, Colors.blue);
      },
    );
  }

  // ─────────────────────────────────────────
  // 4. BACKUP & RESTORE
  // ─────────────────────────────────────────

  void _backupData() {
    final backup = {
      'status': _status.name,
      'startTime': _startTime?.toIso8601String(),
      'lockedAt': _lockedAt?.toIso8601String(),
      'backedUpAt': DateTime.now().toIso8601String(),
    };
    setState(() => _lastBackupTime = DateTime.now().toString());
    _showSnack(
      "Backup saved successfully.",
      Icons.backup_rounded,
      Colors.green,
    );
    debugPrint("Backup: $backup");
  }

  void _restoreData() {
    _showConfirmDialog(
      title: "Restore Last Backup?",
      message: "Current state will be replaced with the last backup.",
      onConfirm: () {
        _showSnack("Data restored.", Icons.restore_rounded, Colors.blue);
      },
    );
  }

  // ─────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────

  void _showSnack(String msg, IconData icon, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text(msg, style: GoogleFonts.poppins(color: Colors.white)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showConfirmDialog({
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(message, style: GoogleFonts.poppins(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: Text(
              "Confirm",
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // STATUS HELPERS
  // ─────────────────────────────────────────

  Color get _statusColor => switch (_status) {
    CompetitionStatus.idle => Colors.grey,
    CompetitionStatus.running => Colors.green,
    CompetitionStatus.paused => Colors.orange,
    CompetitionStatus.locked => Colors.red,
  };

  String get _statusLabel => switch (_status) {
    CompetitionStatus.idle => "Idle",
    CompetitionStatus.running => "Running",
    CompetitionStatus.paused => "Paused",
    CompetitionStatus.locked => "Locked",
  };

  // ─────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──
        Row(
          children: [
            Text(
              "System Controls",
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _statusColor),
              ),
              child: Row(
                children: [
                  Icon(Icons.circle, color: _statusColor, size: 10),
                  const SizedBox(width: 8),
                  Text(
                    _statusLabel,
                    style: GoogleFonts.poppins(
                      color: _statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        if (_startTime != null) ...[
          const SizedBox(height: 6),
          Text(
            "Started: ${_startTime!.toLocal()}",
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
          ),
        ],
        if (_lockedAt != null) ...[
          const SizedBox(height: 4),
          Text(
            "Locked at: ${_lockedAt!.toLocal()}",
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.red),
          ),
        ],

        const SizedBox(height: 30),

        // ── Cards Grid ──
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 1.4,
            children: [
              // Card 1: Start Competition
              _ControlCard(
                icon: Icons.flag_rounded,
                title: "Start Competition",
                description: _status == CompetitionStatus.idle
                    ? "Competition is idle. Ready to start."
                    : "Competition is currently $_statusLabel.",
                color: Colors.green,
                actions: [
                  if (_status == CompetitionStatus.idle)
                    _ActionButton(
                      label: "Start",
                      icon: Icons.play_arrow_rounded,
                      color: Colors.green,
                      onTap: _startCompetition,
                    ),
                  if (_status != CompetitionStatus.idle &&
                      _status != CompetitionStatus.locked)
                    _ActionButton(
                      label: "End",
                      icon: Icons.stop_rounded,
                      color: Colors.orange,
                      onTap: _endCompetition,
                    ),
                ],
              ),

              // Card 2: Pause / Resume
              _ControlCard(
                icon: Icons.pause_circle_rounded,
                title: "Pause / Resume Scoring",
                description: _status == CompetitionStatus.running
                    ? "Scoring is live. You can pause anytime."
                    : _status == CompetitionStatus.paused
                    ? "Scoring is currently paused."
                    : "Not available in current state.",
                color: Colors.orange,
                actions: [
                  if (_status == CompetitionStatus.running ||
                      _status == CompetitionStatus.paused)
                    _ActionButton(
                      label: _status == CompetitionStatus.paused
                          ? "Resume"
                          : "Pause",
                      icon: _status == CompetitionStatus.paused
                          ? Icons.play_arrow_rounded
                          : Icons.pause_rounded,
                      color: Colors.orange,
                      onTap: _togglePauseResume,
                    ),
                ],
              ),

              // Card 3: Lock Final Results
              _ControlCard(
                icon: Icons.lock_rounded,
                title: "Lock Final Results",
                description: _status == CompetitionStatus.locked
                    ? "Results are locked at ${_lockedAt?.toLocal()}"
                    : "Lock scoring to finalize competition results.",
                color: Colors.red,
                actions: [
                  if (_status != CompetitionStatus.idle &&
                      _status != CompetitionStatus.locked)
                    _ActionButton(
                      label: "Lock Results",
                      icon: Icons.lock_rounded,
                      color: Colors.red,
                      onTap: _lockFinalResults,
                    ),
                  if (_status == CompetitionStatus.locked)
                    _ActionButton(
                      label: "Unlock (Admin)",
                      icon: Icons.lock_open_rounded,
                      color: Colors.blueGrey,
                      onTap: _unlockResults,
                    ),
                ],
              ),

              // Card 4: Backup & Restore
              _ControlCard(
                icon: Icons.backup_rounded,
                title: "Backup & Restore",
                description: _lastBackupTime != null
                    ? "Last backup: $_lastBackupTime"
                    : "No backup taken yet.",
                color: AppColors.secondary,
                actions: [
                  _ActionButton(
                    label: "Backup",
                    icon: Icons.save_rounded,
                    color: AppColors.secondary,
                    onTap: _backupData,
                  ),
                  _ActionButton(
                    label: "Restore",
                    icon: Icons.restore_rounded,
                    color: Colors.blueGrey,
                    onTap: _restoreData,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────
// REUSABLE WIDGETS
// ─────────────────────────────────────────

class _ControlCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final List<Widget> actions;

  const _ControlCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            blurRadius: 15,
            color: AppColors.shadow,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
          ),
          const Spacer(),
          if (actions.isNotEmpty)
            Wrap(spacing: 10, children: actions)
          else
            Text(
              "No actions available",
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[400]),
            ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, style: GoogleFonts.poppins(fontSize: 13)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
      ),
    );
  }
}
