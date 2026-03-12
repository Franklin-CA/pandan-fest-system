import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pandan_fest/constant/colors.dart';
import 'package:pandan_fest/models/app_models.dart';

// ═══════════════════════════════════════════════════════════════════
// OVERALL WINNER SCREEN
// Shows combined scores from all 3 stages — sum = final ranking
// ═══════════════════════════════════════════════════════════════════

class OverallWinnerScreen extends StatelessWidget {
  const OverallWinnerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rankings = computeOverallRankings(staticGroups, staticStages, staticCriteria);
    final winner = rankings.isNotEmpty ? rankings.first : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('OVERALL RESULTS', style: GoogleFonts.poppins(
                  fontSize: 10, fontWeight: FontWeight.w700,
                  color: AppColors.secondary, letterSpacing: 1.2)),
              ),
              const SizedBox(height: 6),
              Text('Overall Winner', style: GoogleFonts.poppins(
                fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF1C1C1E))),
              Text('Combined score from all 3 stages',
                style: GoogleFonts.poppins(fontSize: 12.5, color: const Color(0xFF6C6C70))),
            ]),
            const Spacer(),
            // Stage summary chips
            ...staticStages.map((s) {
              const colors = [Color(0xFF5856D6), Color(0xFF007AFF), Color(0xFFAF52DE)];
              final c = colors[s.order - 1];
              return Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: c.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: c.withOpacity(0.3)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.flag_rounded, size: 13, color: c),
                    const SizedBox(width: 5),
                    Text(s.name, style: GoogleFonts.poppins(
                      fontSize: 12, fontWeight: FontWeight.w600, color: c)),
                  ]),
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 22),

        // ── Winner Podium (top 3) ──
        if (rankings.length >= 3) _buildPodium(rankings),
        const SizedBox(height: 20),

        // ── Full Rankings Table ──
        Expanded(child: _buildFullTable(rankings)),
      ],
    );
  }

  // ─── PODIUM ───────────────────────────────────────────────────────

  Widget _buildPodium(List<OverallRankingEntry> rankings) {
    const podiumColors = [AppColors.goldRank, AppColors.silverRank, AppColors.bronzeRank];
    const emojis = ['🥇', '🥈', '🥉'];
    const order = [1, 0, 2]; // silver-gold-bronze visual layout
    final podiumHeights = [160.0, 200.0, 130.0];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1B1B2F),
            AppColors.primary.withOpacity(0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withOpacity(0.3),
              blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(children: [
        Text('🏆  Champions Board', style: GoogleFonts.poppins(
          fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text('Sum of all 3 stage scores', style: GoogleFonts.poppins(
          fontSize: 11, color: Colors.white38)),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: order.map((idx) {
            final entry = rankings[idx];
            final color = podiumColors[idx];
            final emoji = emojis[idx];
            final height = podiumHeights[idx];
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Crown / emoji
                    Text(emoji, style: TextStyle(fontSize: idx == 0 ? 32 : 24)),
                    const SizedBox(height: 6),
                    // Name
                    Text(entry.groupName,
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold,
                          color: color), textAlign: TextAlign.center,
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(entry.barangay, style: GoogleFonts.poppins(
                      fontSize: 10, color: Colors.white38), textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    // Score breakdown chips
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 4, runSpacing: 4,
                      children: staticStages.map((s) {
                        final sc = entry.stageScores[s.id] ?? 0.0;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('${s.name}: ${sc.toStringAsFixed(1)}',
                            style: GoogleFonts.poppins(fontSize: 9, color: Colors.white60)),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    // Total score
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: color.withOpacity(0.4)),
                      ),
                      child: Text(entry.totalScore.toStringAsFixed(2),
                        style: GoogleFonts.poppins(
                          fontSize: idx == 0 ? 20 : 16, fontWeight: FontWeight.bold, color: color)),
                    ),
                    const SizedBox(height: 10),
                    // Podium block
                    Container(
                      height: height,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.22),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                        border: Border.all(color: color.withOpacity(0.35)),
                      ),
                      child: Center(
                        child: Text('#${entry.rank}', style: GoogleFonts.poppins(
                          fontSize: 28, fontWeight: FontWeight.bold,
                          color: color.withOpacity(0.6))),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ]),
    );
  }

  // ─── FULL TABLE ────────────────────────────────────────────────────

  Widget _buildFullTable(List<OverallRankingEntry> rankings) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(children: [
        // Table header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: const BoxDecoration(
            color: Color(0xFF1B1B2F),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Row(children: [
            SizedBox(width: 40, child: Text('Rank', style: _headerStyle)),
            const SizedBox(width: 14),
            Expanded(child: Text('Group', style: _headerStyle)),
            ...staticStages.map((s) => SizedBox(
              width: 90,
              child: Text(s.name, style: _headerStyle, textAlign: TextAlign.center),
            )),
            SizedBox(width: 100, child: Text('Total', style: _headerStyle, textAlign: TextAlign.right)),
          ]),
        ),
        // Rows
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: rankings.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE5E5EA)),
            itemBuilder: (_, i) => _TableRow(entry: rankings[i]),
          ),
        ),
      ]),
    );
  }

  TextStyle get _headerStyle => GoogleFonts.poppins(
    fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white70, letterSpacing: 0.5);
}

// ─── TABLE ROW ──────────────────────────────────────────────────────

class _TableRow extends StatelessWidget {
  final OverallRankingEntry entry;
  const _TableRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final rc = {
      1: AppColors.goldRank,
      2: AppColors.silverRank,
      3: AppColors.bronzeRank,
    }[entry.rank] ?? const Color(0xFF8E8E93);

    const stageColors = [Color(0xFF5856D6), Color(0xFF007AFF), Color(0xFFAF52DE)];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: entry.rank <= 3 ? rc.withOpacity(0.04) : Colors.transparent,
      ),
      child: Row(children: [
        // Rank badge
        SizedBox(
          width: 40,
          child: entry.rank <= 3
              ? Text(entry.rank == 1 ? '🥇' : entry.rank == 2 ? '🥈' : '🥉',
                  style: const TextStyle(fontSize: 20))
              : Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F7), borderRadius: BorderRadius.circular(8)),
                  child: Center(child: Text('#${entry.rank}',
                    style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold,
                        color: const Color(0xFF6C6C70))))),
        ),
        const SizedBox(width: 14),
        // Group info
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(entry.groupName, style: GoogleFonts.poppins(
            fontSize: 13, fontWeight: FontWeight.w600,
            color: entry.rank <= 3 ? rc : const Color(0xFF1C1C1E))),
          Text(entry.barangay, style: GoogleFonts.poppins(
            fontSize: 11, color: const Color(0xFF8E8E93))),
        ])),
        // Per-stage scores
        ...staticStages.asMap().entries.map((e) {
          final stage = e.value;
          final sc = entry.stageScores[stage.id] ?? 0.0;
          final color = stageColors[e.key];
          return SizedBox(
            width: 90,
            child: Center(
              child: sc == 0.0
                  ? Text('—', style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFFAEAEB2)))
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(sc.toStringAsFixed(2),
                        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
                    ),
            ),
          );
        }),
        // Total score
        SizedBox(
          width: 100,
          child: Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: rc.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: rc.withOpacity(0.25)),
              ),
              child: Text(entry.totalScore.toStringAsFixed(2),
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: rc)),
            ),
          ),
        ),
      ]),
    );
  }
}