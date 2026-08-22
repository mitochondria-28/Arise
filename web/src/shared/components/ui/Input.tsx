import { forwardRef, type InputHTMLAttributes } from "react";
import { cn } from "@/shared/lib/cn";

interface InputProps extends InputHTMLAttributes<HTMLInputElement> {
  label?: string;
  error?: string;
  hint?: string;
}

export const Input = forwardRef<HTMLInputElement, InputProps>(
  ({ label, error, hint, className, id, ...rest }, ref) => {
    const inputId = id ?? label?.toLowerCase().replace(/\s+/g, "-");

    return (
      <div className="flex flex-col gap-1.5">
        {label && (
          <label
            htmlFor={inputId}
            className="text-sm font-medium"
            style={{ color: "var(--text-1)" }}
          >
            {label}
          </label>
        )}
        <input
          ref={ref}
          id={inputId}
          className={cn(
            "h-10 w-full rounded-lg border px-3 text-sm outline-none transition-colors",
            "placeholder:text-[var(--text-3)]",
            "bg-[var(--surface-2)] text-[var(--text-1)]",
            error
              ? "border-[var(--danger)] focus:border-[var(--danger)]"
              : "border-[var(--border)] focus:border-[var(--accent)]",
            className
          )}
          {...rest}
        />
        {error && (
          <p className="text-xs" style={{ color: "var(--danger)" }}>{error}</p>
        )}
        {hint && !error && (
          <p className="text-xs" style={{ color: "var(--text-3)" }}>{hint}</p>
        )}
      </div>
    );
  }
);
Input.displayName = "Input";
