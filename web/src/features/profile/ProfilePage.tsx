import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { User, Lock, Trash2, Check, AlertTriangle } from "lucide-react";
import { useNavigate } from "react-router-dom";
import { fetchMe, updateProfile, changePassword, deleteAccount } from "./api";
import { useAuth } from "@/features/auth/AuthContext";
import { Spinner } from "@/shared/components/ui/Spinner";

// ── Section wrapper ────────────────────────────────────────────────────────────

function Section({
  title,
  children,
}: {
  title: string;
  children: React.ReactNode;
}) {
  return (
    <div
      className="rounded-2xl p-5 flex flex-col gap-4"
      style={{ background: "var(--surface-1)", border: "1px solid var(--border)" }}
    >
      <h2 className="text-base font-semibold" style={{ color: "var(--text-1)" }}>
        {title}
      </h2>
      {children}
    </div>
  );
}

// ── Form field ─────────────────────────────────────────────────────────────────

function Field({
  label,
  children,
}: {
  label: string;
  children: React.ReactNode;
}) {
  return (
    <div className="flex flex-col gap-1.5">
      <label className="text-xs font-medium" style={{ color: "var(--text-3)" }}>
        {label}
      </label>
      {children}
    </div>
  );
}

function Input({
  value,
  onChange,
  type = "text",
  placeholder,
  disabled,
}: {
  value: string;
  onChange: (v: string) => void;
  type?: string;
  placeholder?: string;
  disabled?: boolean;
}) {
  return (
    <input
      type={type}
      value={value}
      onChange={(e) => onChange(e.target.value)}
      placeholder={placeholder}
      disabled={disabled}
      className="w-full rounded-xl px-3 py-2 text-sm outline-none transition-colors disabled:opacity-50"
      style={{
        background: "var(--surface-2)",
        border: "1px solid var(--border)",
        color: "var(--text-1)",
      }}
      onFocus={(e) => (e.currentTarget.style.borderColor = "var(--accent)")}
      onBlur={(e) => (e.currentTarget.style.borderColor = "var(--border)")}
    />
  );
}

function SaveButton({
  onClick,
  pending,
  saved,
  disabled,
}: {
  onClick: () => void;
  pending: boolean;
  saved: boolean;
  disabled?: boolean;
}) {
  return (
    <button
      onClick={onClick}
      disabled={disabled || pending}
      className="self-start flex items-center gap-2 px-4 py-2 rounded-xl text-sm font-semibold transition-colors"
      style={{
        background: saved ? "#22c55e" : "var(--accent)",
        color: "#fff",
        opacity: disabled || pending ? 0.6 : 1,
        cursor: disabled || pending ? "not-allowed" : "pointer",
      }}
    >
      {pending ? (
        <Spinner size={13} style={{ color: "#fff" } as React.CSSProperties} />
      ) : saved ? (
        <Check size={13} />
      ) : null}
      {saved ? "Saved!" : pending ? "Saving…" : "Save"}
    </button>
  );
}

// ── Profile info section ───────────────────────────────────────────────────────

function ProfileSection({
  displayName: initialDisplayName,
  bio: initialBio,
  timezone: initialTimezone,
  themePreference: initialTheme,
}: {
  displayName: string;
  bio: string;
  timezone: string;
  themePreference: string;
}) {
  const qc = useQueryClient();
  const [displayName, setDisplayName] = useState(initialDisplayName);
  const [bio, setBio] = useState(initialBio);
  const [timezone, setTimezone] = useState(initialTimezone);
  const [theme, setTheme] = useState(initialTheme);
  const [saved, setSaved] = useState(false);

  const mutation = useMutation({
    mutationFn: () =>
      updateProfile({
        display_name: displayName || undefined,
        bio: bio || undefined,
        timezone: timezone || undefined,
        theme_preference: theme as "dark" | "light" | "system",
      }),
    onSuccess: (data) => {
      qc.setQueryData(["me"], data);
      setSaved(true);
      setTimeout(() => setSaved(false), 2500);
    },
  });

  return (
    <Section title="Profile">
      <Field label="Display name">
        <Input value={displayName} onChange={setDisplayName} placeholder="Your hunter name" />
      </Field>
      <Field label="Bio">
        <textarea
          value={bio}
          onChange={(e) => setBio(e.target.value)}
          placeholder="A short bio about yourself…"
          rows={3}
          maxLength={500}
          className="w-full resize-none rounded-xl px-3 py-2 text-sm outline-none transition-colors"
          style={{
            background: "var(--surface-2)",
            border: "1px solid var(--border)",
            color: "var(--text-1)",
          }}
          onFocus={(e) => (e.currentTarget.style.borderColor = "var(--accent)")}
          onBlur={(e) => (e.currentTarget.style.borderColor = "var(--border)")}
        />
        <span className="text-xs self-end" style={{ color: "var(--text-3)" }}>
          {bio.length}/500
        </span>
      </Field>
      <Field label="Timezone">
        <Input value={timezone} onChange={setTimezone} placeholder="e.g. UTC, America/New_York" />
      </Field>
      <Field label="Theme">
        <div className="flex gap-2">
          {(["dark", "light", "system"] as const).map((t) => (
            <button
              key={t}
              onClick={() => setTheme(t)}
              className="flex-1 py-2 rounded-xl text-xs font-medium capitalize transition-all"
              style={{
                background: theme === t ? "var(--accent)" : "var(--surface-2)",
                color: theme === t ? "#fff" : "var(--text-2)",
                border: theme === t ? "1px solid var(--accent)" : "1px solid var(--border)",
              }}
            >
              {t}
            </button>
          ))}
        </div>
      </Field>
      {mutation.isError && (
        <p className="text-xs" style={{ color: "#ef4444" }}>
          Failed to save. Please try again.
        </p>
      )}
      <SaveButton
        onClick={() => mutation.mutate()}
        pending={mutation.isPending}
        saved={saved}
      />
    </Section>
  );
}

