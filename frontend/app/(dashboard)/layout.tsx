"use client"

import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { AppSidebar } from "@/components/layout/AppSidebar";
import { TopNav } from "@/components/layout/TopNav";
import { MobileNav } from "@/components/layout/MobileNav";
import { useAuth } from "@/stores/auth-context";

export const dynamic = 'force-dynamic'

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const router = useRouter();
  const { user, loading } = useAuth();
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  useEffect(() => {
    if (!loading && !user) {
      router.replace("/login");
    }
  }, [user, loading, router]);

  if (loading || !user) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="h-8 w-8 animate-spin rounded-full border-4 border-amber-500 border-t-transparent" />
      </div>
    );
  }

  return (
    <div className="flex min-h-screen">
      <AppSidebar open={mobileMenuOpen} onClose={() => setMobileMenuOpen(false)} />
      {/* min-w-0 lets this flex child shrink below its content's intrinsic
          width; without it min-width:auto let wide data tables push the page
          past the viewport (QA-TEST-REPORT.md P1-1). */}
      <div className="flex min-w-0 flex-1 flex-col md:pl-64">
        <TopNav onMenuToggle={() => setMobileMenuOpen(true)} />
        <main
          id="main-content"
          tabIndex={-1}
          aria-label="Main content"
          className="flex-1 p-4 md:p-6 lg:p-8 pb-20 md:pb-8"
        >
          {children}
        </main>
      </div>
      <MobileNav />
    </div>
  );
}
