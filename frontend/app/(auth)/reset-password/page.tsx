"use client"

import { Suspense, useState, useCallback } from "react"
import { useSearchParams } from "next/navigation"
import Link from "next/link"
import { useForm } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import { z } from "zod"
import { Eye, EyeOff, KeyRound, CheckCircle2, ArrowLeft } from "lucide-react"

import apiClient from "@/lib/api-client"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"

const resetSchema = z
  .object({
    password: z
      .string()
      .min(8, "Password must be at least 8 characters")
      .regex(/[A-Z]/, "Password must contain at least one uppercase letter")
      .regex(/[a-z]/, "Password must contain at least one lowercase letter")
      .regex(/[0-9]/, "Password must contain at least one number"),
    confirm_password: z.string().min(1, "Please confirm your password"),
  })
  .refine((data) => data.password === data.confirm_password, {
    message: "Passwords do not match",
    path: ["confirm_password"],
  })

type ResetForm = z.infer<typeof resetSchema>

export default function ResetPasswordPage() {
  return (
    <Suspense fallback={
      <Card>
        <CardContent className="pt-6 text-center">
          <p className="text-sm text-muted-foreground">Loading...</p>
        </CardContent>
      </Card>
    }>
      <ResetPasswordForm />
    </Suspense>
  )
}

function ResetPasswordForm() {
  const searchParams = useSearchParams()
  const token = searchParams.get("token")
  const [success, setSuccess] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [showPassword, setShowPassword] = useState(false)
  const [showConfirm, setShowConfirm] = useState(false)

  const {
    register,
    handleSubmit,
    watch,
    formState: { errors, isSubmitting },
  } = useForm<ResetForm>({
    resolver: zodResolver(resetSchema),
  })

  const password = watch("password", "")

  const getStrength = useCallback((val: string): { label: string; color: string; width: string } => {
    const hasUpper = /[A-Z]/.test(val)
    const hasLower = /[a-z]/.test(val)
    const hasNumber = /[0-9]/.test(val)
    const hasLength = val.length >= 8
    const score = [hasUpper, hasLower, hasNumber, hasLength].filter(Boolean).length

    if (val.length === 0) return { label: "", color: "", width: "0%" }
    if (score <= 1) return { label: "Weak", color: "bg-destructive", width: "25%" }
    if (score <= 2) return { label: "Fair", color: "bg-warning", width: "50%" }
    if (score <= 3) return { label: "Good", color: "bg-primary", width: "75%" }
    return { label: "Strong", color: "bg-success", width: "100%" }
  }, [])

  const strength = getStrength(password)

  const onSubmit = async (data: ResetForm) => {
    if (!token) {
      setError("Invalid or missing reset token")
      return
    }
    setError(null)
    try {
      await apiClient.post("/auth/reset-password/", {
        token,
        password: data.password,
        confirm_password: data.confirm_password,
      })
      setSuccess(true)
    } catch (err: unknown) {
      const message =
        err && typeof err === "object" && "response" in err
          ? (err as { response: { data: { message: string } } }).response?.data?.message
          : "Failed to reset password. The link may have expired."
      setError(message)
    }
  }

  if (success) {
    return (
      <Card className="border-border/50 shadow-lg">
        <CardContent className="pt-6 text-center space-y-4">
          <div className="flex justify-center">
            <div className="flex items-center justify-center w-12 h-12 rounded-full bg-success/10">
              <CheckCircle2 className="h-6 w-6 text-success" />
            </div>
          </div>
          <div className="space-y-1">
            <h2 className="text-xl font-semibold tracking-tight">Password Reset</h2>
            <p className="text-sm text-muted-foreground">
              Your password has been successfully reset.
            </p>
          </div>
          <Link
            href="/login"
            className="inline-flex items-center gap-2 text-sm text-primary hover:underline"
          >
            <ArrowLeft className="h-4 w-4" />
            Go to login
          </Link>
        </CardContent>
      </Card>
    )
  }

  if (!token) {
    return (
      <Card className="border-border/50 shadow-lg">
        <CardContent className="pt-6 text-center space-y-4">
          <div className="space-y-1">
            <h2 className="text-xl font-semibold tracking-tight">Invalid Link</h2>
            <p className="text-sm text-muted-foreground">
              This reset link is invalid or has expired.
            </p>
          </div>
          <Link
            href="/forgot-password"
            className="inline-flex items-center gap-2 text-sm text-primary hover:underline"
          >
            Request a new reset link
          </Link>
        </CardContent>
      </Card>
    )
  }

  return (
    <Card className="border-border/50 shadow-lg">
      <CardHeader className="space-y-1 text-center pb-2">
        <div className="flex justify-center mb-4">
          <div className="flex items-center justify-center w-12 h-12 rounded-xl bg-primary text-primary-foreground font-bold text-lg">
            EF
          </div>
        </div>
        <CardTitle className="text-2xl font-bold tracking-tight">Set New Password</CardTitle>
        <CardDescription>Enter your new password below</CardDescription>
      </CardHeader>
      <CardContent>
        <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
          {error && (
            <div className="rounded-md bg-destructive/10 p-3 text-sm text-destructive text-center">
              {error}
            </div>
          )}

          <div className="space-y-2">
            <Label htmlFor="password">New Password</Label>
            <div className="relative">
              <Input
                id="password"
                type={showPassword ? "text" : "password"}
                placeholder="Enter new password"
                autoComplete="new-password"
                {...register("password")}
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground cursor-pointer"
                tabIndex={-1}
              >
                {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
              </button>
            </div>
            {errors.password && (
              <p className="text-sm text-destructive">{errors.password.message}</p>
            )}
            {password.length > 0 && (
              <div className="space-y-1">
                <div className="h-1.5 w-full rounded-full bg-muted overflow-hidden">
                  <div
                    className={`h-full rounded-full transition-all ${strength.color}`}
                    style={{ width: strength.width }}
                  />
                </div>
                <p className="text-xs text-muted-foreground">{strength.label}</p>
              </div>
            )}
          </div>

          <div className="space-y-2">
            <Label htmlFor="confirm_password">Confirm Password</Label>
            <div className="relative">
              <Input
                id="confirm_password"
                type={showConfirm ? "text" : "password"}
                placeholder="Confirm new password"
                autoComplete="new-password"
                {...register("confirm_password")}
              />
              <button
                type="button"
                onClick={() => setShowConfirm(!showConfirm)}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground cursor-pointer"
                tabIndex={-1}
              >
                {showConfirm ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
              </button>
            </div>
            {errors.confirm_password && (
              <p className="text-sm text-destructive">{errors.confirm_password.message}</p>
            )}
          </div>

          <Button type="submit" className="w-full cursor-pointer" disabled={isSubmitting}>
            {isSubmitting ? (
              <span className="flex items-center gap-2">
                <span className="h-4 w-4 animate-spin rounded-full border-2 border-background border-t-transparent" />
                Resetting...
              </span>
            ) : (
              <span className="flex items-center gap-2">
                <KeyRound className="h-4 w-4" />
                Reset Password
              </span>
            )}
          </Button>

          <div className="text-center">
            <Link
              href="/login"
              className="inline-flex items-center gap-2 text-sm text-muted-foreground hover:text-foreground"
            >
              <ArrowLeft className="h-4 w-4" />
              Back to login
            </Link>
          </div>
        </form>
      </CardContent>
    </Card>
  )
}
