import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:eventflow_app/features/leads/domain/repositories/lead_repository.dart';
import 'package:eventflow_app/features/leads/data/models/lead_model.dart';
import 'package:dio/dio.dart';

abstract class LeadEvent extends Equatable {
  const LeadEvent();
  @override
  List<Object?> get props => [];
}

class LoadLeads extends LeadEvent {
  final int page;
  final String? search;
  final bool refresh;
  const LoadLeads({this.page = 1, this.search, this.refresh = false});
  @override
  List<Object?> get props => [page, search, refresh];
}

class LoadLeadDetail extends LeadEvent {
  final int id;
  const LoadLeadDetail({required this.id});
}

class CreateLead extends LeadEvent {
  final Map<String, dynamic> data;
  const CreateLead({required this.data});
}

class UpdateLead extends LeadEvent {
  final int id;
  final Map<String, dynamic> data;
  const UpdateLead({required this.id, required this.data});
}

class ConvertLead extends LeadEvent {
  final int id;
  final int venueId;
  const ConvertLead({required this.id, required this.venueId});
}

abstract class LeadState extends Equatable {
  const LeadState();
  @override
  List<Object?> get props => [];
}

class LeadInitial extends LeadState {}
class LeadsLoading extends LeadState {}

class LeadsLoaded extends LeadState {
  final List<LeadModel> leads;
  final bool hasMore;
  final int currentPage;
  const LeadsLoaded({required this.leads, required this.hasMore, required this.currentPage});
  @override
  List<Object?> get props => [leads, hasMore, currentPage];
}

class LeadDetailLoaded extends LeadState {
  final LeadModel lead;
  const LeadDetailLoaded({required this.lead});
}

class LeadActionSuccess extends LeadState {
  final String message;
  final LeadModel? lead;
  const LeadActionSuccess({this.message = 'Success', this.lead});
}

class LeadError extends LeadState {
  final String message;
  const LeadError({required this.message});
}

class LeadBloc extends Bloc<LeadEvent, LeadState> {
  final LeadRepository _repository;
  List<LeadModel> _allLeads = [];

  LeadBloc({required this._repository})
      : super(LeadInitial()) {
    on<LoadLeads>(_onLoad);
    on<LoadLeadDetail>(_onLoadDetail);
    on<CreateLead>(_onCreate);
    on<UpdateLead>(_onUpdate);
    on<ConvertLead>(_onConvert);
  }

  Future<void> _onLoad(LoadLeads event, Emitter<LeadState> emit) async {
    if (event.page == 1) emit(LeadsLoading());
    try {
      final response = await _repository.getLeads(page: event.page, search: event.search);
      final items = response.data ?? [];
      if (event.page == 1 || event.refresh) {
        _allLeads = items;
      } else {
        _allLeads.addAll(items);
      }
      emit(LeadsLoaded(
        leads: List.from(_allLeads),
        hasMore: response.pagination?.hasMore ?? false,
        currentPage: event.page,
      ));
    } catch (e) {
      emit(LeadError(message: _extractMessage(e)));
    }
  }

  Future<void> _onLoadDetail(LoadLeadDetail event, Emitter<LeadState> emit) async {
    emit(LeadsLoading());
    try {
      final l = await _repository.getLead(event.id);
      emit(LeadDetailLoaded(lead: l));
    } catch (e) {
      emit(LeadError(message: _extractMessage(e)));
    }
  }

  Future<void> _onCreate(CreateLead event, Emitter<LeadState> emit) async {
    emit(LeadsLoading());
    try {
      final l = await _repository.createLead(event.data);
      emit(LeadActionSuccess(message: 'Lead created', lead: l));
    } catch (e) {
      emit(LeadError(message: _extractMessage(e)));
    }
  }

  Future<void> _onUpdate(UpdateLead event, Emitter<LeadState> emit) async {
    emit(LeadsLoading());
    try {
      final l = await _repository.updateLead(event.id, event.data);
      emit(LeadActionSuccess(message: 'Lead updated', lead: l));
    } catch (e) {
      emit(LeadError(message: _extractMessage(e)));
    }
  }

  Future<void> _onConvert(ConvertLead event, Emitter<LeadState> emit) async {
    emit(LeadsLoading());
    try {
      final l = await _repository.convertLead(event.id, event.venueId);
      emit(LeadActionSuccess(message: 'Lead converted to booking', lead: l));
    } catch (e) {
      emit(LeadError(message: _extractMessage(e)));
    }
  }

  String _extractMessage(dynamic error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) return data['message'] as String? ?? 'Operation failed';
      return error.message ?? 'Operation failed';
    }
    return error.toString();
  }
}
