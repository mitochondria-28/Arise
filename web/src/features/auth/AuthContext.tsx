import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useReducer,
  type ReactNode,
} from "react";
import { setAccessToken } from "@/shared/api/client";
import * as authApi from "./api";
import axios from "axios";

// ── State ──────────────────────────────────────────────────────────────────────

type AuthState =
  | { status: "loading" }
  | { status: "authenticated"; email: string }
  | { status: "unauthenticated" };

type AuthAction =
  | { type: "AUTHENTICATED"; email: string }
  | { type: "UNAUTHENTICATED" };

function reducer(_: AuthState, action: AuthAction): AuthState {
  if (action.type === "AUTHENTICATED") return { status: "authenticated", email: action.email };
  return { status: "unauthenticated" };
}

function getEmailFromToken(token: string): string {
  try {
    const payload = JSON.parse(atob(token.split(".")[1]));
    return (payload.sub as string) ?? "";
  } catch {
    return "";
  }
}

// ── Context ────────────────────────────────────────────────────────────────────

interface AuthContextValue {
  state: AuthState;
  login: (email: string, password: string) => Promise<void>;
  register: (email: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
}

const AuthContext = createContext<AuthContextValue | null>(null);

// ── Provider ───────────────────────────────────────────────────────────────────

export function AuthProvider({ children }: { children: ReactNode }) {
  const [state, dispatch] = useReducer(reducer, { status: "loading" });

  // Restore session on mount
  useEffect(() => {
    const stored = localStorage.getItem("arise-refresh-token");
    if (!stored) {
      dispatch({ type: "UNAUTHENTICATED" });
      return;
    }
    axios
      .post<{ access_token: string; refresh_token: string }>("/api/v1/auth/refresh", {
        refresh_token: stored,
      })
      .then(({ data }) => {
        setAccessToken(data.access_token);
        localStorage.setItem("arise-refresh-token", data.refresh_token);
        dispatch({ type: "AUTHENTICATED", email: getEmailFromToken(data.access_token) });
      })
      .catch(() => {
        localStorage.removeItem("arise-refresh-token");
        dispatch({ type: "UNAUTHENTICATED" });
      });
  }, []);

  const login = useCallback(async (email: string, password: string) => {
    const tokens = await authApi.login(email, password);
    setAccessToken(tokens.access_token);
    localStorage.setItem("arise-refresh-token", tokens.refresh_token);
    dispatch({ type: "AUTHENTICATED", email });
  }, []);

  const register = useCallback(async (email: string, password: string) => {
    const tokens = await authApi.register(email, password);
    setAccessToken(tokens.access_token);
    localStorage.setItem("arise-refresh-token", tokens.refresh_token);
    dispatch({ type: "AUTHENTICATED", email });
  }, []);

  const logout = useCallback(async () => {
    await authApi.logout();
    setAccessToken(null);
    localStorage.removeItem("arise-refresh-token");
    dispatch({ type: "UNAUTHENTICATED" });
  }, []);

  return (
    <AuthContext.Provider value={{ state, login, register, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

// ── Hook ───────────────────────────────────────────────────────────────────────

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used inside AuthProvider");
  return ctx;
}
