import { useState } from "react";
import { useMutation } from "@tanstack/react-query";
import { Sparkles, RefreshCw } from "lucide-react";
import { motion, AnimatePresence } from "framer-motion";
import { generateGrowthReport } from "./api";
import { Button } from "@/shared/components/ui/Button";
import type { AIAnalysisResponse } from "@/shared/api/types";
import axios from "axios";

function ReportCard({ report }: { report: AIAnalysisResponse }) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 12 }}
      animate={{ opacity: 1, y: 0 }}
      className="rounded-2xl p-6 relative overflow-hidden"
      style={{ background: "var(--surface-1)", border: "1px solid var(--border)" }}
    >
      <div
        className="absolute -top-12 -right-12 w-48 h-48 rounded-full pointer-events-none"
        style={{ background: "var(--accent-dim)", filter: "blur(40px)" }}
      />
      <div className="relative">
        <div className="flex items-center gap-2 mb-4">
          <div
            className="w-8 h-8 rounded-lg flex items-center justify-center flex-none"
            style={{ background: "var(--accent-dim)" }}
          >
            <Sparkles size={16} style={{ color: "var(--accent)" }} />
          </div>
          <div>
            <p className="text-sm font-semibold" style={{ color: "var(--text-1)" }}>
              Growth Report
            </p>
            <p className="text-xs" style={{ color: "var(--text-3)" }}>
              {new Date(report.created_at).toLocaleDateString(undefined, {
                month: "long",
                day: "numeric",
                year: "numeric",
              })}
              {" · "}{report.model_used}
            </p>
          </div>
        </div>
        <p className="text-sm leading-relaxed whitespace-pre-wrap" style={{ color: "var(--text-2)" }}>
          {report.content}
        </p>
      </div>
    </motion.div>
  );
}

export default function GrowthReportPage() {
  const [report, setReport] = useState<AIAnalysisResponse | null>(null);
  const [error, setError] = useState<string | null>(null);

  const { mutate, isPending } = useMutation({
    mutationFn: generateGrowthReport,
    onSuccess: (data) => {
      setReport(data);
      setError(null);
    },
    onError: (err) => {
      if (axios.isAxiosError(err)) {
        const detail = err.response?.data?.detail;
        setError(typeof detail === "string" ? detail : "Failed to generate report.");
      } else {
        setError("Something went wrong.");
      }
    },
  });

  return (
    <div className="flex flex-col gap-6">
      <div>
        <h1 className="text-2xl font-bold" style={{ color: "var(--text-1)" }}>AI Coach</h1>
        <p className="text-sm mt-1" style={{ color: "var(--text-2)" }}>
          Personalised insights based on your real activity
        </p>
      </div>

      {/* Info card */}
      <div
        className="rounded-xl p-5"
        style={{ background: "var(--surface-1)", border: "1px solid var(--border)" }}
      >
        <h2 className="text-sm font-semibold mb-1.5" style={{ color: "var(--text-1)" }}>
          How it works
        </h2>
        <ul className="text-sm flex flex-col gap-1" style={{ color: "var(--text-2)" }}>
          <li>After you complete a goal, an AI analysis is generated automatically.</li>
          <li>After each mission check-in, the AI reflects on your progress.</li>
          <li>Use the growth report below for a holistic view of your journey.</li>
        </ul>
        <p className="text-xs mt-3" style={{ color: "var(--text-3)" }}>
          Requires a Gemini API key configured on the server. If no key is set, insights are skipped gracefully.
        </p>
      </div>

      {/* Generate button */}
      <Button
        onClick={() => mutate()}
        loading={isPending}
        size="lg"
        className="self-start"
      >
        <RefreshCw size={16} />
        {report ? "Regenerate Report" : "Generate Growth Report"}
      </Button>

      {error && (
        <div
          className="rounded-lg px-4 py-3 text-sm"
          style={{ background: "rgba(239,68,68,0.1)", color: "var(--danger)" }}
        >
          {error}
        </div>
      )}

      <AnimatePresence>
        {report && <ReportCard report={report} />}
      </AnimatePresence>
    </div>
  );
}