// ── Change password section ────────────────────────────────────────────────────

function PasswordSection() {
  const [current, setCurrent] = useState("");
  const [next, setNext] = useState("");
  const [confirm, setConfirm] = useState("");
  const [saved, setSaved] = useState(false);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  const mismatch = confirm.length > 0 && next !== confirm;
  const tooShort = next.length > 0 && next.length < 8;

  const mutation = useMutation({
    mutationFn: () => changePassword(current, next),
    onSuccess: () => {
      setCurrent("");
      setNext("");
      setConfirm("");
      setErrorMsg(null);
      setSaved(true);
      setTimeout(() => setSaved(false), 2500);
    },
    onError: (e: Error) => {
      setErrorMsg(
        e.message?.includes("422") || e.message?.includes("incorrect")
          ? "Current password is incorrect."
          : "Failed to change password."
      );
    },
  });

  const canSave =
    current.length > 0 && next.length >= 8 && next === confirm && !mutation.isPending;

  return (
    <Section title="Security">
      <Field label="Current password">
        <Input type="password" value={current} onChange={setCurrent} />
      </Field>
      <Field label="New password">
        <Input type="password" value={next} onChange={setNext} placeholder="Minimum 8 characters" />
        {tooShort && (
          <p className="text-xs" style={{ color: "#f97316" }}>
            Must be at least 8 characters.
          </p>
        )}
      </Field>
      <Field label="Confirm new password">
        <Input type="password" value={confirm} onChange={setConfirm} />
        {mismatch && (
          <p className="text-xs" style={{ color: "#ef4444" }}>
            Passwords don't match.
          </p>
        )}
      </Field>
      {errorMsg && (
        <p className="text-xs" style={{ color: "#ef4444" }}>
          {errorMsg}
        </p>
      )}
      <SaveButton
        onClick={() => mutation.mutate()}
        pending={mutation.isPending}
        saved={saved}
        disabled={!canSave}
      />
    </Section>
  );
}

// ── Danger zone ────────────────────────────────────────────────────────────────

