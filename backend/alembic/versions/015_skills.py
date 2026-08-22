"""skill tree — catalog + user skill progress

Revision ID: 015
Revises: 014
Create Date: 2026-08-22
"""

from alembic import op
import sqlalchemy as sa
import uuid

revision = "015"
down_revision = "014"
branch_labels = None
depends_on = None

# (emoji, name, description, category, sort_order)
_SKILLS = [
    # vitality
    ("🏃", "Running",            "Build cardiovascular endurance through consistent running practice.", "vitality", 0),
    ("🏊", "Swimming",           "Low-impact full-body workout that builds stamina and lung capacity.",  "vitality", 1),
    ("🧘", "Yoga",               "Improve flexibility, balance, and mind-body awareness through yoga.",  "vitality", 2),
    ("🚴", "Cycling",            "Build leg strength and aerobic capacity through regular cycling.",      "vitality", 3),
    ("😴", "Sleep Optimization", "Master the science and habits of deep, restorative sleep.",             "vitality", 4),
    # strength
    ("🏋️", "Weight Training",   "Progressive overload with free weights and machines for raw strength.", "strength", 5),
    ("💪", "Calisthenics",       "Build functional strength using bodyweight movements and progressions.", "strength", 6),
    ("⚡", "HIIT",               "High-intensity interval training for power, speed, and fat loss.",       "strength", 7),
    ("🧗", "Rock Climbing",      "Build grip, core, and problem-solving through climbing challenges.",     "strength", 8),
    ("🥋", "Martial Arts",       "Develop discipline, reflexes, and self-defence through combat arts.",   "strength", 9),
    # intelligence
    ("🧑‍💻", "Programming",     "Write better code, learn new paradigms, and solve hard problems.",       "intelligence", 10),
    ("📖", "Reading",            "Expand knowledge and vocabulary through deliberate daily reading.",       "intelligence", 11),
    ("♟️", "Chess",              "Sharpen pattern recognition, tactics, and long-term strategic thinking.", "intelligence", 12),
    ("📐", "Mathematics",        "Build logical thinking through problem sets, proofs, and applied math.",  "intelligence", 13),
    ("🌍", "Language Learning",  "Acquire fluency in a new language through daily deliberate practice.",   "intelligence", 14),
    # wisdom
    ("🧘", "Meditation",         "Develop present-moment awareness and emotional regulation.",              "wisdom", 15),
    ("📓", "Journaling",         "Process thoughts, track growth, and build self-awareness in writing.",   "wisdom", 16),
    ("📚", "Philosophy",         "Study great thinkers to sharpen reasoning and ethical clarity.",          "wisdom", 17),
    ("🌿", "Mindfulness",        "Integrate intentional attention into everyday activities and decisions.", "wisdom", 18),
    ("♟️", "Strategic Thinking", "Learn to see systems, anticipate consequences, and plan several moves ahead.", "wisdom", 19),
    # charisma
    ("🎤", "Public Speaking",    "Project confidence, clarity, and authority when speaking to any audience.", "charisma", 20),
    ("👂", "Active Listening",   "Build genuine connection by listening with full attention and empathy.",    "charisma", 21),
    ("📝", "Storytelling",       "Craft and deliver compelling narratives that move and persuade people.",    "charisma", 22),
    ("🤝", "Networking",         "Build mutually valuable relationships with intention and authenticity.",    "charisma", 23),
    ("🧠", "Persuasion",         "Ethically influence decisions using logic, emotion, and credibility.",     "charisma", 24),
    # discipline
    ("📅", "Time Management",    "Design and defend your schedule so your priorities always get done first.", "discipline", 25),
    ("🎯", "Deep Work",          "Enter and sustain states of intense, distraction-free concentration.",      "discipline", 26),
    ("🌅", "Early Rising",       "Build the habit of waking early with energy and a clear morning routine.", "discipline", 27),
    ("📵", "Digital Minimalism", "Take deliberate control of your technology use to reclaim focus and time.", "discipline", 28),
    ("💰", "Financial Discipline","Spend, save, and invest with intention — build wealth through daily habits.", "discipline", 29),
]


def upgrade() -> None:
    op.create_table(
        "skills",
        sa.Column("id",          sa.UUID(as_uuid=True), primary_key=True, default=uuid.uuid4),
        sa.Column("name",        sa.String(100), nullable=False),
        sa.Column("description", sa.Text, nullable=False),
        sa.Column("category",    sa.String(50), nullable=False),
        sa.Column("emoji",       sa.String(10), nullable=False),
        sa.Column("sort_order",  sa.Integer, nullable=False, default=0),
        sa.Column("is_seeded",   sa.Boolean, nullable=False, default=True),
    )
    op.create_index("ix_skills_category", "skills", ["category"])

    op.create_table(
        "user_skills",
        sa.Column("id",               sa.UUID(as_uuid=True), primary_key=True, default=uuid.uuid4),
        sa.Column("user_id",          sa.UUID(as_uuid=True), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("skill_id",         sa.UUID(as_uuid=True), sa.ForeignKey("skills.id", ondelete="CASCADE"), nullable=False),
        sa.Column("level",            sa.Integer, nullable=False, default=1),
        sa.Column("session_count",    sa.Integer, nullable=False, default=0),
        sa.Column("total_xp_earned",  sa.Integer, nullable=False, default=0),
        sa.Column("last_practiced_at",sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at",       sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at",       sa.DateTime(timezone=True), server_default=sa.func.now(), onupdate=sa.func.now(), nullable=False),
    )
    op.create_index("ix_user_skills_user_id",  "user_skills", ["user_id"])
    op.create_index("ix_user_skills_skill_id", "user_skills", ["skill_id"])
    op.create_unique_constraint("uq_user_skills_user_skill", "user_skills", ["user_id", "skill_id"])

    skills_table = sa.table(
        "skills",
        sa.column("id",          sa.UUID),
        sa.column("name",        sa.String),
        sa.column("description", sa.String),
        sa.column("category",    sa.String),
        sa.column("emoji",       sa.String),
        sa.column("sort_order",  sa.Integer),
        sa.column("is_seeded",   sa.Boolean),
    )
    op.bulk_insert(
        skills_table,
        [
            {
                "id":          uuid.uuid4(),
                "name":        name,
                "description": desc,
                "category":    cat,
                "emoji":       emoji,
                "sort_order":  order,
                "is_seeded":   True,
            }
            for emoji, name, desc, cat, order in _SKILLS
        ],
    )


def downgrade() -> None:
    op.drop_table("user_skills")
    op.drop_table("skills")
