"use client"

import { useState, useEffect } from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { LoadingState } from "@/components/common/LoadingState"
import { ErrorState } from "@/components/common/ErrorState"
import { useToast } from "@/components/ui/toast"
import { getSubscription } from "@/services/settings.service"
import type { SubscriptionInfo } from "@/types/settings"
import { CheckCircle, ExternalLink } from "lucide-react"

function StatusBadge({ status }: { status: string }) {
  const variant = status === "active" ? "success" : status === "expired" ? "destructive" : status === "trial" ? "warning" : "secondary"
  return <Badge variant={variant as any}>{status}</Badge>
}

export default function SubscriptionTab() {
  const { toast } = useToast()
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [subscription, setSubscription] = useState<SubscriptionInfo | null>(null)

  useEffect(() => {
    loadSubscription()
  }, [])

  async function loadSubscription() {
    setLoading(true)
    setError(null)
    try {
      const res = await getSubscription()
      if (res.success) setSubscription(res.data)
      else setError(res.message)
    } catch (err: any) {
      setError(err.message || "Failed to load subscription")
    } finally {
      setLoading(false)
    }
  }

  if (loading) return <LoadingState type="page" />
  if (error) return <ErrorState message={error} onRetry={loadSubscription} />
  if (!subscription) return <ErrorState message="No subscription data found" />

  return (
    <Card>
      <CardHeader>
        <CardTitle>Current Plan</CardTitle>
      </CardHeader>
      <CardContent className="space-y-6">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div className="space-y-1">
            <p className="text-sm text-muted-foreground">Plan</p>
            <p className="text-xl font-bold">{subscription.plan_name}</p>
          </div>
          <div className="space-y-1">
            <p className="text-sm text-muted-foreground">Status</p>
            <StatusBadge status={subscription.status} />
          </div>
          <div className="space-y-1">
            <p className="text-sm text-muted-foreground">Start Date</p>
            <p className="font-medium">{new Date(subscription.start_date).toLocaleDateString()}</p>
          </div>
          <div className="space-y-1">
            <p className="text-sm text-muted-foreground">End Date</p>
            <p className="font-medium">{new Date(subscription.end_date).toLocaleDateString()}</p>
          </div>
        </div>

        <div>
          <h3 className="text-sm font-semibold text-slate-700 mb-3">Included Features</h3>
          {subscription.features.length === 0 ? (
            <p className="text-sm text-muted-foreground">No features listed</p>
          ) : (
            <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-2">
              {subscription.features.map((feature, i) => (
                <div key={i} className="flex items-center gap-2 text-sm">
                  <CheckCircle className="h-4 w-4 text-green-500 shrink-0" />
                  <span>{feature}</span>
                </div>
              ))}
            </div>
          )}
        </div>

        <div className="flex justify-end pt-4">
          <Button variant="outline" asChild>
            <a href="/subscriptions" className="inline-flex items-center gap-1">
              Upgrade Plan <ExternalLink className="h-4 w-4" />
            </a>
          </Button>
        </div>
      </CardContent>
    </Card>
  )
}
