import 'package:eventflow_app/core/api/api_response.dart';
import 'package:eventflow_app/features/invoices/data/datasources/invoice_remote_data_source.dart';
import 'package:eventflow_app/features/invoices/data/models/invoice_model.dart';

class InvoiceRepository {
  final InvoiceRemoteDataSource _remoteDataSource;

  InvoiceRepository({required this._remoteDataSource});

  Future<ApiResponse<List<InvoiceModel>>> getInvoices({int page = 1}) {
    return _remoteDataSource.getInvoices(page: page);
  }

  Future<InvoiceModel> getInvoiceDetail(int id) {
    return _remoteDataSource.getInvoiceDetail(id);
  }

  Future<String> getInvoicePdfUrl(int id) {
    return _remoteDataSource.getInvoicePdfUrl(id);
  }
}
