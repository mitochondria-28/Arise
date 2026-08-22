import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { RefreshCw, Trophy, Lock } from "lucide-react";
import { fetchAchievements, syncAchievements } from "./api";
import { Spinner } from "@/shared/components/ui/Spinner";
import type { AchievementCategory, AchievementResponse } from "@/shared/api/types";

// ── Category metadata ──────────────────────────────────────────────────────────

const CATEGORY_META: Record<AchievementCategory, { label: string; color: string }> = {
  xp:       { label: "XP",       color: "#eab308" },
  goals:    { label: "Goals",    color: "#22c55e" },
  streak:   { label: "Streak",   color: "#f97316" },
  missions: { label: "Missions", color: "#a855f7" },
  level:    { label: "Level",    color: "#3b82f6" },
  rank:     { label: "Rank",     color: "#ef4444" },
};

const ALL_CATEGORIES = ["all", ...Object.keys(CATEGORY_META)] as const;
type FilterCategory = typeof ALL_CATEGORIES[number];

// ── Unlock toast ───────────────────────────────────────────────────────────────

function UnlockToast({
  achievements,
  onDismiss,
}: {
  achievements: AchievementResponse[];
  onDismiss: () => void;
}) {
  if (achievements.length === 0) return null;

  return (
    <div
      className="fixed bottom-6 right-6 z-50 flex flex-col gap-2 max-w-xs"
      onClick={onDismiss}
    >
      {achievements.map((a) => (
        <div
          key={a.key}
          className="rounded-xl px-4 py-3 shadow-lg flex items-center gap-3 cursor-pointer"
          style={{
            background: "var(--surface-1)",
            border: `1px solid ${CATEGORY_META[a.category].color}44`,
            boxShadow: `0 0 16px ${CATEGORY_META[a.category].color}22`,
          }}
        >
          <span className="text-2xl">{a.icon}</span>
          <div>
            <p className="text-xs font-semibold uppercase tracking-wide" style={{ color: CATEGORY_META[a.category].color }}>
              Achievement Unlocked!
            </p>
            <p className="text-sm font-bold" style={{ color: "var(--text-1)" }}>
              {a.title}
            </p>
          </div>
        </div>
      ))}
    </div>
  );
}

// ── Achievement card ───────────────────────────────────────────────────────────

function AchievementCard({ a }: { a: AchievementResponse }) {
  const unlocked = a.unlocked_at !== null;
  const meta = CATEGORY_META[a.category];

  return (
    <div
      className="rounded-xl p-4 flex flex-col gap-3 transition-all"
      style={{
        background: unlocked ? "var(--surface-1)" : "var(--surface-1)",
        border: unlocked
          ? `1px solid ${meta.color}44`
          : "1px solid var(--border)",
        opacity: unlocked ? 1 : 0.55,
        boxShadow: unlocked ? `0 0 12px ${meta.color}18` : undefined,
      }}
    >
      {/* Icon row */}
      <div className="flex items-start justify-between">
        <div
          className="w-11 h-11 rounded-xl flex items-center justify-center text-2xl"
          style={{
            background: unlocked ? `${meta.color}18` : "var(--surface-2)",
            filter: unlocked ? undefined : "grayscale(1)",
          }}
        >
          {unlocked ? a.icon : <Lock size={16} style={{ color: "var(--text-3)" }} />}
        </div>
        <span
          className="text-xs font-semibold uppercase tracking-wide px-2 py-0.5 rounded-full"
          style={{
            background: `${meta.color}18`,
            color: unlocked ? meta.color : "var(--text-3)",
          }}
        >
          {meta.label}
        </span>
      </div>

      {/* Text */}
      <div>
        <p
          className="font-semibold text-sm"
          style={{ color: unlocked ? "var(--text-1)" : "var(--text-2)" }}
        >
          {a.title}
        </p>
        <p className="text-xs mt-0.5" style={{ color: "var(--text-3)" }}>
          {a.description}
        </p>
      </div>

      {/* Unlock date or hint */}
      <div>
        {unlocked ? (
          <p className="text-xs" style={{ color: meta.color }}>
            ✓ Unlocked {new Date(a.unlocked_at!).toLocaleDateString()}
          </p>
        ) : (
          <p className="text-xs" style={{ color: "var(--text-3)" }}>
            Locked
          </p>
        )}
      </div>
    </div>
  );
}

// ── Page ───────────────────────────────────────────────────────────────────────

