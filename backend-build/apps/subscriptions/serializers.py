from rest_framework import serializers
from apps.subscriptions.models import SubscriptionPlan, Subscription


class SubscriptionPlanSerializer(serializers.ModelSerializer):
    class Meta:
        model = SubscriptionPlan
        fields = "__all__"
        read_only_fields = ["id"]


class SubscriptionSerializer(serializers.ModelSerializer):
    plan_name = serializers.CharField(source="plan.plan_name", read_only=True)

    class Meta:
        model = Subscription
        fields = [
            "id", "tenant", "plan", "plan_name",
            "start_date", "end_date", "billing_cycle",
            "status", "created_at",
        ]
        read_only_fields = ["id", "tenant", "created_at"]


class RenewSubscriptionSerializer(serializers.Serializer):
    plan_id = serializers.IntegerField()
    billing_cycle = serializers.ChoiceField(choices=["MONTHLY", "QUARTERLY", "YEARLY"])
