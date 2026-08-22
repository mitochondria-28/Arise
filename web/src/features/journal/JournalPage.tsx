import { useState, useEffect } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { BookOpen, Flame, Sparkles, ChevronDown, ChevronUp, Save } from "lucide-react";
import {
  fetchJournalEntries,
  fetchTodayEntry,
  createOrUpdateEntry,
  generateReflection,
} from "./api";
import { Spinner } from "@/shared/components/ui/Spinner";
import type { JournalEntryResponse } from "@/shared/api/types";

// ── Mood helpers ───────────────────────────────────────────────────────────────

const MOODS = [
  { value: 1, emoji: "😔", label: "Low" },
  { value: 2, emoji: "😕", label: "Below average" },
  { value: 3, emoji: "😐", label: "Neutral" },
  { value: 4, emoji: "🙂", label: "Good" },
  { value: 5, emoji: "😄", label: "Great" },
];

function MoodPicker({
  value,
  onChange,
}: {
  value: number | null;
  onChange: (v: number | null) => void;
}) {
  return (
    <div className="flex gap-2">
      {MOODS.map((m) => (
        <button
          key={m.value}
          title={m.label}
          onClick={() => onChange(value === m.value ? null : m.value)}
          className="w-10 h-10 rounded-xl text-xl flex items-center justify-center transition-all"
          style={{
            background: value === m.value ? "var(--accent-dim)" : "var(--surface-2)",
            border: value === m.value ? "1px solid var(--accent)" : "1px solid transparent",
            transform: value === m.value ? "scale(1.15)" : "scale(1)",
          }}
        >
          {m.emoji}
        </button>
      ))}
    </div>
  );
}

// ── AI reflection block ────────────────────────────────────────────────────────

function ReflectionBlock({
  entry,
  onReflectionGenerated,
}: {
  entry: JournalEntryResponse;
  onReflectionGenerated: (updated: JournalEntryResponse) => void;
}) {
  const [generating, setGenerating] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleGenerate = async () => {
    setGenerating(true);
    setError(null);
    try {
      const updated = await generateReflection(entry.id);
      onReflectionGenerated(updated);
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : "AI reflection is unavailable";
      setError(
        msg.includes("503") || msg.includes("configure")
          ? "AI reflection is not configured on this server."
          : msg
      );
    } finally {
      setGenerating(false);
    }
  };

  if (entry.ai_reflection) {
    return (
      <div
        className="rounded-xl p-4 mt-3"
        style={{ background: "var(--accent-dim)", border: "1px solid var(--accent)" }}
      >
        <div className="flex items-center gap-2 mb-2">
          <Sparkles size={14} style={{ color: "var(--accent)" }} />
          <span className="text-xs font-semibold uppercase tracking-wide" style={{ color: "var(--accent)" }}>
            AI Reflection
          </span>
        </div>
        <p className="text-sm leading-relaxed" style={{ color: "var(--text-1)" }}>
          {entry.ai_reflection}
        </p>
      </div>
    );
  }

  return (
    <div className="mt-3">
      {error && (
        <p className="text-xs mb-2" style={{ color: "var(--text-3)" }}>
          {error}
        </p>
      )}
      <button
        onClick={handleGenerate}
        disabled={generating}
        className="flex items-center gap-2 px-3 py-2 rounded-lg text-sm font-medium transition-colors"
        style={{
          background: "var(--surface-2)",
          color: generating ? "var(--text-3)" : "var(--text-2)",
          border: "1px solid var(--border)",
        }}
      >
        {generating ? (
          <Spinner size={13} style={{ color: "var(--accent)" } as React.CSSProperties} />
        ) : (
          <Sparkles size={13} />
        )}
        {generating ? "Generating…" : "Get AI Reflection"}
      </button>
    </div>
  );
}

// ── Today editor ───────────────────────────────────────────────────────────────

