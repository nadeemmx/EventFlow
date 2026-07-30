import 'package:eventflow_app/core/api/api_client.dart';
import 'package:eventflow_app/core/api/api_endpoints.dart';
import 'package:eventflow_app/core/api/api_response.dart';
import 'package:eventflow_app/features/payments/data/models/payment_model.dart';

class PaymentRemoteDataSource {
  final ApiClient _apiClient;

  PaymentRemoteDataSource({required this._apiClient});

  Future<ApiResponse<List<PaymentModel>>> getPayments({int page = 1}) async {
    final response = await _apiClient.get(
      ApiEndpoints.payments,
      queryParameters: {'page': page},
    );
    return ApiResponse.fromJsonList(
      response.data as Map<String, dynamic>,
      (data) => PaymentModel.fromJson(data),
    );
  }

  Future<Map<String, dynamic>> createOrder({
    required int bookingId,
    required double amount,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.paymentCreateOrder,
      data: {
        'booking_id': bookingId,
        'amount': amount,
      },
    );
    final data = response.data as Map<String, dynamic>;
    if (data['success'] == true) {
      return data['data'] as Map<String, dynamic>;
    }
    throw Exception(data['message'] as String? ?? 'Failed to create order');
  }

  Future<Map<String, dynamic>> verifyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    required int bookingId,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.paymentVerify,
      data: {
        'razorpay_order_id': razorpayOrderId,
        'razorpay_payment_id': razorpayPaymentId,
        'razorpay_signature': razorpaySignature,
        'booking_id': bookingId,
      },
    );
    final data = response.data as Map<String, dynamic>;
    if (data['success'] == true) {
      return data['data'] as Map<String, dynamic>;
    }
    throw Exception(data['message'] as String? ?? 'Payment verification failed');
  }

  Future<ApiResponse<PaymentModel>> getPaymentDetail(int id) async {
    final response = await _apiClient.get(ApiEndpoints.paymentDetail(id));
    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => PaymentModel.fromJson(data as Map<String, dynamic>),
    );
  }
}
