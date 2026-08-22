import { apiClient } from "@/shared/api/client";
import type { PracticeResponse, SkillResponse, UserSkillResponse } from "@/shared/api/types";

export async function fetchCatalog(category?: string): Promise<SkillResponse[]> {
  const { data } = await apiClient.get<SkillResponse[]>("/skills", {
    params: category ? { category } : undefined,
  });
  return data;
}

export async function fetchMySkills(): Promise<UserSkillResponse[]> {
  const { data } = await apiClient.get<UserSkillResponse[]>("/skills/me");
  return data;
}

export async function unlockSkill(skillId: string): Promise<UserSkillResponse> {
  const { data } = await apiClient.post<UserSkillResponse>(`/skills/${skillId}/unlock`);
  return data;
}

export async function practiceSkill(
  skillId: string,
  payload: { notes: string; duration_minutes?: number }
): Promise<PracticeResponse> {
  const { data } = await apiClient.post<PracticeResponse>(
    `/skills/${skillId}/practice`,
    payload
  );
  return data;
}
