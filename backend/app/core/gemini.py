"""
Gemini AI client wrapper (google-genai SDK).

The `generate()` method calls the API via asyncio.to_thread so it never
blocks the event loop.  If GEMINI_API_KEY is empty, all calls return None
gracefully — the rest of the system degrades without errors.
"""
import asyncio
import logging

from app.core.config import settings

logger = logging.getLogger(__name__)

_SYSTEM_PROMPT = (
    "You are Arise's personal growth coach. You analyze users' real-world achievements "
    "and provide concise, evidence-based insights to support their development journey.\n\n"
    "Rules:\n"
    "- Only reference what the user has explicitly stated\n"
    "- Be specific, not generic — no filler phrases like 'great job'\n"
    "- Keep responses under 150 words\n"
    "- Use a direct, encouraging tone\n"
    "- Never fabricate or embellish achievements"
)


class GeminiClient:
    def _get_client(self):
        if not settings.GEMINI_API_KEY:
            return None
        try:
            import google.genai as genai
            return genai.Client(api_key=settings.GEMINI_API_KEY)
        except Exception as exc:
            logger.error("Failed to initialise Gemini client: %s", exc)
            return None

    async def generate(self, prompt: str) -> str | None:
        client = self._get_client()
        if not client:
            logger.debug("Gemini not configured; skipping AI analysis.")
            return None
        try:
            import google.genai.types as gtypes

            config = gtypes.GenerateContentConfig(system_instruction=_SYSTEM_PROMPT)
            response = await asyncio.to_thread(
                client.models.generate_content,
                model=settings.GEMINI_MODEL,
                contents=prompt,
                config=config,
            )
            return response.text
        except Exception as exc:
            logger.error("Gemini generation error: %s", exc)
            return None

    async def generate_chat(self, messages: list[dict[str, str]]) -> str | None:
        """Generate a chat response given a list of {"role": "user"|"model", "text": "..."} dicts."""
        client = self._get_client()
        if not client:
            return None
        try:
            import google.genai.types as gtypes

            contents = [
                gtypes.Content(
                    role=m["role"],
                    parts=[gtypes.Part(text=m["text"])],
                )
                for m in messages
            ]
            config = gtypes.GenerateContentConfig(system_instruction=_SYSTEM_PROMPT)
            response = await asyncio.to_thread(
                client.models.generate_content,
                model=settings.GEMINI_MODEL,
                contents=contents,
                config=config,
            )
            return response.text
        except Exception as exc:
            logger.error("Gemini chat error: %s", exc)
            return None

    # ── Prompt builders (pure functions — no I/O) ─────────────────────────────

    def build_goal_prompt(
        self,
        *,
        display_name: str,
        goal_title: str,
        goal_category: str,
        goal_difficulty: str,
        evidence_text: str,
        reflection: str | None,
        effort_level: int,
        xp_awarded: int,
    ) -> str:
        return (
            f"User: {display_name}\n"
            f"Completed goal: \"{goal_title}\"\n"
            f"Category: {goal_category} | Difficulty: {goal_difficulty}"
            f" | Effort: {effort_level}/5 | XP earned: {xp_awarded}\n\n"
            f"Evidence of completion:\n{evidence_text}\n\n"
            f"Personal reflection:\n{reflection or 'Not provided'}\n\n"
            "Provide a brief analysis (2-3 sentences) covering:\n"
            "1. What was genuinely accomplished based on the evidence\n"
            "2. One specific growth insight from this achievement\n"
            "3. One concrete next step to build on this momentum"
        )

    def build_mission_prompt(
        self,
        *,
        display_name: str,
        mission_title: str,
        mission_category: str,
        mission_frequency: str,
        current_streak: int,
        evidence_text: str,
        reflection: str | None,
        effort_level: int,
        xp_awarded: int,
    ) -> str:
        streak_note = (
            f" — current streak: {current_streak}" if current_streak >= 3 else ""
        )
        return (
            f"User: {display_name}\n"
            f"Mission check-in: \"{mission_title}\"{streak_note}\n"
            f"Category: {mission_category} | Frequency: {mission_frequency}"
            f" | Effort: {effort_level}/5 | XP earned: {xp_awarded}\n\n"
            f"What they did:\n{evidence_text}\n\n"
            f"Reflection:\n{reflection or 'Not provided'}\n\n"
            "Provide a brief check-in analysis (2-3 sentences) covering:\n"
            "1. Specific acknowledgement of what was done\n"
            "2. A habit-formation insight based on their streak and consistency\n"
            "3. A motivating observation for their next check-in"
        )

    def build_growth_report_prompt(
        self,
        *,
        display_name: str,
        level: int,
        rank: str,
        total_xp: int,
        stats: dict[str, int],
        recent_completions: list[str],
        top_missions: list[str],
    ) -> str:
        stats_str = (
            ", ".join(f"{k}: {v}" for k, v in stats.items() if v > 0) or "all at 0"
        )
        completions_str = (
            "\n".join(f"- {c}" for c in recent_completions[:5]) or "None yet"
        )
        missions_str = (
            "\n".join(f"- {m}" for m in top_missions[:5]) or "None active"
        )
        return (
            f"User: {display_name} | Level {level} ({rank}-rank) | {total_xp} total XP\n"
            f"Stats: {stats_str}\n\n"
            f"Recent goal completions:\n{completions_str}\n\n"
            f"Active missions:\n{missions_str}\n\n"
            "Generate a personalised growth report (3-4 sentences) that:\n"
            "1. Identifies their strongest area of growth\n"
            "2. Points out a stat or domain that deserves more attention\n"
            "3. Suggests one specific goal or mission type to pursue next\n"
            "4. Celebrates a genuine achievement from their recent activity"
        )

    def build_journal_prompt(
        self,
        *,
        display_name: str,
        entry_date: str,
        content: str,
        mood: int | None,
    ) -> str:
        mood_labels = {1: "😔 Low", 2: "😕 Below average", 3: "😐 Neutral", 4: "🙂 Good", 5: "😄 Great"}
        mood_str = mood_labels.get(mood, "Not specified") if mood else "Not specified"
        return (
            f"User: {display_name} | Date: {entry_date} | Mood: {mood_str}\n\n"
            f"Journal entry:\n{content}\n\n"
            "Provide a brief personal reflection (2-3 sentences) that:\n"
            "1. Identifies the key theme or emotion in this entry\n"
            "2. Offers one grounded insight about what this reveals about their growth\n"
            "3. Suggests one concrete action or mindset shift for tomorrow"
        )

    def build_weekly_review_prompt(
        self,
        *,
        display_name: str,
        week_label: str,
        xp_earned: int,
        goals_completed: int,
        mission_checkins: int,
        best_streak: int,
        skills_practiced: int,
        journal_entries: int,
        mood_avg: float | None,
        top_categories: list[str],
    ) -> str:
        mood_str = f"{mood_avg:.1f}/5" if mood_avg else "not tracked"
        categories_str = ", ".join(top_categories[:3]) or "none"
        return (
            f"User: {display_name} | Week: {week_label}\n"
            f"XP earned: {xp_earned} | Goals completed: {goals_completed}\n"
            f"Mission check-ins: {mission_checkins} | Best streak: {best_streak} days\n"
            f"Skills practiced: {skills_practiced} | Journal entries: {journal_entries}\n"
            f"Average mood: {mood_str} | Top categories: {categories_str}\n\n"
            "Generate a personalised weekly review (4-5 sentences) that:\n"
            "1. Summarises the week's most meaningful progress\n"
            "2. Highlights one genuine strength shown this week\n"
            "3. Identifies one area that needs more attention next week\n"
            "4. Gives one specific, actionable recommendation for the coming week\n"
            "5. Ends with a motivating but grounded closing thought"
        )

    def build_coach_reply_prompt(self, user_message: str, context_summary: str) -> str:
        return (
            f"User context: {context_summary}\n\n"
            f"User message: {user_message}\n\n"
            "Respond as their personal growth coach. Be specific, concise, and practical. "
            "Reference their actual data when relevant. No generic advice."
        )


gemini_client = GeminiClient()
