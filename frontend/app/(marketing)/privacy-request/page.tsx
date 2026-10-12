"use client"

import { useState } from "react"
import { useForm } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import { z } from "zod"
import { Send } from "lucide-react"

import apiClient from "@/lib/api-client"
import { business } from "@/lib/business"
import PageHero from "@/components/marketing/PageHero"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Textarea } from "@/components/ui/textarea"
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"

const requestSchema = z.object({
  email: z.string().email("Please enter the email address on the account"),
  full_name: z.string().max(255).optional().or(z.literal("")),
  request_type: z.string().min(1, "Please choose a request type"),
  description: z.string().max(5000).optional().or(z.literal("")),
  privacy_acknowledged: z.literal(true, {
    errorMap: () => ({ message: "Please confirm this statement" }),
  }),
})

type RequestForm = z.infer<typeof requestSchema>

const REQUEST_TYPES = [
  { value: "ACCESS", label: "Access / copy of my data" },
  { value: "RECTIFICATION", label: "Correction of my data" },
  { value: "ERASURE", label: "Deletion of my data" },
  { value: "PORTABILITY", label: "Export of my data" },
  { value: "RESTRICTION", label: "Restriction of processing" },
  { value: "OBJECTION", label: "Objection to processing" },
  { value: "ACCOUNT_CLOSURE", label: "Account closure" },
  { value: "OTHER", label: "Other privacy question" },
]

