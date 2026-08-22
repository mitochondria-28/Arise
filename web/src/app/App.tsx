import { BrowserRouter } from "react-router-dom";
import { useEffect } from "react";
import { AppRouter } from "./router";
import { AuthProvider } from "@/features/auth/AuthContext";
import { useThemeStore } from "@/shared/stores/theme.store";

function ThemeSync({ children }: { children: React.ReactNode }) {
  const { theme } = useThemeStore();
  useEffect(() => {
    if (theme === "dark") {
      document.documentElement.classList.add("dark");
    } else {
      document.documentElement.classList.remove("dark");
    }
  }, [theme]);
  return <>{children}</>;
}

export default function App() {
  return (
    <BrowserRouter>
      <ThemeSync>
        <AuthProvider>
          <AppRouter />
        </AuthProvider>
      </ThemeSync>
    </BrowserRouter>
  );
}
