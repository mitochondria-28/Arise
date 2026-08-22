import { apiClient } from "@/shared/api/client";
import type { TokenResponse } from "@/shared/api/types";

export async function register(email: string, password: string): Promise<TokenResponse> {
  const { data } = await apiClient.post<TokenResponse>("/auth/register", { email, password });
  return data;
}

export async function login(email: string, password: string): Promise<TokenResponse> {
  const { data } = await apiClient.post<TokenResponse>("/auth/login", { email, password });
  return data;
}

export async function logout(): Promise<void> {
  await apiClient.post("/auth/logout").catch(() => {});
}
