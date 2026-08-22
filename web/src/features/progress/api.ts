import { apiClient } from "@/shared/api/client";
import type { StatHistoryResponse, StatsSummaryResponse, XPHistoryResponse } from "@/shared/api/types";

export async function fetchStatsSummary(): Promise<StatsSummaryResponse> {
  const { data } = await apiClient.get<StatsSummaryResponse>("/stats/summary");
  return data;
}

export async function fetchXPHistory(days = 30): Promise<XPHistoryResponse> {
  const { data } = await apiClient.get<XPHistoryResponse>("/stats/xp-history", {
    params: { days },
  });
  return data;
}

export async function fetchStatHistory(days = 30): Promise<StatHistoryResponse> {
  const { data } = await apiClient.get<StatHistoryResponse>("/stats/stat-history", {
    params: { days },
  });
  return data;
}
