from rest_framework import serializers


class RevenueReportSerializer(serializers.Serializer):
    total_revenue = serializers.DecimalField(max_digits=14, decimal_places=2)
    total_refunds = serializers.DecimalField(max_digits=14, decimal_places=2)
    net_revenue = serializers.DecimalField(max_digits=14, decimal_places=2)
    total_bookings = serializers.IntegerField()
    average_booking_value = serializers.DecimalField(max_digits=14, decimal_places=2)


class BookingReportSerializer(serializers.Serializer):
    total_bookings = serializers.IntegerField()
    by_status = serializers.DictField(child=serializers.IntegerField())
    by_event_type = serializers.DictField(child=serializers.IntegerField())
    average_booking_value = serializers.DecimalField(max_digits=14, decimal_places=2)


class PaymentReportSerializer(serializers.Serializer):
    total_collected = serializers.DecimalField(max_digits=14, decimal_places=2)
    total_refunded = serializers.DecimalField(max_digits=14, decimal_places=2)
    net_revenue = serializers.DecimalField(max_digits=14, decimal_places=2)
    by_method = serializers.DictField(child=serializers.DecimalField(max_digits=14, decimal_places=2))


class OccupancyReportSerializer(serializers.Serializer):
    venue_id = serializers.IntegerField()
    venue_name = serializers.CharField()
    total_capacity = serializers.IntegerField()
    bookings_count = serializers.IntegerField()
    occupancy_percentage = serializers.FloatField()


class LeadReportSerializer(serializers.Serializer):
    total_leads = serializers.IntegerField()
    by_status = serializers.DictField(child=serializers.IntegerField())
    by_source = serializers.DictField(child=serializers.IntegerField())
    conversion_rate = serializers.FloatField()
    converted = serializers.IntegerField()
    lost = serializers.IntegerField()
    active = serializers.IntegerField()


class VendorReportSerializer(serializers.Serializer):
    total_vendors = serializers.IntegerField()
    active_vendors = serializers.IntegerField()
    by_type = serializers.DictField(child=serializers.IntegerField())


class InventoryReportSerializer(serializers.Serializer):
    total_items = serializers.IntegerField()
    low_stock_items = serializers.IntegerField()
    by_category = serializers.DictField(child=serializers.IntegerField())


class OutstandingPaymentsReportSerializer(serializers.Serializer):
    booking_id = serializers.IntegerField()
    booking_number = serializers.CharField()
    customer_name = serializers.CharField()
    venue_name = serializers.CharField()
    event_date = serializers.DateField()
    total_amount = serializers.DecimalField(max_digits=14, decimal_places=2)
    total_paid = serializers.DecimalField(max_digits=14, decimal_places=2)
    outstanding = serializers.DecimalField(max_digits=14, decimal_places=2)
    payment_status = serializers.CharField()


class MonthlyGrowthReportSerializer(serializers.Serializer):
    month = serializers.CharField()
    year = serializers.IntegerField()
    revenue = serializers.DecimalField(max_digits=14, decimal_places=2)
    booking_count = serializers.IntegerField()
    new_leads = serializers.IntegerField()
    conversion_count = serializers.IntegerField()
