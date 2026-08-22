import { useState, useRef, useEffect } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Sparkles, Send, Plus, MessageSquare, Calendar, RefreshCw, Bot, User } from "lucide-react";
import {
  fetchConversations,
  createConversation,
  fetchConversation,
  sendMessage,
  fetchWeeklyReviews,
  generateWeeklyReview,
} from "./api";
import { generateGrowthReport } from "@/features/ai/api";
import { Spinner } from "@/shared/components/ui/Spinner";
import { Button } from "@/shared/components/ui/Button";
import type { AIConversationResponse, AIConversationSummary, AIMessageResponse, WeeklyReviewResponse } from "@/shared/api/types";

// ── Helpers ────────────────────────────────────────────────────────────────────

function fmtDate(iso: string) {
  return new Date(iso).toLocaleDateString(undefined, {
    month: "short", day: "numeric",
  });
}

function fmtTime(iso: string) {
  return new Date(iso).toLocaleTimeString(undefined, {
    hour: "2-digit", minute: "2-digit",
  });
}

// ── Message bubble ─────────────────────────────────────────────────────────────

function MessageBubble({ msg }: { msg: AIMessageResponse }) {
  const isUser = msg.role === "user";
  return (
    <div className={`flex gap-2.5 ${isUser ? "flex-row-reverse" : "flex-row"}`}>
      <div
        className="w-7 h-7 rounded-full flex items-center justify-center flex-none mt-1"
        style={{
          background: isUser ? "var(--accent-dim)" : "var(--surface-2)",
          border: "1px solid var(--border)",
        }}
      >
        {isUser
          ? <User size={13} style={{ color: "var(--accent)" }} />
          : <Bot size={13} style={{ color: "var(--text-2)" }} />
        }
      </div>
      <div className={`max-w-[78%] flex flex-col gap-1 ${isUser ? "items-end" : "items-start"}`}>
        <div
          className="rounded-2xl px-4 py-2.5 text-sm leading-relaxed whitespace-pre-wrap"
          style={{
            background: isUser ? "var(--accent)" : "var(--surface-1)",
            color: isUser ? "#fff" : "var(--text-1)",
            border: isUser ? "none" : "1px solid var(--border)",
            borderTopRightRadius: isUser ? 4 : undefined,
            borderTopLeftRadius: !isUser ? 4 : undefined,
          }}
        >
          {msg.content}
        </div>
        <span className="text-xs px-1" style={{ color: "var(--text-3)" }}>
          {fmtTime(msg.created_at)}
        </span>
      </div>
    </div>
  );
}

// ── Chat window ────────────────────────────────────────────────────────────────

function ChatWindow({ conversationId }: { conversationId: string }) {
  const [input, setInput] = useState("");
  const bottomRef = useRef<HTMLDivElement>(null);
  const qc = useQueryClient();

  const { data: conv, isLoading } = useQuery({
    queryKey: ["coach-conv", conversationId],
    queryFn: () => fetchConversation(conversationId),
    refetchOnWindowFocus: false,
  });

  const { mutate: send, isPending: sending } = useMutation({
    mutationFn: (content: string) => sendMessage(conversationId, content),
    onSuccess: (reply) => {
      qc.setQueryData<AIConversationResponse>(
        ["coach-conv", conversationId],
        (old) => {
          if (!old) return old;
          const userMsg: AIMessageResponse = {
            id: crypto.randomUUID(),
            conversation_id: conversationId,
            role: "user",
            content: input,
            created_at: new Date().toISOString(),
          };
          return { ...old, messages: [...old.messages, userMsg, reply] };
        }
      );
      qc.invalidateQueries({ queryKey: ["coach-conversations"] });
    },
  });

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [conv?.messages]);

  function handleSend() {
    const text = input.trim();
    if (!text || sending) return;
    setInput("");
    send(text);
  }

  if (isLoading) {
    return (
      <div className="flex-1 flex items-center justify-center">
        <Spinner size={24} style={{ color: "var(--accent)" } as React.CSSProperties} />
      </div>
    );
  }

  const messages = conv?.messages ?? [];

  return (
    <div className="flex-1 flex flex-col min-h-0">
      <div className="flex-1 overflow-y-auto px-4 py-4 flex flex-col gap-4">
        {messages.length === 0 && (
          <div className="flex-1 flex items-center justify-center py-12">
            <div className="text-center">
              <Bot size={32} className="mx-auto mb-3" style={{ color: "var(--text-3)" }} />
              <p className="text-sm" style={{ color: "var(--text-3)" }}>
                Start the conversation — your coach is ready.
              </p>
            </div>
          </div>
        )}
        {messages.map((m) => (
          <MessageBubble key={m.id} msg={m} />
        ))}
        {sending && (
          <div className="flex gap-2.5">
            <div
              className="w-7 h-7 rounded-full flex items-center justify-center flex-none"
              style={{ background: "var(--surface-2)", border: "1px solid var(--border)" }}
            >
              <Bot size={13} style={{ color: "var(--text-2)" }} />
            </div>
            <div
              className="rounded-2xl px-4 py-2.5 text-sm"
              style={{
                background: "var(--surface-1)",
                border: "1px solid var(--border)",
                color: "var(--text-3)",
              }}
            >
              Thinking…
            </div>
          </div>
        )}
        <div ref={bottomRef} />
      </div>

      <div
        className="px-4 py-3 flex gap-2 border-t"
        style={{ borderColor: "var(--border)", background: "var(--surface-0)" }}
      >
        <textarea
          value={input}
          onChange={(e) => setInput(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === "Enter" && !e.shiftKey) {
              e.preventDefault();
              handleSend();
            }
          }}
          placeholder="Ask your coach anything…"
          rows={1}
          className="flex-1 resize-none rounded-xl px-3 py-2 text-sm outline-none"
          style={{
            background: "var(--surface-1)",
            border: "1px solid var(--border)",
            color: "var(--text-1)",
            maxHeight: 120,
          }}
        />
        <button
          onClick={handleSend}
          disabled={!input.trim() || sending}
          className="w-9 h-9 rounded-xl flex items-center justify-center transition-opacity"
          style={{
            background: "var(--accent)",
            opacity: !input.trim() || sending ? 0.4 : 1,
          }}
        >
          <Send size={14} color="#fff" />
        </button>
      </div>
    </div>
  );
}

