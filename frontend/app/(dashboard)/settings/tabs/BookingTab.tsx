"use client"

import { useState, useEffect } from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Button } from "@/components/ui/button"
import { Label } from "@/components/ui/label"
import { Switch } from "@/components/ui/switch"
import { Textarea } from "@/components/ui/textarea"
import { LoadingState } from "@/components/common/LoadingState"
import { ErrorState } from "@/components/common/ErrorState"
import { useToast } from "@/components/ui/toast"
import { getBookingSettings, updateBookingSettings } from "@/services/settings.service"
import type { BookingSettings } from "@/types/settings"

export default function BookingTab() {
  const { toast } = useToast()
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [form, setForm] = useState<BookingSettings>({
    id: 0,
    tentative_validity_hours: 48,
    auto_confirm: false,
    buffer_days: 0,
    max_advance_days: 365,
    max_refund_days: 30,
    allow_partial_payment: false,
    deposit_percentage: 25,
    cancellation_policy: "",
    require_full_payment_days: 0,
  })

  useEffect(() => {
    loadSettings()
  }, [])

  async function loadSettings() {
    setLoading(true)
    setError(null)
    try {
      const res = await getBookingSettings()
      if (res.success) setForm(res.data)
      else setError(res.message)
    } catch (err: any) {
      setError(err.message || "Failed to load settings")
    } finally {
      setLoading(false)
    }
  }

  function updateField(field: keyof BookingSettings, value: string | number | boolean) {
    setForm(prev => ({ ...prev, [field]: value }))
  }

  async function handleSave() {
    if (form.tentative_validity_hours < 1) {
      toast({ title: "Validation Error", description: "Validity hours must be at least 1.", variant: "destructive" })
      return
    }
    if (form.deposit_percentage < 0 || form.deposit_percentage > 100) {
      toast({ title: "Validation Error", description: "Deposit percentage must be between 0 and 100.", variant: "destructive" })
      return
    }

    setSaving(true)
    try {
      const res = await updateBookingSettings(form)
      if (res.success) {
        toast({ title: "Settings saved", description: "Booking settings have been updated." })
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
        <CardTitle>Booking Settings</CardTitle>
      </CardHeader>
      <CardContent className="space-y-6">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div className="space-y-2">
            <Label htmlFor="tentative_validity_hours">Tentative Validity (hours) *</Label>
            <Input id="tentative_validity_hours" type="number" value={form.tentative_validity_hours} onChange={e => updateField("tentative_validity_hours", parseInt(e.target.value) || 0)} placeholder="48" />
          </div>
          <div className="space-y-2">
            <Label htmlFor="buffer_days">Buffer Days</Label>
            <Input id="buffer_days" type="number" value={form.buffer_days} onChange={e => updateField("buffer_days", parseInt(e.target.value) || 0)} placeholder="0" />
          </div>
          <div className="space-y-2">
            <Label htmlFor="max_advance_days">Max Advance Booking (days)</Label>
            <Input id="max_advance_days" type="number" value={form.max_advance_days} onChange={e => updateField("max_advance_days", parseInt(e.target.value) || 0)} placeholder="365" />
          </div>
          <div className="space-y-2">
            <Label htmlFor="max_refund_days">Max Refund Days</Label>
            <Input id="max_refund_days" type="number" value={form.max_refund_days} onChange={e => updateField("max_refund_days", parseInt(e.target.value) || 0)} placeholder="30" />
          </div>
          <div className="space-y-2">
            <Label htmlFor="deposit_percentage">Deposit Percentage (%)</Label>
            <Input id="deposit_percentage" type="number" value={form.deposit_percentage} onChange={e => updateField("deposit_percentage", parseFloat(e.target.value) || 0)} placeholder="25" />
          </div>
          <div className="space-y-2">
            <Label htmlFor="require_full_payment_days">Require Full Payment (days before)</Label>
            <Input id="require_full_payment_days" type="number" value={form.require_full_payment_days} onChange={e => updateField("require_full_payment_days", parseInt(e.target.value) || 0)} placeholder="0" />
          </div>
          <div className="flex items-center gap-3 pt-2">
            <Switch id="auto_confirm" checked={form.auto_confirm} onCheckedChange={v => updateField("auto_confirm", v)} />
            <Label htmlFor="auto_confirm">Auto Confirm Bookings</Label>
          </div>
          <div className="flex items-center gap-3 pt-2">
            <Switch id="allow_partial_payment" checked={form.allow_partial_payment} onCheckedChange={v => updateField("allow_partial_payment", v)} />
            <Label htmlFor="allow_partial_payment">Allow Partial Payment</Label>
          </div>
          <div className="space-y-2 md:col-span-3">
            <Label htmlFor="cancellation_policy">Cancellation Policy</Label>
            <Textarea id="cancellation_policy" value={form.cancellation_policy} onChange={e => updateField("cancellation_policy", e.target.value)} placeholder="Describe your cancellation policy..." rows={4} />
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
