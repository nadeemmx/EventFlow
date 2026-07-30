from rest_framework import serializers
from apps.leads.models import Lead, FollowUp, Quotation, QuotationItem


class LeadSerializer(serializers.ModelSerializer):
    customer_name = serializers.SerializerMethodField()

    class Meta:
        model = Lead
        fields = [
            "id", "customer", "customer_name", "lead_source", "event_type",
            "expected_event_date", "expected_guest_count",
            "lead_status", "assigned_to", "created_at", "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at"]

    def get_customer_name(self, obj):
        return obj.customer.full_name if obj.customer else None


class FollowUpSerializer(serializers.ModelSerializer):
    class Meta:
        model = FollowUp
        fields = ["id", "lead", "followup_date", "notes", "next_action", "created_at"]
        read_only_fields = ["id", "lead", "created_at"]


class QuotationItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = QuotationItem
        fields = ["id", "quotation", "item_name", "quantity", "unit_price", "total_price"]
        read_only_fields = ["id", "total_price"]


class QuotationListSerializer(serializers.ModelSerializer):
    customer_name = serializers.SerializerMethodField()
    item_count = serializers.SerializerMethodField()

    class Meta:
        model = Quotation
        fields = ["id", "lead", "customer", "customer_name", "venue", "package", "valid_until", "status", "subtotal", "tax_amount", "total_amount", "item_count", "created_at"]
        read_only_fields = ["id", "subtotal", "tax_amount", "total_amount", "created_at"]

    def get_customer_name(self, obj):
        return obj.customer.full_name if obj.customer else None

    def get_item_count(self, obj):
        return obj.items.count()


class QuotationDetailSerializer(serializers.ModelSerializer):
    items = QuotationItemSerializer(many=True, read_only=True)
    customer_name = serializers.SerializerMethodField()
    venue_name = serializers.SerializerMethodField()

    class Meta:
        model = Quotation
        fields = ["id", "lead", "customer", "customer_name", "venue", "venue_name", "package", "valid_until", "status", "subtotal", "tax_amount", "total_amount", "items", "created_at", "updated_at"]
        read_only_fields = ["id", "subtotal", "tax_amount", "total_amount", "created_at", "updated_at"]

    def get_customer_name(self, obj):
        return obj.customer.full_name if obj.customer else None

    def get_venue_name(self, obj):
        return obj.venue.name if obj.venue else None


class CreateQuotationSerializer(serializers.ModelSerializer):
    items = QuotationItemSerializer(many=True, required=False)

    class Meta:
        model = Quotation
        fields = ["lead", "customer", "venue", "package", "valid_until", "status", "items"]

    def create(self, validated_data):
        items_data = validated_data.pop("items", [])
        tenant = validated_data.pop("tenant", None)
        user = validated_data.pop("created_by", None)
        quotation = Quotation.objects.create(tenant=tenant, created_by=user, **validated_data)
        subtotal = 0
        for item_data in items_data:
            item_data["total_price"] = item_data["quantity"] * item_data["unit_price"]
            QuotationItem.objects.create(quotation=quotation, tenant=tenant, **item_data)
            subtotal += item_data["total_price"]
        quotation.subtotal = subtotal
        quotation.total_amount = subtotal
        quotation.save()
        return quotation
