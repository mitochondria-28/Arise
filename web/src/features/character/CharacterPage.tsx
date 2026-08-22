import { useQuery } from "@tanstack/react-query";
import { fetchCharacter } from "./api";
import { XpBar } from "@/shared/components/ui/XpBar";
import { RankBadge } from "@/shared/components/ui/Badge";
import { Spinner } from "@/shared/components/ui/Spinner";
import { STAT_META } from "@/shared/lib/constants";
import type { StatCategory } from "@/shared/api/types";

export default function CharacterPage() {
  const { data: char, isLoading } = useQuery({
    queryKey: ["character"],
    queryFn: fetchCharacter,
  });

  if (isLoading || !char) {
    return (
      <div className="flex items-center justify-center py-20">
        <Spinner size={28} style={{ color: "var(--accent)" } as React.CSSProperties} />
      </div>
    );
  }

  const stats = char.stats;

  return (
    <div className="flex flex-col gap-6">
      <div>
        <h1 className="text-2xl font-bold" style={{ color: "var(--text-1)" }}>Character</h1>
        <p className="text-sm mt-1" style={{ color: "var(--text-2)" }}>
          Your progression and attributes
        </p>
      </div>

      {/* Hero */}
      <div
        className="rounded-2xl p-6 relative overflow-hidden"
        style={{ background: "var(--surface-1)", border: "1px solid var(--border)" }}
      >
        <div className="absolute -top-12 -right-12 w-56 h-56 rounded-full pointer-events-none"
          style={{ background: "var(--accent-dim)", filter: "blur(40px)" }} />

        <div className="relative">
          <div className="flex items-start justify-between gap-4 mb-6">
            <div>
              <p className="text-xs uppercase tracking-widest font-semibold mb-1" style={{ color: "var(--text-3)" }}>
                {char.title}
              </p>
              <h2 className="text-4xl font-extrabold mb-0.5" style={{ color: "var(--text-1)" }}>
                Level {char.level}
              </h2>
              <p className="text-sm" style={{ color: "var(--text-2)" }}>
                {char.total_xp.toLocaleString()} total XP earned
              </p>
            </div>
            <RankBadge rank={char.rank} size="lg" />
          </div>

          <XpBar
            currentXp={char.current_level_xp}
            xpToNext={char.xp_to_next_level}
            height={8}
          />
        </div>
      </div>

      {/* Rank info */}
      <div
        className="rounded-2xl p-5"
        style={{ background: "var(--surface-1)", border: "1px solid var(--border)" }}
      >
        <h3 className="text-sm font-semibold mb-3" style={{ color: "var(--text-1)" }}>
          Rank Progression
        </h3>
        <div className="flex items-center gap-3 overflow-x-auto pb-1">
          {["E", "D", "C", "B", "A", "S"].map((r) => {
            const isCurrent = r === char.rank;
            const thresholds: Record<string, string> = {
              E: "Lv 1–4", D: "Lv 5–9", C: "Lv 10–19",
              B: "Lv 20–29", A: "Lv 30–49", S: "Lv 50+",
            };
            return (
              <div key={r} className="flex flex-col items-center gap-1.5 flex-none">
                <RankBadge
                  rank={r}
                  size="md"
                  className={isCurrent ? "" : "opacity-40"}
                />
                <span className="text-xs" style={{ color: "var(--text-3)" }}>
                  {thresholds[r]}
                </span>
                {isCurrent && (
                  <span className="text-xs font-medium" style={{ color: "var(--accent)" }}>
                    Current
                  </span>
                )}
              </div>
            );
          })}
        </div>
      </div>

      {/* Stats */}
      {stats && (
        <div
          className="rounded-2xl p-5"
          style={{ background: "var(--surface-1)", border: "1px solid var(--border)" }}
        >
          <h3 className="text-sm font-semibold mb-4" style={{ color: "var(--text-1)" }}>
            Attributes
          </h3>
          <div className="flex flex-col gap-4">
            {(Object.entries(STAT_META) as [StatCategory, typeof STAT_META[StatCategory]][]).map(
              ([key, meta]) => {
                const value = stats[key];
                const max = Math.max(char.level, 1);
                const pct = Math.min(100, (value / max) * 100);
                return (
                  <div key={key}>
                    <div className="flex items-center justify-between mb-2">
                      <span className="text-sm font-medium" style={{ color: "var(--text-1)" }}>
                        {meta.label}
                      </span>
                      <span className="text-sm font-bold tabular-nums" style={{ color: meta.color }}>
                        {value}
                      </span>
                    </div>
                    <div
                      className="h-2 rounded-full overflow-hidden"
                      style={{ background: "var(--surface-3)" }}
                    >
                      <div
                        className="h-full rounded-full transition-all duration-700"
                        style={{ background: meta.color, width: `${pct}%` }}
                      />
                    </div>
                  </div>
                );
              }
            )}
          </div>
        </div>
      )}
    </div>
  );
}
