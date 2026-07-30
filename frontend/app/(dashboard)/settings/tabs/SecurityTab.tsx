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
import { getSecuritySettings, updateSecuritySettings } from "@/services/settings.service"
import type { SecuritySettings } from "@/types/settings"

export default function SecurityTab() {
  const { toast } = useToast()
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [form, setForm] = useState<SecuritySettings>({
    id: 0,
    two_factor_enabled: false,
    session_timeout_minutes: 60,
    password_min_length: 8,
    require_special_char: true,
    require_number: true,
    require_uppercase: true,
    max_login_attempts: 5,
    ip_whitelist_enabled: false,
    allowed_ips: "",
    allowed_domains: "",
  })

  useEffect(() => {
    loadSettings()
  }, [])

  async function loadSettings() {
    setLoading(true)
    setError(null)
    try {
      const res = await getSecuritySettings()
      if (res.success) setForm(res.data)
      else setError(res.message)
    } catch (err: any) {
      setError(err.message || "Failed to load settings")
    } finally {
      setLoading(false)
    }
  }

  function updateField(field: keyof SecuritySettings, value: string | number | boolean) {
    setForm(prev => ({ ...prev, [field]: value }))
  }

  async function handleSave() {
    if (form.session_timeout_minutes < 1) {
      toast({ title: "Validation Error", description: "Session timeout must be at least 1 minute.", variant: "destructive" })
      return
    }
    if (form.password_min_length < 6) {
      toast({ title: "Validation Error", description: "Password min length must be at least 6.", variant: "destructive" })
      return
    }
    if (form.max_login_attempts < 1) {
      toast({ title: "Validation Error", description: "Max login attempts must be at least 1.", variant: "destructive" })
      return
    }

    setSaving(true)
    try {
      const res = await updateSecuritySettings(form)
      if (res.success) {
        toast({ title: "Settings saved", description: "Security settings have been updated." })
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
        <CardTitle>Security Settings</CardTitle>
      </CardHeader>
      <CardContent className="space-y-6">
        <div>
          <h3 className="text-sm font-semibold text-slate-700 mb-3">Authentication</h3>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="flex items-center gap-3 pt-2">
              <Switch id="two_factor_enabled" checked={form.two_factor_enabled} onCheckedChange={v => updateField("two_factor_enabled", v)} />
              <Label htmlFor="two_factor_enabled">Two-Factor Authentication</Label>
            </div>
            <div className="space-y-2">
              <Label htmlFor="session_timeout_minutes">Session Timeout (minutes)</Label>
              <Input id="session_timeout_minutes" type="number" value={form.session_timeout_minutes} onChange={e => updateField("session_timeout_minutes", parseInt(e.target.value) || 0)} placeholder="60" />
            </div>
          </div>
        </div>

        <div>
          <h3 className="text-sm font-semibold text-slate-700 mb-3">Password Policy</h3>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="password_min_length">Minimum Length</Label>
              <Input id="password_min_length" type="number" value={form.password_min_length} onChange={e => updateField("password_min_length", parseInt(e.target.value) || 0)} placeholder="8" />
            </div>
            <div className="space-y-2">
              <Label htmlFor="max_login_attempts">Max Login Attempts</Label>
              <Input id="max_login_attempts" type="number" value={form.max_login_attempts} onChange={e => updateField("max_login_attempts", parseInt(e.target.value) || 0)} placeholder="5" />
            </div>
            <div className="flex items-center gap-3">
              <Switch id="require_special_char" checked={form.require_special_char} onCheckedChange={v => updateField("require_special_char", v)} />
              <Label htmlFor="require_special_char">Require Special Character</Label>
            </div>
            <div className="flex items-center gap-3">
              <Switch id="require_number" checked={form.require_number} onCheckedChange={v => updateField("require_number", v)} />
              <Label htmlFor="require_number">Require Number</Label>
            </div>
            <div className="flex items-center gap-3">
              <Switch id="require_uppercase" checked={form.require_uppercase} onCheckedChange={v => updateField("require_uppercase", v)} />
              <Label htmlFor="require_uppercase">Require Uppercase</Label>
            </div>
          </div>
        </div>

        <div>
          <h3 className="text-sm font-semibold text-slate-700 mb-3">IP Whitelist</h3>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="flex items-center gap-3 pt-2">
              <Switch id="ip_whitelist_enabled" checked={form.ip_whitelist_enabled} onCheckedChange={v => updateField("ip_whitelist_enabled", v)} />
              <Label htmlFor="ip_whitelist_enabled">Enable IP Whitelist</Label>
            </div>
            {form.ip_whitelist_enabled && (
              <>
                <div className="space-y-2 md:col-span-2">
                  <Label htmlFor="allowed_ips">Allowed IPs (one per line)</Label>
                  <Textarea id="allowed_ips" value={form.allowed_ips} onChange={e => updateField("allowed_ips", e.target.value)} placeholder="192.168.1.1&#10;10.0.0.0/24" rows={3} />
                </div>
                <div className="space-y-2 md:col-span-2">
                  <Label htmlFor="allowed_domains">Allowed Domains (one per line)</Label>
                  <Textarea id="allowed_domains" value={form.allowed_domains} onChange={e => updateField("allowed_domains", e.target.value)} placeholder="example.com&#10;mycompany.com" rows={3} />
                </div>
              </>
            )}
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
