import type { StatCategory, GoalDifficulty, MissionFrequency } from "@/shared/api/types";

export const STAT_META: Record<StatCategory, { label: string; color: string }> = {
  vitality:      { label: "Vitality",      color: "#ef4444" },
  strength:      { label: "Strength",      color: "#f97316" },
  intelligence:  { label: "Intelligence",  color: "#3b82f6" },
  wisdom:        { label: "Wisdom",        color: "#a855f7" },
  charisma:      { label: "Charisma",      color: "#eab308" },
  discipline:    { label: "Discipline",    color: "#22c55e" },
};

export const DIFFICULTY_META: Record<GoalDifficulty, { label: string; color: string }> = {
  easy:   { label: "Easy",   color: "#22c55e" },
  medium: { label: "Medium", color: "#eab308" },
  hard:   { label: "Hard",   color: "#f97316" },
  epic:   { label: "Epic",   color: "#a855f7" },
};

export const FREQUENCY_META: Record<MissionFrequency, { label: string }> = {
  daily:   { label: "Daily" },
  weekly:  { label: "Weekly" },
  monthly: { label: "Monthly" },
};

export const RANK_META: Record<string, { color: string; glow: boolean }> = {
  E: { color: "#6b7280", glow: false },
  D: { color: "#22c55e", glow: false },
  C: { color: "#3b82f6", glow: false },
  B: { color: "#a855f7", glow: false },
  A: { color: "#f97316", glow: true },
  S: { color: "#ef4444", glow: true },
};

export const STAT_CATEGORIES: StatCategory[] = [
  "vitality", "strength", "intelligence", "wisdom", "charisma", "discipline",
];

export const GOAL_DIFFICULTIES: GoalDifficulty[] = ["easy", "medium", "hard", "epic"];
export const MISSION_FREQUENCIES: MissionFrequency[] = ["daily", "weekly", "monthly"];
