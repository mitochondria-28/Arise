// ── Auth ──────────────────────────────────────────────────────────────────────

export interface TokenResponse {
  access_token: string;
  refresh_token: string;
  token_type: string;
}

// ── User ──────────────────────────────────────────────────────────────────────

export interface UserResponse {
  id: string;
  email: string;
  is_active: boolean;
  is_verified: boolean;
  created_at: string;
}

export interface ProfileResponse {
  id: string;
  user_id: string;
  display_name: string;
  avatar_url: string | null;
  bio: string | null;
  timezone: string;
  theme_preference: "dark" | "light" | "system";
}

export interface MeResponse {
  id: string;
  email: string;
  is_active: boolean;
  is_verified: boolean;
  created_at: string;
  profile: ProfileResponse | null;
}

// ── Character ─────────────────────────────────────────────────────────────────

export interface StatSnapshot {
  vitality: number;
  strength: number;
  intelligence: number;
  wisdom: number;
  charisma: number;
  discipline: number;
}

export interface CharacterResponse {
  id: string;
  user_id: string;
  title: string;
  level: number;
  rank: string;
  total_xp: number;
  current_level_xp: number;
  xp_to_next_level: number;
  stats: StatSnapshot | null;
}

// ── Goals ─────────────────────────────────────────────────────────────────────

export type StatCategory =
  | "vitality"
  | "strength"
  | "intelligence"
  | "wisdom"
  | "charisma"
  | "discipline";

export type GoalDifficulty = "easy" | "medium" | "hard" | "epic";
export type GoalStatus = "active" | "completed" | "abandoned" | "archived";

export interface GoalCompletionResponse {
  id: string;
  evidence_text: string;
  reflection: string | null;
  effort_level: number;
  xp_awarded: number;
}

export interface GoalResponse {
  id: string;
  user_id: string;
  title: string;
  description: string | null;
  category: StatCategory;
  difficulty: GoalDifficulty;
  target_date: string | null;
  status: GoalStatus;
  completed_at: string | null;
  completion: GoalCompletionResponse | null;
  created_at: string;
  updated_at: string;
}

export interface GoalListResponse {
  goals: GoalResponse[];
  total: number;
  page: number;
  page_size: number;
}

export interface CompleteGoalResponse {
  goal: GoalResponse;
  xp_awarded: number;
  levels_gained: number[];
}

export interface GoalMilestoneResponse {
  id: string;
  goal_id: string;
  title: string;
  description: string | null;
  is_completed: boolean;
  sort_order: number;
  created_at: string;
  updated_at: string;
}

export interface GoalTemplateResponse {
  id: string;
  title: string;
  description: string;
  category: StatCategory;
  difficulty: GoalDifficulty;
  emoji: string;
  sort_order: number;
}

// ── Missions ──────────────────────────────────────────────────────────────────

export type MissionFrequency = "daily" | "weekly" | "monthly";
export type MissionStatus = "active" | "paused" | "completed" | "archived";

export interface MissionLogResponse {
  id: string;
  mission_id: string;
  evidence_text: string;
  reflection: string | null;
  effort_level: number;
  xp_awarded: number;
  streak_at_checkin: number;
  created_at: string;
}

export interface MissionResponse {
  id: string;
  user_id: string;
  title: string;
  description: string | null;
  category: StatCategory;
  difficulty: GoalDifficulty;
  frequency: MissionFrequency;
  status: MissionStatus;
  target_count: number;
  completion_count: number;
  current_streak: number;
  longest_streak: number;
  last_completed_at: string | null;
  can_checkin_now: boolean;
  created_at: string;
  updated_at: string;
}

export interface MissionListResponse {
  missions: MissionResponse[];
  total: number;
  page: number;
  page_size: number;
}

export interface CheckinResponse {
  mission: MissionResponse;
  log: MissionLogResponse;
  xp_awarded: number;
  new_streak: number;
  levels_gained: number[];
}

