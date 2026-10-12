/**
 * NEXT_PUBLIC_* variables are inlined at build time, so a production build
 * without NEXT_PUBLIC_API_URL would silently ship `http://localhost:8000`
 * to every browser. Fail the build instead.
 *
 * - Required for every production build (`next build` sets NODE_ENV=production).
 * - Must be an absolute http(s) URL.
 * - Must not point at localhost/127.0.0.1 unless NEXT_PUBLIC_ALLOW_LOCALHOST=true
 *   (escape hatch for local production previews only).
 */
function validateApiUrl() {
  if (process.env.NEXT_PUBLIC_ALLOW_LOCALHOST === "true") return;

  const raw = process.env.NEXT_PUBLIC_API_URL;
  if (!raw) {
    throw new Error(
      "NEXT_PUBLIC_API_URL is not set. Production builds need it (e.g. " +
        "https://api.example.com/api/v1). Provide frontend/.env.production " +
        "or export NEXT_PUBLIC_API_URL before `npm run build`. " +
        "For a local production preview only, set NEXT_PUBLIC_ALLOW_LOCALHOST=true."
    );
  }

  let parsed;
  try {
    parsed = new URL(raw);
  } catch {
    throw new Error(
      `NEXT_PUBLIC_API_URL must be an absolute URL, got: ${raw}`
    );
  }

  if (parsed.protocol !== "https:" && parsed.protocol !== "http:") {
    throw new Error(
      `NEXT_PUBLIC_API_URL must use http(s), got: ${parsed.protocol}`
    );
  }

  const host = parsed.hostname;
  if (host === "localhost" || host === "127.0.0.1" || host === "::1") {
    throw new Error(
      `NEXT_PUBLIC_API_URL points at ${host}, which is not reachable from a ` +
        "browser in production. Set the real API origin, or " +
        "NEXT_PUBLIC_ALLOW_LOCALHOST=true for a local preview only."
    );
  }
}

validateApiUrl();

/** @type {import('next').NextConfig} */
const nextConfig = {
  images: {
    // Image Optimizer is deliberately disabled: the app has zero next/image
    // usage, so there is nothing to optimize and no remotePatterns attack
    // surface (GHSA-9g9p-9gw9-jx7f and related Image Optimizer advisories).
    unoptimized: true,
  },
  typescript: {
    ignoreBuildErrors: true,
  },
};

export default nextConfig;
