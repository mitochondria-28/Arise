import { type ButtonHTMLAttributes, forwardRef } from "react";
import { cn } from "@/shared/lib/cn";
import { Spinner } from "./Spinner";

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: "primary" | "secondary" | "ghost" | "danger";
  size?: "sm" | "md" | "lg";
  loading?: boolean;
}

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  ({ variant = "primary", size = "md", loading, disabled, children, className, ...rest }, ref) => {
    const base =
      "inline-flex items-center justify-center gap-2 rounded-lg font-medium transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50";

    const sizes = {
      sm: "h-8 px-3 text-sm",
      md: "h-10 px-4 text-sm",
      lg: "h-11 px-6 text-base",
    };

    const variants = {
      primary:   "bg-[var(--accent)] text-white hover:opacity-90 active:opacity-80 focus-visible:ring-[var(--accent)]",
      secondary: "bg-[var(--surface-2)] text-[var(--text-1)] border border-[var(--border)] hover:bg-[var(--surface-3)] focus-visible:ring-[var(--border)]",
      ghost:     "text-[var(--text-2)] hover:bg-[var(--surface-2)] hover:text-[var(--text-1)] focus-visible:ring-[var(--border)]",
      danger:    "bg-[var(--danger)] text-white hover:opacity-90 active:opacity-80 focus-visible:ring-[var(--danger)]",
    };

    return (
      <button
        ref={ref}
        disabled={disabled || loading}
        className={cn(base, sizes[size], variants[variant], className)}
        {...rest}
      >
        {loading && <Spinner size={size === "sm" ? 14 : 16} />}
        {children}
      </button>
    );
  }
);
Button.displayName = "Button";
