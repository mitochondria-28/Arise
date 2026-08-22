import { apiClient } from "@/shared/api/client";
import type {
  CreateJournalRequest,
  JournalEntryResponse,
  JournalListResponse,
  JournalStreakResponse,
  UpdateJournalRequest,
} from "@/shared/api/types";

export async function fetchJournalEntries(
  limit = 30,
  offset = 0
): Promise<JournalListResponse> {
  const { data } = await apiClient.get<JournalListResponse>("/journal", {
    params: { limit, offset },
  });
  return data;
}

export async function fetchTodayEntry(): Promise<JournalEntryResponse | null> {
  const { data } = await apiClient.get<JournalEntryResponse | null>("/journal/today");
  return data;
}

export async function fetchJournalStreak(): Promise<JournalStreakResponse> {
  const { data } = await apiClient.get<JournalStreakResponse>("/journal/streak");
  return data;
}

export async function createOrUpdateEntry(
  body: CreateJournalRequest
): Promise<JournalEntryResponse> {
  const { data } = await apiClient.post<JournalEntryResponse>("/journal", body);
  return data;
}

export async function updateEntry(
  id: string,
  body: UpdateJournalRequest
): Promise<JournalEntryResponse> {
  const { data } = await apiClient.put<JournalEntryResponse>(`/journal/${id}`, body);
  return data;
}

export async function generateReflection(id: string): Promise<JournalEntryResponse> {
  const { data } = await apiClient.post<JournalEntryResponse>(`/journal/${id}/reflect`);
  return data;
}
