import { AlertTriangle } from "lucide-react"
import { Card, CardContent } from "@/components/ui/card"
import { Button } from "@/components/ui/button"

interface ErrorStateProps {
  title?: string
  message?: string
  onRetry?: () => void
}

export function ErrorState({
  title = "Something went wrong",
  message = "An unexpected error occurred. Please try again.",
  onRetry,
}: ErrorStateProps) {
  return (
    <Card className="border-destructive/20">
      <CardContent className="flex flex-col items-center justify-center py-10 px-4 text-center">
        <div className="flex items-center justify-center w-12 h-12 rounded-full bg-destructive/10 mb-4">
          <AlertTriangle className="h-6 w-6 text-destructive" />
        </div>
        <h3 className="text-sm font-semibold text-foreground ">{title}</h3>
        <p className="mt-1 text-sm text-slate-600 max-w-sm">
          {message}
        </p>
        {onRetry && (
          <Button
            variant="outline"
            size="sm"
            className="mt-4 cursor-pointer"
            onClick={onRetry}
          >
            Try Again
          </Button>
        )}
      </CardContent>
    </Card>
  )
}
