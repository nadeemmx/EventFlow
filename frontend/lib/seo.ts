import type { Metadata } from "next"

export function createMetadata(overrides: {
  title: string
  description: string
  path: string
}): Metadata {
  const baseUrl = "https://eventflow.com"
  return {
    title: `${overrides.title} | EventFlow`,
    description: overrides.description,
    openGraph: {
      title: `${overrides.title} | EventFlow`,
      description: overrides.description,
      url: `${baseUrl}${overrides.path}`,
      siteName: "EventFlow",
      type: "website",
    },
    twitter: {
      card: "summary_large_image",
      title: `${overrides.title} | EventFlow`,
      description: overrides.description,
    },
  }
}
