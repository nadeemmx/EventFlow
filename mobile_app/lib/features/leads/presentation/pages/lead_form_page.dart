import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:eventflow_app/core/theme/app_colors.dart';
import 'package:eventflow_app/core/theme/app_dimens.dart';
import 'package:eventflow_app/core/widgets/login_required_sheet.dart';
import 'package:eventflow_app/features/leads/presentation/bloc/lead_bloc.dart';
import 'package:eventflow_app/features/authentication/presentation/bloc/auth_bloc.dart';

class LeadFormPage extends StatefulWidget {
  final int? id;
  const LeadFormPage({super.key, this.id});

  @override
  State<LeadFormPage> createState() => _LeadFormPageState();
}

class _LeadFormPageState extends State<LeadFormPage> {
  bool _isGuest(BuildContext context) {
    return context.read<AuthBloc>().state is AuthGuestAuthenticated;
  }

  final _formKey = GlobalKey<FormState>();
  final _customerController = TextEditingController();
  final _guestCountController = TextEditingController();
  final _eventDateController = TextEditingController();
  String? _leadSource;
  String? _eventType;
  bool _isEditing = false;

  final _leadSources = [
    'Website',
    'Referral',
    'Social Media',
    'Walk-in',
    'Phone',
    'Email',
    'Other',
  ];
  final _eventTypes = [
    'Wedding',
    'Birthday',
    'Corporate',
    'Conference',
    'Party',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.id != null) {
      _isEditing = true;
      context.read<LeadBloc>().add(LoadLeadDetail(id: widget.id!));
    }
  }

  @override
  void dispose() {
    _customerController.dispose();
    _guestCountController.dispose();
    _eventDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LeadBloc, LeadState>(
      listener: (context, state) {
        if (state is LeadDetailLoaded && _isEditing) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            final l = state.lead;
            _customerController.text = l.customer.toString();
            _leadSource = l.leadSource;
            _eventType = l.eventType;
            _eventDateController.text = l.expectedEventDate ?? '';
            _guestCountController.text = l.expectedGuestCount?.toString() ?? '';
          });
        }
        if (state is LeadActionSuccess) {
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
        } else if (state is LeadError) {
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
            _isEditing ? 'Edit Lead' : 'New Lead',
            style: const TextStyle(
              fontSize: AppDimens.fontXxl,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
        ),
        body: BlocBuilder<LeadBloc, LeadState>(
          builder: (context, state) {
            if (state is LeadsLoading && _isEditing) {
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
                                'Sign in to create and edit leads',
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
                      controller: _customerController,
                      label: 'Customer ID',
                      icon: Icons.person_outline_rounded,
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || v.isEmpty
                          ? 'Customer ID is required'
                          : null,
                    ),
                    const SizedBox(height: AppDimens.xxl),
                    _buildSectionTitle('Lead Details'),
                    const SizedBox(height: AppDimens.md),
                    _premiumDropdown(
                      value: _leadSource,
                      label: 'Lead Source',
                      icon: Icons.source_outlined,
                      items: _leadSources,
                      onChanged: (v) => setState(() => _leadSource = v),
                    ),
                    const SizedBox(height: AppDimens.md),
                    _premiumDropdown(
                      value: _eventType,
                      label: 'Event Type',
                      icon: Icons.event_outlined,
                      items: _eventTypes,
                      onChanged: (v) => setState(() => _eventType = v),
                    ),
                    const SizedBox(height: AppDimens.md),
                    _premiumDateField(
                      controller: _eventDateController,
                      label: 'Expected Event Date',
                      icon: Icons.calendar_today_rounded,
                    ),
                    const SizedBox(height: AppDimens.md),
                    _premiumTextField(
                      controller: _guestCountController,
                      label: 'Expected Guest Count',
                      icon: Icons.people_outline_rounded,
                      keyboardType: TextInputType.number,
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

  Widget _premiumDropdown({
    required String? value,
    required String label,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimens.lg,
          vertical: AppDimens.md,
        ),
      ),
      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      items: items
          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _premiumDateField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimens.lg,
          vertical: AppDimens.md,
        ),
        suffixIcon: const Icon(
          Icons.arrow_drop_down,
          color: AppColors.textTertiary,
        ),
      ),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: AppColors.primary,
                  onPrimary: Colors.white,
                  surface: AppColors.surface,
                  onSurface: AppColors.textPrimary,
                ),
                dialogTheme: DialogThemeData(
                  backgroundColor: AppColors.surface,
                ),
              ),
              child: child!,
            );
          },
        );
        if (date != null) {
          _eventDateController.text =
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        }
      },
    );
  }

  Widget _buildSubmitButton(LeadState state) {
    final isLoading = state is LeadsLoading;
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
                    final customerId = int.tryParse(
                      _customerController.text.trim(),
                    );
                    if (customerId == null || customerId <= 0) return;
                    final data = <String, dynamic>{'customer': customerId};
                    if (_leadSource != null) data['lead_source'] = _leadSource!;
                    if (_eventType != null) data['event_type'] = _eventType!;
                    if (_eventDateController.text.trim().isNotEmpty) {
                      data['expected_event_date'] = _eventDateController.text
                          .trim();
                    }
                    final guestCount = int.tryParse(
                      _guestCountController.text.trim(),
                    );
                    if (guestCount != null && guestCount > 0) {
                      data['expected_guest_count'] = guestCount;
                    }
                    if (_isEditing) {
                      context.read<LeadBloc>().add(
                        UpdateLead(id: widget.id!, data: data),
                      );
                    } else {
                      context.read<LeadBloc>().add(CreateLead(data: data));
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
              : Text(_isEditing ? 'Update Lead' : 'Create Lead'),
        ),
      ),
    );
  }
}
