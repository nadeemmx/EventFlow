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
import { getOrganizationSettings, updateOrganizationSettings } from "@/services/settings.service"
import type { OrganizationSettings } from "@/types/settings"

export default function OrganizationTab() {
  const { toast } = useToast()
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [form, setForm] = useState<OrganizationSettings>({
    business_name: "",
    owner_name: "",
    email: "",
    mobile: "",
    address: "",
    gst_number: "",
  })

  useEffect(() => {
    loadSettings()
  }, [])

  async function loadSettings() {
    setLoading(true)
    setError(null)
    try {
      const res = await getOrganizationSettings()
      if (res.success) setForm(res.data)
      else setError(res.message)
    } catch (err: any) {
      setError(err.message || "Failed to load settings")
    } finally {
      setLoading(false)
    }
  }

  function updateField(field: keyof OrganizationSettings, value: string) {
    setForm(prev => ({ ...prev, [field]: value }))
  }

  async function handleSave() {
    if (!form.business_name.trim()) {
      toast({ title: "Validation Error", description: "Business name is required.", variant: "destructive" })
      return
    }
    if (!form.email.trim()) {
      toast({ title: "Validation Error", description: "Email is required.", variant: "destructive" })
      return
    }
    if (!form.mobile.trim()) {
      toast({ title: "Validation Error", description: "Mobile number is required.", variant: "destructive" })
      return
    }

    setSaving(true)
    try {
      const res = await updateOrganizationSettings(form)
      if (res.success) {
        toast({ title: "Settings saved", description: "Organization settings have been updated." })
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
        <CardTitle>Organization Settings</CardTitle>
      </CardHeader>
      <CardContent className="space-y-6">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div className="space-y-2">
            <Label htmlFor="business_name">Business Name *</Label>
            <Input id="business_name" value={form.business_name} onChange={e => updateField("business_name", e.target.value)} placeholder="Your business name" />
          </div>
          <div className="space-y-2">
            <Label htmlFor="owner_name">Owner Name</Label>
            <Input id="owner_name" value={form.owner_name} onChange={e => updateField("owner_name", e.target.value)} placeholder="Owner's full name" />
          </div>
          <div className="space-y-2">
            <Label htmlFor="email">Email *</Label>
            <Input id="email" type="email" value={form.email} onChange={e => updateField("email", e.target.value)} placeholder="business@example.com" />
          </div>
          <div className="space-y-2">
            <Label htmlFor="mobile">Mobile *</Label>
            <Input id="mobile" value={form.mobile} onChange={e => updateField("mobile", e.target.value)} placeholder="+1 234 567 8900" />
          </div>
          <div className="space-y-2 md:col-span-2">
            <Label htmlFor="address">Address</Label>
            <Textarea id="address" value={form.address} onChange={e => updateField("address", e.target.value)} placeholder="Business address" rows={3} />
          </div>
          <div className="space-y-2">
            <Label htmlFor="gst_number">GST Number</Label>
            <Input id="gst_number" value={form.gst_number} onChange={e => updateField("gst_number", e.target.value)} placeholder="GSTIN (if applicable)" />
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
