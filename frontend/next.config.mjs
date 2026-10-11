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
