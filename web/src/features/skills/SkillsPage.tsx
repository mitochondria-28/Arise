import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Zap, Lock, Unlock } from "lucide-react";
import { fetchCatalog, fetchMySkills, unlockSkill, practiceSkill } from "./api";
import { Spinner } from "@/shared/components/ui/Spinner";
import { Button } from "@/shared/components/ui/Button";
import { Modal } from "@/shared/components/ui/Modal";
import type { SkillResponse, StatCategory, UserSkillResponse } from "@/shared/api/types";

// ── Constants ──────────────────────────────────────────────────────────────────

const CATEGORIES: StatCategory[] = [
  "vitality", "strength", "intelligence", "wisdom", "charisma", "discipline",
];

const CAT_COLOR: Record<StatCategory, string> = {
  vitality:     "#22c55e",
  strength:     "#ef4444",
  intelligence: "#3b82f6",
  wisdom:       "#a855f7",
  charisma:     "#ec4899",
  discipline:   "#f97316",
};

const MAX_LEVEL = 10;

// ── Level ring ─────────────────────────────────────────────────────────────────

function LevelRing({ level, color }: { level: number; color: string }) {
  const pct = (level / MAX_LEVEL) * 100;
  const r = 20;
  const circ = 2 * Math.PI * r;
  const dash = (pct / 100) * circ;

  return (
    <div className="relative flex items-center justify-center" style={{ width: 52, height: 52 }}>
      <svg width={52} height={52} style={{ transform: "rotate(-90deg)" }}>
        <circle cx={26} cy={26} r={r} fill="none" stroke="var(--border)" strokeWidth={4} />
        <circle
          cx={26} cy={26} r={r} fill="none"
          stroke={color} strokeWidth={4}
          strokeDasharray={`${dash} ${circ - dash}`}
          strokeLinecap="round"
        />
      </svg>
      <span
        className="absolute text-sm font-bold"
        style={{ color }}
      >
        {level}
      </span>
    </div>
  );
}

// ── Practice modal ─────────────────────────────────────────────────────────────

function PracticeModal({
  userSkill,
  onClose,
}: {
  userSkill: UserSkillResponse;
  onClose: () => void;
}) {
  const qc = useQueryClient();
  const [notes, setNotes] = useState("");
  const [duration, setDuration] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [result, setResult] = useState<{ xp: number; leveled_up: boolean; new_level: number } | null>(null);

  const { mutate, isPending } = useMutation({
    mutationFn: () =>
      practiceSkill(userSkill.skill_id, {
        notes,
        duration_minutes: duration ? parseInt(duration, 10) : undefined,
      }),
    onSuccess: (data) => {
      qc.invalidateQueries({ queryKey: ["skills", "me"] });
      setResult({
        xp: data.xp_awarded,
        leveled_up: data.leveled_up,
        new_level: data.user_skill.level,
      });
    },
    onError: (e: Error) => setError(e.message),
  });

  const color = CAT_COLOR[userSkill.skill.category as StatCategory];

  return (
    <Modal open onClose={onClose} title={`Practice · ${userSkill.skill.emoji} ${userSkill.skill.name}`} size="sm">
      {result ? (
        <div className="flex flex-col items-center gap-4 py-4 text-center">
          <span className="text-4xl">{userSkill.skill.emoji}</span>
          <p className="text-2xl font-bold" style={{ color }}>+{result.xp} XP</p>
          {result.leveled_up && (
            <p className="text-sm font-semibold" style={{ color }}>
              Level up! Now Level {result.new_level}
            </p>
          )}
          <p className="text-sm" style={{ color: "var(--text-2)" }}>
            Great work. Keep the momentum going.
          </p>
          <Button onClick={onClose} className="w-full">Done</Button>
        </div>
      ) : (
        <div className="flex flex-col gap-4">
          <div className="flex items-center gap-3">
            <LevelRing level={userSkill.level} color={color} />
            <div>
              <p className="text-sm font-semibold" style={{ color: "var(--text-1)" }}>
                Level {userSkill.level} · {userSkill.session_count} sessions
              </p>
              {userSkill.level < MAX_LEVEL ? (
                <p className="text-xs" style={{ color: "var(--text-3)" }}>
                  {userSkill.sessions_to_next_level} more to Level {userSkill.level + 1}
                </p>
              ) : (
                <p className="text-xs" style={{ color }}>Max Level</p>
              )}
              <p className="text-xs mt-0.5" style={{ color }}>
                +{userSkill.xp_per_session} XP this session
              </p>
            </div>
          </div>

          {error && (
            <p className="text-xs px-3 py-2 rounded-lg" style={{ background: "#ef444422", color: "#ef4444" }}>
              {error}
            </p>
          )}

          <div className="flex flex-col gap-1.5">
            <label className="text-xs font-medium" style={{ color: "var(--text-2)" }}>
              What did you practice? *
            </label>
            <textarea
              className="w-full rounded-lg px-3 py-2.5 text-sm resize-none"
              style={{
                background: "var(--surface-2)",
                border: "1px solid var(--border)",
                color: "var(--text-1)",
                minHeight: 80,
              }}
              placeholder="Describe what you actually did (min 10 characters)..."
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
            />
          </div>

          <div className="flex flex-col gap-1.5">
            <label className="text-xs font-medium" style={{ color: "var(--text-2)" }}>
              Duration (minutes, optional)
            </label>
            <input
              type="number"
              min={1}
              max={480}
              className="w-full rounded-lg px-3 py-2.5 text-sm"
              style={{
                background: "var(--surface-2)",
                border: "1px solid var(--border)",
                color: "var(--text-1)",
              }}
              placeholder="e.g. 30"
              value={duration}
              onChange={(e) => setDuration(e.target.value)}
            />
            <p className="text-xs" style={{ color: "var(--text-3)" }}>
              Longer sessions (30+ min) earn bonus XP (up to 2×).
            </p>
          </div>

          <Button
            onClick={() => mutate()}
            disabled={notes.length < 10 || isPending}
            className="w-full"
          >
            {isPending ? <Spinner /> : `Log Practice · +${userSkill.xp_per_session} XP`}
          </Button>
        </div>
      )}
    </Modal>
  );
}