export default function PrivacyRequestPage() {
  const [reference, setReference] = useState<string | null>(null)
  const [error, setError] = useState<string | null>(null)

  const {
    register,
    handleSubmit,
    setValue,
    watch,
    formState: { errors, isSubmitting },
  } = useForm<RequestForm>({
    resolver: zodResolver(requestSchema),
    defaultValues: {
      email: "",
      full_name: "",
      request_type: "",
      description: "",
      privacy_acknowledged: undefined as unknown as true,
    },
  })

  const requestType = watch("request_type")

  const onSubmit = async (data: RequestForm) => {
    setError(null)
    try {
      const response = await apiClient.post("/privacy/submit/", {
        email: data.email,
        full_name: data.full_name ?? "",
        request_type: data.request_type,
        description: data.description ?? "",
        privacy_acknowledged: true,
      })
      setReference(response.data?.data?.reference ?? null)
    } catch (err: unknown) {
      const body =
        err && typeof err === "object" && "response" in err
          ? (err as { response?: { data?: { message?: string; errors?: Record<string, string[]> } } })
              .response?.data
          : undefined
      const fieldErrors = body?.errors
        ? Object.values(body.errors).flat().join(" ")
        : ""
      setError(body?.message || fieldErrors || "We could not submit your request. Please try again.")
    }
  }

  return (
    <>
      <PageHero
        title="Privacy"
        highlight="Requests"
        description="Ask to access, correct, export or delete your personal data, or to close an account. Every request is tracked with a reference number."
      />

      <section className="py-16 bg-slate-50/50">
        <div className="mx-auto max-w-3xl px-4 sm:px-6 lg:px-8">
          <div className="rounded-xl border border-slate-200 bg-white p-6 sm:p-8 shadow-sm">
            {reference ? (
              <div role="status" aria-live="polite" className="text-center space-y-3">
                <h2 className="text-xl font-semibold text-slate-900">Request received</h2>
                <p className="text-slate-600">
                  Your reference is <strong className="font-mono text-slate-900">{reference}</strong>.
                  Keep it for follow-up. We verify the requester before acting and aim to respond
                  within 30 days.
                </p>
                <p className="text-sm text-slate-500">
                  A confirmation has been sent to the email address you provided.
                </p>
              </div>
            ) : (
              <form onSubmit={handleSubmit(onSubmit)} className="space-y-5" noValidate>
                <div>
                  <h2 className="text-xl font-semibold text-slate-900">Submit a request</h2>
                  <p className="mt-1 text-sm text-slate-600">
                    Requests about data a venue business holds about you should go to that
                    business first — we support them once instructed.
                  </p>
                </div>

                {error && (
                  <div role="alert" className="rounded-md bg-destructive/10 p-3 text-sm text-destructive">
                    {error}
                  </div>
                )}

                <div className="space-y-2">
                  <Label htmlFor="pr-email">
                    Email on the account <span aria-hidden="true">*</span>
                  </Label>
                  <Input
                    id="pr-email"
                    type="email"
                    autoComplete="email"
                    aria-required="true"
                    aria-invalid={errors.email ? true : undefined}
                    aria-describedby={errors.email ? "pr-email-error" : undefined}
                    {...register("email")}
                  />
                  {errors.email && (
                    <p id="pr-email-error" className="text-sm text-destructive">
                      {errors.email.message}
                    </p>
                  )}
                </div>

                <div className="space-y-2">
                  <Label htmlFor="pr-name">
                    Full name <span className="text-slate-500">(optional)</span>
                  </Label>
                  <Input
                    id="pr-name"
                    autoComplete="name"
                    aria-invalid={errors.full_name ? true : undefined}
                    aria-describedby={errors.full_name ? "pr-name-error" : undefined}
                    {...register("full_name")}
                  />
                  {errors.full_name && (
                    <p id="pr-name-error" className="text-sm text-destructive">
                      {errors.full_name.message}
                    </p>
                  )}
                </div>

                <div className="space-y-2">
                  <Label htmlFor="pr-type">
                    Request type <span aria-hidden="true">*</span>
                  </Label>
                  <Select
                    value={requestType}
                    onValueChange={(value) => setValue("request_type", value, { shouldValidate: true })}
                  >
                    <SelectTrigger
                      id="pr-type"
                      aria-required="true"
                      aria-invalid={errors.request_type ? true : undefined}
                      aria-describedby={errors.request_type ? "pr-type-error" : undefined}
                    >
                      <SelectValue placeholder="Choose a request type" />
                    </SelectTrigger>
                    <SelectContent>
                      {REQUEST_TYPES.map((type) => (
                        <SelectItem key={type.value} value={type.value}>
                          {type.label}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                  {errors.request_type && (
                    <p id="pr-type-error" className="text-sm text-destructive">
                      {errors.request_type.message}
                    </p>
                  )}
                </div>

                <div className="space-y-2">
                  <Label htmlFor="pr-description">
                    Details <span className="text-slate-500">(optional)</span>
                  </Label>
                  <Textarea
                    id="pr-description"
                    rows={4}
                    placeholder="Anything that helps us locate the right records"
                    aria-invalid={errors.description ? true : undefined}
                    aria-describedby={errors.description ? "pr-description-error" : undefined}
                    {...register("description")}
                  />
                  {errors.description && (
                    <p id="pr-description-error" className="text-sm text-destructive">
                      {errors.description.message}
                    </p>
                  )}
                </div>

                <div className="space-y-2">
                  <div className="flex items-start gap-3">
                    <input
                      id="pr-ack"
                      type="checkbox"
                      className="mt-1 h-4 w-4 rounded border-slate-300 text-amber-500 focus:ring-amber-500"
                      aria-invalid={errors.privacy_acknowledged ? true : undefined}
                      aria-describedby={errors.privacy_acknowledged ? "pr-ack-error" : undefined}
                      {...register("privacy_acknowledged")}
                    />
                    <label htmlFor="pr-ack" className="text-sm text-slate-600">
                      I confirm this request relates to my own personal data, or that I am
                      authorised to make it on behalf of the person it concerns. I have read the{" "}
                      <a href="/privacy-policy/" className="underline text-slate-900">
                        Privacy Policy
                      </a>
                      .
                    </label>
                  </div>
                  {errors.privacy_acknowledged && (
                    <p id="pr-ack-error" className="text-sm text-destructive">
                      {errors.privacy_acknowledged.message}
                    </p>
                  )}
                </div>

                <Button type="submit" className="w-full" disabled={isSubmitting}>
                  {isSubmitting ? (
                    <span className="flex items-center gap-2">
                      <span className="h-4 w-4 animate-spin rounded-full border-2 border-background border-t-transparent" />
                      Submitting…
                    </span>
                  ) : (
                    <span className="flex items-center gap-2">
                      <Send className="h-4 w-4" aria-hidden="true" focusable="false" />
                      Submit request
                    </span>
                  )}
                </Button>
              </form>
            )}
          </div>

          <div className="mt-8 rounded-xl border border-slate-200 bg-white p-6 text-sm text-slate-600 space-y-2">
            <h2 className="text-base font-semibold text-slate-900">What happens next</h2>
            <ol className="list-decimal space-y-1 pl-5">
              <li>We acknowledge receipt with a reference number.</li>
              <li>We verify that the requester is the right person (or an authorised agent).</li>
              <li>We review the request and any legal retention exceptions.</li>
              <li>We respond — normally within 30 days — and record the outcome.</li>
            </ol>
            <p>
              Prefer email? Write to{" "}
              <a href={`mailto:${business.privacyEmail}`} className="underline text-slate-900">
                {business.privacyEmail}
              </a>
              .
            </p>
          </div>
        </div>
      </section>
    </>
  )
}
