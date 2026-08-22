import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { Flame, Star, TrendingUp, CheckCircle2, Target, Zap } from "lucide-react";
import {
  LineChart, Line, XAxis, YAxis, Tooltip, Legend, ResponsiveContainer,
} from "recharts";
import { fetchStatsSummary, fetchXPHistory, fetchStatHistory } from "./api";
import { Spinner } from "@/shared/components/ui/Spinner";
import { RankBadge } from "@/shared/components/ui/Badge";
import { DIFFICULTY_META, RANK_META } from "@/shared/lib/constants";
import type { StatsSummaryResponse, XPDayEntry } from "@/shared/api/types";

// ── Helpers ────────────────────────────────────────────────────────────────────

function formatXP(xp: number): string {
  if (xp >= 1_000_000) return `${(xp / 1_000_000).toFixed(1)}M`;
  if (xp >= 1_000) return `${(xp / 1_000).toFixed(1)}k`;
  return String(xp);
}

function capitalize(s: string) {
  return s.charAt(0).toUpperCase() + s.slice(1);
}

// ── Stat card ──────────────────────────────────────────────────────────────────

function StatCard({
  label,
  value,
  sub,
  icon: Icon,
  color,
}: {
  label: string;
  value: string;
  sub?: React.ReactNode;
  icon: React.FC<{ size?: number }>;
  color: string;
}) {
  return (
    <div
      className="rounded-xl p-4 flex flex-col gap-2"
      style={{ background: "var(--surface-1)", border: "1px solid var(--border)" }}
    >
      <div className="flex items-center gap-1.5">
        <Icon size={14} />
        <span className="text-xs font-medium" style={{ color: "var(--text-3)" }}>
          {label}
        </span>
      </div>
      <div className="flex items-baseline gap-1.5">
        <span className="text-3xl font-extrabold" style={{ color }}>
          {value}
        </span>
        {sub && (
          <span className="text-xs" style={{ color: "var(--text-3)" }}>
            {sub}
          </span>
        )}
      </div>
    </div>
  );
}

// ── XP bar chart ──────────────────────────────────────────────────────────────

function XPBarChart({ entries }: { entries: XPDayEntry[] }) {
  const maxXp = Math.max(...entries.map((e) => e.xp), 1);

  if (entries.every((e) => e.xp === 0)) {
    return (
      <div className="h-28 flex items-center justify-center">
        <span className="text-sm" style={{ color: "var(--text-3)" }}>
          No XP activity in this period
        </span>
      </div>
    );
  }

  return (
    <div className="flex items-end gap-0.5 h-28 w-full">
      {entries.map((entry, i) => {
        const totalH = (entry.xp / maxXp) * 100;
        const goalFrac = entry.xp > 0 ? entry.goal_xp / entry.xp : 0;
        const missionH = totalH * (1 - goalFrac);
        const goalH = totalH * goalFrac;
        return (
          <div
            key={i}
            className="flex-1 flex flex-col justify-end"
            title={`${entry.date}\n+${entry.xp} XP (goals: ${entry.goal_xp}, missions: ${entry.mission_xp})`}
          >
            {missionH > 0 && (
              <div
                className="w-full rounded-t"
                style={{
                  height: `${missionH}%`,
                  background: "#a855f7cc",
                  borderRadius: goalH > 0 ? "2px 2px 0 0" : "2px",
                }}
              />
            )}
            {goalH > 0 && (
              <div
                className="w-full"
                style={{
                  height: `${goalH}%`,
                  background: "#3b82f6cc",
                  borderRadius: missionH > 0 ? "0" : "2px 2px 0 0",
                }}
              />
            )}
          </div>
        );
      })}
    </div>
  );
}

// ── Progress row ───────────────────────────────────────────────────────────────

function ProgressRow({
  label,
  value,
  total,
  color,
}: {
  label: string;
  value: number;
  total: number;
  color: string;
}) {
  const pct = total > 0 ? Math.round((value / total) * 100) : 0;

  return (
    <div className="flex items-center gap-3">
      <span className="w-24 text-sm shrink-0" style={{ color: "var(--text-2)" }}>
        {label}
      </span>
      <div className="flex-1 h-1.5 rounded-full overflow-hidden" style={{ background: `${color}22` }}>
        <div
          className="h-full rounded-full transition-all duration-500"
          style={{ width: `${pct}%`, background: color }}
        />
      </div>
      <span className="text-xs w-6 text-right font-semibold" style={{ color: "var(--text-3)" }}>
        {value}
      </span>
    </div>
  );
}