// ── My skill card ──────────────────────────────────────────────────────────────

function MySkillCard({
  us,
  onPractice,
}: {
  us: UserSkillResponse;
  onPractice: () => void;
}) {
  const color = CAT_COLOR[us.skill.category as StatCategory];

  return (
    <div
      className="rounded-xl p-4 flex flex-col gap-3"
      style={{
        background: "var(--surface-1)",
        border: `1px solid ${color}33`,
        boxShadow: `0 0 10px ${color}0d`,
      }}
    >
      <div className="flex items-start gap-3">
        <LevelRing level={us.level} color={color} />
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2 flex-wrap">
            <span className="text-lg">{us.skill.emoji}</span>
            <span className="font-semibold text-sm truncate" style={{ color: "var(--text-1)" }}>
              {us.skill.name}
            </span>
          </div>
          <span
            className="inline-block mt-1 text-[10px] font-semibold uppercase tracking-wide px-2 py-0.5 rounded"
            style={{ background: `${color}22`, color }}
          >
            {us.skill.category}
          </span>
        </div>
      </div>

      <div>
        <div className="flex justify-between text-xs mb-1" style={{ color: "var(--text-3)" }}>
          <span>{us.session_count} sessions</span>
          {us.level < MAX_LEVEL ? (
            <span>{us.sessions_to_next_level} to L{us.level + 1}</span>
          ) : (
            <span style={{ color }}>Max Level</span>
          )}
        </div>
        {us.level < MAX_LEVEL && (
          <div className="h-1.5 rounded-full" style={{ background: "var(--surface-2)" }}>
            <div
              className="h-full rounded-full transition-all"
              style={{
                background: color,
                width: `${Math.min(100, Math.max(0, ((us.level * 5 - us.sessions_to_next_level) / (us.level * 5)) * 100))}%`,
              }}
            />
          </div>
        )}
      </div>

      <div className="flex items-center justify-between">
        <span className="text-xs" style={{ color: "var(--text-3)" }}>
          +{us.xp_per_session} XP per session
        </span>
        <Button size="sm" onClick={onPractice}>
          <Zap size={13} />
          Practice
        </Button>
      </div>
    </div>
  );
}

// ── Catalog card ───────────────────────────────────────────────────────────────

function CatalogCard({
  skill,
  unlocked,
  onUnlock,
  unlocking,
}: {
  skill: SkillResponse;
  unlocked: boolean;
  onUnlock: () => void;
  unlocking: boolean;
}) {
  const color = CAT_COLOR[skill.category as StatCategory];

  return (
    <div
      className="rounded-xl p-4 flex flex-col gap-2.5 transition-all"
      style={{
        background: "var(--surface-1)",
        border: unlocked ? `1px solid ${color}33` : "1px solid var(--border)",
        opacity: unlocked ? 0.75 : 1,
      }}
    >
      <div className="flex items-center gap-2">
        <span className="text-xl">{skill.emoji}</span>
        <span className="font-semibold text-sm" style={{ color: "var(--text-1)" }}>
          {skill.name}
        </span>
      </div>
      <span
        className="inline-block text-[10px] font-semibold uppercase tracking-wide px-2 py-0.5 rounded self-start"
        style={{ background: `${color}22`, color }}
      >
        {skill.category}
      </span>
      <p className="text-xs leading-relaxed" style={{ color: "var(--text-2)" }}>
        {skill.description}
      </p>
      {unlocked ? (
        <div className="flex items-center gap-1.5 text-xs" style={{ color }}>
          <Unlock size={11} />
          Unlocked
        </div>
      ) : (
        <Button size="sm" variant="secondary" onClick={onUnlock} disabled={unlocking} className="self-start">
          {unlocking ? <Spinner /> : <><Lock size={12} /> Unlock</>}
        </Button>
      )}
    </div>
  );
}

// ── Main page ──────────────────────────────────────────────────────────────────

