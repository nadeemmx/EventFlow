import type { Metadata } from "next";
import { ThemeProvider } from "@/components/common/ThemeProvider";
import { QueryProvider } from "@/lib/query-provider";
import { AuthProvider } from "@/stores/auth-context";
import { Toaster } from "@/components/ui/toaster";
import "./globals.css";

export const metadata: Metadata = {
  title: "EventFlow - Venue Management Platform for Event Businesses",
  description:
    "Run your entire event venue business from one dashboard. Manage bookings, leads, CRM, invoices, payments, vendors, staff, and analytics.",
  keywords: [
    "venue management software",
    "event venue platform",
    "banquet hall management",
    "marriage lawn booking system",
    "convention center software",
    "event business CRM",
    "B2B SaaS",
  ],
  openGraph: {
    title: "EventFlow - Venue Management Platform for Event Businesses",
    description:
      "Run your entire event venue business from one dashboard. Bookings, CRM, payments, and analytics unified.",
    type: "website",
    siteName: "EventFlow",
  },
  twitter: {
    card: "summary_large_image",
    title: "EventFlow - Venue Management Platform for Event Businesses",
    description:
      "Run your entire event venue business from one dashboard. Bookings, CRM, payments, and analytics unified.",
  },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body className="min-h-screen bg-background antialiased font-sans">
        <ThemeProvider attribute="class" defaultTheme="light" enableSystem>
          <QueryProvider>
            <AuthProvider>
              {children}
              <Toaster />
            </AuthProvider>
          </QueryProvider>
        </ThemeProvider>
      </body>
    </html>
  );
}
