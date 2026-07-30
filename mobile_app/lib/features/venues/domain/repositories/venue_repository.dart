import 'package:eventflow_app/core/api/api_response.dart';
import 'package:eventflow_app/features/venues/data/datasources/venue_remote_data_source.dart';
import 'package:eventflow_app/features/venues/data/models/venue_model.dart';

class VenueRepository {
  final VenueRemoteDataSource _remoteDataSource;

  VenueRepository({required this._remoteDataSource});

  Future<ApiResponse<List<VenueModel>>> getVenues({int page = 1}) {
    return _remoteDataSource.getVenues(page: page);
  }

  Future<VenueModel> getVenue(int id) => _remoteDataSource.getVenue(id);

  Future<void> uploadImage(int venueId, String filePath) =>
      _remoteDataSource.uploadVenueImage(venueId, filePath);
}
