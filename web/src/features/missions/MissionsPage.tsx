import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { useForm, Controller } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { Plus, Flame, Archive, LayoutGrid, X } from "lucide-react";
import { motion, AnimatePresence } from "framer-motion";
import { fetchMissions, createMission, checkinMission, archiveMission, fetchMissionTemplates } from "./api";
import { Modal } from "@/shared/components/ui/Modal";
import { Button } from "@/shared/components/ui/Button";
import { Input } from "@/shared/components/ui/Input";
import { Select } from "@/shared/components/ui/Select";
import { StatBadge, DifficultyBadge, FrequencyBadge, StatusBadge } from "@/shared/components/ui/Badge";
import { Spinner } from "@/shared/components/ui/Spinner";
import { STAT_CATEGORIES, GOAL_DIFFICULTIES, MISSION_FREQUENCIES } from "@/shared/lib/constants";
import type { MissionFrequency, MissionResponse, MissionTemplateResponse, StatCategory, GoalDifficulty } from "@/shared/api/types";
import axios from "axios";

// ── Schemas ───────────────────────────────────────────────────────────────────

const createSchema = z.object({
  title:        z.string().min(3, "At least 3 characters").max(200),
  description:  z.string().optional(),
  category:     z.enum(["vitality", "strength", "intelligence", "wisdom", "charisma", "discipline"]),
  difficulty:   z.enum(["easy", "medium", "hard", "epic"]),
  frequency:    z.enum(["daily", "weekly", "monthly"]),
  target_count: z.coerce.number().int().min(0).optional(),
});

const checkinSchema = z.object({
  evidence_text: z.string().min(30, "Describe what you did — at least 30 characters"),
  reflection:    z.string().optional(),
  effort_level:  z.number().int().min(1).max(5),
});

type CreateForm = z.infer<typeof createSchema>;
type CheckinForm = z.infer<typeof checkinSchema>;

// ── Effort selector ───────────────────────────────────────────────────────────

function EffortSelector({ value, onChange }: { value: number; onChange: (v: number) => void }) {
  const labels = ["", "Minimal", "Light", "Moderate", "Strong", "Maximum"];
  return (
    <div className="flex flex-col gap-2">
      <label className="text-sm font-medium" style={{ color: "var(--text-1)" }}>
        Effort — <span style={{ color: "var(--accent)" }}>{labels[value]}</span>
      </label>
      <div className="flex gap-2">
        {[1, 2, 3, 4, 5].map((n) => (
          <button
            key={n}
            type="button"
            onClick={() => onChange(n)}
            className="flex-1 h-9 rounded-lg text-sm font-semibold transition-all"
            style={{
              background: value >= n ? "var(--accent)" : "var(--surface-2)",
              color: value >= n ? "#fff" : "var(--text-3)",
              border: `1px solid ${value >= n ? "var(--accent)" : "var(--border)"}`,
            }}
          >
            {n}
          </button>
        ))}
      </div>
    </div>
  );
}

// ── Mission card ──────────────────────────────────────────────────────────────