function DangerZone() {
  const { logout } = useAuth();
  const navigate = useNavigate();
  const [open, setOpen] = useState(false);
  const [password, setPassword] = useState("");
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  const mutation = useMutation({
    mutationFn: () => deleteAccount(password),
    onSuccess: async () => {
      await logout();
      navigate("/login", { replace: true });
    },
    onError: () => {
      setErrorMsg("Incorrect password. Account not deleted.");
    },
  });

  return (
    <div
      className="rounded-2xl p-5 flex flex-col gap-4"
      style={{ background: "var(--surface-1)", border: "1px solid #ef444440" }}
    >
      <div className="flex items-center gap-2">
        <AlertTriangle size={16} style={{ color: "#ef4444" }} />
        <h2 className="text-base font-semibold" style={{ color: "#ef4444" }}>
          Danger Zone
        </h2>
      </div>

      {!open ? (
        <div className="flex items-center justify-between">
          <div>
            <p className="text-sm font-medium" style={{ color: "var(--text-1)" }}>
              Delete account
            </p>
            <p className="text-xs mt-0.5" style={{ color: "var(--text-3)" }}>
              Permanently deactivate your account. This cannot be undone.
            </p>
          </div>
          <button
            onClick={() => setOpen(true)}
            className="px-3 py-1.5 rounded-lg text-sm font-medium transition-colors"
            style={{
              background: "#ef44441a",
              color: "#ef4444",
              border: "1px solid #ef444440",
            }}
          >
            Delete
          </button>
        </div>
      ) : (
        <div className="flex flex-col gap-3">
          <p className="text-sm" style={{ color: "var(--text-2)" }}>
            Enter your password to confirm account deletion:
          </p>
          <Input type="password" value={password} onChange={setPassword} placeholder="Password" />
          {errorMsg && (
            <p className="text-xs" style={{ color: "#ef4444" }}>
              {errorMsg}
            </p>
          )}
          <div className="flex gap-2">
            <button
              onClick={() => {
                setOpen(false);
                setPassword("");
                setErrorMsg(null);
              }}
              className="flex-1 py-2 rounded-xl text-sm font-medium"
              style={{
                background: "var(--surface-2)",
                color: "var(--text-2)",
                border: "1px solid var(--border)",
              }}
            >
              Cancel
            </button>
            <button
              onClick={() => mutation.mutate()}
              disabled={!password || mutation.isPending}
              className="flex-1 py-2 rounded-xl text-sm font-semibold flex items-center justify-center gap-2"
              style={{
                background: "#ef4444",
                color: "#fff",
                opacity: !password || mutation.isPending ? 0.6 : 1,
                cursor: !password || mutation.isPending ? "not-allowed" : "pointer",
              }}
            >
              {mutation.isPending ? (
                <Spinner size={13} style={{ color: "#fff" } as React.CSSProperties} />
              ) : (
                <Trash2 size={13} />
              )}
              {mutation.isPending ? "Deleting…" : "Confirm Delete"}
            </button>
          </div>
        </div>
      )}
    </div>
  );
}

// ── Account info card ──────────────────────────────────────────────────────────

function AccountCard({
  email,
  memberSince,
}: {
  email: string;
  memberSince: string;
}) {
  const since = new Date(memberSince).toLocaleDateString("en-US", {
    year: "numeric",
    month: "long",
    day: "numeric",
  });

  return (
    <div
      className="rounded-2xl p-5 flex items-center gap-4"
      style={{ background: "var(--surface-1)", border: "1px solid var(--border)" }}
    >
      <div
        className="w-14 h-14 rounded-full flex items-center justify-center text-xl font-bold flex-none"
        style={{ background: "var(--accent-dim)", color: "var(--accent)" }}
      >
        {email.slice(0, 2).toUpperCase()}
      </div>
      <div className="flex flex-col gap-0.5 min-w-0">
        <p
          className="text-sm font-semibold truncate"
          style={{ color: "var(--text-1)" }}
        >
          {email}
        </p>
        <p className="text-xs" style={{ color: "var(--text-3)" }}>
          Member since {since}
        </p>
      </div>
    </div>
  );
}

// ── Page ───────────────────────────────────────────────────────────────────────

export default function ProfilePage() {
  const { data, isLoading, isError } = useQuery({
    queryKey: ["me"],
    queryFn: fetchMe,
  });

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-[60vh]">
        <Spinner size={28} style={{ color: "var(--accent)" } as React.CSSProperties} />
      </div>
    );
  }

  if (isError || !data) {
    return (
      <div className="flex items-center justify-center min-h-[60vh]">
        <p className="text-sm" style={{ color: "var(--text-3)" }}>
          Failed to load profile.
        </p>
      </div>
    );
  }

  const profile = data.profile;

  return (
    <div className="flex flex-col gap-6">
      <div>
        <div className="flex items-center gap-2 mb-1">
          <User size={20} style={{ color: "var(--accent)" }} />
          <h1 className="text-2xl font-bold" style={{ color: "var(--text-1)" }}>
            Profile & Settings
          </h1>
        </div>
        <p className="text-sm" style={{ color: "var(--text-2)" }}>
          Manage your account information and preferences
        </p>
      </div>

      <AccountCard email={data.email} memberSince={data.created_at} />

      {profile ? (
        <ProfileSection
          displayName={profile.display_name}
          bio={profile.bio ?? ""}
          timezone={profile.timezone}
          themePreference={profile.theme_preference}
        />
      ) : (
        <div
          className="rounded-2xl p-5"
          style={{ background: "var(--surface-1)", border: "1px solid var(--border)" }}
        >
          <p className="text-sm" style={{ color: "var(--text-3)" }}>
            Profile not yet set up.
          </p>
        </div>
      )}

      <PasswordSection />

      <div>
        <div
          className="flex items-center gap-2 px-2 py-1 mb-3"
        >
          <Lock size={14} style={{ color: "var(--text-3)" }} />
          <p className="text-xs" style={{ color: "var(--text-3)" }}>
            Account actions
          </p>
        </div>
        <DangerZone />
      </div>
    </div>
  );
}
