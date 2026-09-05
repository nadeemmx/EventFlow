from django.db import models
from core.base_models import TenantBaseModel
from core.choices import PaymentGateway
from core.fields import EncryptedTextField
from core.validators import validate_image_file, validate_pdf_file


class PaymentGatewaySettings(TenantBaseModel):
    gateway = models.CharField(max_length=50, choices=PaymentGateway.choices, db_index=True)
    api_key = EncryptedTextField()
    api_secret = EncryptedTextField()
    webhook_secret = EncryptedTextField(blank=True)
    is_active = models.BooleanField(default=False, db_index=True)
    environment = models.CharField(max_length=20, default="test", choices=[
        ("test", "Test"), ("live", "Live"),
    ], db_index=True)

    class Meta:
        db_table = "payment_gateway_settings"
        unique_together = ["tenant", "gateway"]
        verbose_name = "Payment Gateway Setting"
        verbose_name_plural = "Payment Gateway Settings"

    def __str__(self):
        return f"{self.gateway} - {self.tenant.business_name}"


class WhatsAppSettings(TenantBaseModel):
    provider = models.CharField(max_length=50, default="twilio", choices=[
        ("twilio", "Twilio"), ("gupshup", "Gupshup"),
        ("whatsapp_business", "WhatsApp Business API"),
    ], db_index=True)
    api_key = EncryptedTextField(blank=True)
    phone_number_id = EncryptedTextField(blank=True)
    business_account_id = EncryptedTextField(blank=True)
    webhook_verify_token = EncryptedTextField(blank=True)
    is_active = models.BooleanField(default=False, db_index=True)
    send_notifications = models.BooleanField(default=True)

    class Meta:
        db_table = "whatsapp_settings"
        verbose_name = "WhatsApp Setting"
        verbose_name_plural = "WhatsApp Settings"

    def __str__(self):
        return f"WhatsApp - {self.tenant.business_name}"


class EmailSettings(TenantBaseModel):
    smtp_host = models.CharField(max_length=255)
    smtp_port = models.IntegerField(default=587)
    smtp_username = models.CharField(max_length=255)
    smtp_password = EncryptedTextField()
    from_email = models.EmailField()
    from_name = models.CharField(max_length=255, blank=True)
    use_tls = models.BooleanField(default=True)
    use_ssl = models.BooleanField(default=False)
    is_active = models.BooleanField(default=False, db_index=True)

    class Meta:
        db_table = "email_settings"
        verbose_name = "Email Setting"
        verbose_name_plural = "Email Settings"

    def __str__(self):
        return f"Email - {self.tenant.business_name}"


class InvoiceSettings(TenantBaseModel):
    prefix = models.CharField(max_length=50, default="INV")
    next_number = models.IntegerField(default=1)
    logo = models.ImageField(upload_to="invoices/logos/", blank=True, validators=[validate_image_file])
    footer_text = models.TextField(blank=True)
    payment_terms = models.CharField(max_length=500, blank=True)
    gst_enabled = models.BooleanField(default=True)
    gst_rate = models.DecimalField(max_digits=5, decimal_places=2, default=18.00)
    show_gst = models.BooleanField(default=True)
    template = models.CharField(max_length=50, default="standard", choices=[
        ("standard", "Standard"), ("premium", "Premium"), ("minimal", "Minimal"),
    ])
    due_days = models.IntegerField(default=30)
    late_payment_penalty = models.DecimalField(max_digits=5, decimal_places=2, default=0.00)
    currency = models.CharField(max_length=10, default="INR")

    class Meta:
        db_table = "invoice_settings"
        verbose_name = "Invoice Setting"
        verbose_name_plural = "Invoice Settings"

    def __str__(self):
        return f"Invoice Settings - {self.tenant.business_name}"


class BookingSettings(TenantBaseModel):
    tentative_validity_hours = models.IntegerField(default=48)
    auto_confirm = models.BooleanField(default=False)
    buffer_days = models.IntegerField(default=0, help_text="Buffer days between bookings")
    max_advance_days = models.IntegerField(default=365)
    max_refund_days = models.IntegerField(default=7)
    allow_partial_payment = models.BooleanField(default=True)
    deposit_percentage = models.DecimalField(max_digits=5, decimal_places=2, default=25.00)
    cancellation_policy = models.TextField(blank=True)
    require_full_payment_days = models.IntegerField(default=7, help_text="Days before event to require full payment")

    class Meta:
        db_table = "booking_settings"
        verbose_name = "Booking Setting"
        verbose_name_plural = "Booking Settings"

    def __str__(self):
        return f"Booking Settings - {self.tenant.business_name}"


class NotificationSettings(TenantBaseModel):
    notify_on_booking = models.BooleanField(default=True)
    notify_on_payment = models.BooleanField(default=True)
    notify_on_cancellation = models.BooleanField(default=True)
    notify_on_checkin = models.BooleanField(default=False)
    notify_on_lead = models.BooleanField(default=True)
    email_enabled = models.BooleanField(default=True)
    whatsapp_enabled = models.BooleanField(default=False)
    sms_enabled = models.BooleanField(default=False)
    notify_admin_only = models.BooleanField(default=False)
    daily_digest = models.BooleanField(default=False)
    reminder_hours = models.IntegerField(default=24, help_text="Hours before event to send reminder")

    class Meta:
        db_table = "notification_settings"
        verbose_name = "Notification Setting"
        verbose_name_plural = "Notification Settings"

    def __str__(self):
        return f"Notification Settings - {self.tenant.business_name}"


class SecuritySettings(TenantBaseModel):
    two_factor_enabled = models.BooleanField(default=False)
    session_timeout_minutes = models.IntegerField(default=120)
    password_min_length = models.IntegerField(default=8)
    require_special_char = models.BooleanField(default=True)
    require_number = models.BooleanField(default=True)
    require_uppercase = models.BooleanField(default=True)
    max_login_attempts = models.IntegerField(default=5)
    ip_whitelist_enabled = models.BooleanField(default=False)
    allowed_ips = models.TextField(blank=True, help_text="One IP per line")
    allowed_domains = models.TextField(blank=True, help_text="One domain per line")

    class Meta:
        db_table = "security_settings"
        verbose_name = "Security Setting"
        verbose_name_plural = "Security Settings"

    def __str__(self):
        return f"Security Settings - {self.tenant.business_name}"


class BrandingSettings(TenantBaseModel):
    primary_color = models.CharField(max_length=7, default="#0F172A")
    secondary_color = models.CharField(max_length=7, default="#F59E0B")
    accent_color = models.CharField(max_length=7, default="#10B981")
    logo = models.ImageField(upload_to="branding/logos/", blank=True, validators=[validate_image_file])
    favicon = models.ImageField(upload_to="branding/favicons/", blank=True, validators=[validate_image_file])
    custom_domain = models.CharField(max_length=255, blank=True)
    custom_css = models.TextField(blank=True)
    custom_js = models.TextField(blank=True)

    class Meta:
        db_table = "branding_settings"
        verbose_name = "Branding Setting"
        verbose_name_plural = "Branding Settings"

    def __str__(self):
        return f"Branding Settings - {self.tenant.business_name}"
