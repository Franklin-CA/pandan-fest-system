import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

// ─────────────────────────────────────────────────────────────────────────────
// LiveSessionState  — singleton ChangeNotifier
//
// Uses localStorage to share state across browser tabs (Admin ↔ Judge).
// Polls every 500ms so judges see admin pushes in near-real-time.
// ─────────────────────────────────────────────────────────────────────────────

class LiveSessionState extends ChangeNotifier {
  LiveSessionState._() {
    // Poll localStorage every 500ms to pick up cross-tab changes
    _pollTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _syncFromStorage();
    });
    _syncFromStorage();
  }

  static final LiveSessionState instance = LiveSessionState._();

  Timer? _pollTimer;

  // ── Keys ────────────────────────────────────────────────────────
  static const String _activeGroupPrefix = 'pf_active_group_';
  static const String _focalPushedKey    = 'pf_focal_pushed';

  // ── In-memory cache (kept in sync with localStorage) ────────────
  final Map<String, String?> _activeGroupPerStage = {};
  String? _pushedFocalGroupId;

  // ── Public reads ────────────────────────────────────────────────
  String? activeGroupId(String stageId) => _activeGroupPerStage[stageId];
  String? get pushedFocalGroupId => _pushedFocalGroupId;

  // ── Sync from localStorage (called on each poll tick) ───────────
  void _syncFromStorage() {
    bool changed = false;

    // Active groups per stage
    final keys = html.window.localStorage.keys
        .where((k) => k.startsWith(_activeGroupPrefix))
        .toList();
    final stageIds = keys.map((k) => k.replaceFirst(_activeGroupPrefix, '')).toList();

    for (final stageId in stageIds) {
      final val = html.window.localStorage['$_activeGroupPrefix$stageId'];
      if (_activeGroupPerStage[stageId] != val) {
        _activeGroupPerStage[stageId] = val;
        changed = true;
      }
    }

    // Focal pushed group
    final focal = html.window.localStorage[_focalPushedKey];
    if (_pushedFocalGroupId != focal) {
      _pushedFocalGroupId = focal;
      changed = true;
    }

    if (changed) notifyListeners();
  }

  // ── Writes (write to localStorage + update cache immediately) ───

  void setActiveGroup(String stageId, String? groupId) {
    if (groupId == null) {
      html.window.localStorage.remove('$_activeGroupPrefix$stageId');
    } else {
      html.window.localStorage['$_activeGroupPrefix$stageId'] = groupId;
    }
    _activeGroupPerStage[stageId] = groupId;
    notifyListeners();
  }

  void clearActiveGroup(String stageId) => setActiveGroup(stageId, null);

  void pushFocalContestant(String groupId) {
    html.window.localStorage[_focalPushedKey] = groupId;
    _pushedFocalGroupId = groupId;
    notifyListeners();
  }

  void clearFocalPush() {
    html.window.localStorage.remove(_focalPushedKey);
    _pushedFocalGroupId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}

class MaxValueFormatter extends TextInputFormatter {
  final double maxValue;
  MaxValueFormatter(this.maxValue);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final parsed = double.tryParse(newValue.text);
    if (parsed == null) return oldValue;
    if (parsed > maxValue) return oldValue;
    return newValue;
  }
}