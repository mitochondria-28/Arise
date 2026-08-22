import { useQuery } from "@tanstack/react-query";
import { Link } from "react-router-dom";
import { Target, RefreshCw, Zap, ArrowRight } from "lucide-react";
import { fetchCharacter } from "@/features/character/api";
import { fetchGoals } from "@/features/goals/api";
import { fetchMissions } from "@/features/missions/api";
import { XpBar } from "@/shared/components/ui/XpBar";
import { RankBadge } from "@/shared/components/ui/Badge";
import { Spinner } from "@/shared/components/ui/Spinner";
import { STAT_META } from "@/shared/lib/constants";
import type { StatCategory } from "@/shared/api/types";

export default function DashboardPage() {
  const { data: char, isLoading: charLoading } = useQuery({
    queryKey: ["character"],
    queryFn: fetchCharacter,
  });

  const { data: goals } = useQuery({
    queryKey: ["goals", {}],
    queryFn: () => fetchGoals({ page_size: 100 }),
  });

  const { data: missions } = useQuery({
    queryKey: ["missions", {}],
    queryFn: () => fetchMissions({ status: "active", page_size: 5 }),
  });

  if (charLoading || !char) {
    return (
      <div className="flex items-center justify-center py-20">
        <Spinner size={28} style={{ color: "var(--accent)" } as React.CSSProperties} />
      </div>
    );
  }

  const activeGoals = goals?.goals.filter((g) => g.status === "active").length ?? 0;
  const completedGoals = goals?.goals.filter((g) => g.status === "completed").length ?? 0;
  const topMissions = missions?.missions.slice(0, 3) ?? [];

  const stats = char.stats;

  return (
    <div className="flex flex-col gap-6">
      {/* Hero card */}
      <div
        className="rounded-2xl p-6 relative overflow-hidden"
        style={{
          background: "var(--surface-1)",
          border: "1px solid var(--border)",
        }}
      >
        {/* Subtle accent glow */}
        <div
          className="absolute -top-16 -right-16 w-64 h-64 rounded-full pointer-events-none"
          style={{ background: "var(--accent-dim)", filter: "blur(40px)" }}
        />

        <div className="relative flex items-start justify-between gap-4">
          <div className="flex-1">
            <p className="text-xs font-semibold uppercase tracking-widest mb-1" style={{ color: "var(--text-3)" }}>
              {char.title}
            </p>
            <h1 className="text-3xl font-bold mb-1" style={{ color: "var(--text-1)" }}>
              Level {char.level}
            </h1>
            <p className="text-sm mb-4" style={{ color: "var(--text-2)" }}>
              {char.total_xp.toLocaleString()} total XP
            </p>
            <XpBar
              currentXp={char.current_level_xp}
              xpToNext={char.xp_to_next_level}
            />
          </div>
          <RankBadge rank={char.rank} size="lg" />
        </div>
      </div>

      {/* Quick stats */}
      <div className="grid grid-cols-3 gap-3">
        {[
          { label: "Active Goals", value: activeGoals, Icon: Target, color: "var(--accent)" },
          { label: "Completed", value: completedGoals, Icon: Zap, color: "var(--success)" },
          { label: "Missions", value: missions?.total ?? 0, Icon: RefreshCw, color: "var(--warning)" },
        ].map(({ label, value, Icon, color }) => (
          <div
            key={label}
            className="rounded-xl p-4 flex flex-col gap-2"
            style={{ background: "var(--surface-1)", border: "1px solid var(--border)" }}
          >
            <div className="w-8 h-8 rounded-lg flex items-center justify-center" style={{ background: `${color}1a`, color }}>
              <Icon size={16} />
            </div>
            <div>
              <p className="text-xl font-bold" style={{ color: "var(--text-1)" }}>{value}</p>
              <p className="text-xs" style={{ color: "var(--text-2)" }}>{label}</p>
            </div>
          </div>
        ))}
      </div>

      {/* Stats overview */}
      {stats && (
        <div
          className="rounded-2xl p-5"
          style={{ background: "var(--surface-1)", border: "1px solid var(--border)" }}
        >
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-sm font-semibold" style={{ color: "var(--text-1)" }}>Stats</h2>
            <Link
              to="/character"
              className="text-xs flex items-center gap-1 hover:underline"
              style={{ color: "var(--accent)" }}
            >
              View all <ArrowRight size={12} />
            </Link>
          </div>
          <div className="grid grid-cols-2 sm:grid-cols-3 gap-x-6 gap-y-4">
            {(Object.entries(STAT_META) as [StatCategory, typeof STAT_META[StatCategory]][]).map(([key, meta]) => {
              const value = stats[key];
              return (
                <div key={key}>
                  <div className="flex justify-between text-xs mb-1">
                    <span style={{ color: "var(--text-2)" }}>{meta.label}</span>
                    <span className="font-semibold" style={{ color: meta.color }}>{value}</span>
                  </div>
                  <div className="h-1.5 rounded-full overflow-hidden" style={{ background: "var(--surface-3)" }}>
                    <div
                      className="h-full rounded-full transition-all duration-700"
                      style={{
                        background: meta.color,
                        width: `${Math.min(100, (value / Math.max(1, char.level)) * 100)}%`,
                      }}
                    />
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      )}

      {/* Active missions */}
      {topMissions.length > 0 && (
        <div
          className="rounded-2xl p-5"
          style={{ background: "var(--surface-1)", border: "1px solid var(--border)" }}
        >
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-sm font-semibold" style={{ color: "var(--text-1)" }}>Active Missions</h2>
            <Link
              to="/missions"
              className="text-xs flex items-center gap-1 hover:underline"
              style={{ color: "var(--accent)" }}
            >
              View all <ArrowRight size={12} />
            </Link>
          </div>
          <div className="flex flex-col gap-2">
            {topMissions.map((m) => (
              <div
                key={m.id}
                className="flex items-center justify-between py-2.5 px-3 rounded-lg"
                style={{ background: "var(--surface-2)" }}
              >
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium truncate" style={{ color: "var(--text-1)" }}>{m.title}</p>
                  <p className="text-xs capitalize" style={{ color: "var(--text-3)" }}>{m.frequency}</p>
                </div>
                <div className="flex items-center gap-2 ml-3">
                  {m.can_checkin_now && (
                    <span className="text-xs px-2 py-0.5 rounded-full" style={{ background: "var(--accent-dim)", color: "var(--accent)" }}>
                      Ready
                    </span>
                  )}
                  <div className="text-right">
                    <p className="text-sm font-bold" style={{ color: "var(--xp-color)" }}>
                      {m.current_streak}
                    </p>
                    <p className="text-xs" style={{ color: "var(--text-3)" }}>streak</p>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
