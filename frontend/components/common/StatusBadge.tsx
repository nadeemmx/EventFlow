import { cn } from "@/lib/utils"
import { Badge } from "@/components/ui/badge"
import { STATUS_COLORS } from "@/lib/constants"

interface StatusBadgeProps {
  status: string
  type?: "booking" | "lead" | "payment" | "venue" | "contract" | "quotation" | "generic"
}

export function StatusBadge({
  status,
  type = "generic",
}: StatusBadgeProps) {
  const value = status ?? ""
  const colorClass = STATUS_COLORS[value] || "bg-slate-200 text-slate-900"

  return (
    <Badge
      variant="outline"
      className={cn(
        "font-medium border-0",
        colorClass
      )}
    >
      {value.replace(/_/g, " ") || "—"}
    </Badge>
  )
}