function TodayEditor({
  initial,
  onSaved,
}: {
  initial: JournalEntryResponse | null | undefined;
  onSaved: (entry: JournalEntryResponse) => void;
}) {
  const [content, setContent] = useState(initial?.content ?? "");
  const [mood, setMood] = useState<number | null>(initial?.mood ?? null);
  const [saved, setSaved] = useState(false);
  const [currentEntry, setCurrentEntry] = useState<JournalEntryResponse | null>(
    initial ?? null
  );

  // Sync when today's entry loads asynchronously
  useEffect(() => {
    if (initial && !currentEntry) {
      setContent(initial.content);
      setMood(initial.mood);
      setCurrentEntry(initial);
    }
  }, [initial, currentEntry]);

  const saveMutation = useMutation({
    mutationFn: () => createOrUpdateEntry({ content, mood }),
    onSuccess: (entry) => {
      setCurrentEntry(entry);
      onSaved(entry);
      setSaved(true);
      setTimeout(() => setSaved(false), 2500);
    },
  });

  const wordCount = content.trim().split(/\s+/).filter(Boolean).length;
  const canSave = content.trim().length >= 20;

  return (
    <div
      className="rounded-2xl p-5 flex flex-col gap-4"
      style={{ background: "var(--surface-1)", border: "1px solid var(--border)" }}
    >
      <div className="flex items-center justify-between">
        <div>
          <h2 className="font-semibold text-base" style={{ color: "var(--text-1)" }}>
            Today's Entry
          </h2>
          <p className="text-xs mt-0.5" style={{ color: "var(--text-3)" }}>
            {new Date().toLocaleDateString("en-US", {
              weekday: "long",
              month: "long",
              day: "numeric",
            })}
          </p>
        </div>
        {currentEntry && (
          <span
            className="text-xs px-2 py-0.5 rounded-full"
            style={{ background: "var(--accent-dim)", color: "var(--accent)" }}
          >
            Saved
          </span>
        )}
      </div>

      <div>
        <p className="text-xs font-medium mb-2" style={{ color: "var(--text-3)" }}>
          How are you feeling?
        </p>
        <MoodPicker value={mood} onChange={setMood} />
      </div>

      <div>
        <textarea
          value={content}
          onChange={(e) => setContent(e.target.value)}
          placeholder="What happened today? What did you do, learn, or feel? Be honest and specific…"
          rows={8}
          className="w-full resize-none rounded-xl px-4 py-3 text-sm leading-relaxed outline-none transition-colors"
          style={{
            background: "var(--surface-2)",
            border: "1px solid var(--border)",
            color: "var(--text-1)",
          }}
          onFocus={(e) => (e.currentTarget.style.borderColor = "var(--accent)")}
          onBlur={(e) => (e.currentTarget.style.borderColor = "var(--border)")}
        />
        <div className="flex justify-between mt-1.5">
          <span className="text-xs" style={{ color: "var(--text-3)" }}>
            {wordCount} words
          </span>
          {content.trim().length < 20 && content.length > 0 && (
            <span className="text-xs" style={{ color: "var(--text-3)" }}>
              Minimum 20 characters
            </span>
          )}
        </div>
      </div>

      <button
        onClick={() => saveMutation.mutate()}
        disabled={!canSave || saveMutation.isPending}
        className="flex items-center justify-center gap-2 rounded-xl py-2.5 text-sm font-semibold transition-colors"
        style={{
          background: saved ? "#22c55e" : canSave ? "var(--accent)" : "var(--surface-2)",
          color: canSave ? "#fff" : "var(--text-3)",
          cursor: canSave ? "pointer" : "not-allowed",
        }}
      >
        {saveMutation.isPending ? (
          <Spinner size={14} style={{ color: "#fff" } as React.CSSProperties} />
        ) : (
          <Save size={14} />
        )}
        {saved ? "Saved!" : saveMutation.isPending ? "Saving…" : "Save Entry"}
      </button>

      {currentEntry && (
        <ReflectionBlock
          entry={currentEntry}
          onReflectionGenerated={(updated) => setCurrentEntry(updated)}
        />
      )}
    </div>
  );
}

// ── Past entry card ────────────────────────────────────────────────────────────

