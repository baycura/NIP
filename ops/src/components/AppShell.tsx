import type { ReactNode } from "react";
import AppHeader from "./AppHeader";
import BottomNav from "./BottomNav";

// Mobile-first shell: fixed header, scrollable content, bottom nav.
export default function AppShell({ children }: { children: ReactNode }) {
  return (
    <div className="app-shell">
      <AppHeader />
      <main className="app-content">{children}</main>
      <BottomNav />
    </div>
  );
}
