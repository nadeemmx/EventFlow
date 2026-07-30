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
import { getWhatsAppSettings, updateWhatsAppSettings } from "@/services/settings.service"
import type { WhatsAppSettings } from "@/types/settings"

const PROVIDERS = [
  { value: "twilio", label: "Twilio" },
  { value: "gupshup", label: "Gupshup" },
  { value: "messagebird", label: "MessageBird" },
  { value: "wati", label: "WATI" },
]

export default function WhatsAppTab() {
  const { toast } = useToast()
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [form, setForm] = useState<WhatsAppSettings>({
    id: 0,
    provider: "",
    api_key: "",
    phone_number_id: "",
    business_account_id: "",
    webhook_verify_token: "",
    is_active: false,
    send_notifications: false,
  })

  useEffect(() => {
    loadSettings()
  }, [])

  async function loadSettings() {
    setLoading(true)
    setError(null)
    try {
      const res = await getWhatsAppSettings()
      if (res.success) setForm(res.data)
      else setError(res.message)
    } catch (err: any) {
      setError(err.message || "Failed to load settings")
    } finally {
      setLoading(false)
    }
  }

  function updateField(field: keyof WhatsAppSettings, value: string | boolean) {
    setForm(prev => ({ ...prev, [field]: value }))
  }

  async function handleSave() {
    if (!form.provider) {
      toast({ title: "Validation Error", description: "Please select a provider.", variant: "destructive" })
      return
    }
    if (!form.api_key.trim()) {
      toast({ title: "Validation Error", description: "API key is required.", variant: "destructive" })
      return
    }

    setSaving(true)
    try {
      const res = await updateWhatsAppSettings(form)
      if (res.success) {
        toast({ title: "Settings saved", description: "WhatsApp settings have been updated." })
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
        <CardTitle>WhatsApp Settings</CardTitle>
      </CardHeader>
      <CardContent className="space-y-6">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div className="space-y-2">
            <Label htmlFor="provider">Provider *</Label>
            <Select value={form.provider} onValueChange={v => updateField("provider", v)}>
              <SelectTrigger id="provider">
                <SelectValue placeholder="Select provider" />
              </SelectTrigger>
              <SelectContent>
                {PROVIDERS.map(p => (
                  <SelectItem key={p.value} value={p.value}>{p.label}</SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          <div className="space-y-2">
            <Label htmlFor="api_key">API Key *</Label>
            <Input id="api_key" type="password" value={form.api_key} onChange={e => updateField("api_key", e.target.value)} placeholder="API key" />
          </div>
          <div className="space-y-2">
            <Label htmlFor="phone_number_id">Phone Number ID</Label>
            <Input id="phone_number_id" value={form.phone_number_id} onChange={e => updateField("phone_number_id", e.target.value)} placeholder="WhatsApp phone number ID" />
          </div>
          <div className="space-y-2">
            <Label htmlFor="business_account_id">Business Account ID</Label>
            <Input id="business_account_id" value={form.business_account_id} onChange={e => updateField("business_account_id", e.target.value)} placeholder="WABA ID" />
          </div>
          <div className="space-y-2 md:col-span-2">
            <Label htmlFor="webhook_verify_token">Webhook Verify Token</Label>
            <Input id="webhook_verify_token" value={form.webhook_verify_token} onChange={e => updateField("webhook_verify_token", e.target.value)} placeholder="Webhook verification token" />
          </div>
          <div className="flex items-center gap-3 pt-2">
            <Switch id="is_active" checked={form.is_active} onCheckedChange={v => updateField("is_active", v)} />
            <Label htmlFor="is_active">Active</Label>
          </div>
          <div className="flex items-center gap-3 pt-2">
            <Switch id="send_notifications" checked={form.send_notifications} onCheckedChange={v => updateField("send_notifications", v)} />
            <Label htmlFor="send_notifications">Send Notifications</Label>
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
