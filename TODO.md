# PandanFest Admin Dashboard Fix Plan

## Completed Steps
- [] Fixed import conflicts (judges.dart AppColors duplicate removed)
- [] Added missing imports (GoogleFonts, models, services)

## Pending Fixes for lib/admin/admin_dashboard.dart (Primary Blocker)
1. [ ] Add missing fields/methods:
   - double _penaltyBadge = 2.5;
   - Widget _buildPage() { if (_sel == 0) return _buildDashboardHome(); return _PlaceholderPage('Page $_sel', Icons.star); }
   - List<Map<String, dynamic>> _getDashboardCards() => [...] (stat cards data)
   - void onNavigate(int index) { setState(() => _sel = index); }
   - Widget _buildWelcomeBanner() => Container(...) (sample banner)

2. [ ] Fix GridView.builder syntax (lines 263-280):
   - final card = _getDashboardCards()[index];
   - return DashboardCard(title: card['title'], ... , onTap: () => onNavigate(card['navIndex']));

3. [ ] Define DashboardCard widget class.

4. [ ] Import lib/models/app_models.dart for kGroups, rankedGroups.

## Other Files
5. [ ] lib/admin/live_control_panel.dart: Fix unmatched [, duplicate methods, add imports
6. [ ] lib/judge/judge_scoring_screen.dart: Fix StatefulWidget conversions, props
7. [ ] Global: Fix withOpacity → .withValues(alpha: ...) deprecations

## Testing
- [ ] flutter pub get
- [ ] flutter analyze (0 errors)
- [ ] flutter run -d chrome (app loads AdminDashboard)

**Next: Fix admin_dashboard.dart missing methods/syntax**

