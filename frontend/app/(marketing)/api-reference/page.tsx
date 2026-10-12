import { createMetadata } from "@/lib/seo"
import PageHero from "@/components/marketing/PageHero"
import PageCTA from "@/components/marketing/PageCTA"
import { XCircle } from "lucide-react"

export const metadata = createMetadata({
  title: "API Reference",
  description:
    "Reference for the EventFlow REST API: authentication, bookings and customers endpoints, with request and sample response examples.",
  path: "/api-reference",
})

const baseUrl = "https://api.eventflow.com/api/v1"

const endpoints = [
  {
    method: "POST",
    path: "/api/v1/auth/login/",
    description:
      "Sign in with your EventFlow account credentials and receive a JWT access token plus a refresh token.",
    request: `curl -X POST ${baseUrl}/auth/login/ \\
  -H "Content-Type: application/json" \\
  -d '{"email": "you@yourvenue.com", "password": "your-password"}'`,
    response: `{
  "success": true,
  "message": "Login successful",
  "data": {
    "access_token": "<access_token>",
    "refresh_token": "<refresh_token>",
    "user": { "id": 1, "email": "you@yourvenue.com", "role": "OWNER" }
  }
}`,
    errors: ["400 Validation error", "401 Invalid credentials", "429 Too many requests"],
  },
  {
    method: "GET",
    path: "/api/v1/bookings/",
    description:
      "List the bookings in your account, with optional filtering by status, venue or event type, plus search and pagination.",
    request: `curl ${baseUrl}/bookings/ \\
  -H "Authorization: Bearer <access_token>" \\
  -H "Content-Type: application/json"`,
    response: `{
  "success": true,
  "data": [
    {
      "id": 12,
      "booking_number": "BK-000012",
      "venue": 1,
      "venue_name": "Main Hall",
      "customer": 7,
      "customer_name": "A. Sharma",
      "event_type": "wedding",
      "event_date": "2026-08-20",
      "guest_count": 180,
      "total_amount": 450000,
      "advance_amount": 50000,
      "status": "CONFIRMED"
    }
  ],
  "pagination": { "page": 1, "page_size": 20, "total_records": 1, "total_pages": 1 }
}`,
    errors: ["400 Invalid filter parameter", "401 Unauthorized", "429 Too many requests"],
  },
  {
    method: "POST",
    path: "/api/v1/bookings/",
    description:
      "Create a booking. The venue and customer records must already exist in your account.",
    request: `curl -X POST ${baseUrl}/bookings/ \\
  -H "Authorization: Bearer <access_token>" \\
  -H "Content-Type: application/json" \\
  -d '{
  "venue": 1,
  "customer": 7,
  "event_type": "wedding",
  "event_date": "2026-09-10",
  "guest_count": 50,
  "total_amount": 120000,
  "advance_amount": 20000
}'`,
    response: `{
  "success": true,
  "message": "Booking created",
  "data": { "id": 13, "booking_number": "BK-000013", "status": "DRAFT", "event_date": "2026-09-10" }
}`,
    errors: ["400 Validation error", "401 Unauthorized", "403 Not permitted"],
  },
  {
    method: "GET",
    path: "/api/v1/bookings/:id/",
    description: "Retrieve a single booking by its id.",
    request: `curl ${baseUrl}/bookings/12/ \\
  -H "Authorization: Bearer <access_token>"`,
    response: `{
  "success": true,
  "data": { "id": 12, "booking_number": "BK-000012", "status": "CONFIRMED", "event_date": "2026-08-20" }
}`,
    errors: ["401 Unauthorized", "404 Not found"],
  },
  {
    method: "PUT",
    path: "/api/v1/bookings/:id/",
    description: "Update an existing booking.",
    request: `curl -X PUT ${baseUrl}/bookings/12/ \\
  -H "Authorization: Bearer <access_token>" \\
  -H "Content-Type: application/json" \\
  -d '{
  "guest_count": 200,
  "remarks": "Updated guest count"
}'`,
    response: `{
  "success": true,
  "data": { "id": 12, "booking_number": "BK-000012", "guest_count": 200 }
}`,
    errors: ["400 Validation error", "401 Unauthorized", "404 Not found"],
  },
  {
    method: "DELETE",
    path: "/api/v1/bookings/:id/",
    description: "Delete a booking. Cancellation and refund handling is done in the app, not by this endpoint.",
    request: `curl -X DELETE ${baseUrl}/bookings/12/ \\
  -H "Authorization: Bearer <access_token>"`,
    response: `{
  "success": true,
  "message": "Booking deleted"
}`,
    errors: ["401 Unauthorized", "404 Not found"],
  },
  {
    method: "GET",
    path: "/api/v1/customers/",
    description: "List customers with search and pagination support.",
    request: `curl "${baseUrl}/customers/?search=jane" \\
  -H "Authorization: Bearer <access_token>"`,
    response: `{
  "success": true,
  "data": [
    {
      "id": 7,
      "full_name": "Jane Smith",
      "email": "jane@example.com",
      "mobile": "+91 98765 43210",
      "created_at": "2026-01-15T08:00:00Z"
    }
  ],
  "pagination": { "page": 1, "page_size": 20, "total_records": 1, "total_pages": 1 }
}`,
    errors: ["400 Invalid search parameter", "401 Unauthorized", "429 Too many requests"],
  },
]