// ── Weekly review card ─────────────────────────────────────────────────────────

function WeeklyReviewCard({ review }: { review: WeeklyReviewResponse }) {
  return (
    <div
      className="rounded-xl p-5 flex flex-col gap-3"
      style={{ background: "var(--surface-1)", border: "1px solid var(--border)" }}
    >
      <div className="flex items-center gap-2">
        <Calendar size={14} style={{ color: "var(--accent)" }} />
        <span className="text-xs font-semibold" style={{ color: "var(--text-2)" }}>
          Week of {review.week_start} → {review.week_end}
        </span>
      </div>
      <p className="text-sm leading-relaxed" style={{ color: "var(--text-2)" }}>
        {review.content}
      </p>
      <span className="text-xs" style={{ color: "var(--text-3)" }}>
        {fmtDate(review.created_at)} · {review.model_used}
      </span>
    </div>
  );
}

// ── Weekly reviews tab ─────────────────────────────────────────────────────────

function WeeklyReviewsTab() {
  const qc = useQueryClient();
  const { data: reviews, isLoading } = useQuery({
    queryKey: ["weekly-reviews"],
    queryFn: fetchWeeklyReviews,
  });

  const { mutate: generate, isPending } = useMutation({
    mutationFn: generateWeeklyReview,
    onSuccess: () => qc.invalidateQueries({ queryKey: ["weekly-reviews"] }),
  });

  return (
    <div className="flex flex-col gap-4">
      <Button onClick={() => generate()} loading={isPending} size="md" className="self-start">
        <RefreshCw size={14} />
        {isPending ? "Generating…" : "Generate This Week's Review"}
      </Button>

      {isLoading ? (
        <div className="flex justify-center py-8">
          <Spinner size={22} style={{ color: "var(--accent)" } as React.CSSProperties} />
        </div>
      ) : reviews && reviews.length > 0 ? (
        reviews.map((r) => <WeeklyReviewCard key={r.id} review={r} />)
      ) : (
        <p className="text-sm text-center py-8" style={{ color: "var(--text-3)" }}>
          No weekly reviews yet — click "Generate" to create your first one.
        </p>
      )}
    </div>
  );
}

// ── Growth report tab ──────────────────────────────────────────────────────────

function GrowthReportTab() {
  const [content, setContent] = useState<string | null>(null);
  const [err, setErr] = useState<string | null>(null);

  const { mutate, isPending } = useMutation({
    mutationFn: generateGrowthReport,
    onSuccess: (data) => {
      setContent(data.content);
      setErr(null);
    },
    onError: () => setErr("Failed to generate report. Check your Gemini API key."),
  });

  return (
    <div className="flex flex-col gap-4">
      <Button onClick={() => mutate()} loading={isPending} size="md" className="self-start">
        <Sparkles size={14} />
        {content ? "Regenerate" : "Generate Growth Report"}
      </Button>

      {err && (
        <div
          className="rounded-lg px-4 py-3 text-sm"
          style={{ background: "rgba(239,68,68,0.1)", color: "var(--danger)" }}
        >
          {err}
        </div>
      )}

      {content && (
        <div
          className="rounded-xl p-5"
          style={{ background: "var(--surface-1)", border: "1px solid var(--border)" }}
        >
          <div className="flex items-center gap-2 mb-4">
            <Sparkles size={14} style={{ color: "var(--accent)" }} />
            <span className="text-sm font-semibold" style={{ color: "var(--text-1)" }}>
              Your Growth Report
            </span>
          </div>
          <p className="text-sm leading-relaxed whitespace-pre-wrap" style={{ color: "var(--text-2)" }}>
            {content}
          </p>
        </div>
      )}
    </div>
  );
}

// ── Page ───────────────────────────────────────────────────────────────────────

type Tab = "chat" | "weekly" | "report";

