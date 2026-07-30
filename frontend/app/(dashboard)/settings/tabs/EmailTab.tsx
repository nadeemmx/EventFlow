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
import { getEmailSettings, updateEmailSettings } from "@/services/settings.service"
import type { EmailSettings } from "@/types/settings"

export default function EmailTab() {
  const { toast } = useToast()
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [form, setForm] = useState<EmailSettings>({
    id: 0,
    smtp_host: "",
    smtp_port: 587,
    smtp_username: "",
    smtp_password: "",
    from_email: "",
    from_name: "",
    use_tls: true,
    use_ssl: false,
    is_active: false,
  })

  useEffect(() => {
    loadSettings()
  }, [])

  async function loadSettings() {
    setLoading(true)
    setError(null)
    try {
      const res = await getEmailSettings()
      if (res.success) setForm(res.data)
      else setError(res.message)
    } catch (err: any) {
      setError(err.message || "Failed to load settings")
    } finally {
      setLoading(false)
    }
  }

  function updateField(field: keyof EmailSettings, value: string | number | boolean) {
    setForm(prev => ({ ...prev, [field]: value }))
  }

  async function handleSave() {
    if (!form.smtp_host.trim()) {
      toast({ title: "Validation Error", description: "SMTP host is required.", variant: "destructive" })
      return
    }
    if (!form.smtp_port || form.smtp_port < 1 || form.smtp_port > 65535) {
      toast({ title: "Validation Error", description: "SMTP port must be between 1 and 65535.", variant: "destructive" })
      return
    }
    if (!form.from_email.trim()) {
      toast({ title: "Validation Error", description: "From email is required.", variant: "destructive" })
      return
    }

    setSaving(true)
    try {
      const res = await updateEmailSettings(form)
      if (res.success) {
        toast({ title: "Settings saved", description: "Email settings have been updated." })
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
        <CardTitle>Email Settings</CardTitle>
      </CardHeader>
      <CardContent className="space-y-6">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div className="space-y-2">
            <Label htmlFor="smtp_host">SMTP Host *</Label>
            <Input id="smtp_host" value={form.smtp_host} onChange={e => updateField("smtp_host", e.target.value)} placeholder="smtp.example.com" />
          </div>
          <div className="space-y-2">
            <Label htmlFor="smtp_port">SMTP Port *</Label>
            <Input id="smtp_port" type="number" value={form.smtp_port} onChange={e => updateField("smtp_port", parseInt(e.target.value) || "")} placeholder="587" />
          </div>
          <div className="space-y-2">
            <Label htmlFor="smtp_username">SMTP Username</Label>
            <Input id="smtp_username" value={form.smtp_username} onChange={e => updateField("smtp_username", e.target.value)} placeholder="SMTP username" />
          </div>
          <div className="space-y-2">
            <Label htmlFor="smtp_password">SMTP Password</Label>
            <Input id="smtp_password" type="password" value={form.smtp_password} onChange={e => updateField("smtp_password", e.target.value)} placeholder="SMTP password" />
          </div>
          <div className="space-y-2">
            <Label htmlFor="from_email">From Email *</Label>
            <Input id="from_email" type="email" value={form.from_email} onChange={e => updateField("from_email", e.target.value)} placeholder="noreply@example.com" />
          </div>
          <div className="space-y-2">
            <Label htmlFor="from_name">From Name</Label>
            <Input id="from_name" value={form.from_name} onChange={e => updateField("from_name", e.target.value)} placeholder="Your Business Name" />
          </div>
          <div className="flex items-center gap-3 pt-2">
            <Switch id="use_tls" checked={form.use_tls} onCheckedChange={v => updateField("use_tls", v)} />
            <Label htmlFor="use_tls">Use TLS</Label>
          </div>
          <div className="flex items-center gap-3 pt-2">
            <Switch id="use_ssl" checked={form.use_ssl} onCheckedChange={v => updateField("use_ssl", v)} />
            <Label htmlFor="use_ssl">Use SSL</Label>
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