// ── Summary section ────────────────────────────────────────────────────────────

function SummaryCards({ s }: { s: StatsSummaryResponse }) {
  const rankColor = RANK_META[s.rank]?.color ?? "#6b7280";
  return (
    <div className="grid grid-cols-2 md:grid-cols-3 gap-3">
      <StatCard
        label="Total XP"
        value={formatXP(s.total_xp)}
        icon={Star}
        color="#eab308"
      />
      <StatCard
        label="Level"
        value={`${s.current_level}`}
        sub={<RankBadge rank={s.rank} />}
        icon={TrendingUp}
        color={rankColor}
      />
      <StatCard
        label="Goals Done"
        value={`${s.goals_completed}`}
        icon={Target}
        color="#22c55e"
      />
      <StatCard
        label="Check-ins"
        value={`${s.total_checkins}`}
        icon={CheckCircle2}
        color="#a855f7"
      />
      <StatCard
        label="Best Streak"
        value={`${s.best_streak}`}
        sub="days"
        icon={Flame}
        color="#f97316"
      />
      <StatCard
        label="Active Missions"
        value={`${s.missions_active}`}
        icon={Zap}
        color="#ef4444"
      />
    </div>
  );
}

// ── Goals breakdown section ────────────────────────────────────────────────────

function GoalsBreakdown({ s }: { s: StatsSummaryResponse }) {
  const byDiff = Object.entries(s.goals_by_difficulty).sort((a, b) => b[1] - a[1]);
  const byCat = Object.entries(s.goals_by_category).sort((a, b) => b[1] - a[1]);

  return (
    <div
      className="rounded-xl p-5 flex flex-col gap-5"
      style={{ background: "var(--surface-1)", border: "1px solid var(--border)" }}
    >
      <h3 className="font-semibold" style={{ color: "var(--text-1)" }}>Goals Breakdown</h3>

      {byDiff.length > 0 && (
        <div className="flex flex-col gap-3">
          <span className="text-xs font-medium uppercase tracking-wider" style={{ color: "var(--text-3)" }}>
            By Difficulty
          </span>
          {byDiff.map(([d, v]) => (
            <ProgressRow
              key={d}
              label={capitalize(d)}
              value={v}
              total={s.goals_completed}
              color={DIFFICULTY_META[d as keyof typeof DIFFICULTY_META]?.color ?? "#6b7280"}
            />
          ))}
        </div>
      )}

      {byCat.length > 0 && (
        <div className="flex flex-col gap-3">
          <span className="text-xs font-medium uppercase tracking-wider" style={{ color: "var(--text-3)" }}>
            By Category
          </span>
          {byCat.map(([c, v]) => (
            <ProgressRow
              key={c}
              label={capitalize(c)}
              value={v}
              total={s.goals_completed}
              color="var(--accent)"
            />
          ))}
        </div>
      )}
    </div>
  );
}

// ── Top missions section ───────────────────────────────────────────────────────

