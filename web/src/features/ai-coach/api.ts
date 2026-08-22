import { apiClient } from "@/shared/api/client";
import type {
  AIConversationResponse,
  AIConversationSummary,
  AIMessageResponse,
  WeeklyReviewResponse,
} from "@/shared/api/types";

export async function fetchConversations(): Promise<AIConversationSummary[]> {
  const { data } = await apiClient.get<AIConversationSummary[]>("/coach/conversations");
  return data;
}

export async function createConversation(title = "New Conversation"): Promise<AIConversationSummary> {
  const { data } = await apiClient.post<AIConversationSummary>("/coach/conversations", { title });
  return data;
}

export async function fetchConversation(id: string): Promise<AIConversationResponse> {
  const { data } = await apiClient.get<AIConversationResponse>(`/coach/conversations/${id}`);
  return data;
}

export async function sendMessage(
  conversationId: string,
  content: string
): Promise<AIMessageResponse> {
  const { data } = await apiClient.post<AIMessageResponse>(
    `/coach/conversations/${conversationId}/messages`,
    { content }
  );
  return data;
}

export async function fetchWeeklyReviews(): Promise<WeeklyReviewResponse[]> {
  const { data } = await apiClient.get<WeeklyReviewResponse[]>("/coach/weekly-reviews");
  return data;
}

export async function generateWeeklyReview(): Promise<WeeklyReviewResponse> {
  const { data } = await apiClient.post<WeeklyReviewResponse>("/coach/weekly-reviews/generate");
  return data;
}
