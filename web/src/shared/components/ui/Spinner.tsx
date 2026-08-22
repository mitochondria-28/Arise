import type { CSSProperties } from "react";

interface SpinnerProps {
  size?: number;
  className?: string;
  style?: CSSProperties;
}

export function Spinner({ size = 20, className, style }: SpinnerProps) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      className={className}
      style={{ animation: "spin 0.7s linear infinite", ...style }}
      aria-label="Loading"
    >
      <style>{`@keyframes spin { to { transform: rotate(360deg); } }`}</style>
      <circle
        cx="12" cy="12" r="10"
        stroke="currentColor"
        strokeWidth="3"
        strokeLinecap="round"
        strokeDasharray="40 60"
        opacity="0.8"
      />
    </svg>
  );
}
