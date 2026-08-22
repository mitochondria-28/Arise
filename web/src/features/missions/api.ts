import { apiClient } from "@/shared/api/client";
import type {
  MissionResponse,
  MissionListResponse,
  MissionTemplateResponse,
  CheckinResponse,
  GoalDifficulty,
  MissionFrequency,
  MissionStatus,
  StatCategory,
} from "@/shared/api/types";

export interface CreateMissionInput {
  title: string;
  description?: string;
  category: StatCategory;
  difficulty: GoalDifficulty;
  frequency: MissionFrequency;
  target_count?: number;
}

export interface CheckinInput {
  evidence_text: string;
  reflection?: string;
  effort_level: number;
}

export async function fetchMissions(params?: {
  status?: MissionStatus;
  category?: StatCategory;
  frequency?: MissionFrequency;
  page?: number;
  page_size?: number;
}): Promise<MissionListResponse> {
  const { data } = await apiClient.get<MissionListResponse>("/missions", { params });
  return data;
}

export async function createMission(input: CreateMissionInput): Promise<MissionResponse> {
  const { data } = await apiClient.post<MissionResponse>("/missions", input);
  return data;
}

export async function checkinMission(
  missionId: string,
  input: CheckinInput
): Promise<CheckinResponse> {
  const { data } = await apiClient.post<CheckinResponse>(
    `/missions/${missionId}/checkin`,
    input
  );
  return data;
}

export async function archiveMission(missionId: string): Promise<void> {
  await apiClient.delete(`/missions/${missionId}`);
}

export async function fetchMissionTemplates(params?: {
  category?: string;
  frequency?: string;
}): Promise<MissionTemplateResponse[]> {
  const { data } = await apiClient.get<MissionTemplateResponse[]>(
    "/missions/templates",
    { params }
  );
  return data;
}
