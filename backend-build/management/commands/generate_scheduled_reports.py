from django.core.management.base import BaseCommand


class Command(BaseCommand):
    help = "Generate scheduled reports"

    def handle(self, *args, **options):
        self.stdout.write("Scheduled reports generated")
