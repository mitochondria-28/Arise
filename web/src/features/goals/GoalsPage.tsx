import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { useForm, Controller } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { Plus, CheckCircle2, Archive, Calendar, LayoutGrid, X, ChevronDown, ChevronUp, Trash2 } from "lucide-react";
import { motion, AnimatePresence } from "framer-motion";
import { fetchGoals, createGoal, completeGoal, archiveGoal, fetchTemplates, fetchMilestones, createMilestone, toggleMilestone, deleteMilestone } from "./api";
import { Modal } from "@/shared/components/ui/Modal";
import { Button } from "@/shared/components/ui/Button";
import { Input } from "@/shared/components/ui/Input";
import { Select } from "@/shared/components/ui/Select";
import { StatBadge, DifficultyBadge, StatusBadge } from "@/shared/components/ui/Badge";
import { Spinner } from "@/shared/components/ui/Spinner";
import { STAT_CATEGORIES, GOAL_DIFFICULTIES } from "@/shared/lib/constants";
import type { GoalMilestoneResponse, GoalResponse, GoalTemplateResponse, StatCategory, GoalDifficulty } from "@/shared/api/types";
import axios from "axios";

// ── Schemas ───────────────────────────────────────────────────────────────────

const createSchema = z.object({
  title:       z.string().min(3, "At least 3 characters").max(200),
  description: z.string().optional(),
  category:    z.enum(["vitality", "strength", "intelligence", "wisdom", "charisma", "discipline"]),
  difficulty:  z.enum(["easy", "medium", "hard", "epic"]),
  target_date: z.string().optional(),
});

const completeSchema = z.object({
  evidence_text: z.string().min(30, "Describe what you actually did — at least 30 characters"),
  reflection:    z.string().optional(),
  effort_level:  z.number().int().min(1).max(5),
});

type CreateForm = z.infer<typeof createSchema>;
type CompleteForm = z.infer<typeof completeSchema>;

// ── Level-up banner ───────────────────────────────────────────────────────────

