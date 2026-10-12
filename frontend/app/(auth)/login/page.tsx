"use client"

import { useState } from "react"
import { useRouter } from "next/navigation"
import Link from "next/link"
import { useForm } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import { z } from "zod"
import { Eye, EyeOff, LogIn } from "lucide-react"

import { useAuth } from "@/stores/auth-context"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"

const loginSchema = z.object({
  email: z.string().email("Please enter a valid email address"),
  password: z.string().min(1, "Password is required"),
})

type LoginForm = z.infer<typeof loginSchema>

export default function LoginPage() {
  const router = useRouter()
  const { login } = useAuth()
  const [showPassword, setShowPassword] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<LoginForm>({
    resolver: zodResolver(loginSchema),
  })

  const onSubmit = async (data: LoginForm) => {
    setError(null)
    try {
      await login(data.email, data.password)
      router.push("/dashboard")
    } catch (err: unknown) {
      const message =
        err && typeof err === "object" && "response" in err
          ? (err as { response: { data: { message: string } } }).response?.data?.message
          : "Invalid email or password"
      setError(message || "Invalid email or password")
    }
  }

  return (
    <Card className="premium-card shadow-lg">
      <CardHeader className="space-y-1 text-center pb-2">
        <div className="flex justify-center mb-4">
          <div className="flex items-center justify-center w-12 h-12 rounded-xl bg-amber-500 text-slate-900 font-bold text-lg">
            EF
          </div>
        </div>
        <CardTitle className="text-2xl font-bold tracking-tight ">Welcome back</CardTitle>
        <CardDescription className="text-slate-700">Sign in to your EventFlow account</CardDescription>
      </CardHeader>
      <CardContent>
        <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
          {error && (
            <div
              role="alert"
              className="rounded-md bg-destructive/10 p-3 text-sm text-destructive text-center"
            >
              {error}
            </div>
          )}

          <div className="space-y-2">
            <Label htmlFor="email">Email</Label>
            <Input
              id="email"
              type="email"
              placeholder="you@example.com"
              autoComplete="email"
              aria-invalid={errors.email ? true : undefined}
              aria-describedby={errors.email ? "email-error" : undefined}
              {...register("email")}
            />
            {errors.email && (
              <p id="email-error" role="alert" className="text-sm text-destructive">
                {errors.email.message}
              </p>
            )}
          </div>

          <div className="space-y-2">
            <div className="flex items-center justify-between">
              <Label htmlFor="password">Password</Label>
              <Link
                href="/forgot-password"
                className="text-xs text-amber-600 hover:text-amber-700"
              >
                Forgot password?
              </Link>
            </div>
            <div className="relative">
              <Input
                id="password"
                type={showPassword ? "text" : "password"}
                placeholder="Enter your password"
                autoComplete="current-password"
                aria-invalid={errors.password ? true : undefined}
                aria-describedby={errors.password ? "password-error" : undefined}
                {...register("password")}
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                aria-label={showPassword ? "Hide password" : "Show password"}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground cursor-pointer"
              >
                {showPassword ? (
                  <EyeOff aria-hidden="true" focusable="false" className="h-4 w-4" />
                ) : (
                  <Eye aria-hidden="true" focusable="false" className="h-4 w-4" />
                )}
              </button>
            </div>
            {errors.password && (
              <p id="password-error" role="alert" className="text-sm text-destructive">
                {errors.password.message}
              </p>
            )}
          </div>

          <Button type="submit" className="w-full cursor-pointer" disabled={isSubmitting}>
            {isSubmitting ? (
              <span className="flex items-center gap-2">
                <span className="h-4 w-4 animate-spin rounded-full border-2 border-background border-t-transparent" />
                Signing in...
              </span>
            ) : (
              <span className="flex items-center gap-2">
                <LogIn aria-hidden="true" focusable="false" className="h-4 w-4" />
                Sign In
              </span>
            )}
          </Button>
        </form>
      </CardContent>
    </Card>
  )
}
