"use client"

import { useState, useMemo } from "react"
import { useRouter } from "next/navigation"
import { ChevronLeft, ChevronRight, CalendarDays } from "lucide-react"
import { useCalendarBookings } from "@/hooks/use-bookings"
import { PageHeader } from "@/components/common/PageHeader"
import { StatusBadge } from "@/components/common/StatusBadge"
import { LoadingState } from "@/components/common/LoadingState"
import { ErrorState } from "@/components/common/ErrorState"
import { Button } from "@/components/ui/button"
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from "@/components/ui/dialog"
import { ScrollArea } from "@/components/ui/scroll-area"
import { cn, formatDate, formatINR } from "@/lib/utils"
import type { Booking } from "@/types/api"

const DAYS = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

export default function CalendarPage() {
  const router = useRouter()
  const now = new Date()
  const [currentMonth, setCurrentMonth] = useState(now.getMonth() + 1)
  const [currentYear, setCurrentYear] = useState(now.getFullYear())
  const [selectedDay, setSelectedDay] = useState<{
    date: string
    bookings: Booking[]
  } | null>(null)

  const { data, isLoading, error, refetch } = useCalendarBookings({
    month: currentMonth,
    year: currentYear,
  })

  const bookings = data?.data ?? []

  const calendarData = useMemo(() => {
    const firstDay = new Date(currentYear, currentMonth - 1, 1)
    const lastDay = new Date(currentYear, currentMonth, 0)
    const startDayOfWeek = firstDay.getDay()
    const daysInMonth = lastDay.getDate()

    const bookingsByDate: Record<string, Booking[]> = {}
    bookings.forEach((b) => {
      const dateKey = b.event_date
      if (!bookingsByDate[dateKey]) bookingsByDate[dateKey] = []
      bookingsByDate[dateKey].push(b)
    })

    const cells: { day: number; dateStr: string; isToday: boolean; isCurrentMonth: boolean }[] = []

    for (let i = 0; i < startDayOfWeek; i++) {
      cells.push({ day: 0, dateStr: "", isToday: false, isCurrentMonth: false })
    }

    const todayStr = `${currentYear}-${String(currentMonth).padStart(2, "0")}-${String(now.getDate()).padStart(2, "0")}`

    for (let d = 1; d <= daysInMonth; d++) {
      const dateStr = `${currentYear}-${String(currentMonth).padStart(2, "0")}-${String(d).padStart(2, "0")}`
      cells.push({
        day: d,
        dateStr,
        isToday: dateStr === todayStr,
        isCurrentMonth: true,
      })
    }

    return { cells, bookingsByDate }
  }, [currentYear, currentMonth, bookings, now])

  const handlePrevMonth = () => {
    if (currentMonth === 1) {
      setCurrentMonth(12)
      setCurrentYear((y) => y - 1)
    } else {
      setCurrentMonth((m) => m - 1)
    }
  }

  const handleNextMonth = () => {
    if (currentMonth === 12) {
      setCurrentMonth(1)
      setCurrentYear((y) => y + 1)
    } else {
      setCurrentMonth((m) => m + 1)
    }
  }

  const handleDayClick = (dateStr: string) => {
    const dayBookings = calendarData.bookingsByDate[dateStr]
    if (dayBookings && dayBookings.length > 0) {
      setSelectedDay({ date: dateStr, bookings: dayBookings })
    }
  }

  const monthName = new Date(currentYear, currentMonth - 1).toLocaleString("en-US", { month: "long" })

  return (
    <div className="space-y-6">
      <PageHeader title="Calendar" description="View bookings by date" />

      <div className="bg-card rounded-lg border shadow-sm overflow-hidden">
        <div className="flex items-center justify-between p-4 border-b">
          <Button variant="outline" size="sm" onClick={handlePrevMonth} className="cursor-pointer">
            <ChevronLeft className="h-4 w-4 mr-1" />
            Previous
          </Button>
          <div className="flex items-center gap-2">
            <CalendarDays className="h-5 w-5 text-primary" />
            <span className="text-lg font-semibold">
              {monthName} {currentYear}
            </span>
          </div>
          <Button variant="outline" size="sm" onClick={handleNextMonth} className="cursor-pointer">
            Next
            <ChevronRight className="h-4 w-4 ml-1" />
          </Button>
        </div>

        {isLoading ? (
          <div className="p-8">
            <LoadingState type="spinner" />
          </div>
        ) : error ? (
          <div className="p-8">
            <ErrorState
              message={(error as Error).message}
              onRetry={() => refetch()}
            />
          </div>
        ) : (
          <>
            <div className="grid grid-cols-7 border-b">
              {DAYS.map((d) => (
                <div
                  key={d}
                  className="px-2 py-3 text-center text-xs font-medium text-muted-foreground border-r last:border-r-0"
                >
                  {d}
                </div>
              ))}
            </div>

            <div className="grid grid-cols-7">
              {calendarData.cells.map((cell, idx) => {
                const dayBookings = cell.dateStr
                  ? calendarData.bookingsByDate[cell.dateStr]
                  : undefined
                const hasEvents = !!dayBookings && dayBookings.length > 0

                return (
                  <div
                    key={idx}
                    role={cell.dateStr ? "button" : undefined}
                    tabIndex={cell.dateStr ? 0 : undefined}
                    aria-label={
                      cell.dateStr
                        ? `View bookings for ${formatDate(cell.dateStr)}`
                        : undefined
                    }
                    className={cn(
                      "min-h-[100px] p-2 border-b border-r last:border-r-0 relative transition-colors",
                      cell.isCurrentMonth ? "bg-background" : "bg-muted/30",
                      cell.isToday && "bg-primary/5",
                      hasEvents && "cursor-pointer hover:bg-accent/50"
                    )}
                    onClick={() => cell.dateStr && handleDayClick(cell.dateStr)}
                    onKeyDown={(e) => {
                      if (e.target !== e.currentTarget || !cell.dateStr) return
                      if (e.key === "Enter" || e.key === " ") {
                        e.preventDefault()
                        handleDayClick(cell.dateStr)
                      }
                    }}
                  >
                    {cell.day > 0 && (
                      <>
                        <div
                          className={cn(
                            "inline-flex items-center justify-center w-7 h-7 text-sm rounded-full mb-1",
                            cell.isToday
                              ? "bg-primary text-primary-foreground font-bold"
                              : "text-foreground"
                          )}
                        >
                          {cell.day}
                        </div>
                        {hasEvents && (
                          <div className="space-y-1">
                            {dayBookings!.slice(0, 3).map((b) => (
                              <div
                                key={b.id}
                                className="text-[10px] truncate rounded px-1 py-0.5 bg-primary/10 text-primary font-medium"
                                title={b.booking_number}
                              >
                                {b.booking_number}
                              </div>
                            ))}
                            {dayBookings!.length > 3 && (
                              <p className="text-[10px] text-muted-foreground pl-1">
                                +{dayBookings!.length - 3} more
                              </p>
                            )}
                          </div>
                        )}
                      </>
                    )}
                  </div>
                )
              })}
            </div>
          </>
        )}
      </div>

      <Dialog
        open={!!selectedDay}
        onOpenChange={(open) => !open && setSelectedDay(null)}
      >
        <DialogContent className="max-w-lg">
          <DialogHeader>
            <DialogTitle>
              Bookings for {selectedDay && formatDate(selectedDay.date)}
            </DialogTitle>
            <DialogDescription>
              {selectedDay?.bookings.length} booking{selectedDay?.bookings.length !== 1 ? "s" : ""} on this day
            </DialogDescription>
          </DialogHeader>
          <ScrollArea className="max-h-[350px]">
            <div className="space-y-3">
              {selectedDay?.bookings.map((b) => (
                <div
                  key={b.id}
                  role="button"
                  tabIndex={0}
                  aria-label={`View booking ${b.booking_number}`}
                  className="flex items-center justify-between p-3 rounded-lg border bg-card hover:bg-accent/50 cursor-pointer transition-colors"
                  onClick={() => {
                    setSelectedDay(null)
                    router.push(`/bookings/${b.id}`)
                  }}
                  onKeyDown={(e) => {
                    if (e.target !== e.currentTarget) return
                    if (e.key === "Enter" || e.key === " ") {
                      e.preventDefault()
                      setSelectedDay(null)
                      router.push(`/bookings/${b.id}`)
                    }
                  }}
                >
                  <div className="min-w-0 flex-1">
                    <p className="font-mono text-sm font-medium text-primary truncate">
                      {b.booking_number}
                    </p>
                    <p className="text-xs text-muted-foreground mt-0.5">
                      {b.event_type.replace(/_/g, " ")} · {b.guest_count} guests
                    </p>
                  </div>
                  <div className="flex items-center gap-3 shrink-0">
                    <span className="text-sm font-mono font-medium">
                      {formatINR(Number(b.total_amount))}
                    </span>
                    <StatusBadge status={b.status} type="booking" />
                  </div>
                </div>
              ))}
            </div>
          </ScrollArea>
        </DialogContent>
      </Dialog>
    </div>
  )
}
