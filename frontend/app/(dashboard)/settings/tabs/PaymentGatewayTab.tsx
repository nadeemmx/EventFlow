"use client"

import { useState, useEffect } from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Button } from "@/components/ui/button"
import { Label } from "@/components/ui/label"
import { Switch } from "@/components/ui/switch"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { LoadingState } from "@/components/common/LoadingState"
import { ErrorState } from "@/components/common/ErrorState"
import { useToast } from "@/components/ui/toast"
import { getPaymentGatewaySettings, updatePaymentGatewaySettings } from "@/services/settings.service"
import type { PaymentGatewaySettings } from "@/types/settings"

const GATEWAYS = [
  { value: "razorpay", label: "Razorpay" },
  { value: "stripe", label: "Stripe" },
  { value: "paypal", label: "PayPal" },
  { value: "instamojo", label: "Instamojo" },
  { value: "paytm", label: "Paytm" },
]

export default function PaymentGatewayTab() {
  const { toast } = useToast()
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [form, setForm] = useState<PaymentGatewaySettings>({
    id: 0,
    gateway: "",
    api_key: "",
    api_secret: "",
    webhook_secret: "",
    is_active: false,
    environment: "test",
  })

  useEffect(() => {
    loadSettings()
  }, [])

  async function loadSettings() {
    setLoading(true)
    setError(null)
    try {
      const res = await getPaymentGatewaySettings()
      if (res.success) setForm(res.data)
      else setError(res.message)
    } catch (err: any) {
      setError(err.message || "Failed to load settings")
    } finally {
      setLoading(false)
    }
  }

  function updateField(field: keyof PaymentGatewaySettings, value: string | boolean) {
    setForm(prev => ({ ...prev, [field]: value }))
  }

  async function handleSave() {
    if (!form.gateway) {
      toast({ title: "Validation Error", description: "Please select a gateway.", variant: "destructive" })
      return
    }
    if (!form.api_key.trim()) {
      toast({ title: "Validation Error", description: "API key is required.", variant: "destructive" })
      return
    }

    setSaving(true)
    try {
      const res = await updatePaymentGatewaySettings(form)
      if (res.success) {
        toast({ title: "Settings saved", description: "Payment gateway settings have been updated." })
      } else {
        toast({ title: "Error", description: res.message, variant: "destructive" })
      }
    } catch (err: any) {
      toast({ title: "Error", description: err.message, variant: "destructive" })
    } finally {
      setSaving(false)
    }
  }

  if (loading) return <LoadingState type="page" />
  if (error) return <ErrorState message={error} onRetry={loadSettings} />

  return (
    <Card>
      <CardHeader>
        <CardTitle>Payment Gateway Settings</CardTitle>
      </CardHeader>
      <CardContent className="space-y-6">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div className="space-y-2">
            <Label htmlFor="gateway">Gateway *</Label>
            <Select value={form.gateway} onValueChange={v => updateField("gateway", v)}>
              <SelectTrigger id="gateway">
                <SelectValue placeholder="Select gateway" />
              </SelectTrigger>
              <SelectContent>
                {GATEWAYS.map(g => (
                  <SelectItem key={g.value} value={g.value}>{g.label}</SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          <div className="space-y-2">
            <Label htmlFor="environment">Environment</Label>
            <Select value={form.environment} onValueChange={v => updateField("environment", v)}>
              <SelectTrigger id="environment">
                <SelectValue placeholder="Select environment" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="test">Test</SelectItem>
                <SelectItem value="live">Live</SelectItem>
              </SelectContent>
            </Select>
          </div>
          <div className="space-y-2">
            <Label htmlFor="api_key">API Key *</Label>
            <Input id="api_key" value={form.api_key} onChange={e => updateField("api_key", e.target.value)} placeholder="API key" />
          </div>
          <div className="space-y-2">
            <Label htmlFor="api_secret">API Secret</Label>
            <Input id="api_secret" type="password" value={form.api_secret} onChange={e => updateField("api_secret", e.target.value)} placeholder="API secret" />
          </div>
          <div className="space-y-2 md:col-span-2">
            <Label htmlFor="webhook_secret">Webhook Secret</Label>
            <Input id="webhook_secret" type="password" value={form.webhook_secret} onChange={e => updateField("webhook_secret", e.target.value)} placeholder="Webhook signing secret" />
          </div>
          <div className="flex items-center gap-3 pt-2">
            <Switch id="is_active" checked={form.is_active} onCheckedChange={v => updateField("is_active", v)} />
            <Label htmlFor="is_active">Active</Label>
          </div>
        </div>
        <div className="flex justify-end pt-4">
          <Button onClick={handleSave} disabled={saving}>
            {saving ? "Saving..." : "Save Changes"}
          </Button>
        </div>
      </CardContent>
    </Card>
  )
}
