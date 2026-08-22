import { apiClient } from "@/shared/api/client";
import type { AchievementResponse, SyncResponse } from "@/shared/api/types";

export async function fetchAchievements(): Promise<AchievementResponse[]> {
  const { data } = await apiClient.get<AchievementResponse[]>("/achievements");
  return data;
}

export async function syncAchievements(): Promise<SyncResponse> {
  const { data } = await apiClient.post<SyncResponse>("/achievements/sync");
  return data;
}
