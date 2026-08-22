import { apiClient } from "@/shared/api/client";
import type { CharacterResponse } from "@/shared/api/types";

export async function fetchCharacter(): Promise<CharacterResponse> {
  const { data } = await apiClient.get<CharacterResponse>("/character");
  return data;
}
