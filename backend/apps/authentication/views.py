from rest_framework.views import APIView
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.throttling import ScopedRateThrottle
from apps.authentication.serializers import (
    LoginSerializer, RefreshSerializer, ForgotPasswordSerializer,
    ResetPasswordSerializer, ChangePasswordSerializer, ProfileSerializer,
    RegisterSerializer,
)
from services.auth_service import AuthService
from core.responses import ok, error
from core.exceptions import ValidationException


class RegisterView(APIView):
    permission_classes = [AllowAny]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "login"

    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        try:
            result = AuthService().register(
                full_name=serializer.validated_data["full_name"],
                email=serializer.validated_data["email"],
                password=serializer.validated_data["password"],
                mobile=serializer.validated_data.get("mobile", ""),
                business_name=serializer.validated_data.get("business_name", ""),
            )
            return ok(result, "Registration successful", status=201)
        except ValidationException as e:
            return error(e.message, status=400)


class LoginView(APIView):
    permission_classes = [AllowAny]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "login"

    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        try:
            result = AuthService().login(
                serializer.validated_data["email"],
                serializer.validated_data["password"],
                request,
            )
            return ok(result, "Login successful")
        except ValidationException as e:
            return error(e.message, status=401)


class RefreshView(APIView):
    permission_classes = [AllowAny]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "token_refresh"

    def post(self, request):
        serializer = RefreshSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        try:
            result = AuthService().refresh(serializer.validated_data["refresh_token"])
            return ok(result)
        except ValidationException as e:
            return error(e.message, status=401)


class LogoutView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = RefreshSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        AuthService().logout(
            request.user,
            serializer.validated_data["refresh_token"],
            access_token=self._bearer_token(request),
        )
        return ok(None, "Logged out successfully")

    @staticmethod
    def _bearer_token(request):
        """The raw access token on this request, so it can be revoked too.

        Leaving it live meant a stolen access token kept working for the rest
        of its lifetime after the user logged out (QA-TEST-REPORT-ROLES.md F-3).
        """
        header = request.headers.get("Authorization", "")
        if header.lower().startswith("bearer "):
            return header[7:].strip()
        return None


class ForgotPasswordView(APIView):
    permission_classes = [AllowAny]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "forgot_password"

    def post(self, request):
        serializer = ForgotPasswordSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        AuthService().forgot_password(serializer.validated_data["email"])
        return ok(None, "Password reset link sent")


class ResetPasswordView(APIView):
    permission_classes = [AllowAny]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "password_reset"

    def post(self, request):
        serializer = ResetPasswordSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        try:
            AuthService().reset_password(
                serializer.validated_data["token"],
                serializer.validated_data["password"],
            )
            return ok(None, "Password reset successful")
        except ValidationException as e:
            return error(e.message)


class ChangePasswordView(APIView):
    permission_classes = [IsAuthenticated]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "password_change"

    def post(self, request):
        serializer = ChangePasswordSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        try:
            AuthService().change_password(
                request.user,
                serializer.validated_data["current_password"],
                serializer.validated_data["new_password"],
            )
            return ok(None, "Password changed successfully")
        except ValidationException as e:
            return error(e.message)


class ProfileView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        serializer = ProfileSerializer(request.user)
        return ok(serializer.data)

    def put(self, request):
        serializer = ProfileSerializer(request.user, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        for field, value in serializer.validated_data.items():
            setattr(request.user, field, value)
        request.user.save()
        return ok(serializer.data, "Profile updated")