function MissionCard({
  mission,
  onCheckin,
  onArchive,
}: {
  mission: MissionResponse;
  onCheckin: (m: MissionResponse) => void;
  onArchive: (id: string) => void;
}) {
  return (
    <motion.div
      layout
      initial={{ opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, scale: 0.97 }}
      className="rounded-xl p-4 flex flex-col gap-3"
      style={{ background: "var(--surface-1)", border: "1px solid var(--border)" }}
    >
      <div className="flex items-start justify-between gap-3">
        <div className="flex-1 min-w-0">
          <p className="font-semibold text-sm leading-snug" style={{ color: "var(--text-1)" }}>
            {mission.title}
          </p>
          {mission.description && (
            <p className="text-xs mt-0.5 line-clamp-2" style={{ color: "var(--text-2)" }}>
              {mission.description}
            </p>
          )}
        </div>
        <StatusBadge status={mission.status} />
      </div>

      <div className="flex flex-wrap gap-1.5">
        <StatBadge category={mission.category} />
        <DifficultyBadge difficulty={mission.difficulty} />
        <FrequencyBadge frequency={mission.frequency} />
      </div>

      <div className="flex items-center justify-between">
        <div className="flex items-center gap-1.5">
          <Flame size={14} style={{ color: mission.current_streak > 0 ? "var(--warning)" : "var(--text-3)" }} />
          <span className="text-sm font-semibold" style={{ color: mission.current_streak > 0 ? "var(--warning)" : "var(--text-3)" }}>
            {mission.current_streak}
          </span>
          <span className="text-xs" style={{ color: "var(--text-3)" }}>
            day streak · best {mission.longest_streak}
          </span>
        </div>
        {mission.target_count > 0 && (
          <span className="text-xs" style={{ color: "var(--text-3)" }}>
            {mission.completion_count}/{mission.target_count}
          </span>
        )}
      </div>

      {mission.status === "active" && (
        <div className="flex gap-2 pt-1">
          <Button
            size="sm"
            onClick={() => onCheckin(mission)}
            disabled={!mission.can_checkin_now}
            className="flex-1"
          >
            {mission.can_checkin_now ? "Check In" : "Already checked in"}
          </Button>
          <Button size="sm" variant="ghost" onClick={() => onArchive(mission.id)} title="Archive">
            <Archive size={14} />
          </Button>
        </div>
      )}
    </motion.div>
  );
}

// ── Frequency colour helper ───────────────────────────────────────────────────

const DIFF_COLOR: Record<string, string> = {
  easy:   "#22c55e",
  medium: "#f59e0b",
  hard:   "#f97316",
  epic:   "#a855f7",
};

const FREQ_COLOR: Record<string, string> = {
  daily:   "#3b82f6",
  weekly:  "#8b5cf6",
  monthly: "#ec4899",
};

// ── Mission Templates Overlay ─────────────────────────────────────────────────

const ALL_CATEGORIES = ["all", ...STAT_CATEGORIES] as const;
const ALL_FREQUENCIES = ["all", ...MISSION_FREQUENCIES] as const;
type CategoryFilter = typeof ALL_CATEGORIES[number];
type FrequencyFilter = typeof ALL_FREQUENCIES[number];