export default function AchievementsPage() {
  const qc = useQueryClient();
  const [filter, setFilter] = useState<FilterCategory>("all");
  const [newlyUnlocked, setNewlyUnlocked] = useState<AchievementResponse[]>([]);

  const { data: achievements, isLoading } = useQuery({
    queryKey: ["achievements"],
    queryFn: fetchAchievements,
  });

  const syncMutation = useMutation({
    mutationFn: syncAchievements,
    onSuccess: (data) => {
      qc.invalidateQueries({ queryKey: ["achievements"] });
      if (data.newly_unlocked.length > 0) {
        setNewlyUnlocked(data.newly_unlocked);
        setTimeout(() => setNewlyUnlocked([]), 6000);
      }
    },
  });

  const filtered =
    filter === "all"
      ? (achievements ?? [])
      : (achievements ?? []).filter((a) => a.category === filter);

  const unlockedCount = (achievements ?? []).filter((a) => a.unlocked_at !== null).length;
  const total = (achievements ?? []).length;

  return (
    <div className="flex flex-col gap-6">
      {/* Header */}
      <div className="flex items-start justify-between">
        <div>
          <h1 className="text-2xl font-bold" style={{ color: "var(--text-1)" }}>
            Achievements
          </h1>
          <p className="text-sm mt-1" style={{ color: "var(--text-2)" }}>
            {isLoading ? "—" : `${unlockedCount} / ${total} unlocked`}
          </p>
        </div>
        <button
          onClick={() => syncMutation.mutate()}
          disabled={syncMutation.isPending}
          className="flex items-center gap-2 px-3 py-2 rounded-lg text-sm font-medium transition-colors"
          style={{
            background: "var(--accent-dim)",
            color: "var(--accent)",
            border: "1px solid var(--accent)",
            opacity: syncMutation.isPending ? 0.6 : 1,
          }}
        >
          {syncMutation.isPending ? (
            <Spinner size={14} style={{ color: "var(--accent)" } as React.CSSProperties} />
          ) : (
            <RefreshCw size={14} />
          )}
          Sync
        </button>
      </div>

      {/* Progress bar */}
      {!isLoading && total > 0 && (
        <div>
          <div className="h-1.5 rounded-full overflow-hidden" style={{ background: "var(--border)" }}>
            <div
              className="h-full rounded-full transition-all duration-700"
              style={{
                width: `${(unlockedCount / total) * 100}%`,
                background: "var(--accent)",
              }}
            />
          </div>
          <p className="text-xs mt-1.5" style={{ color: "var(--text-3)" }}>
            {Math.round((unlockedCount / total) * 100)}% complete
          </p>
        </div>
      )}

      {/* Category filter */}
      <div className="flex gap-2 flex-wrap">
        {ALL_CATEGORIES.map((cat) => {
          const isSelected = filter === cat;
          const meta = cat !== "all" ? CATEGORY_META[cat as AchievementCategory] : null;
          return (
            <button
              key={cat}
              onClick={() => setFilter(cat)}
              className="px-3 py-1.5 rounded-lg text-xs font-semibold transition-colors capitalize"
              style={{
                background: isSelected
                  ? meta
                    ? `${meta.color}18`
                    : "var(--accent-dim)"
                  : "var(--surface-2)",
                color: isSelected
                  ? meta
                    ? meta.color
                    : "var(--accent)"
                  : "var(--text-2)",
                border: isSelected
                  ? `1px solid ${meta ? meta.color + "44" : "var(--accent)"}`
                  : "1px solid transparent",
              }}
            >
              {cat}
            </button>
          );
        })}
      </div>

      {/* Grid */}
      {isLoading ? (
        <div className="flex items-center justify-center py-20">
          <Spinner size={28} style={{ color: "var(--accent)" } as React.CSSProperties} />
        </div>
      ) : filtered.length === 0 ? (
        <div className="flex flex-col items-center gap-3 py-20">
          <Trophy size={36} style={{ color: "var(--text-3)" }} />
          <p className="text-sm" style={{ color: "var(--text-3)" }}>
            No achievements in this category yet
          </p>
        </div>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {filtered.map((a) => (
            <AchievementCard key={a.key} a={a} />
          ))}
        </div>
      )}

      {/* Unlock toast */}
      <UnlockToast
        achievements={newlyUnlocked}
        onDismiss={() => setNewlyUnlocked([])}
      />
    </div>
  );
}