export default function CoachPage() {
  const [tab, setTab] = useState<Tab>("chat");
  const [activeConvId, setActiveConvId] = useState<string | null>(null);
  const qc = useQueryClient();

  const { data: conversations, isLoading: convsLoading } = useQuery({
    queryKey: ["coach-conversations"],
    queryFn: fetchConversations,
    enabled: tab === "chat",
  });

  const { mutate: newConv, isPending: creating } = useMutation({
    mutationFn: () => createConversation(),
    onSuccess: (conv) => {
      qc.invalidateQueries({ queryKey: ["coach-conversations"] });
      setActiveConvId(conv.id);
    },
  });

  const TABS: { id: Tab; label: string; Icon: React.FC<{ size?: number }> }[] = [
    { id: "chat", label: "Chat", Icon: MessageSquare },
    { id: "weekly", label: "Weekly Review", Icon: Calendar },
    { id: "report", label: "Growth Report", Icon: Sparkles },
  ];

  return (
    <div className="flex flex-col gap-6 h-full">
      <div>
        <h1 className="text-2xl font-bold" style={{ color: "var(--text-1)" }}>AI Coach</h1>
        <p className="text-sm mt-1" style={{ color: "var(--text-2)" }}>
          Your personal growth companion powered by Gemini
        </p>
      </div>

      {/* Tabs */}
      <div
        className="flex gap-1 p-1 rounded-xl"
        style={{ background: "var(--surface-1)", border: "1px solid var(--border)" }}
      >
        {TABS.map(({ id, label, Icon }) => (
          <button
            key={id}
            onClick={() => setTab(id)}
            className="flex-1 flex items-center justify-center gap-1.5 py-2 rounded-lg text-sm font-medium transition-colors"
            style={{
              background: tab === id ? "var(--surface-2)" : "transparent",
              color: tab === id ? "var(--text-1)" : "var(--text-3)",
              border: tab === id ? "1px solid var(--border)" : "1px solid transparent",
            }}
          >
            <Icon size={13} />
            {label}
          </button>
        ))}
      </div>

      {tab === "chat" && (
        <div
          className="flex gap-0 rounded-xl overflow-hidden flex-1 min-h-0"
          style={{ border: "1px solid var(--border)", minHeight: 500 }}
        >
          {/* Sidebar */}
          <div
            className="w-56 flex flex-col border-r"
            style={{
              background: "var(--surface-1)",
              borderColor: "var(--border)",
              flexShrink: 0,
            }}
          >
            <div className="p-3">
              <button
                onClick={() => newConv()}
                disabled={creating}
                className="w-full flex items-center gap-1.5 px-3 py-2 rounded-lg text-sm transition-colors"
                style={{
                  background: "var(--accent-dim)",
                  color: "var(--accent)",
                  border: "1px solid var(--accent)",
                }}
              >
                <Plus size={13} />
                New Chat
              </button>
            </div>

            <div className="flex-1 overflow-y-auto px-2 pb-2 flex flex-col gap-1">
              {convsLoading ? (
                <div className="flex justify-center py-4">
                  <Spinner size={18} style={{ color: "var(--text-3)" } as React.CSSProperties} />
                </div>
              ) : !conversations || conversations.length === 0 ? (
                <p className="text-xs text-center py-4 px-2" style={{ color: "var(--text-3)" }}>
                  No conversations yet
                </p>
              ) : (
                conversations.map((c: AIConversationSummary) => (
                  <button
                    key={c.id}
                    onClick={() => setActiveConvId(c.id)}
                    className="w-full text-left px-3 py-2 rounded-lg text-xs transition-colors"
                    style={{
                      background: activeConvId === c.id ? "var(--surface-2)" : "transparent",
                      color: activeConvId === c.id ? "var(--text-1)" : "var(--text-2)",
                      border: `1px solid ${activeConvId === c.id ? "var(--border)" : "transparent"}`,
                    }}
                  >
                    <p className="truncate font-medium">{c.title}</p>
                    <p className="mt-0.5" style={{ color: "var(--text-3)" }}>{fmtDate(c.updated_at)}</p>
                  </button>
                ))
              )}
            </div>
          </div>

          {/* Chat area */}
          <div className="flex-1 flex flex-col min-h-0" style={{ background: "var(--surface-0)" }}>
            {activeConvId ? (
              <ChatWindow conversationId={activeConvId} />
            ) : (
              <div className="flex-1 flex items-center justify-center">
                <div className="text-center">
                  <MessageSquare size={36} className="mx-auto mb-3" style={{ color: "var(--text-3)" }} />
                  <p className="text-sm mb-4" style={{ color: "var(--text-3)" }}>
                    Select a chat or start a new one
                  </p>
                  <Button onClick={() => newConv()} loading={creating} size="sm">
                    <Plus size={13} />
                    New Chat
                  </Button>
                </div>
              </div>
            )}
          </div>
        </div>
      )}

      {tab === "weekly" && <WeeklyReviewsTab />}
      {tab === "report" && <GrowthReportTab />}
    </div>
  );
}
