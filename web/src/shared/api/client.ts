import axios from "axios";

export const apiClient = axios.create({
  baseURL: "/api/v1",
  headers: { "Content-Type": "application/json" },
});

let _accessToken: string | null = null;

export function setAccessToken(token: string | null) {
  _accessToken = token;
}

export function getAccessToken(): string | null {
  return _accessToken;
}

// ── Request: attach bearer token ──────────────────────────────────────────────

apiClient.interceptors.request.use((config) => {
  if (_accessToken) {
    config.headers.Authorization = `Bearer ${_accessToken}`;
  }
  return config;
});

// ── Response: 401 → silent refresh → retry ────────────────────────────────────

let _refreshing: Promise<string> | null = null;

async function silentRefresh(): Promise<string> {
  const stored = localStorage.getItem("arise-refresh-token");
  if (!stored) throw new Error("No refresh token");
  const { data } = await axios.post<{
    access_token: string;
    refresh_token: string;
  }>("/api/v1/auth/refresh", { refresh_token: stored });
  setAccessToken(data.access_token);
  localStorage.setItem("arise-refresh-token", data.refresh_token);
  return data.access_token;
}

apiClient.interceptors.response.use(
  (res) => res,
  async (error: unknown) => {
    if (!axios.isAxiosError(error)) return Promise.reject(error);
    const config = error.config as typeof error.config & { _retry?: boolean };
    if (error.response?.status !== 401 || config?._retry) {
      return Promise.reject(error);
    }
    if (config) config._retry = true;
    try {
      if (!_refreshing) {
        _refreshing = silentRefresh().finally(() => { _refreshing = null; });
      }
      const token = await _refreshing;
      if (config) {
        config.headers = config.headers ?? {};
        config.headers.Authorization = `Bearer ${token}`;
        return apiClient(config);
      }
    } catch {
      setAccessToken(null);
      localStorage.removeItem("arise-refresh-token");
      window.location.href = "/login";
    }
    return Promise.reject(error);
  }
);
