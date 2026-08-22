import { apiClient } from "@/shared/api/client";
import type { AIAnalysisResponse } from "@/shared/api/types";

export async function generateGrowthReport(): Promise<AIAnalysisResponse> {
  const { data } = await apiClient.post<AIAnalysisResponse>("/ai/growth-report");
  return data;
}

export async function fetchGoalAnalysis(goalId: string): Promise<AIAnalysisResponse> {
  const { data } = await apiClient.get<AIAnalysisResponse>(`/ai/analysis/goal/${goalId}`);
  return data;
}

export async function fetchMissionAnalysis(missionId: string): Promise<AIAnalysisResponse> {
  const { data } = await apiClient.get<AIAnalysisResponse>(`/ai/analysis/mission/${missionId}`);
  return data;
}
