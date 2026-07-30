# Guest Mode Implementation Plan

> **For agentic workers:** This plan implements Guest Mode for EventFlow Flutter app.

**Goal:** Add a read-only demo/guest mode that allows users to explore the entire app without authentication.

**Architecture:** Extend auth BLoC with `GuestAuthenticated` state; add demo data providers for all features; route guard allows guest access; write operations blocked with "Login Required" bottom sheet.

**Tech Stack:** Flutter, flutter_bloc, go_router, get_it, Hive

---

## File Structure

### New Files
- `lib/core/services/guest_session_service.dart` - Guest session persistence
- `lib/core/services/demo_data_provider.dart` - All realistic demo data
- `lib/core/widgets/demo_banner.dart` - Persistent DEMO MODE banner
- `lib/core/widgets/login_required_sheet.dart` - Bottom sheet for blocked actions
- `lib/core/routes/guest_route_guard.dart` - Guest route protection

### Modified Files
- `lib/main.dart` - Initialize guest session
- `lib/injector.dart` - Register demo services
- `lib/core/routes/app_router.dart` - Guest-aware redirects
- `lib/core/services/token_service.dart` - No changes needed
- `lib/features/authentication/presentation/bloc/auth_bloc.dart` - Add guest events/states
- `lib/features/authentication/presentation/pages/splash_page.dart` - Guest button
- `lib/features/authentication/presentation/pages/login_page.dart` - Guest button
- `lib/features/dashboard/presentation/pages/dashboard_page.dart` - Demo banner, drawer
- All list pages - Show demo banner
- `lib/core/widgets/app_scaffold.dart` - Optional demo mode integration

---

## Implementation Tasks

### Task 1: Guest Session Service
Create `lib/core/services/guest_session_service.dart` for persisting guest state in Hive.

### Task 2: Demo Data Provider
Create `lib/core/services/demo_data_provider.dart` with realistic Indian event management data.

### Task 3: Auth Bloc Guest Support
Extend `auth_bloc.dart` with `GuestLoginRequested`, `GuestLogoutRequested`, `GuestAuthenticated`.

### Task 4: Auth Repository Guest Support
Extend `auth_repository.dart` with guest login/logout.

### Task 5: DI Registration
Update `injector.dart` to register demo services.

### Task 6: Route Protection
Update `app_router.dart` with guest-aware redirects.

### Task 7: Login Screen Guest Button
Update `login_page.dart` with "Continue as Guest" button.

### Task 8: Splash Screen Guest Flow
Update `splash_page.dart` for guest session detection.

### Task 9: Demo Banner Widget
Create `lib/core/widgets/demo_banner.dart`.

### Task 10: Login Required Bottom Sheet
Create `lib/core/widgets/login_required_sheet.dart`.

### Task 11: Dashboard and Drawer Updates
Update `dashboard_page.dart` with demo banner and guest drawer.

### Task 12: Feature Pages - Blocked Actions
Add "Login Required" sheet to all write actions.

### Task 13: Profile Page Guest Mode
Update `profile_page.dart` for guest behavior.

### Task 14: Settings Page Guest Mode
Update `settings_page.dart` for guest behavior.

### Task 15: Invoice Detail Page Guest Mode
Block PDF download/share for guests.

### Task 16: Tests
Add tests for guest mode.

### Task 17: Build Release APK
Build and verify.