function MissionTemplatesOverlay({
  onClose,
  onUse,
}: {
  onClose: () => void;
  onUse: (t: MissionTemplateResponse) => void;
}) {
  const [catFilter, setCatFilter] = useState<CategoryFilter>("all");
  const [freqFilter, setFreqFilter] = useState<FrequencyFilter>("all");

  const { data: templates, isLoading } = useQuery({
    queryKey: ["mission-templates"],
    queryFn: () => fetchMissionTemplates(),
    staleTime: Infinity,
  });

  const visible = (templates ?? []).filter((t) => {
    if (catFilter  !== "all" && t.category  !== catFilter)  return false;
    if (freqFilter !== "all" && t.frequency !== freqFilter) return false;
    return true;
  });

  return (
    <motion.div
      className="fixed inset-0 z-50 flex items-end sm:items-center justify-center p-0 sm:p-4"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
    >
      <div className="absolute inset-0" style={{ background: "rgba(0,0,0,0.6)" }} onClick={onClose} />

      <motion.div
        className="relative w-full sm:max-w-2xl max-h-[90vh] rounded-t-2xl sm:rounded-2xl flex flex-col overflow-hidden"
        style={{ background: "var(--bg)", border: "1px solid var(--border)" }}
        initial={{ y: 40, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        exit={{ y: 40, opacity: 0 }}
        transition={{ type: "spring", stiffness: 320, damping: 28 }}
      >
        {/* Header */}
        <div
          className="flex items-center justify-between px-5 py-4 border-b flex-none"
          style={{ borderColor: "var(--border)" }}
        >
          <div>
            <h2 className="text-base font-semibold" style={{ color: "var(--text-1)" }}>
              Mission Templates
            </h2>
            <p className="text-xs mt-0.5" style={{ color: "var(--text-3)" }}>
              Pick a habit to pre-fill your new mission
            </p>
          </div>
          <button
            onClick={onClose}
            className="w-8 h-8 rounded-lg flex items-center justify-center hover:bg-[var(--surface-2)]"
            style={{ color: "var(--text-3)" }}
          >
            <X size={16} />
          </button>
        </div>

        {/* Filters */}
        <div
          className="flex flex-col gap-2 px-5 py-3 border-b flex-none"
          style={{ borderColor: "var(--border)" }}
        >
          {/* Category */}
          <div className="flex gap-1.5 overflow-x-auto">
            {ALL_CATEGORIES.map((cat) => (
              <button
                key={cat}
                onClick={() => setCatFilter(cat)}
                className="px-3 py-1 rounded-full text-xs font-medium capitalize whitespace-nowrap transition-all"
                style={
                  catFilter === cat
                    ? { background: "var(--accent)", color: "#fff" }
                    : { background: "var(--surface-2)", color: "var(--text-2)" }
                }
              >
                {cat}
              </button>
            ))}
          </div>
          {/* Frequency */}
          <div className="flex gap-1.5">
            {ALL_FREQUENCIES.map((f) => (
              <button
                key={f}
                onClick={() => setFreqFilter(f)}
                className="px-3 py-1 rounded-full text-xs font-medium capitalize whitespace-nowrap transition-all"
                style={
                  freqFilter === f
                    ? { background: FREQ_COLOR[f] ?? "var(--accent)", color: "#fff" }
                    : { background: "var(--surface-2)", color: "var(--text-2)" }
                }
              >
                {f}
              </button>
            ))}
          </div>
        </div>

        {/* Template grid */}
        <div className="flex-1 overflow-y-auto p-5">
          {isLoading ? (
            <div className="flex justify-center py-12">
              <Spinner size={24} style={{ color: "var(--accent)" } as React.CSSProperties} />
            </div>
          ) : visible.length === 0 ? (
            <p className="text-sm text-center py-10" style={{ color: "var(--text-3)" }}>
              No templates match these filters.
            </p>
          ) : (
            <div className="grid gap-3 sm:grid-cols-2">
              {visible.map((t) => (
                <div
                  key={t.id}
                  className="rounded-xl p-4 flex flex-col gap-2"
                  style={{ background: "var(--surface-1)", border: "1px solid var(--border)" }}
                >
                  <div className="flex items-start gap-3">
                    <span className="text-2xl flex-none leading-none mt-0.5">{t.emoji}</span>
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-semibold leading-snug" style={{ color: "var(--text-1)" }}>
                        {t.title}
                      </p>
                      <div className="flex gap-1.5 mt-1 flex-wrap">
                        <StatBadge category={t.category as StatCategory} />
                        <span
                          className="inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium capitalize"
                          style={{
                            background: `${DIFF_COLOR[t.difficulty]}18`,
                            color: DIFF_COLOR[t.difficulty],
                          }}
                        >
                          {t.difficulty}
                        </span>
                        <span
                          className="inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium capitalize"
                          style={{
                            background: `${FREQ_COLOR[t.frequency]}18`,
                            color: FREQ_COLOR[t.frequency],
                          }}
                        >
                          {t.frequency}
                        </span>
                      </div>
                    </div>
                  </div>
                  <p className="text-xs leading-relaxed" style={{ color: "var(--text-2)" }}>
                    {t.description}
                  </p>
                  <button
                    onClick={() => onUse(t)}
                    className="mt-1 w-full py-2 rounded-lg text-xs font-semibold transition-colors"
                    style={{ background: "var(--accent-dim)", color: "var(--accent)" }}
                  >
                    Use this template
                  </button>
                </div>
              ))}
            </div>
          )}
        </div>
      </motion.div>
    </motion.div>
  );
}

// ── Page ──────────────────────────────────────────────────────────────────────

export default function MissionsPage() {
  const qc = useQueryClient();
  const [filterFreq, setFilterFreq] = useState<MissionFrequency | "all">("all");
  const [createOpen, setCreateOpen] = useState(false);
  const [templatesOpen, setTemplatesOpen] = useState(false);
  const [checkinTarget, setCheckinTarget] = useState<MissionResponse | null>(null);
  const [formError, setFormError] = useState<string | null>(null);
  const [xpToast, setXpToast] = useState<{ xp: number; streak: number } | null>(null);

  const { data, isLoading } = useQuery({
    queryKey: ["missions", { filterFreq }],
    queryFn: () =>
      fetchMissions({
        frequency: filterFreq === "all" ? undefined : filterFreq,
        status: "active",
        page_size: 50,
      }),
  });

  const createMut = useMutation({
    mutationFn: (values: CreateForm) => createMission(values),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["missions"] });
      setCreateOpen(false);
      createReset();
    },
    onError: (err) => {
      if (axios.isAxiosError(err)) {
        const d = err.response?.data?.detail;
        setFormError(typeof d === "string" ? d : "Failed to create mission.");
      }
    },
  });

  const checkinMut = useMutation({
    mutationFn: ({ id, input }: { id: string; input: CheckinForm }) =>
      checkinMission(id, input),
    onSuccess: (result) => {
      qc.invalidateQueries({ queryKey: ["missions"] });
      qc.invalidateQueries({ queryKey: ["character"] });
      setCheckinTarget(null);
      checkinReset();
      setXpToast({ xp: result.xp_awarded, streak: result.new_streak });
      setTimeout(() => setXpToast(null), 3000);
    },
    onError: (err) => {
      if (axios.isAxiosError(err)) {
        const d = err.response?.data?.detail;
        setFormError(typeof d === "string" ? d : "Check-in failed.");
      }
    },
  });

  const archiveMut = useMutation({
    mutationFn: archiveMission,
    onSuccess: () => qc.invalidateQueries({ queryKey: ["missions"] }),
  });

  const {
    register: regCreate,
    handleSubmit: handleCreate,
    control: createControl,
    reset: createReset,
    formState: { errors: createErrors, isSubmitting: createSubmitting },
  } = useForm<CreateForm>({
    resolver: zodResolver(createSchema),
    defaultValues: { category: "vitality", difficulty: "medium", frequency: "daily" },
  });

  const {
    register: regCheckin,
    handleSubmit: handleCheckin,
    control: checkinControl,
    reset: checkinReset,
    formState: { errors: checkinErrors, isSubmitting: checkinSubmitting },
  } = useForm<CheckinForm>({
    resolver: zodResolver(checkinSchema),
    defaultValues: { effort_level: 3 },
  });

  const handleUseTemplate = (t: MissionTemplateResponse) => {
    createReset({
      title:       t.title,
      description: t.description,
      category:    t.category as StatCategory,
      difficulty:  t.difficulty as GoalDifficulty,
      frequency:   t.frequency as MissionFrequency,
    });
    setTemplatesOpen(false);
    setFormError(null);
    setCreateOpen(true);
  };

  return (
    <div className="flex flex-col gap-6">
      {/* XP toast */}
      <AnimatePresence>
        {xpToast && (
          <motion.div
            className="fixed top-4 right-4 z-50 rounded-xl px-4 py-3 flex items-center gap-3"
            style={{ background: "var(--surface-1)", border: "1px solid var(--border)", boxShadow: "0 4px 20px rgba(0,0,0,0.2)" }}
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: 20 }}
          >
            <Flame size={18} style={{ color: "var(--warning)" }} />
            <div>
              <p className="text-sm font-semibold" style={{ color: "var(--text-1)" }}>+{xpToast.xp} XP</p>
              <p className="text-xs" style={{ color: "var(--text-2)" }}>Streak: {xpToast.streak}</p>
            </div>
          </motion.div>
        )}
        {templatesOpen && (
          <MissionTemplatesOverlay
            onClose={() => setTemplatesOpen(false)}
            onUse={handleUseTemplate}
          />
        )}
      </AnimatePresence>

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold" style={{ color: "var(--text-1)" }}>Missions</h1>
          <p className="text-sm mt-0.5" style={{ color: "var(--text-2)" }}>
            Recurring habits that build streaks
          </p>
        </div>
        <div className="flex gap-2">
          <Button variant="secondary" onClick={() => setTemplatesOpen(true)}>
            <LayoutGrid size={15} /> Templates
          </Button>
          <Button onClick={() => { setFormError(null); createReset({ category: "vitality", difficulty: "medium", frequency: "daily" }); setCreateOpen(true); }}>
            <Plus size={16} /> New Mission
          </Button>
        </div>
      </div>

      {/* Frequency filter */}
      <div className="flex gap-1 p-1 rounded-lg w-fit" style={{ background: "var(--surface-2)" }}>
        {(["all", ...MISSION_FREQUENCIES] as const).map((f) => (
          <button
            key={f}
            onClick={() => setFilterFreq(f)}
            className="px-4 py-1.5 rounded-md text-sm font-medium capitalize transition-all"
            style={
              filterFreq === f
                ? { background: "var(--surface-1)", color: "var(--text-1)", boxShadow: "0 1px 3px rgba(0,0,0,0.1)" }
                : { color: "var(--text-2)" }
            }
          >
            {f}
          </button>
        ))}
      </div>

      {/* Mission list */}
      {isLoading ? (
        <div className="flex justify-center py-12">
          <Spinner size={24} style={{ color: "var(--accent)" } as React.CSSProperties} />
        </div>
      ) : !data?.missions.length ? (
        <div className="text-center py-16">
          <p className="text-sm" style={{ color: "var(--text-2)" }}>No active missions.</p>
          <div className="flex items-center justify-center gap-3 mt-3">
            <button
              onClick={() => setTemplatesOpen(true)}
              className="text-sm font-medium hover:underline"
              style={{ color: "var(--accent)" }}
            >
              Browse templates
            </button>
            <span style={{ color: "var(--text-3)" }}>·</span>
            <button
              onClick={() => setCreateOpen(true)}
              className="text-sm font-medium hover:underline"
              style={{ color: "var(--accent)" }}
            >
              Create from scratch
            </button>
          </div>
        </div>
      ) : (
        <div className="grid gap-3 sm:grid-cols-2">
          <AnimatePresence mode="popLayout">
            {data.missions.map((m) => (
              <MissionCard
                key={m.id}
                mission={m}
                onCheckin={setCheckinTarget}
                onArchive={(id) => archiveMut.mutate(id)}
              />
            ))}
          </AnimatePresence>
        </div>
      )}

      {/* Create modal */}
      <Modal
        open={createOpen}
        onClose={() => { setCreateOpen(false); setFormError(null); createReset(); }}
        title="New Mission"
      >
        <form
          onSubmit={handleCreate((values) => { setFormError(null); createMut.mutate(values); })}
          className="flex flex-col gap-4"
        >
          <Input
            label="Title"
            placeholder="What habit do you want to build?"
            error={createErrors.title?.message}
            {...regCreate("title")}
          />
          <Input
            label="Description"
            placeholder="Optional context"
            {...regCreate("description")}
          />
          <div className="grid grid-cols-2 gap-3">
            <Controller
              name="category"
              control={createControl}
              render={({ field }) => (
                <Select
                  label="Category"
                  options={STAT_CATEGORIES.map((c) => ({ value: c, label: c.charAt(0).toUpperCase() + c.slice(1) }))}
                  error={createErrors.category?.message}
                  {...field}
                />
              )}
            />
            <Controller
              name="difficulty"
              control={createControl}
              render={({ field }) => (
                <Select
                  label="Difficulty"
                  options={GOAL_DIFFICULTIES.map((d) => ({ value: d, label: d.charAt(0).toUpperCase() + d.slice(1) }))}
                  error={createErrors.difficulty?.message}
                  {...field}
                />
              )}
            />
          </div>
          <Controller
            name="frequency"
            control={createControl}
            render={({ field }) => (
              <Select
                label="Frequency"
                options={MISSION_FREQUENCIES.map((f) => ({ value: f, label: f.charAt(0).toUpperCase() + f.slice(1) }))}
                error={createErrors.frequency?.message}
                {...field}
              />
            )}
          />
          <Input
            label="Target completions"
            type="number"
            min={0}
            placeholder="0 = unlimited"
            hint="Set a number to auto-complete after that many check-ins"
            {...regCreate("target_count")}
          />
          {formError && (
            <p className="text-sm px-3 py-2 rounded-lg" style={{ background: "rgba(239,68,68,0.1)", color: "var(--danger)" }}>
              {formError}
            </p>
          )}
          <div className="flex gap-3 pt-2">
            <Button type="button" variant="secondary" className="flex-1" onClick={() => { setCreateOpen(false); createReset(); }}>
              Cancel
            </Button>
            <Button type="submit" loading={createSubmitting || createMut.isPending} className="flex-1">
              Create
            </Button>
          </div>
        </form>
      </Modal>

      {/* Check-in modal */}
      <Modal
        open={!!checkinTarget}
        onClose={() => { setCheckinTarget(null); setFormError(null); checkinReset(); }}
        title="Mission Check-in"
      >
        {checkinTarget && (
          <form
            onSubmit={handleCheckin((values) => {
              setFormError(null);
              checkinMut.mutate({ id: checkinTarget.id, input: values });
            })}
            className="flex flex-col gap-5"
          >
            <div className="rounded-lg px-4 py-3" style={{ background: "var(--surface-2)" }}>
              <p className="text-xs mb-0.5" style={{ color: "var(--text-3)" }}>Checking in</p>
              <p className="text-sm font-semibold" style={{ color: "var(--text-1)" }}>{checkinTarget.title}</p>
              {checkinTarget.current_streak > 0 && (
                <p className="text-xs mt-0.5" style={{ color: "var(--warning)" }}>
                  Current streak: {checkinTarget.current_streak}
                </p>
              )}
            </div>

            <div className="flex flex-col gap-1.5">
              <label className="text-sm font-medium" style={{ color: "var(--text-1)" }}>
                What did you do?
              </label>
              <textarea
                className="w-full rounded-lg border px-3 py-2.5 text-sm outline-none transition-colors resize-none"
                style={{
                  background: "var(--surface-2)",
                  border: "1px solid " + (checkinErrors.evidence_text ? "var(--danger)" : "var(--border)"),
                  color: "var(--text-1)",
                }}
                rows={4}
                placeholder="Be specific — minimum 30 characters"
                {...regCheckin("evidence_text")}
              />
              {checkinErrors.evidence_text && (
                <p className="text-xs" style={{ color: "var(--danger)" }}>{checkinErrors.evidence_text.message}</p>
              )}
            </div>

            <div className="flex flex-col gap-1.5">
              <label className="text-sm font-medium" style={{ color: "var(--text-1)" }}>
                Reflection <span style={{ color: "var(--text-3)" }}>(optional)</span>
              </label>
              <textarea
                className="w-full rounded-lg border px-3 py-2.5 text-sm outline-none transition-colors resize-none"
                style={{ background: "var(--surface-2)", border: "1px solid var(--border)", color: "var(--text-1)" }}
                rows={3}
                placeholder="What felt different today?"
                {...regCheckin("reflection")}
              />
            </div>

            <Controller
              name="effort_level"
              control={checkinControl}
              render={({ field }) => (
                <EffortSelector value={field.value} onChange={field.onChange} />
              )}
            />

            {formError && (
              <p className="text-sm px-3 py-2 rounded-lg" style={{ background: "rgba(239,68,68,0.1)", color: "var(--danger)" }}>
                {formError}
              </p>
            )}

            <div className="flex gap-3 pt-1">
              <Button type="button" variant="secondary" className="flex-1" onClick={() => { setCheckinTarget(null); checkinReset(); }}>
                Cancel
              </Button>
              <Button type="submit" loading={checkinSubmitting || checkinMut.isPending} className="flex-1">
                Submit
              </Button>
            </div>
          </form>
        )}
      </Modal>
    </div>
  );
}
