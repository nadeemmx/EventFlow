import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:eventflow_app/features/authentication/domain/repositories/auth_repository.dart';
import 'package:eventflow_app/features/authentication/data/models/user_model.dart';
import 'package:eventflow_app/core/services/token_service.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;

  const LoginRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class ForgotPasswordRequested extends AuthEvent {
  final String email;

  const ForgotPasswordRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

class ResetPasswordRequested extends AuthEvent {
  final String token;
  final String password;
  final String confirmPassword;

  const ResetPasswordRequested({
    required this.token,
    required this.password,
    required this.confirmPassword,
  });

  @override
  List<Object?> get props => [token, password, confirmPassword];
}

class ChangePasswordRequested extends AuthEvent {
  final String currentPassword;
  final String newPassword;
  final String confirmPassword;

  const ChangePasswordRequested({
    required this.currentPassword,
    required this.newPassword,
    required this.confirmPassword,
  });

  @override
  List<Object?> get props => [currentPassword, newPassword, confirmPassword];
}

class LoadProfile extends AuthEvent {}

class UpdateProfileRequested extends AuthEvent {
  final Map<String, dynamic> data;

  const UpdateProfileRequested({required this.data});

  @override
  List<Object?> get props => [data];
}

class LogoutRequested extends AuthEvent {}

class UploadProfileImage extends AuthEvent {
  final String filePath;
  const UploadProfileImage({required this.filePath});
  @override
  List<Object?> get props => [filePath];
}

class CheckAuthStatus extends AuthEvent {}

class GuestLoginRequested extends AuthEvent {}
class GuestLogoutRequested extends AuthEvent {}

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserModel user;

  const AuthAuthenticated({required this.user});

  @override
  List<Object?> get props => [user];
}

class AuthGuestAuthenticated extends AuthState {
  final UserModel user;
  const AuthGuestAuthenticated({required this.user});
  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {}

class AuthPasswordResetSent extends AuthState {
  final String message;
  const AuthPasswordResetSent({this.message = 'Password reset link sent to your email'});
  @override
  List<Object?> get props => [message];
}

class AuthPasswordResetSuccess extends AuthState {
  final String message;
  const AuthPasswordResetSuccess({this.message = 'Password reset successful'});
  @override
  List<Object?> get props => [message];
}

class AuthPasswordChanged extends AuthState {
  final String message;
  const AuthPasswordChanged({this.message = 'Password changed successfully'});
  @override
  List<Object?> get props => [message];
}

class AuthProfileLoaded extends AuthState {
  final UserModel user;
  const AuthProfileLoaded({required this.user});
  @override
  List<Object?> get props => [user];
}

class AuthProfileUpdated extends AuthState {
  final UserModel user;
  const AuthProfileUpdated({required this.user});
  @override
  List<Object?> get props => [user];
}

class AuthError extends AuthState {
  final String message;
  const AuthError({required this.message});
  @override
  List<Object?> get props => [message];
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final TokenService _tokenService;

  AuthBloc({
    required this._authRepository,
    required this._tokenService,
  }) : super(AuthInitial()) {
    on<LoginRequested>(_onLogin);
    on<ForgotPasswordRequested>(_onForgotPassword);
    on<ResetPasswordRequested>(_onResetPassword);
    on<ChangePasswordRequested>(_onChangePassword);
    on<LoadProfile>(_onLoadProfile);
    on<UpdateProfileRequested>(_onUpdateProfile);
    on<UploadProfileImage>(_onUploadProfileImage);
    on<LogoutRequested>(_onLogout);
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<GuestLoginRequested>(_onGuestLogin);
    on<GuestLogoutRequested>(_onGuestLogout);
  }

  Future<void> _onLogin(LoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final response = await _authRepository.login(event.email, event.password);
      await _tokenService.saveUserData(jsonEncode(response.user.toJson()));
      emit(AuthAuthenticated(user: response.user));
    } catch (e) {
      emit(AuthError(message: _extractErrorMessage(e)));
    }
  }

  Future<void> _onForgotPassword(ForgotPasswordRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _authRepository.forgotPassword(event.email);
      emit(const AuthPasswordResetSent());
    } catch (e) {
      emit(AuthError(message: _extractErrorMessage(e)));
    }
  }

  Future<void> _onResetPassword(ResetPasswordRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _authRepository.resetPassword(event.token, event.password, event.confirmPassword);
      emit(const AuthPasswordResetSuccess());
    } catch (e) {
      emit(AuthError(message: _extractErrorMessage(e)));
    }
  }

  Future<void> _onChangePassword(ChangePasswordRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _authRepository.changePassword(event.currentPassword, event.newPassword, event.confirmPassword);
      emit(const AuthPasswordChanged());
    } catch (e) {
      emit(AuthError(message: _extractErrorMessage(e)));
    }
  }

  Future<void> _onLoadProfile(LoadProfile event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.getProfile();
      emit(AuthProfileLoaded(user: user));
    } catch (e) {
      emit(AuthError(message: _extractErrorMessage(e)));
    }
  }

  Future<void> _onUpdateProfile(UpdateProfileRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.updateProfile(event.data);
      emit(AuthProfileUpdated(user: user));
    } catch (e) {
      emit(AuthError(message: _extractErrorMessage(e)));
    }
  }

  Future<void> _onUploadProfileImage(UploadProfileImage event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.uploadProfileImage(event.filePath);
      emit(AuthProfileUpdated(user: user));
    } catch (e) {
      emit(AuthError(message: _extractErrorMessage(e)));
    }
  }

  Future<void> _onLogout(LogoutRequested event, Emitter<AuthState> emit) async {
    await _authRepository.logout();
    emit(AuthUnauthenticated());
  }

  Future<void> _onGuestLogin(GuestLoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.guestLogin();
      emit(AuthGuestAuthenticated(user: user));
    } catch (e) {
      emit(AuthError(message: _extractErrorMessage(e)));
    }
  }

  Future<void> _onGuestLogout(GuestLogoutRequested event, Emitter<AuthState> emit) async {
    await _authRepository.guestLogout();
    emit(AuthUnauthenticated());
  }

  Future<void> _onCheckAuthStatus(CheckAuthStatus event, Emitter<AuthState> emit) async {
    final isGuest = await _authRepository.isGuest();
    if (isGuest) {
      final user = await _authRepository.guestLogin();
      emit(AuthGuestAuthenticated(user: user));
      return;
    }
    final isLoggedIn = await _authRepository.isLoggedIn();
    if (isLoggedIn) {
      final userData = await _tokenService.getUserData();
      if (userData != null) {
        try {
          final decoded = jsonDecode(userData);
          if (decoded is Map<String, dynamic>) {
            final user = UserModel.fromJson(decoded);
            emit(AuthAuthenticated(user: user));
          } else {
            emit(AuthUnauthenticated());
          }
        } catch (_) {
          await _tokenService.clearTokens();
          emit(AuthUnauthenticated());
        }
      } else {
        emit(AuthUnauthenticated());
      }
    } else {
      emit(AuthUnauthenticated());
    }
  }

  String _extractErrorMessage(dynamic error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        return data['message'] as String? ?? error.message ?? 'Something went wrong';
      }
      return error.message ?? 'Something went wrong';
    }
    return error.toString();
  }
}
