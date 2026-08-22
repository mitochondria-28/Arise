import { useState, useEffect } from "react";

type Theme = "light" | "dark";

function getSystemTheme(): Theme {
  if (typeof window === "undefined") return "dark";
  return window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";
}

function getStoredTheme(): Theme | null {
  try {
    const stored = localStorage.getItem("arise-theme");
    if (stored === "light" || stored === "dark") return stored;
  } catch {}
  return null;
}

// Minimal store — replaced with Zustand in Phase 7
let _theme: Theme = getStoredTheme() ?? getSystemTheme();
const _listeners = new Set<() => void>();

function setTheme(t: Theme) {
  _theme = t;
  try { localStorage.setItem("arise-theme", t); } catch {}
  _listeners.forEach((fn) => fn());
}

export function useThemeStore() {
  const [theme, setLocalTheme] = useState<Theme>(_theme);

  useEffect(() => {
    const sync = () => setLocalTheme(_theme);
    _listeners.add(sync);
    return () => { _listeners.delete(sync); };
  }, []);

  return {
    theme,
    setTheme,
    toggle: () => setTheme(_theme === "dark" ? "light" : "dark"),
  };
}
