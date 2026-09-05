from django.core.management.base import BaseCommand
from django.contrib.auth import authenticate, get_backends
from django.conf import settings
from apps.users.models import User


class Command(BaseCommand):
    help = "Diagnose authentication issues"

    def add_arguments(self, parser):
        parser.add_argument("email", type=str)
        parser.add_argument("password", type=str)

    def handle(self, *args, **options):
        email = options["email"]
        password = options["password"]

        self.stdout.write(self.style.WARNING("=== AUTH DIAGNOSTIC ===\n"))

        # 1. Check AUTHENTICATION_BACKENDS
        self.stdout.write("--- AUTHENTICATION_BACKENDS setting ---")
        backends = getattr(settings, "AUTHENTICATION_BACKENDS", None)
        if backends:
            for b in backends:
                self.stdout.write(f"  Configured: {b}")
        else:
            self.stdout.write(self.style.ERROR("  NOT SET — Django uses default ModelBackend (expects 'username')"))

        # 2. List actually loaded backends
        self.stdout.write("\n--- Loaded backends from get_backends() ---")
        for b in get_backends():
            self.stdout.write(f"  {b.__class__.__module__}.{b.__class__.__name__}")

        # 3. Check if user exists
        self.stdout.write(f"\n--- User lookup: email={email!r} ---")
        try:
            user = User.objects.get(email=email)
            self.stdout.write(self.style.SUCCESS(f"  Found: id={user.id}, email={user.email!r}, is_active={user.is_active}, role={user.role}"))
        except User.DoesNotExist:
            self.stdout.write(self.style.ERROR(f"  No user with email={email!r}"))
            return

        # 4. Check password field
        self.stdout.write(f"\n--- Password hash check ---")
        raw_hash = user.password
        self.stdout.write(f"  Stored hash (first 30 chars): {raw_hash[:30]}")
        if not raw_hash.startswith(("pbkdf2_", "argon2", "bcrypt", "scrypt")):
            self.stdout.write(self.style.ERROR(f"  WARNING: password does NOT start with a known hasher prefix!"))
            self.stdout.write(self.style.ERROR(f"  This means the password was NOT hashed by Django's set_password()."))

        # 5. Direct check_password
        self.stdout.write(f"\n--- check_password() ---")
        result = user.check_password(password)
        self.stdout.write(f"  Result: {result}")

        # 6. Full authenticate() call
        self.stdout.write(f"\n--- authenticate(email='{email}') ---")
        auth_result = authenticate(email=email, password=password)
        if auth_result:
            self.stdout.write(self.style.SUCCESS(f"  SUCCESS: authenticated as {auth_result.email}"))
        else:
            self.stdout.write(self.style.ERROR("  FAILED: authenticate() returned None"))

        # 7. Try each backend manually
        self.stdout.write("\n--- Manual backend iteration ---")
        for backend in get_backends():
            try:
                manual = backend.authenticate(request=None, email=email, password=password)
                self.stdout.write(f"  {backend.__class__.__name__}.authenticate() => {manual}")
            except Exception as e:
                self.stdout.write(self.style.ERROR(f"  {backend.__class__.__name__}.authenticate() EXCEPTION: {e}"))

        self.stdout.write("\n=== END DIAGNOSTIC ===")
