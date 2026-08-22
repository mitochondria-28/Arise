"""goal templates seed

Revision ID: 013
Revises: 012
Create Date: 2026-08-22
"""

from alembic import op
import sqlalchemy as sa
import uuid

revision = "013"
down_revision = "012"
branch_labels = None
depends_on = None

_TEMPLATES = [
    # vitality — health & physical wellness
    ("🚶", "Daily Walk", "Walk at least 30 minutes every day, rain or shine.", "vitality", "easy", 0),
    ("🏋️", "Gym Habit", "Go to the gym at least 3 times per week for a full month.", "vitality", "hard", 1),
    ("😴", "Sleep Schedule", "Get 7–8 hours of sleep consistently for 30 consecutive days.", "vitality", "medium", 2),
    ("💧", "Hydration Challenge", "Drink at least 2 litres of water every single day for a month.", "vitality", "easy", 3),
    # strength — physical challenges & endurance
    ("🏃", "Run 5K", "Train from scratch until you can run a 5K without stopping.", "strength", "hard", 4),
    ("💪", "100 Pushups Challenge", "Build to 100 consecutive pushups through daily progressive training.", "strength", "epic", 5),
    ("🧊", "Cold Shower Habit", "Take a cold shower every morning for 21 days straight.", "strength", "medium", 6),
    ("🧘", "Bodyweight Strength", "Complete a 30-day bodyweight program with no missed sessions.", "strength", "hard", 7),
    # intelligence — learning & knowledge
    ("📚", "Read 12 Books", "Read one book per month — at least 12 books in total this year.", "intelligence", "hard", 8),
    ("🧑‍💻", "Learn a New Skill", "Complete a structured course in a skill you have been putting off.", "intelligence", "medium", 9),
    ("📖", "Daily Study Habit", "Study something meaningful for at least 1 hour every day.", "intelligence", "medium", 10),
    ("🌍", "Language Learning", "Reach conversational level in a new language through daily practice.", "intelligence", "epic", 11),
    # wisdom — reflection, mindfulness & self-awareness
    ("🧘", "Daily Meditation", "Meditate for at least 10 minutes every day for 30 days.", "wisdom", "easy", 12),
    ("📋", "Weekly Review", "Conduct a structured weekly review of goals and plans every Sunday.", "wisdom", "easy", 13),
    ("🙏", "Gratitude Practice", "Write 3 things you are grateful for at the end of each day.", "wisdom", "easy", 14),
    ("📵", "Digital Detox Day", "Spend one full day per week completely offline — no social media, no screens.", "wisdom", "medium", 15),
    # charisma — social skills & relationships
    ("🤝", "Networking Challenge", "Attend at least 2 networking events per month for 3 months.", "charisma", "medium", 16),
    ("🎤", "Public Speaking", "Give a presentation or talk to a group of at least 10 people.", "charisma", "hard", 17),
    ("💛", "Daily Kindness", "Perform one genuine act of kindness or encouragement every single day.", "charisma", "easy", 18),
    ("👥", "Expand Social Circle", "Make 3 meaningful new connections — people you genuinely talk to regularly.", "charisma", "medium", 19),
    # discipline — habits, focus & productivity
    ("🌅", "Early Riser", "Wake up at 6AM (or earlier) every day for 30 days straight.", "discipline", "hard", 20),
    ("🎯", "Deep Work Block", "Complete at least 2 hours of uninterrupted deep work every day.", "discipline", "hard", 21),
    ("🥗", "No Junk Food", "Eliminate junk food, fast food, and sugary snacks for 30 days.", "discipline", "hard", 22),
    ("☝️", "Single Tasking", "Focus on one task at a time — no multitasking, no tab switching — for a month.", "discipline", "medium", 23),
]


def upgrade() -> None:
    op.create_table(
        "goal_templates",
        sa.Column("id", sa.UUID(as_uuid=True), primary_key=True, default=uuid.uuid4),
        sa.Column("title", sa.String(200), nullable=False),
        sa.Column("description", sa.Text, nullable=False),
        sa.Column("category", sa.String(50), nullable=False),
        sa.Column("difficulty", sa.String(20), nullable=False),
        sa.Column("emoji", sa.String(10), nullable=False),
        sa.Column("sort_order", sa.Integer, nullable=False, server_default="0"),
    )
    op.create_index("ix_goal_templates_category", "goal_templates", ["category"])

    rows = [
        {
            "id": uuid.uuid4(),
            "emoji": emoji,
            "title": title,
            "description": description,
            "category": category,
            "difficulty": difficulty,
            "sort_order": sort_order,
        }
        for emoji, title, description, category, difficulty, sort_order in _TEMPLATES
    ]
    op.bulk_insert(
        sa.table(
            "goal_templates",
            sa.column("id", sa.UUID),
            sa.column("emoji", sa.String),
            sa.column("title", sa.String),
            sa.column("description", sa.Text),
            sa.column("category", sa.String),
            sa.column("difficulty", sa.String),
            sa.column("sort_order", sa.Integer),
        ),
        rows,
    )


def downgrade() -> None:
    op.drop_index("ix_goal_templates_category", table_name="goal_templates")
    op.drop_table("goal_templates")
