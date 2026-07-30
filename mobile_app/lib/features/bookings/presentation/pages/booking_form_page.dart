import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:eventflow_app/core/theme/app_colors.dart';
import 'package:eventflow_app/core/theme/app_dimens.dart';
import 'package:eventflow_app/core/widgets/login_required_sheet.dart';
import 'package:eventflow_app/features/bookings/presentation/bloc/booking_bloc.dart';
import 'package:eventflow_app/features/authentication/presentation/bloc/auth_bloc.dart';

class BookingFormPage extends StatefulWidget {
  final int? id;
  const BookingFormPage({super.key, this.id});

  @override
  State<BookingFormPage> createState() => _BookingFormPageState();
}

class _BookingFormPageState extends State<BookingFormPage> {
  bool _isGuest(BuildContext context) {
    return context.read<AuthBloc>().state is AuthGuestAuthenticated;
  }

  final _formKey = GlobalKey<FormState>();
  final _customerIdController = TextEditingController();
  final _eventTypeController = TextEditingController();
  final _eventDateController = TextEditingController();
  final _guestCountController = TextEditingController();
  final _totalAmountController = TextEditingController();
  final _advanceAmountController = TextEditingController();
  final _remarksController = TextEditingController();
  final _venueIdController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    if (widget.id != null) {
      _isEditing = true;
      context.read<BookingBloc>().add(LoadBookingDetail(id: widget.id!));
    }
  }

  @override
  void dispose() {
    _customerIdController.dispose();
    _eventTypeController.dispose();
    _eventDateController.dispose();
    _guestCountController.dispose();
    _totalAmountController.dispose();
    _advanceAmountController.dispose();
    _remarksController.dispose();
    _venueIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BookingBloc, BookingState>(
      listener: (context, state) {
        if (state is BookingDetailLoaded && _isEditing) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            final b = state.booking;
            _customerIdController.text = b.customer.toString();
            _eventTypeController.text = b.eventType;
            _eventDateController.text = b.eventDate;
            _guestCountController.text = b.guestCount.toString();
            _totalAmountController.text = b.totalAmount.toString();
            _advanceAmountController.text = b.advanceAmount.toString();
            _remarksController.text = b.remarks ?? '';
            _venueIdController.text = b.venue?.toString() ?? '';
          });
        }
        if (state is BookingActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              ),
            ),
          );
          context.pop();
        } else if (state is BookingError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              ),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          title: Text(
            _isEditing ? 'Edit Booking' : 'New Booking',
            style: const TextStyle(
              fontSize: AppDimens.fontXxl,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
        ),
        body: BlocBuilder<BookingBloc, BookingState>(
          builder: (context, state) {
            if (state is BookingsLoading && _isEditing) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimens.lg),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_isGuest(context))
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.infoLight,
                          borderRadius: BorderRadius.circular(
                            AppDimens.radiusMd,
                          ),
                          border: Border.all(
                            color: AppColors.info.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              size: 18,
                              color: AppColors.info,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Sign in to create and edit bookings',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.info,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    _buildSectionTitle('Customer Information'),
                    const SizedBox(height: AppDimens.md),
                    _premiumTextField(
                      controller: _customerIdController,
                      label: 'Customer ID',
                      icon: Icons.person_outline_rounded,
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || v.isEmpty
                          ? 'Customer ID is required'
                          : null,
                    ),
                    const SizedBox(height: AppDimens.md),
                    _premiumTextField(
                      controller: _venueIdController,
                      label: 'Venue ID (optional)',
                      icon: Icons.location_city_outlined,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: AppDimens.xxl),
                    _buildSectionTitle('Event Information'),
                    const SizedBox(height: AppDimens.md),
                    _premiumTextField(
                      controller: _eventTypeController,
                      label: 'Event Type',
                      icon: Icons.event_outlined,
                      validator: (v) => v == null || v.isEmpty
                          ? 'Event type is required'
                          : null,
                    ),
                    const SizedBox(height: AppDimens.md),
                    _premiumTextField(
                      controller: _eventDateController,
                      label: 'Event Date (YYYY-MM-DD)',
                      icon: Icons.calendar_today_rounded,
                      validator: (v) => v == null || v.isEmpty
                          ? 'Event date is required'
                          : null,
                    ),
                    const SizedBox(height: AppDimens.md),
                    _premiumTextField(
                      controller: _guestCountController,
                      label: 'Guest Count',
                      icon: Icons.people_outline_rounded,
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || v.isEmpty
                          ? 'Guest count is required'
                          : null,
                    ),
                    const SizedBox(height: AppDimens.xxl),
                    _buildSectionTitle('Payment Details'),
                    const SizedBox(height: AppDimens.md),
                    _premiumTextField(
                      controller: _totalAmountController,
                      label: 'Total Amount (₹)',
                      icon: Icons.currency_rupee_rounded,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: AppDimens.md),
                    _premiumTextField(
                      controller: _advanceAmountController,
                      label: 'Advance Amount (₹)',
                      icon: Icons.payments_outlined,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: AppDimens.xxl),
                    _buildSectionTitle('Additional Notes'),
                    const SizedBox(height: AppDimens.md),
                    _premiumTextField(
                      controller: _remarksController,
                      label: 'Remarks',
                      icon: Icons.notes_rounded,
                      maxLines: 3,
                    ),
                    const SizedBox(height: AppDimens.xxxl),
                    _buildSubmitButton(state),
                    const SizedBox(height: AppDimens.huge),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: AppDimens.fontMd,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.2,
      ),
    );
  }

  Widget _premiumTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(
        fontSize: AppDimens.fontMd,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: AppDimens.fontMd,
        ),
        prefixIcon: Icon(icon, size: 20, color: AppColors.textTertiary),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimens.lg,
          vertical: AppDimens.md,
        ),
      ),
    );
  }

  Widget _buildSubmitButton(BookingState state) {
    final isLoading = state is BookingsLoading;
    return SizedBox(
      height: AppDimens.buttonHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: isLoading ? null : AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: isLoading
              ? null
              : () {
                  if (_isGuest(context)) {
                    showLoginRequiredSheet(context);
                    return;
                  }
                  if (_formKey.currentState?.validate() ?? false) {
                    final customerId = int.tryParse(_customerIdController.text);
                    if (customerId == null || customerId <= 0) return;
                    final data = <String, dynamic>{
                      'customer': customerId,
                      'event_type': _eventTypeController.text.trim(),
                      'event_date': _eventDateController.text.trim(),
                      'guest_count':
                          int.tryParse(_guestCountController.text) ?? 0,
                      'total_amount':
                          double.tryParse(_totalAmountController.text) ?? 0,
                      'advance_amount':
                          double.tryParse(_advanceAmountController.text) ?? 0,
                      'remarks': _remarksController.text.trim(),
                    };
                    if (_venueIdController.text.isNotEmpty) {
                      final venueId = int.tryParse(_venueIdController.text);
                      if (venueId != null) data['venue'] = venueId;
                    }
                    if (_isEditing) {
                      context.read<BookingBloc>().add(
                        UpdateBooking(id: widget.id!, data: data),
                      );
                    } else {
                      context.read<BookingBloc>().add(
                        CreateBooking(data: data),
                      );
                    }
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: isLoading
                ? AppColors.borderLight
                : Colors.transparent,
            foregroundColor: isLoading ? AppColors.textSecondary : Colors.white,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            ),
            textStyle: const TextStyle(
              fontSize: AppDimens.fontMd,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.textSecondary,
                  ),
                )
              : Text(_isEditing ? 'Update Booking' : 'Create Booking'),
        ),
      ),
    );
  }
}
