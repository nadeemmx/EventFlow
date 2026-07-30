import 'package:eventflow_app/core/api/api_response.dart';
import 'package:eventflow_app/features/payments/data/datasources/payment_remote_data_source.dart';
import 'package:eventflow_app/features/payments/data/models/payment_model.dart';

class PaymentRepository {
  final PaymentRemoteDataSource _remoteDataSource;

  PaymentRepository({required this._remoteDataSource});

  Future<ApiResponse<List<PaymentModel>>> getPayments({int page = 1}) {
    return _remoteDataSource.getPayments(page: page);
  }

  Future<Map<String, dynamic>> createOrder({
    required int bookingId,
    required double amount,
  }) {
    return _remoteDataSource.createOrder(bookingId: bookingId, amount: amount);
  }

  Future<Map<String, dynamic>> verifyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    required int bookingId,
  }) {
    return _remoteDataSource.verifyPayment(
      razorpayOrderId: razorpayOrderId,
      razorpayPaymentId: razorpayPaymentId,
      razorpaySignature: razorpaySignature,
      bookingId: bookingId,
    );
  }

  Future<ApiResponse<PaymentModel>> getPaymentDetail(int id) {
    return _remoteDataSource.getPaymentDetail(id);
  }
}
