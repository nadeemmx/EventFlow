export default function AuthLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="flex min-h-screen items-center justify-center p-4 bg-slate-200">
      <main id="main-content" tabIndex={-1} className="w-full max-w-md">{children}</main>
    </div>
  );
}
