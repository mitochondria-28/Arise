import { lazy, Suspense } from "react";
import { Routes, Route, Navigate, Outlet } from "react-router-dom";
import { useAuth } from "@/features/auth/AuthContext";
import { Spinner } from "@/shared/components/ui/Spinner";
import AuthLayout from "@/shared/layouts/AuthLayout";
import AppLayout from "@/shared/layouts/AppLayout";

const LoginPage    = lazy(() => import("@/features/auth/LoginPage"));
const RegisterPage = lazy(() => import("@/features/auth/RegisterPage"));
const DashboardPage    = lazy(() => import("@/features/dashboard/DashboardPage"));
const CharacterPage    = lazy(() => import("@/features/character/CharacterPage"));
const GoalsPage        = lazy(() => import("@/features/goals/GoalsPage"));
const MissionsPage     = lazy(() => import("@/features/missions/MissionsPage"));
const CoachPage        = lazy(() => import("@/features/ai-coach/CoachPage"));
const ProgressPage        = lazy(() => import("@/features/progress/ProgressPage"));
const AchievementsPage    = lazy(() => import("@/features/achievements/AchievementsPage"));
const JournalPage         = lazy(() => import("@/features/journal/JournalPage"));
const ProfilePage         = lazy(() => import("@/features/profile/ProfilePage"));
const SkillsPage          = lazy(() => import("@/features/skills/SkillsPage"));

function PageLoader() {
  return (
    <div className="flex items-center justify-center min-h-[60vh]">
      <Spinner size={28} style={{ color: "var(--accent)" } as React.CSSProperties} />
    </div>
  );
}

function FullPageLoader() {
  return (
    <div
      className="flex items-center justify-center h-screen"
      style={{ background: "var(--bg)" }}
    >
      <div className="flex flex-col items-center gap-3">
        <span className="text-sm font-semibold uppercase tracking-widest" style={{ color: "var(--accent)" }}>
          Arise
        </span>
        <Spinner size={24} style={{ color: "var(--text-3)" } as React.CSSProperties} />
      </div>
    </div>
  );
}

function ProtectedRoute() {
  const { state } = useAuth();
  if (state.status === "loading") return <FullPageLoader />;
  if (state.status === "unauthenticated") return <Navigate to="/login" replace />;
  return <Outlet />;
}

function GuestRoute() {
  const { state } = useAuth();
  if (state.status === "loading") return <FullPageLoader />;
  if (state.status === "authenticated") return <Navigate to="/dashboard" replace />;
  return <Outlet />;
}

export function AppRouter() {
  return (
    <Routes>
      {/* Auth routes — redirect to dashboard if already signed in */}
      <Route element={<GuestRoute />}>
        <Route element={<AuthLayout />}>
          <Route
            path="/login"
            element={
              <Suspense fallback={<PageLoader />}>
                <LoginPage />
              </Suspense>
            }
          />
          <Route
            path="/register"
            element={
              <Suspense fallback={<PageLoader />}>
                <RegisterPage />
              </Suspense>
            }
          />
        </Route>
      </Route>

      {/* App routes — require auth */}
      <Route element={<ProtectedRoute />}>
        <Route element={<AppLayout />}>
          <Route index element={<Navigate to="/dashboard" replace />} />
          <Route
            path="/dashboard"
            element={
              <Suspense fallback={<PageLoader />}>
                <DashboardPage />
              </Suspense>
            }
          />
          <Route
            path="/character"
            element={
              <Suspense fallback={<PageLoader />}>
                <CharacterPage />
              </Suspense>
            }
          />
          <Route
            path="/goals"
            element={
              <Suspense fallback={<PageLoader />}>
                <GoalsPage />
              </Suspense>
            }
          />
          <Route
            path="/missions"
            element={
              <Suspense fallback={<PageLoader />}>
                <MissionsPage />
              </Suspense>
            }
          />
          <Route
            path="/progress"
            element={
              <Suspense fallback={<PageLoader />}>
                <ProgressPage />
              </Suspense>
            }
          />
          <Route
            path="/journal"
            element={
              <Suspense fallback={<PageLoader />}>
                <JournalPage />
              </Suspense>
            }
          />
          <Route
            path="/achievements"
            element={
              <Suspense fallback={<PageLoader />}>
                <AchievementsPage />
              </Suspense>
            }
          />
          <Route
            path="/coach"
            element={
              <Suspense fallback={<PageLoader />}>
                <CoachPage />
              </Suspense>
            }
          />
          <Route
            path="/profile"
            element={
              <Suspense fallback={<PageLoader />}>
                <ProfilePage />
              </Suspense>
            }
          />
          <Route
            path="/skills"
            element={
              <Suspense fallback={<PageLoader />}>
                <SkillsPage />
              </Suspense>
            }
          />
        </Route>
      </Route>

      <Route path="*" element={<Navigate to="/dashboard" replace />} />
    </Routes>
  );
}
