import { motion } from "framer-motion";

interface XpBarProps {
  currentXp: number;
  xpToNext: number;
  showLabel?: boolean;
  height?: number;
}

export function XpBar({ currentXp, xpToNext, showLabel = true, height = 6 }: XpBarProps) {
  const pct = xpToNext > 0 ? Math.min(100, Math.round((currentXp / xpToNext) * 100)) : 0;

  return (
    <div>
      {showLabel && (
        <div className="flex justify-between text-xs mb-1.5">
          <span style={{ color: "var(--xp-color)" }}>
            {currentXp.toLocaleString()} XP
          </span>
          <span style={{ color: "var(--text-3)" }}>
            {xpToNext.toLocaleString()} to next level
          </span>
        </div>
      )}
      <div
        className="relative w-full rounded-full overflow-hidden"
        style={{ background: "var(--surface-3)", height }}
      >
        <motion.div
          className="absolute inset-y-0 left-0 rounded-full"
          style={{ background: "var(--xp-color)" }}
          initial={{ width: 0 }}
          animate={{ width: `${pct}%` }}
          transition={{ duration: 0.9, ease: [0.4, 0, 0.2, 1] }}
        />
      </div>
    </div>
  );
}
