import { cn } from "@/shared/lib/cn";
import { STAT_META, DIFFICULTY_META, FREQUENCY_META, RANK_META } from "@/shared/lib/constants";
import type { StatCategory, GoalDifficulty, MissionFrequency } from "@/shared/api/types";

interface BadgeProps {
  className?: string;
}

function pillStyle(color: string) {
  return {
    background: `${color}1a`,
    color,
    border: `1px solid ${color}33`,
  };
}

export function StatBadge({ category, className }: { category: StatCategory } & BadgeProps) {
  const meta = STAT_META[category];
  return (
    <span
      className={cn("inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium", className)}
      style={pillStyle(meta.color)}
    >
      {meta.label}
    </span>
  );
}

export function DifficultyBadge({ difficulty, className }: { difficulty: GoalDifficulty } & BadgeProps) {
  const meta = DIFFICULTY_META[difficulty];
  return (
    <span
      className={cn("inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium", className)}
      style={pillStyle(meta.color)}
    >
      {meta.label}
    </span>
  );
}

export function FrequencyBadge({ frequency, className }: { frequency: MissionFrequency } & BadgeProps) {
  const meta = FREQUENCY_META[frequency];
  return (
    <span
      className={cn("inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium bg-[var(--surface-2)] border border-[var(--border)]", className)}
      style={{ color: "var(--text-2)" }}
    >
      {meta.label}
    </span>
  );
}

export function StatusBadge({ status, className }: { status: string } & BadgeProps) {
  const styles: Record<string, { bg: string; color: string }> = {
    active:    { bg: "var(--accent-dim)", color: "var(--accent)" },
    completed: { bg: "rgba(52,211,153,0.12)", color: "var(--success)" },
    paused:    { bg: "rgba(251,191,36,0.12)", color: "var(--warning)" },
    archived:  { bg: "var(--surface-2)", color: "var(--text-3)" },
    abandoned: { bg: "var(--surface-2)", color: "var(--text-3)" },
  };
  const s = styles[status] ?? styles.archived;
  return (
    <span
      className={cn("inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium capitalize", className)}
      style={{ background: s.bg, color: s.color }}
    >
      {status}
    </span>
  );
}

export function RankBadge({ rank, size = "sm", className }: { rank: string; size?: "sm" | "md" | "lg" } & BadgeProps) {
  const meta = RANK_META[rank] ?? { color: "#6b7280", glow: false };
  const sizes = { sm: "w-7 h-7 text-sm", md: "w-10 h-10 text-base", lg: "w-16 h-16 text-2xl" };
  return (
    <span
      className={cn("inline-flex items-center justify-center rounded-full font-bold", sizes[size], className)}
      style={{
        background: `${meta.color}22`,
        color: meta.color,
        border: `2px solid ${meta.color}66`,
        boxShadow: meta.glow ? `0 0 12px ${meta.color}55` : undefined,
      }}
    >
      {rank}
    </span>
  );
}