function LevelUpBanner({ level, onClose }: { level: number; onClose: () => void }) {
  return (
    <motion.div
      className="fixed inset-0 z-[60] flex items-center justify-center"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
    >
      <div className="absolute inset-0" style={{ background: "rgba(0,0,0,0.75)" }} onClick={onClose} />
      <motion.div
        className="relative text-center px-12 py-10 rounded-2xl"
        style={{ background: "var(--surface-1)", border: "2px solid var(--accent)" }}
        initial={{ scale: 0.8, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        exit={{ scale: 0.8, opacity: 0 }}
        transition={{ type: "spring", stiffness: 300, damping: 25 }}
      >
        <p className="text-xs uppercase tracking-widest mb-2" style={{ color: "var(--accent)" }}>
          Level Up
        </p>
        <p className="text-6xl font-extrabold mb-1" style={{ color: "var(--text-1)" }}>
          {level}
        </p>
        <p className="text-sm" style={{ color: "var(--text-2)" }}>You reached a new level</p>
        <button
          onClick={onClose}
          className="mt-6 text-xs px-4 py-2 rounded-lg transition-colors"
          style={{ background: "var(--accent-dim)", color: "var(--accent)" }}
        >
          Continue
        </button>
      </motion.div>
    </motion.div>
  );
}

// ── Milestones section ────────────────────────────────────────────────────────

function MilestonesSection({ goalId, disabled }: { goalId: string; disabled: boolean }) {
  const qc = useQueryClient();
  const [open, setOpen] = useState(false);
  const [newTitle, setNewTitle] = useState("");
  const [adding, setAdding] = useState(false);

  const { data: milestones = [], isLoading } = useQuery<GoalMilestoneResponse[]>({
    queryKey: ["milestones", goalId],
    queryFn: () => fetchMilestones(goalId),
    enabled: open,
  });

  const { mutate: doToggle } = useMutation({
    mutationFn: ({ id, done }: { id: string; done: boolean }) =>
      toggleMilestone(goalId, id, done),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["milestones", goalId] }),
  });

  const { mutate: doDelete } = useMutation({
    mutationFn: (id: string) => deleteMilestone(goalId, id),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["milestones", goalId] }),
  });

  const { mutate: doAdd, isPending: isAdding } = useMutation({
    mutationFn: () => createMilestone(goalId, { title: newTitle.trim() }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["milestones", goalId] });
      setNewTitle("");
      setAdding(false);
    },
  });

  const done = milestones.filter((m) => m.is_completed).length;

  return (
    <div className="border-t pt-2 mt-1" style={{ borderColor: "var(--border)" }}>
      <button
        className="flex items-center gap-1.5 text-xs w-full text-left transition-colors"
        style={{ color: "var(--text-3)" }}
        onClick={() => setOpen((v) => !v)}
      >
        {open ? <ChevronUp size={12} /> : <ChevronDown size={12} />}
        Milestones
        {milestones.length > 0 && (
          <span style={{ color: done === milestones.length && milestones.length > 0 ? "var(--success)" : "var(--text-3)" }}>
            ({done}/{milestones.length})
          </span>
        )}
      </button>

      {open && (
        <div className="mt-2 flex flex-col gap-1.5">
          {isLoading ? (
            <Spinner />
          ) : (
            milestones.map((m) => (
              <div key={m.id} className="flex items-center gap-2 group">
                <input
                  type="checkbox"
                  checked={m.is_completed}
                  disabled={disabled}
                  onChange={(e) => doToggle({ id: m.id, done: e.target.checked })}
                  className="rounded cursor-pointer"
                />
                <span
                  className="text-xs flex-1"
                  style={{
                    color: m.is_completed ? "var(--text-3)" : "var(--text-2)",
                    textDecoration: m.is_completed ? "line-through" : undefined,
                  }}
                >
                  {m.title}
                </span>
                {!disabled && (
                  <button
                    onClick={() => doDelete(m.id)}
                    className="opacity-0 group-hover:opacity-100 transition-opacity"
                    style={{ color: "var(--text-3)" }}
                  >
                    <Trash2 size={11} />
                  </button>
                )}
              </div>
            ))
          )}

          {!disabled && (
            adding ? (
              <div className="flex gap-1.5 mt-1">
                <input
                  className="flex-1 text-xs rounded px-2 py-1"
                  style={{ background: "var(--surface-2)", border: "1px solid var(--border)", color: "var(--text-1)" }}
                  placeholder="Milestone title..."
                  value={newTitle}
                  onChange={(e) => setNewTitle(e.target.value)}
                  onKeyDown={(e) => {
                    if (e.key === "Enter" && newTitle.trim().length >= 3) doAdd();
                    if (e.key === "Escape") { setAdding(false); setNewTitle(""); }
                  }}
                  autoFocus
                />
                <button
                  onClick={() => doAdd()}
                  disabled={newTitle.trim().length < 3 || isAdding}
                  className="text-xs px-2 py-1 rounded"
                  style={{ background: "var(--accent)", color: "var(--accent-fg)" }}
                >
                  {isAdding ? "…" : "Add"}
                </button>
                <button
                  onClick={() => { setAdding(false); setNewTitle(""); }}
                  className="text-xs px-1"
                  style={{ color: "var(--text-3)" }}
                >
                  <X size={12} />
                </button>
              </div>
            ) : (
              <button
                onClick={() => setAdding(true)}
                className="text-xs flex items-center gap-1 mt-0.5"
                style={{ color: "var(--accent)" }}
              >
                <Plus size={11} /> Add milestone
              </button>
            )
          )}
        </div>
      )}
    </div>
  );
}

// ── Goal card ─────────────────────────────────────────────────────────────────

function GoalCard({
  goal,
  onComplete,
  onArchive,
}: {
  goal: GoalResponse;
  onComplete: (g: GoalResponse) => void;
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
            {goal.title}
          </p>
          {goal.description && (
            <p className="text-xs mt-0.5 line-clamp-2" style={{ color: "var(--text-2)" }}>
              {goal.description}
            </p>
          )}
        </div>
        <StatusBadge status={goal.status} />
      </div>

      <div className="flex flex-wrap gap-1.5">
        <StatBadge category={goal.category} />
        <DifficultyBadge difficulty={goal.difficulty} />
        {goal.target_date && (
          <span
            className="inline-flex items-center gap-1 rounded-full px-2.5 py-0.5 text-xs"
            style={{ background: "var(--surface-2)", color: "var(--text-3)" }}
          >
            <Calendar size={10} />
            {new Date(goal.target_date).toLocaleDateString()}
          </span>
        )}
      </div>

      {goal.status === "active" && (
        <div className="flex gap-2 pt-1">
          <Button size="sm" onClick={() => onComplete(goal)} className="flex-1">
            <CheckCircle2 size={14} />
            Complete
          </Button>
          <Button
            size="sm"
            variant="ghost"
            onClick={() => onArchive(goal.id)}
            title="Archive goal"
          >
            <Archive size={14} />
          </Button>
        </div>
      )}

      {goal.status === "completed" && goal.completion && (
        <div
          className="rounded-lg px-3 py-2 text-xs"
          style={{ background: "rgba(52,211,153,0.08)", color: "var(--success)" }}
        >
          +{goal.completion.xp_awarded} XP earned
        </div>
      )}

      <MilestonesSection goalId={goal.id} disabled={goal.status !== "active"} />
    </motion.div>
  );
}