function TopMissions({ s }: { s: StatsSummaryResponse }) {
  if (s.top_missions.length === 0) return null;

  return (
    <div
      className="rounded-xl p-5 flex flex-col gap-4"
      style={{ background: "var(--surface-1)", border: "1px solid var(--border)" }}
    >
      <h3 className="font-semibold" style={{ color: "var(--text-1)" }}>Top Missions by Streak</h3>
      <div className="flex flex-col gap-3">
        {s.top_missions.map((m, i) => (
          <div key={i} className="flex items-center gap-3">
            <span className="text-xs font-bold w-4 text-right" style={{ color: "var(--text-3)" }}>
              {i + 1}
            </span>
            <div className="flex-1 min-w-0">
              <p className="text-sm font-medium truncate" style={{ color: "var(--text-1)" }}>
                {m.title}
              </p>
              <p className="text-xs" style={{ color: "var(--text-3)" }}>
                {m.completion_count} check-ins · {capitalize(m.frequency)}
              </p>
            </div>
            <div className="text-right shrink-0">
              <div className="flex items-center gap-1 justify-end">
                <Flame size={13} style={{ color: "#f97316" }} />
                <span className="text-sm font-bold" style={{ color: "#f97316" }}>
                  {m.current_streak}
                </span>
              </div>
              <span className="text-xs" style={{ color: "var(--text-3)" }}>
                best: {m.longest_streak}
              </span>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

// ── XP History section ─────────────────────────────────────────────────────────

const DAY_OPTIONS = [7, 30, 90] as const;

function XPHistorySection() {
  const [days, setDays] = useState<7 | 30 | 90>(30);

  const { data: history, isLoading } = useQuery({
    queryKey: ["xp-history", days],
    queryFn: () => fetchXPHistory(days),
  });

  return (
    <div
      className="rounded-xl p-5 flex flex-col gap-4"
      style={{ background: "var(--surface-1)", border: "1px solid var(--border)" }}
    >
      <div className="flex items-center justify-between">
        <h3 className="font-semibold" style={{ color: "var(--text-1)" }}>XP History</h3>
        <div className="flex gap-1">
          {DAY_OPTIONS.map((d) => (
            <button
              key={d}
              onClick={() => setDays(d)}
              className="px-2.5 py-1 rounded-md text-xs font-medium transition-colors"
              style={{
                background: days === d ? "var(--accent-dim)" : "transparent",
                color: days === d ? "var(--accent)" : "var(--text-3)",
                border: `1px solid ${days === d ? "var(--accent)" : "transparent"}`,
              }}
            >
              {d}d
            </button>
          ))}
        </div>
      </div>

      {isLoading ? (
        <div className="h-28 flex items-center justify-center">
          <Spinner size={20} style={{ color: "var(--accent)" } as React.CSSProperties} />
        </div>
      ) : history ? (
        <>
          <XPBarChart entries={history.entries} />
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4">
              <div className="flex items-center gap-1.5">
                <div className="w-2.5 h-2.5 rounded-sm" style={{ background: "#3b82f6cc" }} />
                <span className="text-xs" style={{ color: "var(--text-3)" }}>Goals</span>
              </div>
              <div className="flex items-center gap-1.5">
                <div className="w-2.5 h-2.5 rounded-sm" style={{ background: "#a855f7cc" }} />
                <span className="text-xs" style={{ color: "var(--text-3)" }}>Missions</span>
              </div>
            </div>
            <span className="text-xs" style={{ color: "var(--text-3)" }}>
              {formatXP(history.total_xp_in_period)} XP in {history.days}d
            </span>
          </div>
        </>
      ) : null}
    </div>
  );
}

// ── Stat Trend Chart ──────────────────────────────────────────────────────────

const STAT_COLORS: Record<string, string> = {
  vitality:     "#ef4444",
  strength:     "#f97316",
  intelligence: "#3b82f6",
  wisdom:       "#8b5cf6",
  charisma:     "#ec4899",
  discipline:   "#22c55e",
};

const STAT_KEYS = ["vitality", "strength", "intelligence", "wisdom", "charisma", "discipline"] as const;

function StatTrendSection() {
  const [days, setDays] = useState<7 | 30 | 90>(30);
  const [activeStats, setActiveStats] = useState<Set<string>>(
    new Set(["vitality", "strength", "intelligence"])
  );

  const { data: history, isLoading } = useQuery({
    queryKey: ["stat-history", days],
    queryFn: () => fetchStatHistory(days),
  });

  function toggleStat(stat: string) {
    setActiveStats((prev) => {
      const next = new Set(prev);
      if (next.has(stat)) {
        if (next.size > 1) next.delete(stat);
      } else {
        next.add(stat);
      }
      return next;
    });
  }

  return (
    <div
      className="rounded-xl p-5 flex flex-col gap-4"
      style={{ background: "var(--surface-1)", border: "1px solid var(--border)" }}
    >
      <div className="flex items-center justify-between flex-wrap gap-2">
        <h3 className="font-semibold" style={{ color: "var(--text-1)" }}>Stat Trends</h3>
        <div className="flex gap-1">
          {([7, 30, 90] as const).map((d) => (
            <button
              key={d}
              onClick={() => setDays(d)}
              className="px-2.5 py-1 rounded-md text-xs font-medium transition-colors"
              style={{
                background: days === d ? "var(--accent-dim)" : "transparent",
                color: days === d ? "var(--accent)" : "var(--text-3)",
                border: `1px solid ${days === d ? "var(--accent)" : "transparent"}`,
              }}
            >
              {d}d
            </button>
          ))}
        </div>
      </div>

      <div className="flex flex-wrap gap-2">
        {STAT_KEYS.map((stat) => (
          <button
            key={stat}
            onClick={() => toggleStat(stat)}
            className="px-2 py-0.5 rounded-full text-xs font-medium transition-all"
            style={{
              background: activeStats.has(stat) ? `${STAT_COLORS[stat]}22` : "transparent",
              color: activeStats.has(stat) ? STAT_COLORS[stat] : "var(--text-3)",
              border: `1px solid ${activeStats.has(stat) ? STAT_COLORS[stat] : "var(--border)"}`,
            }}
          >
            {stat.charAt(0).toUpperCase() + stat.slice(1)}
          </button>
        ))}
      </div>

      {isLoading ? (
        <div className="h-48 flex items-center justify-center">
          <Spinner size={20} style={{ color: "var(--accent)" } as React.CSSProperties} />
        </div>
      ) : !history || history.entries.length === 0 ? (
        <div className="h-48 flex items-center justify-center">
          <span className="text-sm" style={{ color: "var(--text-3)" }}>
            No stat history yet — complete goals or missions to record data
          </span>
        </div>
      ) : (
        <ResponsiveContainer width="100%" height={220}>
          <LineChart data={history.entries} margin={{ top: 4, right: 8, left: -16, bottom: 0 }}>
            <XAxis
              dataKey="date"
              tickFormatter={(v: string) => v.slice(5)}
              tick={{ fontSize: 10, fill: "var(--text-3)" }}
              tickLine={false}
              axisLine={false}
            />
            <YAxis
              tick={{ fontSize: 10, fill: "var(--text-3)" }}
              tickLine={false}
              axisLine={false}
            />
            <Tooltip
              contentStyle={{
                background: "var(--surface-2)",
                border: "1px solid var(--border)",
                borderRadius: 8,
                fontSize: 12,
              }}
              labelStyle={{ color: "var(--text-2)", marginBottom: 4 }}
            />
            <Legend
              wrapperStyle={{ fontSize: 11, color: "var(--text-3)" }}
              iconType="circle"
              iconSize={8}
            />
            {STAT_KEYS.filter((s) => activeStats.has(s)).map((stat) => (
              <Line
                key={stat}
                type="monotone"
                dataKey={stat}
                stroke={STAT_COLORS[stat]}
                strokeWidth={2}
                dot={false}
                activeDot={{ r: 4 }}
              />
            ))}
          </LineChart>
        </ResponsiveContainer>
      )}
    </div>
  );
}

// ── Page ───────────────────────────────────────────────────────────────────────

export default function ProgressPage() {
  const { data: summary, isLoading } = useQuery({
    queryKey: ["stats-summary"],
    queryFn: fetchStatsSummary,
  });

  return (
    <div className="flex flex-col gap-6">
      <div>
        <h1 className="text-2xl font-bold" style={{ color: "var(--text-1)" }}>Progress</h1>
        <p className="text-sm mt-1" style={{ color: "var(--text-2)" }}>
          Your journey at a glance
        </p>
      </div>

      {isLoading || !summary ? (
        <div className="flex items-center justify-center py-20">
          <Spinner size={28} style={{ color: "var(--accent)" } as React.CSSProperties} />
        </div>
      ) : (
        <>
          <SummaryCards s={summary} />
          <XPHistorySection />
          <StatTrendSection />
          {summary.goals_completed > 0 && <GoalsBreakdown s={summary} />}
          <TopMissions s={summary} />
        </>
      )}
    </div>
  );
}