export default function SkillsPage() {
  const qc = useQueryClient();
  const [tab, setTab] = useState<"my" | "discover">("my");
  const [catFilter, setCatFilter] = useState<StatCategory | "all">("all");
  const [practicing, setPracticing] = useState<UserSkillResponse | null>(null);
  const [unlockingId, setUnlockingId] = useState<string | null>(null);

  const { data: mySkills = [], isLoading: myLoading } = useQuery({
    queryKey: ["skills", "me"],
    queryFn: fetchMySkills,
  });

  const { data: catalog = [], isLoading: catLoading } = useQuery({
    queryKey: ["skills", "catalog"],
    queryFn: () => fetchCatalog(),
    staleTime: Infinity,
  });

  const { mutate: doUnlock } = useMutation({
    mutationFn: (skillId: string) => unlockSkill(skillId),
    onMutate: (skillId) => setUnlockingId(skillId),
    onSettled: () => setUnlockingId(null),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["skills", "me"] }),
  });

  const unlockedIds = new Set(mySkills.map((us) => us.skill_id));

  const visibleCatalog = catFilter === "all"
    ? catalog
    : catalog.filter((s) => s.category === catFilter);

  const visibleMySkills = catFilter === "all"
    ? mySkills
    : mySkills.filter((us) => us.skill.category === catFilter);

  const isLoading = tab === "my" ? myLoading : catLoading;

  return (
    <div className="flex flex-col gap-6">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold" style={{ color: "var(--text-1)" }}>
          Skill Tree
        </h1>
        <p className="text-sm mt-1" style={{ color: "var(--text-2)" }}>
          Unlock skills and practice them to earn XP and level up each discipline.
        </p>
      </div>

      {/* Tabs */}
      <div
        className="flex rounded-xl p-1 gap-1"
        style={{ background: "var(--surface-2)" }}
      >
        {(["my", "discover"] as const).map((t) => (
          <button
            key={t}
            onClick={() => setTab(t)}
            className="flex-1 py-2 rounded-lg text-sm font-medium transition-colors"
            style={{
              background: tab === t ? "var(--surface-1)" : "transparent",
              color: tab === t ? "var(--accent)" : "var(--text-2)",
              boxShadow: tab === t ? "0 1px 4px rgba(0,0,0,0.15)" : undefined,
            }}
          >
            {t === "my"
              ? `My Skills${mySkills.length > 0 ? ` (${mySkills.length})` : ""}`
              : "Discover"}
          </button>
        ))}
      </div>

      {/* Category filters */}
      <div className="flex flex-wrap gap-2">
        <button
          onClick={() => setCatFilter("all")}
          className="px-3 py-1 rounded-full text-xs font-medium transition-colors"
          style={{
            background: catFilter === "all" ? "var(--accent)" : "var(--surface-2)",
            color: catFilter === "all" ? "var(--accent-fg)" : "var(--text-2)",
          }}
        >
          All
        </button>
        {CATEGORIES.map((cat) => (
          <button
            key={cat}
            onClick={() => setCatFilter(cat)}
            className="px-3 py-1 rounded-full text-xs font-medium capitalize transition-colors"
            style={{
              background: catFilter === cat ? CAT_COLOR[cat] : "var(--surface-2)",
              color: catFilter === cat ? "#fff" : "var(--text-2)",
            }}
          >
            {cat}
          </button>
        ))}
      </div>

      {/* Content */}
      {isLoading ? (
        <div className="flex justify-center py-16">
          <Spinner />
        </div>
      ) : tab === "my" ? (
        visibleMySkills.length === 0 ? (
          <div className="flex flex-col items-center gap-3 py-16 text-center">
            <Zap size={36} style={{ color: "var(--text-3)" }} />
            <p className="font-semibold" style={{ color: "var(--text-1)" }}>
              {mySkills.length === 0 ? "No skills unlocked yet" : `No ${catFilter} skills`}
            </p>
            <p className="text-sm" style={{ color: "var(--text-2)" }}>
              {mySkills.length === 0
                ? 'Switch to "Discover" to unlock your first skill.'
                : "Try a different category filter."}
            </p>
            {mySkills.length === 0 && (
              <Button variant="secondary" size="sm" onClick={() => setTab("discover")}>
                Browse Skills
              </Button>
            )}
          </div>
        ) : (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
            {visibleMySkills.map((us) => (
              <MySkillCard key={us.id} us={us} onPractice={() => setPracticing(us)} />
            ))}
          </div>
        )
      ) : (
        visibleCatalog.length === 0 ? (
          <div className="flex flex-col items-center gap-3 py-16 text-center">
            <p className="text-sm" style={{ color: "var(--text-2)" }}>No skills in this category.</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
            {visibleCatalog.map((skill) => (
              <CatalogCard
                key={skill.id}
                skill={skill}
                unlocked={unlockedIds.has(skill.id)}
                onUnlock={() => doUnlock(skill.id)}
                unlocking={unlockingId === skill.id}
              />
            ))}
          </div>
        )
      )}

      {practicing && (
        <PracticeModal
          userSkill={practicing}
          onClose={() => setPracticing(null)}
        />
      )}
    </div>
  );
}