// ── Effort selector ───────────────────────────────────────────────────────────

function EffortSelector({ value, onChange }: { value: number; onChange: (v: number) => void }) {
  const labels = ["", "Minimal", "Light", "Moderate", "Strong", "Maximum"];
  return (
    <div className="flex flex-col gap-2">
      <label className="text-sm font-medium" style={{ color: "var(--text-1)" }}>
        Effort Level — <span style={{ color: "var(--accent)" }}>{labels[value]}</span>
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

// ── Difficulty colour helper ──────────────────────────────────────────────────

const DIFF_COLOR: Record<string, string> = {
  easy:   "#22c55e",
  medium: "#f59e0b",
  hard:   "#f97316",
  epic:   "#a855f7",
};

// ── Templates overlay ─────────────────────────────────────────────────────────

const ALL_CATEGORIES = ["all", ...STAT_CATEGORIES] as const;
type CategoryFilter = typeof ALL_CATEGORIES[number];

function GoalTemplatesOverlay({
  onClose,
  onUse,
}: {
  onClose: () => void;
  onUse: (t: GoalTemplateResponse) => void;
}) {
  const [filter, setFilter] = useState<CategoryFilter>("all");

  const { data: templates, isLoading } = useQuery({
    queryKey: ["goal-templates"],
    queryFn: () => fetchTemplates(),
    staleTime: Infinity,
  });

  const visible = filter === "all"
    ? templates ?? []
    : (templates ?? []).filter((t) => t.category === filter);

  return (
    <motion.div
      className="fixed inset-0 z-50 flex items-end sm:items-center justify-center p-0 sm:p-4"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
    >
      {/* Backdrop */}
      <div
        className="absolute inset-0"
        style={{ background: "rgba(0,0,0,0.6)" }}
        onClick={onClose}
      />

      {/* Panel */}
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
              Goal Templates
            </h2>
            <p className="text-xs mt-0.5" style={{ color: "var(--text-3)" }}>
              Pick one to pre-fill your new goal
            </p>
          </div>
          <button
            onClick={onClose}
            className="w-8 h-8 rounded-lg flex items-center justify-center transition-colors hover:bg-[var(--surface-2)]"
            style={{ color: "var(--text-3)" }}
          >
            <X size={16} />
          </button>
        </div>

        {/* Category filter */}
        <div
          className="flex gap-1.5 px-5 py-3 border-b overflow-x-auto flex-none"
          style={{ borderColor: "var(--border)" }}
        >
          {ALL_CATEGORIES.map((cat) => (
            <button
              key={cat}
              onClick={() => setFilter(cat)}
              className="px-3 py-1 rounded-full text-xs font-medium capitalize whitespace-nowrap transition-all"
              style={
                filter === cat
                  ? { background: "var(--accent)", color: "#fff" }
                  : { background: "var(--surface-2)", color: "var(--text-2)" }
              }
            >
              {cat}
            </button>
          ))}
        </div>

        {/* Template grid */}
        <div className="flex-1 overflow-y-auto p-5">
          {isLoading ? (
            <div className="flex justify-center py-12">
              <Spinner size={24} style={{ color: "var(--accent)" } as React.CSSProperties} />
            </div>
          ) : visible.length === 0 ? (
            <p className="text-sm text-center py-10" style={{ color: "var(--text-3)" }}>
              No templates in this category.
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

export default function GoalsPage() {
  const qc = useQueryClient();
  const [filterStatus, setFilterStatus] = useState<"active" | "completed" | "all">("active");
  const [createOpen, setCreateOpen] = useState(false);
  const [templatesOpen, setTemplatesOpen] = useState(false);
  const [completeTarget, setCompleteTarget] = useState<GoalResponse | null>(null);
  const [levelUp, setLevelUp] = useState<number | null>(null);
  const [formError, setFormError] = useState<string | null>(null);

  const { data, isLoading } = useQuery({
    queryKey: ["goals", { filterStatus }],
    queryFn: () =>
      fetchGoals({
        status: filterStatus === "all" ? undefined : filterStatus,
        page_size: 50,
      }),
  });

  const createMutation = useMutation({
    mutationFn: (values: CreateForm) => createGoal(values),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["goals"] });
      setCreateOpen(false);
      createReset();
    },
    onError: (err) => {
      if (axios.isAxiosError(err)) {
        const d = err.response?.data?.detail;
        setFormError(typeof d === "string" ? d : "Failed to create goal.");
      }
    },
  });

  const completeMutation = useMutation({
    mutationFn: ({ id, input }: { id: string; input: CompleteForm }) =>
      completeGoal(id, input),
    onSuccess: (result) => {
      qc.invalidateQueries({ queryKey: ["goals"] });
      qc.invalidateQueries({ queryKey: ["character"] });
      setCompleteTarget(null);
      completeReset();
      if (result.levels_gained.length > 0) {
        setLevelUp(result.levels_gained[result.levels_gained.length - 1]);
      }
    },
    onError: (err) => {
      if (axios.isAxiosError(err)) {
        const d = err.response?.data?.detail;
        setFormError(typeof d === "string" ? d : "Failed to complete goal.");
      }
    },
  });

  const archiveMutation = useMutation({
    mutationFn: archiveGoal,
    onSuccess: () => qc.invalidateQueries({ queryKey: ["goals"] }),
  });

  // Create form
  const { register: regCreate, handleSubmit: handleCreate, control: createControl, reset: createReset, formState: { errors: createErrors, isSubmitting: createSubmitting } } =
    useForm<CreateForm>({
      resolver: zodResolver(createSchema),
      defaultValues: { category: "vitality", difficulty: "medium" },
    });

  // Complete form
  const { register: regComplete, handleSubmit: handleComplete, control: completeControl, reset: completeReset, formState: { errors: completeErrors, isSubmitting: completeSubmitting } } =
    useForm<CompleteForm>({
      resolver: zodResolver(completeSchema),
      defaultValues: { effort_level: 3 },
    });

  const handleUseTemplate = (t: GoalTemplateResponse) => {
    createReset({
      title: t.title,
      description: t.description,
      category: t.category as StatCategory,
      difficulty: t.difficulty as GoalDifficulty,
      target_date: "",
    });
    setTemplatesOpen(false);
    setFormError(null);
    setCreateOpen(true);
  };

  return (
    <div className="flex flex-col gap-6">
      <AnimatePresence>
        {levelUp !== null && (
          <LevelUpBanner level={levelUp} onClose={() => setLevelUp(null)} />
        )}
        {templatesOpen && (
          <GoalTemplatesOverlay
            onClose={() => setTemplatesOpen(false)}
            onUse={handleUseTemplate}
          />
        )}
      </AnimatePresence>

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold" style={{ color: "var(--text-1)" }}>Goals</h1>
          <p className="text-sm mt-0.5" style={{ color: "var(--text-2)" }}>
            Real achievements that earn XP
          </p>
        </div>
        <div className="flex gap-2">
          <Button variant="secondary" onClick={() => setTemplatesOpen(true)}>
            <LayoutGrid size={15} /> Templates
          </Button>
          <Button onClick={() => { setFormError(null); createReset({ category: "vitality", difficulty: "medium" }); setCreateOpen(true); }}>
            <Plus size={16} /> New Goal
          </Button>
        </div>
      </div>

      {/* Filter tabs */}
      <div className="flex gap-1 p-1 rounded-lg w-fit" style={{ background: "var(--surface-2)" }}>
        {(["active", "completed", "all"] as const).map((s) => (
          <button
            key={s}
            onClick={() => setFilterStatus(s)}
            className="px-4 py-1.5 rounded-md text-sm font-medium capitalize transition-all"
            style={
              filterStatus === s
                ? { background: "var(--surface-1)", color: "var(--text-1)", boxShadow: "0 1px 3px rgba(0,0,0,0.1)" }
                : { color: "var(--text-2)" }
            }
          >
            {s}
          </button>
        ))}
      </div>

      {/* Goal list */}
      {isLoading ? (
        <div className="flex justify-center py-12">
          <Spinner size={24} style={{ color: "var(--accent)" } as React.CSSProperties} />
        </div>
      ) : !data?.goals.length ? (
        <div className="text-center py-16">
          <p className="text-sm" style={{ color: "var(--text-2)" }}>No goals yet.</p>
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
            {data.goals.map((g) => (
              <GoalCard
                key={g.id}
                goal={g}
                onComplete={setCompleteTarget}
                onArchive={(id) => archiveMutation.mutate(id)}
              />
            ))}
          </AnimatePresence>
        </div>
      )}

      {/* Create modal */}
      <Modal
        open={createOpen}
        onClose={() => { setCreateOpen(false); setFormError(null); createReset(); }}
        title="New Goal"
      >
        <form onSubmit={handleCreate((values) => { setFormError(null); createMutation.mutate(values); })}
          className="flex flex-col gap-4">
          <Input
            label="Title"
            placeholder="What do you want to achieve?"
            error={createErrors.title?.message}
            {...regCreate("title")}
          />
          <Input
            label="Description"
            placeholder="Optional context"
            error={createErrors.description?.message}
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
          <Input
            label="Target Date"
            type="date"
            error={createErrors.target_date?.message}
            {...regCreate("target_date")}
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
            <Button type="submit" loading={createSubmitting || createMutation.isPending} className="flex-1">
              Create
            </Button>
          </div>
        </form>
      </Modal>

      {/* Complete modal */}
      <Modal
        open={!!completeTarget}
        onClose={() => { setCompleteTarget(null); setFormError(null); completeReset(); }}
        title="Complete Goal"
      >
        {completeTarget && (
          <form
            onSubmit={handleComplete((values) => {
              setFormError(null);
              completeMutation.mutate({ id: completeTarget.id, input: values });
            })}
            className="flex flex-col gap-5"
          >
            <div className="rounded-lg px-4 py-3" style={{ background: "var(--surface-2)" }}>
              <p className="text-xs mb-0.5" style={{ color: "var(--text-3)" }}>Completing</p>
              <p className="text-sm font-semibold" style={{ color: "var(--text-1)" }}>{completeTarget.title}</p>
            </div>

            <div className="flex flex-col gap-1.5">
              <label className="text-sm font-medium" style={{ color: "var(--text-1)" }}>
                Evidence of completion
              </label>
              <textarea
                className="w-full rounded-lg border px-3 py-2.5 text-sm outline-none transition-colors resize-none"
                style={{
                  background: "var(--surface-2)",
                  border: "1px solid " + (completeErrors.evidence_text ? "var(--danger)" : "var(--border)"),
                  color: "var(--text-1)",
                }}
                rows={4}
                placeholder="Describe specifically what you did — minimum 30 characters"
                {...regComplete("evidence_text")}
              />
              {completeErrors.evidence_text && (
                <p className="text-xs" style={{ color: "var(--danger)" }}>{completeErrors.evidence_text.message}</p>
              )}
            </div>

            <div className="flex flex-col gap-1.5">
              <label className="text-sm font-medium" style={{ color: "var(--text-1)" }}>
                Reflection <span style={{ color: "var(--text-3)" }}>(optional)</span>
              </label>
              <textarea
                className="w-full rounded-lg border px-3 py-2.5 text-sm outline-none transition-colors resize-none"
                style={{
                  background: "var(--surface-2)",
                  border: "1px solid var(--border)",
                  color: "var(--text-1)",
                }}
                rows={3}
                placeholder="What did you learn? What was harder than expected?"
                {...regComplete("reflection")}
              />
            </div>

            <Controller
              name="effort_level"
              control={completeControl}
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
              <Button
                type="button"
                variant="secondary"
                className="flex-1"
                onClick={() => { setCompleteTarget(null); completeReset(); }}
              >
                Cancel
              </Button>
              <Button
                type="submit"
                loading={completeSubmitting || completeMutation.isPending}
                className="flex-1"
              >
                Submit Evidence
              </Button>
            </div>
          </form>
        )}
      </Modal>
    </div>
  );
}
