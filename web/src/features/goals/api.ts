import { apiClient } from "@/shared/api/client";
import type {
  GoalMilestoneResponse,
  GoalResponse,
  GoalListResponse,
  GoalTemplateResponse,
  CompleteGoalResponse,
  GoalDifficulty,
  GoalStatus,
  StatCategory,
} from "@/shared/api/types";

export interface CreateGoalInput {
  title: string;
  description?: string;
  category: StatCategory;
  difficulty: GoalDifficulty;
  target_date?: string;
}

export interface CompleteGoalInput {
  evidence_text: string;
  reflection?: string;
  effort_level: number;
}

export async function fetchGoals(params?: {
  status?: GoalStatus;
  category?: StatCategory;
  page?: number;
  page_size?: number;
}): Promise<GoalListResponse> {
  const { data } = await apiClient.get<GoalListResponse>("/goals", { params });
  return data;
}

export async function createGoal(input: CreateGoalInput): Promise<GoalResponse> {
  const { data } = await apiClient.post<GoalResponse>("/goals", input);
  return data;
}

export async function completeGoal(
  goalId: string,
  input: CompleteGoalInput
): Promise<CompleteGoalResponse> {
  const { data } = await apiClient.post<CompleteGoalResponse>(
    `/goals/${goalId}/complete`,
    input
  );
  return data;
}

export async function archiveGoal(goalId: string): Promise<void> {
  await apiClient.delete(`/goals/${goalId}`);
}

export async function fetchTemplates(category?: string): Promise<GoalTemplateResponse[]> {
  const { data } = await apiClient.get<GoalTemplateResponse[]>("/goals/templates", {
    params: category ? { category } : undefined,
  });
  return data;
}

// ── Milestones ─────────────────────────────────────────────────────────────────

export async function fetchMilestones(goalId: string): Promise<GoalMilestoneResponse[]> {
  const { data } = await apiClient.get<GoalMilestoneResponse[]>(`/goals/${goalId}/milestones`);
  return data;
}

export async function createMilestone(
  goalId: string,
  payload: { title: string; description?: string; sort_order?: number }
): Promise<GoalMilestoneResponse> {
  const { data } = await apiClient.post<GoalMilestoneResponse>(
    `/goals/${goalId}/milestones`,
    payload
  );
  return data;
}

export async function toggleMilestone(
  goalId: string,
  milestoneId: string,
  is_completed: boolean
): Promise<GoalMilestoneResponse> {
  const { data } = await apiClient.patch<GoalMilestoneResponse>(
    `/goals/${goalId}/milestones/${milestoneId}`,
    { is_completed }
  );
  return data;
}

export async function deleteMilestone(goalId: string, milestoneId: string): Promise<void> {
  await apiClient.delete(`/goals/${goalId}/milestones/${milestoneId}`);
}
