"use client"

import { useState, useEffect } from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Button } from "@/components/ui/button"
import { Label } from "@/components/ui/label"
import { Switch } from "@/components/ui/switch"
import { LoadingState } from "@/components/common/LoadingState"
import { ErrorState } from "@/components/common/ErrorState"
import { useToast } from "@/components/ui/toast"
import { getNotificationSettings, updateNotificationSettings } from "@/services/settings.service"
import type { NotificationSettings } from "@/types/settings"

export default function NotificationTab() {
  const { toast } = useToast()
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [form, setForm] = useState<NotificationSettings>({
    id: 0,
    notify_on_booking: true,
    notify_on_payment: true,
    notify_on_cancellation: true,
    notify_on_checkin: false,
    notify_on_lead: false,
    email_enabled: true,
    whatsapp_enabled: false,
    sms_enabled: false,
    notify_admin_only: true,
    daily_digest: false,
    reminder_hours: 24,
  })

  useEffect(() => {
    loadSettings()
  }, [])

  async function loadSettings() {
    setLoading(true)
    setError(null)
    try {
      const res = await getNotificationSettings()
      if (res.success) setForm(res.data)
      else setError(res.message)
    } catch (err: any) {
      setError(err.message || "Failed to load settings")
    } finally {
      setLoading(false)
    }
  }

  function updateField(field: keyof NotificationSettings, value: boolean | number) {
    setForm(prev => ({ ...prev, [field]: value }))
  }

  async function handleSave() {
    if (form.reminder_hours < 1) {
      toast({ title: "Validation Error", description: "Reminder hours must be at least 1.", variant: "destructive" })
      return
    }

    setSaving(true)
    try {
      const res = await updateNotificationSettings(form)
      if (res.success) {
        toast({ title: "Settings saved", description: "Notification settings have been updated." })
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
        <CardTitle>Notification Settings</CardTitle>
      </CardHeader>
      <CardContent className="space-y-6">
        <div>
          <h3 className="text-sm font-semibold text-slate-700 mb-3">Events</h3>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
            <div className="flex items-center gap-3">
              <Switch id="notify_on_booking" checked={form.notify_on_booking} onCheckedChange={v => updateField("notify_on_booking", v)} />
              <Label htmlFor="notify_on_booking">New Booking</Label>
            </div>
            <div className="flex items-center gap-3">
              <Switch id="notify_on_payment" checked={form.notify_on_payment} onCheckedChange={v => updateField("notify_on_payment", v)} />
              <Label htmlFor="notify_on_payment">Payment Received</Label>
            </div>
            <div className="flex items-center gap-3">
              <Switch id="notify_on_cancellation" checked={form.notify_on_cancellation} onCheckedChange={v => updateField("notify_on_cancellation", v)} />
              <Label htmlFor="notify_on_cancellation">Cancellation</Label>
            </div>
            <div className="flex items-center gap-3">
              <Switch id="notify_on_checkin" checked={form.notify_on_checkin} onCheckedChange={v => updateField("notify_on_checkin", v)} />
              <Label htmlFor="notify_on_checkin">Check-in</Label>
            </div>
            <div className="flex items-center gap-3">
              <Switch id="notify_on_lead" checked={form.notify_on_lead} onCheckedChange={v => updateField("notify_on_lead", v)} />
              <Label htmlFor="notify_on_lead">New Lead</Label>
            </div>
          </div>
        </div>

        <div>
          <h3 className="text-sm font-semibold text-slate-700 mb-3">Channels</h3>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
            <div className="flex items-center gap-3">
              <Switch id="email_enabled" checked={form.email_enabled} onCheckedChange={v => updateField("email_enabled", v)} />
              <Label htmlFor="email_enabled">Email</Label>
            </div>
            <div className="flex items-center gap-3">
              <Switch id="whatsapp_enabled" checked={form.whatsapp_enabled} onCheckedChange={v => updateField("whatsapp_enabled", v)} />
              <Label htmlFor="whatsapp_enabled">WhatsApp</Label>
            </div>
            <div className="flex items-center gap-3">
              <Switch id="sms_enabled" checked={form.sms_enabled} onCheckedChange={v => updateField("sms_enabled", v)} />
              <Label htmlFor="sms_enabled">SMS</Label>
            </div>
          </div>
        </div>

        <div>
          <h3 className="text-sm font-semibold text-slate-700 mb-3">Preferences</h3>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
            <div className="flex items-center gap-3">
              <Switch id="notify_admin_only" checked={form.notify_admin_only} onCheckedChange={v => updateField("notify_admin_only", v)} />
              <Label htmlFor="notify_admin_only">Admin Only</Label>
            </div>
            <div className="flex items-center gap-3">
              <Switch id="daily_digest" checked={form.daily_digest} onCheckedChange={v => updateField("daily_digest", v)} />
              <Label htmlFor="daily_digest">Daily Digest</Label>
            </div>
            <div className="space-y-2">
              <Label htmlFor="reminder_hours">Reminder (hours before)</Label>
              <Input id="reminder_hours" type="number" value={form.reminder_hours} onChange={e => updateField("reminder_hours", parseInt(e.target.value) || 0)} placeholder="24" className="max-w-[200px]" />
            </div>
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
