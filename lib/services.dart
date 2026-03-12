import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LiveSessionState  — singleton ChangeNotifier
//
// Tracks which contestant is currently being scored at each stage.
// The Judge screen calls setActiveGroup() when a contestant is selected.
// The Admin Live Control Panel listens via ListenableBuilder to show the
// "Now Performing" banner in real time.
// ─────────────────────────────────────────────────────────────────────────────

class LiveSessionState extends ChangeNotifier {
  LiveSessionState._();
  static final LiveSessionState instance = LiveSessionState._();

  // stageId  →  groupId (null = nobody currently being scored)
  final Map<String, String?> _activeGroupPerStage = {};

  String? activeGroupId(String stageId) => _activeGroupPerStage[stageId];

  void setActiveGroup(String stageId, String? groupId) {
    if (_activeGroupPerStage[stageId] == groupId) return;
    _activeGroupPerStage[stageId] = groupId;
    notifyListeners();
  }

  void clearActiveGroup(String stageId) => setActiveGroup(stageId, null);
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
    if (parsed > maxValue) return oldValue; // block if over max
    return newValue;
  }
}