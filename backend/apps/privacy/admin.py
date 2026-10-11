from django.contrib import admin

from apps.privacy.models import ContactMessage, PrivacyRequest


@admin.register(PrivacyRequest)
class PrivacyRequestAdmin(admin.ModelAdmin):
    list_display = ("id", "request_type", "email", "status", "tenant", "created_at", "responded_at")
    list_filter = ("request_type", "status")
    search_fields = ("email", "full_name", "description")
    readonly_fields = ("created_at", "updated_at", "ip_address", "tenant", "user")


@admin.register(ContactMessage)
class ContactMessageAdmin(admin.ModelAdmin):
    list_display = ("id", "source", "name", "email", "company", "is_handled", "created_at")
    list_filter = ("source", "is_handled", "marketing_opt_in")
    search_fields = ("name", "email", "company", "subject", "message")
    readonly_fields = ("created_at", "updated_at", "ip_address")
