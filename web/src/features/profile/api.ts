import { apiClient } from "@/shared/api/client";
import type { MeResponse } from "@/shared/api/types";

export async function fetchMe(): Promise<MeResponse> {
  const { data } = await apiClient.get<MeResponse>("/users/me");
  return data;
}

export async function updateProfile(payload: {
  display_name?: string;
  bio?: string;
  timezone?: string;
  theme_preference?: "dark" | "light" | "system";
}): Promise<MeResponse> {
  const { data } = await apiClient.patch<MeResponse>("/users/me/profile", payload);
  return data;
}

export async function changePassword(
  current_password: string,
  new_password: string
): Promise<void> {
  await apiClient.post("/users/me/change-password", { current_password, new_password });
}

export async function deleteAccount(password: string): Promise<void> {
  await apiClient.delete("/users/me", { data: { password } });
}