const methodColors: Record<string, string> = {
  GET: "bg-emerald-100 text-emerald-700",
  POST: "bg-blue-100 text-blue-700",
  PUT: "bg-amber-100 text-amber-700",
  DELETE: "bg-red-100 text-red-700",
}

export default function ApiReferencePage() {
  return (
    <>
      <PageHero
        title="API Reference"
        highlight=""
        description="The endpoints the EventFlow app itself uses. All requests must be authenticated and made over HTTPS."
      />

      <section className="py-16 bg-slate-50/50">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="mb-12">
            <h2 className="text-2xl font-bold text-slate-900 mb-4">Using the API</h2>
            <dl className="grid sm:grid-cols-3 gap-6">
              <div className="bg-white rounded-xl border border-slate-200 p-5">
                <dt className="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-1">
                  Base URL
                </dt>
                <dd className="text-sm font-mono text-slate-800 break-all">{baseUrl}/</dd>
              </div>
              <div className="bg-white rounded-xl border border-slate-200 p-5">
                <dt className="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-1">
                  Authentication
                </dt>
                <dd className="text-sm text-slate-700">
                  JWT. Post your credentials to <code className="text-xs">/api/v1/auth/login/</code>{" "}
                  and send <code className="text-xs">Authorization: Bearer &lt;access_token&gt;</code>{" "}
                  on every request.
                </dd>
              </div>
              <div className="bg-white rounded-xl border border-slate-200 p-5">
                <dt className="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-1">
                  Version
                </dt>
                <dd className="text-sm text-slate-700">v1</dd>
              </div>
            </dl>
            <p className="mt-4 text-sm text-slate-600">
              Payments are not taken through this API. Card and UPI payments are collected through
              the Razorpay checkout in the app, and recorded against bookings from there.
            </p>
          </div>

          <h2 className="text-2xl font-bold text-slate-900 mb-6">Endpoints</h2>

          <div className="space-y-8">
            {endpoints.map((ep) => (
              <div
                key={`${ep.method}-${ep.path}`}
                className="bg-white rounded-xl border border-slate-200 overflow-hidden"
              >
                {/* Endpoint header */}
                <div className="flex flex-wrap items-center gap-3 px-6 py-4 border-b border-slate-100 bg-slate-50">
                  <span
                    className={`inline-flex items-center px-2.5 py-0.5 rounded-md text-xs font-bold ${methodColors[ep.method]}`}
                  >
                    {ep.method}
                  </span>
                  <h3 className="text-sm font-mono text-slate-800">{ep.path}</h3>
                </div>

                <div className="p-6 space-y-6">
                  <p className="text-slate-600 text-sm">{ep.description}</p>

                  {/* Request */}
                  <div>
                    <p className="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-2">
                      Request
                    </p>
                    <pre className="bg-slate-900 text-slate-100 rounded-lg p-4 text-sm overflow-x-auto">
                      <code>{ep.request}</code>
                    </pre>
                  </div>

                  {/* Response */}
                  <div>
                    <p className="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-2">
                      Sample response (illustrative)
                    </p>
                    <pre className="bg-slate-900 text-slate-100 rounded-lg p-4 text-sm overflow-x-auto">
                      <code>{ep.response}</code>
                    </pre>
                    <p className="mt-2 text-xs text-slate-500">
                      Illustrative only — field names and shapes may differ from your account&apos;s
                      live responses.
                    </p>
                  </div>

                  {/* Error codes */}
                  <div>
                    <p className="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-2">
                      Error Codes
                    </p>
                    <div className="flex flex-wrap gap-2">
                      {ep.errors.map((err) => (
                        <span
                          key={err}
                          className="inline-flex items-center gap-1 px-2.5 py-1 bg-red-50 text-red-700 rounded-md text-xs font-medium"
                        >
                          <XCircle className="w-3 h-3" aria-hidden="true" focusable="false" />
                          {err}
                        </span>
                      ))}
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      <PageCTA
        title="API access is part of"
        highlight="an EventFlow account"
        description="Sign in and call the API with your own access token. If you have questions about access or usage, contact us and we will help."
        buttonText="Contact Us"
        buttonHref="/contact"
      />
    </>
  )
}