export interface MissionTemplateResponse {
  id: string;
  title: string;
  description: string;
  category: StatCategory;
  difficulty: GoalDifficulty;
  frequency: MissionFrequency;
  emoji: string;
  sort_order: number;
}

// ── Journal ───────────────────────────────────────────────────────────────────

export interface JournalEntryResponse {
  id: string;
  user_id: string;
  entry_date: string;   // YYYY-MM-DD
  content: string;
  mood: number | null;  // 1–5
  ai_reflection: string | null;
  created_at: string;
  updated_at: string;
}

export interface JournalListResponse {
  entries: JournalEntryResponse[];
  total: number;
  streak: number;
}

export interface JournalStreakResponse {
  streak: number;
  total_entries: number;
}

export interface CreateJournalRequest {
  content: string;
  mood?: number | null;
  entry_date?: string | null;
}

export interface UpdateJournalRequest {
  content: string;
  mood?: number | null;
}

// ── Achievements ──────────────────────────────────────────────────────────────

export type AchievementCategory = "xp" | "goals" | "streak" | "missions" | "level" | "rank";

export interface AchievementResponse {
  key: string;
  title: string;
  description: string;
  icon: string;
  category: AchievementCategory;
  threshold: number;
  unlocked_at: string | null;
}

export interface SyncResponse {
  newly_unlocked: AchievementResponse[];
  total_unlocked: number;
}

// ── Stats ─────────────────────────────────────────────────────────────────────

export interface MissionStreakEntry {
  title: string;
  current_streak: number;
  longest_streak: number;
  completion_count: number;
  frequency: string;
}

export interface StatsSummaryResponse {
  total_xp: number;
  current_level: number;
  rank: string;
  goals_completed: number;
  goals_by_difficulty: Record<string, number>;
  goals_by_category: Record<string, number>;
  missions_active: number;
  total_checkins: number;
  best_streak: number;
  current_streak_max: number;
  top_missions: MissionStreakEntry[];
}

export interface XPDayEntry {
  date: string;
  xp: number;
  goal_xp: number;
  mission_xp: number;
}

export interface XPHistoryResponse {
  entries: XPDayEntry[];
  total_xp_in_period: number;
  days: number;
}

export interface StatHistoryEntry {
  date: string;
  vitality: number;
  strength: number;
  intelligence: number;
  wisdom: number;
  charisma: number;
  discipline: number;
  total_xp: number;
  level: number;
}

export interface StatHistoryResponse {
  entries: StatHistoryEntry[];
  days: number;
}

// ── Skills ────────────────────────────────────────────────────────────────────

export interface SkillResponse {
  id: string;
  name: string;
  description: string;
  category: StatCategory;
  emoji: string;
  sort_order: number;
}

export interface UserSkillResponse {
  id: string;
  user_id: string;
  skill_id: string;
  level: number;
  session_count: number;
  total_xp_earned: number;
  last_practiced_at: string | null;
  skill: SkillResponse;
  sessions_to_next_level: number;
  xp_per_session: number;
}

export interface PracticeResponse {
  user_skill: UserSkillResponse;
  xp_awarded: number;
  levels_gained: number[];
  leveled_up: boolean;
}

// ── AI ────────────────────────────────────────────────────────────────────────

export interface AIAnalysisResponse {
  id: string;
  character_id: string;
  source_type: string;
  source_id: string | null;
  content: string;
  model_used: string;
  created_at: string;
}

// ── Coach (Chat + Weekly Reviews) ─────────────────────────────────────────────

export interface AIMessageResponse {
  id: string;
  conversation_id: string;
  role: "user" | "model";
  content: string;
  created_at: string;
}

export interface AIConversationSummary {
  id: string;
  title: string;
  created_at: string;
  updated_at: string;
}

export interface AIConversationResponse extends AIConversationSummary {
  user_id: string;
  messages: AIMessageResponse[];
}

export interface WeeklyReviewResponse {
  id: string;
  user_id: string;
  week_start: string;
  week_end: string;
  content: string;
  model_used: string;
  created_at: string;
}
