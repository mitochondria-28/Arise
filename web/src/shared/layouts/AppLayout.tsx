import { NavLink, Outlet, useNavigate } from "react-router-dom";
import { LayoutDashboard, Target, RefreshCw, User, Sparkles, LogOut, Sun, Moon, BarChart2, Trophy, BookOpen, Settings, Zap } from "lucide-react";
import { useAuth } from "@/features/auth/AuthContext";
import { useThemeStore } from "@/shared/stores/theme.store";
import { cn } from "@/shared/lib/cn";

const NAV = [
  { to: "/dashboard",  label: "Dashboard",  Icon: LayoutDashboard },
  { to: "/character",  label: "Character",  Icon: User },
  { to: "/goals",      label: "Goals",      Icon: Target },
  { to: "/missions",   label: "Missions",   Icon: RefreshCw },
  { to: "/skills",        label: "Skills",        Icon: Zap },
  { to: "/progress",      label: "Progress",      Icon: BarChart2 },
  { to: "/journal",       label: "Journal",       Icon: BookOpen },
  { to: "/achievements",  label: "Achievements",  Icon: Trophy },
  { to: "/coach",         label: "AI Coach",      Icon: Sparkles },
];

function NavItem({ to, label, Icon }: typeof NAV[0]) {
  return (
    <NavLink
      to={to}
      className={({ isActive }) =>
        cn(
          "flex items-center gap-3 px-3 py-2 rounded-lg text-sm font-medium transition-colors",
          isActive
            ? "bg-[var(--accent-dim)] text-[var(--accent)]"
            : "text-[var(--text-2)] hover:bg-[var(--surface-2)] hover:text-[var(--text-1)]"
        )
      }
    >
      <Icon size={17} />
      <span>{label}</span>
    </NavLink>
  );
}

function MobileNavItem({ to, Icon }: Pick<typeof NAV[0], "to" | "Icon">) {
  return (
    <NavLink
      to={to}
      className={({ isActive }) =>
        cn(
          "flex flex-col items-center justify-center flex-1 py-2 transition-colors",
          isActive ? "text-[var(--accent)]" : "text-[var(--text-3)]"
        )
      }
    >
      <Icon size={20} />
    </NavLink>
  );
}

export default function AppLayout() {
  const { state, logout } = useAuth();
  const { theme, toggle } = useThemeStore();
  const navigate = useNavigate();

  const email = state.status === "authenticated" ? state.email : "";
  const initials = email.slice(0, 2).toUpperCase();

  const handleLogout = async () => {
    await logout();
    navigate("/login", { replace: true });
  };

  return (
    <div className="flex h-screen overflow-hidden" style={{ background: "var(--bg)" }}>
      {/* Sidebar — desktop */}
      <aside
        className="hidden md:flex flex-col w-[220px] flex-none border-r"
        style={{ borderColor: "var(--border)", background: "var(--surface-1)" }}
      >
        {/* Logo */}
        <div className="px-4 py-5 border-b" style={{ borderColor: "var(--border)" }}>
          <span
            className="text-base font-bold tracking-tight"
            style={{ color: "var(--accent)" }}
          >
            Arise
          </span>
        </div>

        {/* Navigation */}
        <nav className="flex-1 overflow-y-auto px-3 py-4 flex flex-col gap-1">
          {NAV.map((item) => (
            <NavItem key={item.to} {...item} />
          ))}
        </nav>

        {/* Footer */}
        <div className="px-3 py-4 border-t flex flex-col gap-2" style={{ borderColor: "var(--border)" }}>
          {/* User — click to go to profile */}
          <NavLink
            to="/profile"
            className={({ isActive }) =>
              cn(
                "flex items-center gap-2.5 px-2 py-1.5 rounded-lg transition-colors",
                isActive
                  ? "bg-[var(--accent-dim)]"
                  : "hover:bg-[var(--surface-2)]"
              )
            }
          >
            <div
              className="w-7 h-7 rounded-full flex items-center justify-center text-xs font-bold flex-none"
              style={{ background: "var(--accent-dim)", color: "var(--accent)" }}
            >
              {initials}
            </div>
            <span className="text-xs truncate flex-1" style={{ color: "var(--text-2)" }}>
              {email}
            </span>
            <Settings size={13} style={{ color: "var(--text-3)", flexShrink: 0 }} />
          </NavLink>

          {/* Controls row */}
          <div className="flex items-center gap-1 px-1">
            <button
              onClick={toggle}
              className="flex-1 flex items-center justify-center h-8 rounded-lg text-xs gap-1.5 transition-colors hover:bg-[var(--surface-2)]"
              style={{ color: "var(--text-2)" }}
            >
              {theme === "dark" ? <Sun size={14} /> : <Moon size={14} />}
            </button>
            <button
              onClick={handleLogout}
              className="flex-1 flex items-center justify-center h-8 rounded-lg text-xs gap-1.5 transition-colors hover:bg-[var(--surface-2)]"
              style={{ color: "var(--text-2)" }}
            >
              <LogOut size={14} />
            </button>
          </div>
        </div>
      </aside>

      {/* Main */}
      <div className="flex flex-col flex-1 overflow-hidden">
        {/* Mobile top bar */}
        <header
          className="md:hidden flex items-center justify-between px-4 h-14 border-b flex-none"
          style={{ borderColor: "var(--border)", background: "var(--surface-1)" }}
        >
          <span className="font-bold tracking-tight" style={{ color: "var(--accent)" }}>
            Arise
          </span>
          <div className="flex items-center gap-1">
            <button onClick={toggle} className="w-9 h-9 flex items-center justify-center rounded-lg" style={{ color: "var(--text-2)" }}>
              {theme === "dark" ? <Sun size={18} /> : <Moon size={18} />}
            </button>
            <NavLink to="/profile" className="w-9 h-9 flex items-center justify-center rounded-lg" style={{ color: "var(--text-2)" }}>
              <Settings size={18} />
            </NavLink>
            <button onClick={handleLogout} className="w-9 h-9 flex items-center justify-center rounded-lg" style={{ color: "var(--text-2)" }}>
              <LogOut size={18} />
            </button>
          </div>
        </header>

        {/* Page content */}
        <main className="flex-1 overflow-y-auto">
          <div className="max-w-4xl mx-auto px-4 py-6 md:px-8 pb-24 md:pb-8">
            <Outlet />
          </div>
        </main>
      </div>

      {/* Bottom nav — mobile */}
      <nav
        className="md:hidden fixed bottom-0 left-0 right-0 flex border-t"
        style={{ background: "var(--surface-1)", borderColor: "var(--border)", height: 60 }}
      >
        {NAV.map((item) => (
          <MobileNavItem key={item.to} to={item.to} Icon={item.Icon} />
        ))}
      </nav>
    </div>
  );
}