function PastEntryCard({ entry }: { entry: JournalEntryResponse }) {
  const [expanded, setExpanded] = useState(false);
  const mood = MOODS.find((m) => m.value === entry.mood);
  const preview = entry.content.slice(0, 120) + (entry.content.length > 120 ? "…" : "");

  return (
    <div
      className="rounded-xl overflow-hidden transition-all"
      style={{ background: "var(--surface-1)", border: "1px solid var(--border)" }}
    >
      <button
        className="w-full flex items-start gap-3 p-4 text-left"
        onClick={() => setExpanded((v) => !v)}
      >
        <div className="flex flex-col items-center gap-1 shrink-0 w-10">
          <span className="text-xs font-bold" style={{ color: "var(--accent)" }}>
            {new Date(entry.entry_date + "T00:00:00").toLocaleDateString("en-US", {
              day: "2-digit",
            })}
          </span>
          <span className="text-xs" style={{ color: "var(--text-3)" }}>
            {new Date(entry.entry_date + "T00:00:00").toLocaleDateString("en-US", {
              month: "short",
            })}
          </span>
        </div>
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2 mb-1">
            {mood && <span title={mood.label}>{mood.emoji}</span>}
            {entry.ai_reflection && (
              <Sparkles size={12} style={{ color: "var(--accent)" }} />
            )}
          </div>
          <p className="text-sm leading-relaxed" style={{ color: "var(--text-2)" }}>
            {expanded ? entry.content : preview}
          </p>
        </div>
        <div className="shrink-0 pt-0.5" style={{ color: "var(--text-3)" }}>
          {expanded ? <ChevronUp size={16} /> : <ChevronDown size={16} />}
        </div>
      </button>

      {expanded && entry.ai_reflection && (
        <div
          className="mx-4 mb-4 rounded-xl p-3"
          style={{ background: "var(--accent-dim)", border: "1px solid var(--accent)" }}
        >
          <div className="flex items-center gap-1.5 mb-1">
            <Sparkles size={12} style={{ color: "var(--accent)" }} />
            <span className="text-xs font-semibold" style={{ color: "var(--accent)" }}>
              AI Reflection
            </span>
          </div>
          <p className="text-sm leading-relaxed" style={{ color: "var(--text-1)" }}>
            {entry.ai_reflection}
          </p>
        </div>
      )}
    </div>
  );
}

// ── Page ───────────────────────────────────────────────────────────────────────

export default function JournalPage() {
  const qc = useQueryClient();

  const { data: todayData, isLoading: todayLoading } = useQuery({
    queryKey: ["journal-today"],
    queryFn: fetchTodayEntry,
  });

  const { data: listData, isLoading: listLoading } = useQuery({
    queryKey: ["journal"],
    queryFn: () => fetchJournalEntries(50, 0),
  });

  const handleSaved = (entry: JournalEntryResponse) => {
    qc.invalidateQueries({ queryKey: ["journal"] });
    qc.setQueryData(["journal-today"], entry);
  };

  const today = new Date().toISOString().split("T")[0];
  const pastEntries = (listData?.entries ?? []).filter(
    (e) => e.entry_date !== today
  );

  return (
    <div className="flex flex-col gap-6">
      <div className="flex items-start justify-between">
        <div>
          <h1 className="text-2xl font-bold" style={{ color: "var(--text-1)" }}>
            Journal
          </h1>
          <p className="text-sm mt-1" style={{ color: "var(--text-2)" }}>
            Daily reflections on your journey
          </p>
        </div>

        {(listData?.streak ?? 0) > 0 && (
          <div
            className="flex items-center gap-2 px-3 py-2 rounded-xl"
            style={{ background: "#f9731618", border: "1px solid #f9731644" }}
          >
            <Flame size={16} style={{ color: "#f97316" }} />
            <span className="text-sm font-bold" style={{ color: "#f97316" }}>
              {listData!.streak}
            </span>
            <span className="text-xs" style={{ color: "#f97316" }}>
              {listData!.streak === 1 ? "day" : "days"}
            </span>
          </div>
        )}
      </div>

      {/* Today editor */}
      {todayLoading ? (
        <div
          className="rounded-2xl p-5 flex items-center justify-center"
          style={{
            background: "var(--surface-1)",
            border: "1px solid var(--border)",
            minHeight: 200,
          }}
        >
          <Spinner size={24} style={{ color: "var(--accent)" } as React.CSSProperties} />
        </div>
      ) : (
        <TodayEditor
          initial={todayData}
          onSaved={handleSaved}
        />
      )}

      {/* Past entries */}
      {!listLoading && pastEntries.length > 0 && (
        <div className="flex flex-col gap-3">
          <div className="flex items-center gap-2">
            <BookOpen size={15} style={{ color: "var(--text-3)" }} />
            <h3 className="text-sm font-semibold" style={{ color: "var(--text-2)" }}>
              Past Entries ({listData?.total ?? 0})
            </h3>
          </div>
          {pastEntries.map((e) => (
            <PastEntryCard key={e.id} entry={e} />
          ))}
        </div>
      )}

      {!listLoading && !todayLoading && (listData?.total ?? 0) === 0 && !todayData && (
        <div className="flex flex-col items-center gap-2 py-10">
          <BookOpen size={32} style={{ color: "var(--text-3)" }} />
          <p className="text-sm" style={{ color: "var(--text-3)" }}>
            Write your first entry above to start your journal streak.
          </p>
        </div>
      )}
    </div>
  );
}
