"use client"

import { useState, useEffect } from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Button } from "@/components/ui/button"
import { Label } from "@/components/ui/label"
import { Switch } from "@/components/ui/switch"
import { Textarea } from "@/components/ui/textarea"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { LoadingState } from "@/components/common/LoadingState"
import { ErrorState } from "@/components/common/ErrorState"
import { useToast } from "@/components/ui/toast"
import { getInvoiceSettings, updateInvoiceSettings } from "@/services/settings.service"
import type { InvoiceSettings } from "@/types/settings"

const TEMPLATES = [
  { value: "standard", label: "Standard" },
  { value: "professional", label: "Professional" },
  { value: "minimal", label: "Minimal" },
]

const CURRENCIES = [
  { value: "INR", label: "INR (₹)" },
  { value: "USD", label: "USD ($)" },
  { value: "EUR", label: "EUR (€)" },
  { value: "GBP", label: "GBP (£)" },
  { value: "AUD", label: "AUD (A$)" },
]

export default function InvoiceTab() {
  const { toast } = useToast()
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [form, setForm] = useState<InvoiceSettings>({
    id: 0,
    prefix: "INV",
    next_number: 1,
    footer_text: "",
    payment_terms: "",
    gst_enabled: false,
    gst_rate: 18,
    show_gst: false,
    template: "standard",
    due_days: 30,
    late_payment_penalty: 0,
    currency: "INR",
  })

  useEffect(() => {
    loadSettings()
  }, [])

  async function loadSettings() {
    setLoading(true)
    setError(null)
    try {
      const res = await getInvoiceSettings()
      if (res.success) setForm(res.data)
      else setError(res.message)
    } catch (err: any) {
      setError(err.message || "Failed to load settings")
    } finally {
      setLoading(false)
    }
  }

  function updateField(field: keyof InvoiceSettings, value: string | number | boolean) {
    setForm(prev => ({ ...prev, [field]: value }))
  }

  async function handleSave() {
    if (!form.prefix.trim()) {
      toast({ title: "Validation Error", description: "Invoice prefix is required.", variant: "destructive" })
      return
    }
    if (form.due_days < 0) {
      toast({ title: "Validation Error", description: "Due days must be non-negative.", variant: "destructive" })
      return
    }

    setSaving(true)
    try {
      const res = await updateInvoiceSettings(form)
      if (res.success) {
        toast({ title: "Settings saved", description: "Invoice settings have been updated." })
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
        <CardTitle>Invoice Settings</CardTitle>
      </CardHeader>
      <CardContent className="space-y-6">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div className="space-y-2">
            <Label htmlFor="prefix">Invoice Prefix *</Label>
            <Input id="prefix" value={form.prefix} onChange={e => updateField("prefix", e.target.value)} placeholder="INV" />
          </div>
          <div className="space-y-2">
            <Label htmlFor="next_number">Next Number</Label>
            <Input id="next_number" type="number" value={form.next_number} onChange={e => updateField("next_number", parseInt(e.target.value) || 1)} />
          </div>
          <div className="space-y-2">
            <Label htmlFor="template">Template</Label>
            <Select value={form.template} onValueChange={v => updateField("template", v)}>
              <SelectTrigger id="template">
                <SelectValue placeholder="Select template" />
              </SelectTrigger>
              <SelectContent>
                {TEMPLATES.map(t => (
                  <SelectItem key={t.value} value={t.value}>{t.label}</SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          <div className="space-y-2">
            <Label htmlFor="currency">Currency</Label>
            <Select value={form.currency} onValueChange={v => updateField("currency", v)}>
              <SelectTrigger id="currency">
                <SelectValue placeholder="Select currency" />
              </SelectTrigger>
              <SelectContent>
                {CURRENCIES.map(c => (
                  <SelectItem key={c.value} value={c.value}>{c.label}</SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          <div className="space-y-2">
            <Label htmlFor="due_days">Due Days</Label>
            <Input id="due_days" type="number" value={form.due_days} onChange={e => updateField("due_days", parseInt(e.target.value) || 0)} placeholder="30" />
          </div>
          <div className="space-y-2">
            <Label htmlFor="late_payment_penalty">Late Payment Penalty (%)</Label>
            <Input id="late_payment_penalty" type="number" value={form.late_payment_penalty} onChange={e => updateField("late_payment_penalty", parseFloat(e.target.value) || 0)} placeholder="0" />
          </div>
          <div className="space-y-2">
            <Label htmlFor="payment_terms">Payment Terms</Label>
            <Input id="payment_terms" value={form.payment_terms} onChange={e => updateField("payment_terms", e.target.value)} placeholder="Net 30" />
          </div>
          <div className="space-y-2 md:col-span-3">
            <Label htmlFor="footer_text">Footer Text</Label>
            <Textarea id="footer_text" value={form.footer_text} onChange={e => updateField("footer_text", e.target.value)} placeholder="Thank you for your business" rows={2} />
          </div>
          <div className="flex items-center gap-3 pt-2">
            <Switch id="gst_enabled" checked={form.gst_enabled} onCheckedChange={v => updateField("gst_enabled", v)} />
            <Label htmlFor="gst_enabled">Enable GST</Label>
          </div>
          {form.gst_enabled && (
            <>
              <div className="space-y-2">
                <Label htmlFor="gst_rate">GST Rate (%)</Label>
                <Input id="gst_rate" type="number" value={form.gst_rate} onChange={e => updateField("gst_rate", parseFloat(e.target.value) || 0)} placeholder="18" />
              </div>
              <div className="flex items-center gap-3 pt-2">
                <Switch id="show_gst" checked={form.show_gst} onCheckedChange={v => updateField("show_gst", v)} />
                <Label htmlFor="show_gst">Show GST on Invoice</Label>
              </div>
            </>
          )}
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
