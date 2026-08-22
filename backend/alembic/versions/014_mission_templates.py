"""mission templates seed

Revision ID: 014
Revises: 013
Create Date: 2026-08-22
"""

from alembic import op
import sqlalchemy as sa
import uuid

revision = "014"
down_revision = "013"
branch_labels = None
depends_on = None

# (emoji, title, description, category, difficulty, frequency, sort_order)
_TEMPLATES = [
    # vitality — health & physical wellness
    ("🏃", "Morning Run",        "Go for a run every morning, even if only 10 minutes — no excuses.", "vitality", "medium", "daily",   0),
    ("🥗", "Healthy Meal",       "Eat at least one fully nutritious, home-prepared meal every single day.", "vitality", "easy",   "daily",   1),
    ("💧", "Hydration Check",    "Drink at least 8 glasses of water before the day ends.", "vitality", "easy",   "daily",   2),
    ("🏋️", "Gym Session",        "Complete a full gym workout of at least 45 minutes.", "vitality", "hard",   "weekly",  3),
    # strength — physical challenges & endurance
    ("💪", "Pushup Set",         "Complete your daily pushup set, increasing reps progressively each week.", "strength", "medium", "daily",   4),
    ("🧊", "Cold Shower",        "Take a cold shower every morning without hesitation — no warm water first.", "strength", "hard",   "daily",   5),
    ("🧘", "Stretching Routine", "Stretch for at least 10 minutes every morning or evening.", "strength", "easy",   "daily",   6),
    ("🏃", "Weekly Long Run",    "Go for a long run of at least 5K once per week.", "strength", "hard",   "weekly",  7),
    # intelligence — learning & knowledge
    ("📖", "Daily Reading",      "Read at least 20 pages of a non-fiction book — no articles, no summaries.", "intelligence", "medium", "daily",   8),
    ("🧑‍💻", "Code Practice",     "Write or study code for at least 30 minutes every day.", "intelligence", "medium", "daily",   9),
    ("🎧", "Learn Something",    "Listen to an educational podcast, lecture, or course segment daily.", "intelligence", "easy",   "daily",   10),
    ("📝", "Weekly Study Block", "Dedicate at least 2 focused hours to structured study or skill practice.", "intelligence", "hard",   "weekly",  11),
    # wisdom — reflection, mindfulness & self-awareness
    ("🧘", "Morning Meditation", "Meditate for 10 minutes before checking your phone each morning.", "wisdom", "easy",   "daily",   12),
    ("📓", "Gratitude Log",      "Write 3 specific things you are grateful for every evening.", "wisdom", "easy",   "daily",   13),
    ("🌙", "Evening Reflection", "Spend 5 minutes reviewing your day: what went well, what didn't.", "wisdom", "easy",   "daily",   14),
    ("📋", "Weekly Planning",    "Plan and review your goals and schedule every Sunday evening.", "wisdom", "medium", "weekly",  15),
    # charisma — social skills & relationships
    ("💬", "Meaningful Conversation", "Have at least one deep, intentional conversation with someone today.", "charisma", "medium", "daily",   16),
    ("🤝", "Reach Out",          "Contact someone you haven't spoken to in a while — catch up genuinely.", "charisma", "easy",   "weekly",  17),
    ("💌", "Express Gratitude",  "Send a genuine thank-you or appreciation message to someone today.", "charisma", "easy",   "daily",   18),
    ("👥", "Social Event",       "Attend one social, networking, or group event this month.", "charisma", "medium", "monthly", 19),
    # discipline — habits, focus & productivity
    ("🎯", "Deep Work Block",    "Complete 90 minutes of fully uninterrupted, single-task focused work.", "discipline", "hard",   "daily",   20),
    ("📵", "Phone-Free Morning", "No phone for the first hour after waking up — start intentionally.", "discipline", "medium", "daily",   21),
    ("📝", "Daily Priorities",   "Write your top 3 priorities for the day before starting any work.", "discipline", "easy",   "daily",   22),
    ("📊", "Weekly Review",      "Review your week: wins, losses, and lessons — adjust next week's plan.", "discipline", "medium", "weekly",  23),
]


def upgrade() -> None:
    op.create_table(
        "mission_templates",
        sa.Column("id",          sa.UUID(as_uuid=True), primary_key=True, default=uuid.uuid4),
        sa.Column("title",       sa.String(200), nullable=False),
        sa.Column("description", sa.Text, nullable=False),
        sa.Column("category",    sa.String(50), nullable=False),
        sa.Column("difficulty",  sa.String(20), nullable=False),
        sa.Column("frequency",   sa.String(20), nullable=False),
        sa.Column("emoji",       sa.String(10), nullable=False),
        sa.Column("sort_order",  sa.Integer, nullable=False, server_default="0"),
    )
    op.create_index("ix_mission_templates_category",  "mission_templates", ["category"])
    op.create_index("ix_mission_templates_frequency", "mission_templates", ["frequency"])

    rows = [
        {
            "id":          uuid.uuid4(),
            "emoji":       emoji,
            "title":       title,
            "description": description,
            "category":    category,
            "difficulty":  difficulty,
            "frequency":   frequency,
            "sort_order":  sort_order,
        }
        for emoji, title, description, category, difficulty, frequency, sort_order in _TEMPLATES
    ]
    op.bulk_insert(
        sa.table(
            "mission_templates",
            sa.column("id",          sa.UUID),
            sa.column("emoji",       sa.String),
            sa.column("title",       sa.String),
            sa.column("description", sa.Text),
            sa.column("category",    sa.String),
            sa.column("difficulty",  sa.String),
            sa.column("frequency",   sa.String),
            sa.column("sort_order",  sa.Integer),
        ),
        rows,
    )


def downgrade() -> None:
    op.drop_index("ix_mission_templates_frequency", table_name="mission_templates")
    op.drop_index("ix_mission_templates_category",  table_name="mission_templates")
    op.drop_table("mission_templates")
