import 'package:eventflow_app/core/api/api_client.dart';
import 'package:eventflow_app/core/api/api_endpoints.dart';
import 'package:eventflow_app/core/api/api_response.dart';
import 'package:eventflow_app/features/invoices/data/models/invoice_model.dart';

class InvoiceRemoteDataSource {
  final ApiClient _apiClient;

  InvoiceRemoteDataSource({required this._apiClient});

  Future<ApiResponse<List<InvoiceModel>>> getInvoices({int page = 1}) async {
    final response = await _apiClient.get(
      ApiEndpoints.invoices,
      queryParameters: {'page': page},
    );
    return ApiResponse.fromJsonList(
      response.data as Map<String, dynamic>,
      (data) => InvoiceModel.fromJson(data),
    );
  }

  Future<InvoiceModel> getInvoiceDetail(int id) async {
    final response = await _apiClient.get(ApiEndpoints.invoiceDetail(id));
    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => InvoiceModel.fromJson(data as Map<String, dynamic>),
    );
    if (!apiResponse.success || apiResponse.data == null) {
      throw Exception(apiResponse.message);
    }
    return apiResponse.data!;
  }

  Future<String> getInvoicePdfUrl(int id) async {
    return '${ApiEndpoints.baseUrl}${ApiEndpoints.invoicePdf(id)}';
  }
}
