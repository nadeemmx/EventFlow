import type { LucideIcon } from "lucide-react"
import { cn } from "@/lib/utils"
import { Card, CardContent } from "@/components/ui/card"
import { Skeleton } from "@/components/ui/skeleton"

interface StatCardProps {
  title: string
  value: string | number
  icon: LucideIcon
  trend?: {
    value: string
    positive: boolean
  }
  description?: string
  loading?: boolean
}

export function StatCard({
  title,
  value,
  icon: Icon,
  trend,
  description,
  loading = false,
}: StatCardProps) {
  if (loading) {
    return (
      <Card>
        <CardContent className="p-6">
          <div className="flex items-center justify-between">
            <div className="space-y-3">
              <Skeleton className="h-4 w-24" />
              <Skeleton className="h-8 w-16" />
              <Skeleton className="h-3 w-32" />
            </div>
            <Skeleton className="h-10 w-10 rounded-lg" />
          </div>
        </CardContent>
      </Card>
    )
  }

  return (
    <div className="premium-stat">
      <div className="p-5">
        <div className="flex items-center justify-between">
          <div className="space-y-1">
            <p className="text-sm font-medium text-slate-600">{title}</p>
            <p className="text-2xl font-bold  tracking-tight text-slate-900">{value}</p>
            {(trend || description) && (
              <div className="flex items-center gap-2">
                {trend && (
                  <span
                    className={cn(
                      "text-xs font-medium",
                      trend.positive ? "text-success" : "text-destructive"
                    )}
                  >
                    {trend.positive ? "↑" : "↓"} {trend.value}
                  </span>
                )}
                {description && (
                  <span className="text-xs text-slate-600">{description}</span>
                )}
              </div>
            )}
          </div>
          <div className="flex items-center justify-center w-11 h-11 rounded-xl bg-amber-500/10 border border-amber-500/20 text-amber-600">
            <Icon className="h-5 w-5" />
          </div>
        </div>
      </div>
    </div>
  )
}
