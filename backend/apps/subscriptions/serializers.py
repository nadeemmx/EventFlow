from rest_framework import serializers
from django.utils import timezone
from datetime import timedelta
from apps.subscriptions.models import SubscriptionPlan, Subscription
from core.choices import BillingCycle, SubscriptionStatus


class SubscriptionPlanSerializer(serializers.ModelSerializer):
    class Meta:
        model = SubscriptionPlan
        fields = "__all__"
        read_only_fields = ["id"]


class SubscriptionSerializer(serializers.ModelSerializer):
    plan_name = serializers.CharField(required=False, allow_blank=True, write_only=True)
    amount = serializers.SerializerMethodField()

    class Meta:
        model = Subscription
        fields = [
            "id", "tenant", "plan", "plan_name", "amount",
            "start_date", "end_date", "billing_cycle",
            "status", "created_at",
        ]
        read_only_fields = ["id", "tenant", "created_at"]

    def get_amount(self, obj) -> str:
        if not obj.plan:
            return "0.00"
        if obj.billing_cycle == BillingCycle.YEARLY:
            price = obj.plan.yearly_price
        elif obj.billing_cycle == BillingCycle.QUARTERLY:
            price = obj.plan.monthly_price * 3
        else:
            price = obj.plan.monthly_price
        return str(price)

    def to_representation(self, instance):
        data = super().to_representation(instance)
        data["plan_name"] = instance.plan.get_plan_name_display() if instance.plan else None
        return data

    def validate(self, attrs):
        instance = self.instance
        plan = attrs.get("plan")
        if plan is None:
            plan_name = (attrs.get("plan_name") or "").strip()
            if plan_name:
                plan = SubscriptionPlan.objects.filter(
                    plan_name__iexact=plan_name, status="ACTIVE"
                ).first()
                if not plan:
                    raise serializers.ValidationError(
                        {"plan_name": "No active subscription plan matches this name."}
                    )
                attrs["plan"] = plan
            elif instance is None:
                raise serializers.ValidationError(
                    {"plan": "A subscription plan is required."}
                )

        start_date = attrs.get("start_date") or (instance.start_date if instance else None)
        end_date = attrs.get("end_date") or (instance.end_date if instance else None)
        if instance is None:
            start_date = start_date or timezone.now().date()
            end_date = end_date or start_date + timedelta(days=30)
            attrs.setdefault("start_date", start_date)
            attrs.setdefault("end_date", end_date)
            attrs.setdefault("billing_cycle", BillingCycle.MONTHLY)
            attrs.setdefault("status", SubscriptionStatus.TRIAL)

        if start_date and end_date and end_date < start_date:
            raise serializers.ValidationError(
                {"end_date": "End date must be on or after start date."}
            )
        return attrs


class RenewSubscriptionSerializer(serializers.Serializer):
    plan_id = serializers.IntegerField()
    billing_cycle = serializers.ChoiceField(choices=["MONTHLY", "QUARTERLY", "YEARLY"])
