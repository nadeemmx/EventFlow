import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:eventflow_app/core/theme/design_system.dart';
import 'package:eventflow_app/core/widgets/components/eventflow_text_field.dart';
import 'package:eventflow_app/core/widgets/components/eventflow_button.dart';
import 'package:eventflow_app/core/widgets/components/eventflow_section_header.dart';
import 'package:eventflow_app/features/bookings/presentation/bloc/booking_bloc.dart';
import 'package:eventflow_app/features/authentication/presentation/bloc/auth_bloc.dart';

class BookingFormPage extends StatefulWidget {
  final int? id;
  const BookingFormPage({super.key, this.id});

  @override
  State<BookingFormPage> createState() => _BookingFormPageState();
}

class _BookingFormPageState extends State<BookingFormPage> {
  bool get _isGuest => context.read<AuthBloc>().state is AuthGuestAuthenticated;

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
  bool _hasInteracted = false;

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

  void _onFieldInteraction() {
    if (!_hasInteracted) {
      setState(() => _hasInteracted = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: DesignSystem.spacing2),
                  Expanded(
                    child: Text(
                      state.message,
                      style: DesignSystem.bodyMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: DesignSystem.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignSystem.radiusMd),
              ),
            ),
          );
          context.pop();
        } else if (state is BookingError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: DesignSystem.spacing2),
                  Expanded(
                    child: Text(
                      state.message,
                      style: DesignSystem.bodyMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: colorScheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignSystem.radiusMd),
              ),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          backgroundColor: colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          title: Text(
            _isEditing ? 'Edit Booking' : 'New Booking',
            style: DesignSystem.headlineSmall.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
        ),
        body: BlocBuilder<BookingBloc, BookingState>(
          builder: (context, state) {
            if (state is BookingsLoading && _isEditing) {
              return _buildFormSkeleton(colorScheme);
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(DesignSystem.spacing4),
              child: Form(
                key: _formKey,
                onChanged: _onFieldInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_isGuest) _buildGuestBanner(colorScheme),
                    _buildCustomerSection(colorScheme),
                    const SizedBox(height: DesignSystem.spacing6),
                    _buildEventSection(colorScheme),
                    const SizedBox(height: DesignSystem.spacing6),
                    _buildPaymentSection(colorScheme),
                    const SizedBox(height: DesignSystem.spacing6),
                    _buildRemarksSection(colorScheme),
                    const SizedBox(height: DesignSystem.spacing8),
                    _buildSubmitButton(state, colorScheme),
                    const SizedBox(height: DesignSystem.spacing10),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGuestBanner(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: DesignSystem.spacing4),
      padding: const EdgeInsets.all(DesignSystem.spacing3),
      decoration: BoxDecoration(
        color: DesignSystem.infoLight,
        borderRadius: BorderRadius.circular(DesignSystem.radiusMd),
        border: Border.all(
          color: DesignSystem.info.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: DesignSystem.info,
          ),
          const SizedBox(width: DesignSystem.spacing2),
          Expanded(
            child: Text(
              'Sign in to create and edit bookings',
              style: DesignSystem.bodySmall.copyWith(
                color: DesignSystem.info,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerSection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EventFlowSectionHeader(
          title: 'Customer Information',
          subtitle: 'Required fields marked with *',
          leadingIcon: Icons.person_outline_rounded,
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: DesignSystem.spacing3),
        _buildField(
          controller: _customerIdController,
          label: 'Customer ID *',
          prefixIcon: Icons.person_outline_rounded,
          keyboardType: TextInputType.number,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Customer ID is required';
            final id = int.tryParse(v);
            if (id == null || id <= 0) return 'Please enter a valid ID';
            return null;
          },
        ),
        const SizedBox(height: DesignSystem.spacing3),
        _buildField(
          controller: _venueIdController,
          label: 'Venue ID (optional)',
          prefixIcon: Icons.location_city_outlined,
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildEventSection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EventFlowSectionHeader(
          title: 'Event Information',
          subtitle: 'Tell us about the event',
          leadingIcon: Icons.event_outlined,
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: DesignSystem.spacing3),
        _buildField(
          controller: _eventTypeController,
          label: 'Event Type *',
          prefixIcon: Icons.category_outlined,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Event type is required';
            return null;
          },
        ),
        const SizedBox(height: DesignSystem.spacing3),
        _buildField(
          controller: _eventDateController,
          label: 'Event Date (YYYY-MM-DD) *',
          prefixIcon: Icons.calendar_today_rounded,
          keyboardType: TextInputType.datetime,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Event date is required';
            final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
            if (!dateRegex.hasMatch(v)) return 'Use format YYYY-MM-DD';
            return null;
          },
        ),
        const SizedBox(height: DesignSystem.spacing3),
        _buildField(
          controller: _guestCountController,
          label: 'Guest Count *',
          prefixIcon: Icons.people_outline_rounded,
          keyboardType: TextInputType.number,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Guest count is required';
            final count = int.tryParse(v);
            if (count == null || count <= 0) return 'Please enter a valid count';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPaymentSection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EventFlowSectionHeader(
          title: 'Payment Details',
          subtitle: 'Amounts in INR',
          leadingIcon: Icons.payments_outlined,
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: DesignSystem.spacing3),
        _buildField(
          controller: _totalAmountController,
          label: 'Total Amount (₹)',
          prefixIcon: Icons.currency_rupee_rounded,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: DesignSystem.spacing3),
        _buildField(
          controller: _advanceAmountController,
          label: 'Advance Amount (₹)',
          prefixIcon: Icons.account_balance_wallet_outlined,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
      ],
    );
  }

  Widget _buildRemarksSection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EventFlowSectionHeader(
          title: 'Additional Notes',
          subtitle: 'Optional',
          leadingIcon: Icons.notes_rounded,
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: DesignSystem.spacing3),
        _buildField(
          controller: _remarksController,
          label: 'Remarks',
          prefixIcon: Icons.notes_rounded,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return EventFlowTextField(
      controller: controller,
      label: label,
      prefixIcon: prefixIcon,
      keyboardType: keyboardType,
      maxLines: maxLines,
    );
  }

  Widget _buildSubmitButton(BookingState state, ColorScheme colorScheme) {
    final isLoading = state is BookingsLoading;
    return EventFlowButton.filled(
      label: _isEditing ? 'Update Booking' : 'Create Booking',
      icon: _isEditing ? Icons.save_rounded : Icons.add_rounded,
      isLoading: isLoading,
      isExpanded: true,
      size: EventFlowButtonSize.large,
      onPressed: isLoading
          ? null
          : () {
              if (_isGuest) {
                _showLoginRequired(context);
                return;
              }
              HapticFeedback.mediumImpact();
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
    );
  }

  Widget _buildFormSkeleton(ColorScheme colorScheme) {
    return Shimmer.fromColors(
      baseColor: colorScheme.surfaceContainerHighest,
      highlightColor: colorScheme.surfaceContainerLowest,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignSystem.spacing4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 24,
              width: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(DesignSystem.radiusXs),
              ),
            ),
            const SizedBox(height: DesignSystem.spacing2),
            Container(
              height: 14,
              width: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(DesignSystem.radiusXs),
              ),
            ),
            const SizedBox(height: DesignSystem.spacing4),
            ...List.generate(4, (index) => Padding(
              padding: const EdgeInsets.only(bottom: DesignSystem.spacing3),
              child: Container(
                height: 56,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(DesignSystem.radiusMd),
                ),
              ),
            )),
            const SizedBox(height: DesignSystem.spacing6),
            Container(
              height: 24,
              width: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(DesignSystem.radiusXs),
              ),
            ),
            const SizedBox(height: DesignSystem.spacing2),
            Container(
              height: 14,
              width: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(DesignSystem.radiusXs),
              ),
            ),
            const SizedBox(height: DesignSystem.spacing4),
            ...List.generate(3, (index) => Padding(
              padding: const EdgeInsets.only(bottom: DesignSystem.spacing3),
              child: Container(
                height: 56,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(DesignSystem.radiusMd),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  void _showLoginRequired(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DesignSystem.radiusXl),
        ),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(DesignSystem.spacing6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(DesignSystem.radiusFull),
              ),
            ),
            const SizedBox(height: DesignSystem.spacing4),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_outline_rounded,
                size: 32,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: DesignSystem.spacing4),
            Text(
              'Sign in required',
              style: DesignSystem.titleLarge.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: DesignSystem.spacing2),
            Text(
              'Sign in to create and manage bookings',
              style: DesignSystem.bodyMedium.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignSystem.spacing5),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push('/login');
                },
                icon: const Icon(Icons.login_rounded, size: 18),
                label: const Text('Sign in'),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    vertical: DesignSystem.spacing3,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DesignSystem.radiusMd),
                  ),
                ),
              ),
            ),
            const SizedBox(height: DesignSystem.spacing3),
          ],
        ),
      ),
    );
  }
}
