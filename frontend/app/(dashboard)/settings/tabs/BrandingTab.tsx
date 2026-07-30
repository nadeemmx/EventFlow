"use client"

import { useState, useEffect } from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Button } from "@/components/ui/button"
import { Label } from "@/components/ui/label"
import { Textarea } from "@/components/ui/textarea"
import { LoadingState } from "@/components/common/LoadingState"
import { ErrorState } from "@/components/common/ErrorState"
import { useToast } from "@/components/ui/toast"
import { getBrandingSettings, updateBrandingSettings } from "@/services/settings.service"
import type { BrandingSettings } from "@/types/settings"

export default function BrandingTab() {
  const { toast } = useToast()
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [form, setForm] = useState<BrandingSettings>({
    id: 0,
    primary_color: "#000000",
    secondary_color: "#000000",
    accent_color: "#000000",
    custom_domain: "",
    custom_css: "",
    custom_js: "",
  })

  useEffect(() => {
    loadSettings()
  }, [])

  async function loadSettings() {
    setLoading(true)
    setError(null)
    try {
      const res = await getBrandingSettings()
      if (res.success) setForm(res.data)
      else setError(res.message)
    } catch (err: any) {
      setError(err.message || "Failed to load settings")
    } finally {
      setLoading(false)
    }
  }

  function updateField(field: keyof BrandingSettings, value: string) {
    setForm(prev => ({ ...prev, [field]: value }))
  }

  async function handleSave() {
    setSaving(true)
    try {
      const res = await updateBrandingSettings(form)
      if (res.success) {
        toast({ title: "Settings saved", description: "Branding settings have been updated." })
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
        <CardTitle>Branding Settings</CardTitle>
      </CardHeader>
      <CardContent className="space-y-6">
        <div>
          <h3 className="text-sm font-semibold text-slate-700 mb-3">Colors</h3>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="space-y-2">
              <Label htmlFor="primary_color">Primary Color</Label>
              <div className="flex gap-2">
                <Input id="primary_color" type="color" value={form.primary_color} onChange={e => updateField("primary_color", e.target.value)} className="w-12 h-9 p-1" />
                <Input value={form.primary_color} onChange={e => updateField("primary_color", e.target.value)} placeholder="#000000" />
              </div>
            </div>
            <div className="space-y-2">
              <Label htmlFor="secondary_color">Secondary Color</Label>
              <div className="flex gap-2">
                <Input id="secondary_color" type="color" value={form.secondary_color} onChange={e => updateField("secondary_color", e.target.value)} className="w-12 h-9 p-1" />
                <Input value={form.secondary_color} onChange={e => updateField("secondary_color", e.target.value)} placeholder="#000000" />
              </div>
            </div>
            <div className="space-y-2">
              <Label htmlFor="accent_color">Accent Color</Label>
              <div className="flex gap-2">
                <Input id="accent_color" type="color" value={form.accent_color} onChange={e => updateField("accent_color", e.target.value)} className="w-12 h-9 p-1" />
                <Input value={form.accent_color} onChange={e => updateField("accent_color", e.target.value)} placeholder="#000000" />
              </div>
            </div>
          </div>
        </div>

        <div className="space-y-2">
          <Label htmlFor="custom_domain">Custom Domain</Label>
          <Input id="custom_domain" value={form.custom_domain} onChange={e => updateField("custom_domain", e.target.value)} placeholder="events.yourdomain.com" />
        </div>

        <div className="space-y-2">
          <Label htmlFor="custom_css">Custom CSS</Label>
          <Textarea id="custom_css" value={form.custom_css} onChange={e => updateField("custom_css", e.target.value)} placeholder="/* Custom CSS here */" rows={6} className="font-mono text-xs" />
        </div>

        <div className="space-y-2">
          <Label htmlFor="custom_js">Custom JavaScript</Label>
          <Textarea id="custom_js" value={form.custom_js} onChange={e => updateField("custom_js", e.target.value)} placeholder="// Custom JavaScript here" rows={6} className="font-mono text-xs" />
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
