import { Outlet } from "react-router-dom";
import { useThemeStore } from "@/shared/stores/theme.store";
import { Sun, Moon } from "lucide-react";

export default function AuthLayout() {
  const { theme, toggle } = useThemeStore();

  return (
    <div
      className="min-h-screen flex flex-col items-center justify-center p-4 relative"
      style={{ background: "var(--bg)" }}
    >
      {/* Theme toggle */}
      <button
        onClick={toggle}
        className="absolute top-4 right-4 w-9 h-9 flex items-center justify-center rounded-lg transition-colors hover:bg-[var(--surface-2)]"
        style={{ color: "var(--text-2)" }}
        aria-label="Toggle theme"
      >
        {theme === "dark" ? <Sun size={18} /> : <Moon size={18} />}
      </button>

      {/* Subtle background pattern */}
      <div
        className="absolute inset-0 opacity-[0.03] pointer-events-none"
        style={{
          backgroundImage: `radial-gradient(var(--accent) 1px, transparent 1px)`,
          backgroundSize: "32px 32px",
        }}
      />

      <div className="relative w-full max-w-sm">
        <div
          className="rounded-2xl p-8"
          style={{
            background: "var(--surface-1)",
            border: "1px solid var(--border)",
          }}
        >
          <Outlet />
        </div>
      </div>
    </div>
  );
}
