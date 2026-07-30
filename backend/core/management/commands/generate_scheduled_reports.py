import logging
from django.core.management.base import BaseCommand
from django.utils import timezone
from django.conf import settings
from django.core.mail import send_mail
from core.choices import UserRole
from services.report_service import ReportService

logger = logging.getLogger(__name__)


class Command(BaseCommand):
    help = "Generate and email scheduled reports"

    def add_arguments(self, parser):
        parser.add_argument(
            "--frequency",
            type=str,
            choices=["daily", "weekly", "monthly"],
            default="daily",
            help="Report frequency",
        )

    def handle(self, *args, **options):
        from apps.tenants.models import Tenant

        frequency = options["frequency"]
        today = timezone.now().date()

        for tenant in Tenant.objects.filter(status="ACTIVE"):
            try:
                service = ReportService(tenant=tenant)

                report_data = None
                report_name = ""
                if frequency == "daily":
                    report_name = "Daily Summary"
                    report_data = service.revenue_report(
                        start_date=today - timezone.timedelta(days=1),
                        end_date=today,
                    )
                elif frequency == "weekly":
                    report_name = "Weekly Summary"
                    report_data = service.revenue_report(
                        start_date=today - timezone.timedelta(days=7),
                        end_date=today,
                    )
                elif frequency == "monthly":
                    report_name = "Monthly Summary"
                    report_data = service.revenue_report(
                        start_date=today.replace(day=1),
                        end_date=today,
                    )

                if report_data:
                    admins = tenant.user_set.filter(
                        role__in=[UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.MANAGER],
                        is_active=True,
                    )
                    for admin in admins:
                        send_mail(
                            subject=f"{report_name} - {tenant.business_name}",
                            message=f"Please find the {report_name} attached.",
                            from_email=settings.DEFAULT_FROM_EMAIL,
                            recipient_list=[admin.email],
                            fail_silently=True,
                        )

                self.stdout.write(
                    self.style.SUCCESS(f"Sent {frequency} report for {tenant.business_name}")
                )
            except Exception as e:
                logger.error("Report generation failed for %s: %s", tenant.business_name, e)

        self.stdout.write(self.style.SUCCESS(f"{frequency.capitalize()} reports done"))
