import apiClient from "@/lib/api-client"

/**
 * Shared submission helpers for the public marketing forms.
 *
 * Every public form posts to `POST /api/v1/contact/`, which requires an
 * explicit privacy acknowledgement before it will store anything.
 */

type ContactFields = {
  source: "contact" | "demo" | "careers" | "status"
  name: string
  email: string
  message: string
  privacy_acknowledged: boolean
  marketing_opt_in?: boolean
  company?: string
  phone?: string
  subject?: string
}

function readError(err: unknown): string {
  const body =
    err && typeof err === "object" && "response" in err
      ? (err as { response?: { data?: { message?: string; errors?: Record<string, string[]> } } })
          .response?.data
      : undefined
  const fieldErrors = body?.errors ? Object.values(body.errors).flat().join(" ") : ""
  return (
    body?.message || fieldErrors || "We could not send this right now. Please try again."
  )
}

export async function submitContactJson(fields: ContactFields): Promise<string> {
  try {
    const response = await apiClient.post("/contact/", fields)
    return response.data?.data?.reference ?? ""
  } catch (err) {
    throw new Error(readError(err))
  }
}

export async function submitContactForm(formData: FormData): Promise<string> {
  try {
    const base = apiClient.defaults.baseURL
    const headers: Record<string, string> = {}
    const token = typeof window !== "undefined" ? localStorage.getItem("access_token") : null
    if (token) headers.Authorization = `Bearer ${token}`

    const response = await fetch(`${base}/contact/`, {
      method: "POST",
      headers,
      body: formData,
    })
    const payload = await response.json().catch(() => null)
    if (!response.ok) {
      const errors = payload?.errors as Record<string, string[]> | undefined
      throw new Error(
        payload?.message ||
          (errors ? Object.values(errors).flat().join(" ") : "") ||
          "We could not send this right now. Please try again."
      )
    }
    return payload?.data?.reference ?? ""
  } catch (err) {
    if (err instanceof Error) throw err
    throw new Error("We could not send this right now. Please try again.")
  }
}
