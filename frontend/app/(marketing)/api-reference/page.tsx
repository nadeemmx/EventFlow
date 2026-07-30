import { createMetadata } from "@/lib/seo"
import PageHero from "@/components/marketing/PageHero"
import PageCTA from "@/components/marketing/PageCTA"
import { CheckCircle, XCircle, AlertTriangle, Copy } from "lucide-react"

export const metadata = createMetadata({
  title: "API Reference",
  description: "Complete API reference for EventFlow. Explore endpoints for bookings, customers, payments, and more with request and response examples.",
  path: "/api-reference",
})

const endpoints = [
  {
    method: "GET",
    path: "/bookings",
    description: "Retrieve a list of all bookings with optional filtering by date, venue, or status.",
    request: `curl https://api.eventflow.com/v1/bookings \\
  -H "Authorization: Bearer $EVENTFLOW_API_KEY" \\
  -H "Content-Type: application/json"`,
    response: `{
  "data": [
    {
      "id": "b_xyz789",
      "venue_id": "v_abc123",
      "event_name": "Summer Wedding",
      "date": "2026-08-20",
      "status": "confirmed",
      "guest_count": 180,
      "customer": {
        "name": "Emily Davis",
        "email": "emily@example.com"
      },
      "total": 12500.00,
      "currency": "usd",
      "created_at": "2026-06-01T14:30:00Z"
    }
  ],
  "meta": {
    "total": 42,
    "page": 1,
    "per_page": 25
  }
}`,
    errors: ["400 Invalid filter parameter", "401 Unauthorized", "403 Forbidden"],
  },
  {
    method: "POST",
    path: "/bookings",
    description: "Create a new booking for a venue. Requires venue availability and valid customer details.",
    request: `curl -X POST https://api.eventflow.com/v1/bookings \\
  -H "Authorization: Bearer $EVENTFLOW_API_KEY" \\
  -H "Content-Type: application/json" \\
  -d '{
  "venue_id": "v_abc123",
  "event_name": "Corporate Retreat",
  "date": "2026-09-10",
  "start_time": "09:00",
  "end_time": "17:00",
  "guest_count": 50,
  "customer": {
    "name": "Michael Brown",
    "email": "michael@acme.com",
    "phone": "+1-555-987-6543"
  }
}'`,
    response: `{
  "id": "b_xyz790",
  "venue_id": "v_abc123",
  "event_name": "Corporate Retreat",
  "date": "2026-09-10",
  "status": "pending_confirmation",
  "guest_count": 50,
  "total": 4500.00,
  "currency": "usd",
  "created_at": "2026-06-15T10:00:00Z"
}`,
    errors: ["400 Validation error", "409 Venue unavailable", "422 Unprocessable entity"],
  },
  {
    method: "GET",
    path: "/bookings/:id",
    description: "Retrieve details for a specific booking by its unique identifier.",
    request: `curl https://api.eventflow.com/v1/bookings/b_xyz789 \\
  -H "Authorization: Bearer $EVENTFLOW_API_KEY"`,
    response: `{
  "id": "b_xyz789",
  "venue_id": "v_abc123",
  "event_name": "Summer Wedding",
  "date": "2026-08-20",
  "status": "confirmed",
  "guest_count": 180,
  "special_requests": "Vegetarian meals for 30 guests",
  "customer": {
    "name": "Emily Davis",
    "email": "emily@example.com",
    "phone": "+1-555-456-7890"
  },
  "total": 12500.00,
  "currency": "usd",
  "created_at": "2026-06-01T14:30:00Z",
  "updated_at": "2026-06-10T09:15:00Z"
}`,
    errors: ["401 Unauthorized", "404 Booking not found"],
  },
  {
    method: "PUT",
    path: "/bookings/:id",
    description: "Update an existing booking. Partial updates are supported.",
    request: `curl -X PUT https://api.eventflow.com/v1/bookings/b_xyz789 \\
  -H "Authorization: Bearer $EVENTFLOW_API_KEY" \\
  -H "Content-Type: application/json" \\
  -d '{
  "guest_count": 200,
  "special_requests": "Updated vegetarian meals count to 40"
}'`,
    response: `{
  "id": "b_xyz789",
  "venue_id": "v_abc123",
  "event_name": "Summer Wedding",
  "date": "2026-08-20",
  "status": "confirmed",
  "guest_count": 200,
  "special_requests": "Updated vegetarian meals count to 40",
  "updated_at": "2026-06-18T11:45:00Z"
}`,
    errors: ["400 Validation error", "404 Booking not found", "409 Conflict"],
  },
  {
    method: "DELETE",
    path: "/bookings/:id",
    description: "Cancel and delete a booking. May be subject to cancellation policies.",
    request: `curl -X DELETE https://api.eventflow.com/v1/bookings/b_xyz789 \\
  -H "Authorization: Bearer $EVENTFLOW_API_KEY"`,
    response: `{
  "id": "b_xyz789",
  "status": "cancelled",
  "cancelled_at": "2026-06-20T16:00:00Z",
  "refund": {
    "amount": 12500.00,
    "currency": "usd",
    "status": "pending"
  }
}`,
    errors: ["401 Unauthorized", "404 Booking not found", "409 Cannot cancel past event"],
  },
  {
    method: "GET",
    path: "/customers",
    description: "List all customers with search and pagination support.",
    request: `curl https://api.eventflow.com/v1/customers?search=jane&page=1 \\
  -H "Authorization: Bearer $EVENTFLOW_API_KEY"`,
    response: `{
  "data": [
    {
      "id": "c_456def",
      "name": "Jane Smith",
      "email": "jane@example.com",
      "phone": "+1-555-123-4567",
      "total_bookings": 3,
      "total_spent": 28500.00,
      "created_at": "2026-01-15T08:00:00Z"
    }
  ],
  "meta": {
    "total": 1,
    "page": 1,
    "per_page": 25
  }
}`,
    errors: ["400 Invalid search parameter", "401 Unauthorized"],
  },
  {
    method: "POST",
    path: "/payments",
    description: "Process a payment for a booking. Supports major credit cards and digital wallets.",
    request: `curl -X POST https://api.eventflow.com/v1/payments \\
  -H "Authorization: Bearer $EVENTFLOW_API_KEY" \\
  -H "Content-Type: application/json" \\
  -d '{
  "booking_id": "b_xyz790",
  "amount": 4500.00,
  "currency": "usd",
  "payment_method": "card",
  "card": {
    "number": "4242424242424242",
    "exp_month": 12,
    "exp_year": 2028,
    "cvc": "123"
  }
}'`,
    response: `{
  "id": "p_321fed",
  "booking_id": "b_xyz790",
  "amount": 4500.00,
  "currency": "usd",
  "status": "succeeded",
  "payment_method": "card",
  "card_brand": "visa",
  "last4": "4242",
  "receipt_url": "https://dashboard.eventflow.com/receipts/p_321fed",
  "created_at": "2026-06-15T10:05:00Z"
}`,
    errors: ["400 Validation error", "402 Payment failed", "404 Booking not found"],
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
        description="Explore every endpoint in the EventFlow API. All requests must be authenticated and made over HTTPS."
      />

      <section className="py-16 bg-slate-50/50">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="grid lg:grid-cols-4 gap-6 mb-12">
            <div className="bg-white rounded-xl border border-slate-200 p-5 text-center">
              <div className="text-3xl font-bold text-slate-900">7</div>
              <div className="text-sm text-slate-500">Endpoints</div>
            </div>
            <div className="bg-white rounded-xl border border-slate-200 p-5 text-center">
              <div className="text-3xl font-bold text-emerald-600">99.9%</div>
              <div className="text-sm text-slate-500">Uptime SLA</div>
            </div>
            <div className="bg-white rounded-xl border border-slate-200 p-5 text-center">
              <div className="text-3xl font-bold text-slate-900">&lt;50ms</div>
              <div className="text-sm text-slate-500">Avg Response</div>
            </div>
            <div className="bg-white rounded-xl border border-slate-200 p-5 text-center">
              <div className="text-3xl font-bold text-amber-600">v1</div>
              <div className="text-sm text-slate-500">API Version</div>
            </div>
          </div>

          <div className="space-y-8">
            {endpoints.map((ep) => (
              <div key={`${ep.method}-${ep.path}`} className="bg-white rounded-xl border border-slate-200 overflow-hidden">
                {/* Endpoint header */}
                <div className="flex items-center gap-3 px-6 py-4 border-b border-slate-100 bg-slate-50">
                  <span className={`inline-flex items-center px-2.5 py-0.5 rounded-md text-xs font-bold ${methodColors[ep.method]}`}>
                    {ep.method}
                  </span>
                  <code className="text-sm font-mono text-slate-800">{ep.path}</code>
                </div>

                <div className="p-6 space-y-6">
                  <p className="text-slate-600 text-sm">{ep.description}</p>

                  {/* Request */}
                  <div>
                    <h4 className="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-2">Request</h4>
                    <pre className="bg-slate-900 text-slate-100 rounded-lg p-4 text-sm overflow-x-auto">
                      <code>{ep.request}</code>
                    </pre>
                  </div>

                  {/* Response */}
                  <div>
                    <h4 className="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-2">Response</h4>
                    <pre className="bg-slate-900 text-slate-100 rounded-lg p-4 text-sm overflow-x-auto">
                      <code>{ep.response}</code>
                    </pre>
                  </div>

                  {/* Error codes */}
                  <div>
                    <h4 className="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-2">Error Codes</h4>
                    <div className="flex flex-wrap gap-2">
                      {ep.errors.map((err) => (
                        <span key={err} className="inline-flex items-center gap-1 px-2.5 py-1 bg-red-50 text-red-700 rounded-md text-xs font-medium">
                          <XCircle className="w-3 h-3" />
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
        title="Start building with"
        highlight="EventFlow."
        description="Get your API keys, explore our SDKs, and join thousands of venues transforming their operations."
        buttonText="Get API Keys"
        buttonHref="/login"
      />
    </>
  )
}
