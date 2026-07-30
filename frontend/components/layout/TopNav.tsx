"use client"

import { Search, Menu } from "lucide-react"
import { Input } from "@/components/ui/input"
import { Button } from "@/components/ui/button"
import { UserNav } from "@/components/layout/UserNav"

interface TopNavProps {
  onMenuToggle?: () => void
}

export function TopNav({ onMenuToggle }: TopNavProps) {
  return (
    <header className="sticky top-0 z-20 flex h-16 items-center gap-4 border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60 px-4 md:px-6">
      <Button
        variant="ghost"
        size="icon"
        className="md:hidden cursor-pointer"
        onClick={onMenuToggle}
        aria-label="Toggle menu"
      >
        <Menu className="h-5 w-5" />
      </Button>

      <div className="flex-1 flex items-center gap-4">
        <div className="hidden sm:block">
          <h1 className="text-lg font-semibold tracking-tight ">Dashboard</h1>
        </div>

        <div className="hidden sm:block flex-1 max-w-md ml-auto">
          <div className="relative">
            <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-amber-600 pointer-events-none" />
            <Input
              type="search"
              placeholder="Search bookings, customers..."
              className="pl-9 h-9 bg-amber-500/10 border-amber-500/20 placeholder:text-amber-600/50"
            />
          </div>
        </div>
      </div>

      <UserNav />
    </header>
  )
}
