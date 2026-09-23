import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/customer.dart';
import '../../../sync/cubit/sync_cubit.dart';
import '../../cubit/customer_detail_cubit.dart';

class CustomerPhoneCard extends StatefulWidget {
  final Customer customer;
  final bool isSaving;

  const CustomerPhoneCard({super.key, required this.customer, required this.isSaving});

  @override
  State<CustomerPhoneCard> createState() => _CustomerPhoneCardState();
}

class _CustomerPhoneCardState extends State<CustomerPhoneCard> {
  final _formKey = GlobalKey<FormState>();
  late final _controller = TextEditingController(text: widget.customer.phone);
  bool _editing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startEditing() {
    _controller.text = widget.customer.phone;
    setState(() => _editing = true);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_controller.text.trim() == widget.customer.phone) {
      setState(() => _editing = false);
      return;
    }
    FocusScope.of(context).unfocus();
    final offline = !context.read<SyncCubit>().state.isOnline;
    final saved = await context.read<CustomerDetailCubit>().savePhone(_controller.text, offline: offline);
    if (saved && mounted) setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    final customer = widget.customer;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: _editing
            ? Form(
                key: _formKey,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: const Key('phone_field'),
                        controller: _controller,
                        autofocus: true,
                        enabled: !widget.isSaving,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _save(),
                        validator: CustomerDetailCubit.validatePhone,
                        decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone_outlined)),
                      ),
                    ),
                    const SizedBox(width: 4),
                    if (widget.isSaving)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    else ...[
                      IconButton(
                        key: const Key('phone_save'),
                        tooltip: 'Save',
                        icon: const Icon(Icons.check_rounded, color: AppTheme.statusConfirmedText),
                        onPressed: _save,
                      ),
                      IconButton(
                        tooltip: 'Cancel',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => setState(() => _editing = false),
                      ),
                    ],
                  ],
                ),
              )
            : Row(
                children: [
                  const Icon(Icons.phone_outlined, color: AppTheme.textSecondary),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Phone', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        const SizedBox(height: 2),
                        Text(
                          customer.phone.isEmpty ? 'Not set' : customer.phone,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        if (customer.hasPendingSync) ...[
                          const SizedBox(height: 4),
                          const Row(
                            children: [
                              Icon(Icons.cloud_upload_outlined, size: 14, color: AppTheme.statusSyncPendingText),
                              SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Waiting to sync',
                                  style: TextStyle(fontSize: 12, color: AppTheme.statusSyncPendingText),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  TextButton.icon(
                    key: const Key('phone_edit'),
                    onPressed: _startEditing,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit'),
                  ),
                ],
              ),
      ),
    );
  }
}
