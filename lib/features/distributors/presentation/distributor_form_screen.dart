import 'package:flutter/material.dart';
import 'package:hoberadius_app/core/format/input_rules.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/visible_error_message.dart';
import '../../../core/auth/permissions.dart';
import '../../../core/format/number_input.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/form_field_row.dart';
import '../../../shared/widgets/hub_layout.dart';
import '../../../shared/widgets/hub_switch_row.dart';
import '../../../shared/widgets/page_header.dart';
import '../../admins/data/admins_repository.dart';
import '../../admins/domain/admin_model.dart';
import '../../subscribers/presentation/widgets/subscriber_form_sections.dart'
    show canPickResponsibleManager;
import '../data/distributors_repository.dart';
import '../domain/distributor_model.dart';
import 'distributor_detail_screen.dart';
import 'distributors_list_screen.dart';

/// Largest «حد الائتمان» the form accepts.
const num kDistributorCreditLimitMax = 1000000000;

/// «حد الائتمان» validator — the SAME strict reader the save uses («1,5» is
/// refused with the reason; it used to pass here and save as 0).
String? validateDistributorCreditLimit(String? raw) {
  final r = readNumberInput(raw);
  if (r.isEmpty) return null;
  if (r.error != null) return r.error;
  if (r.value! > kDistributorCreditLimitMax) return 'حد الائتمان كبير جدًا.';
  return null;
}

/// «حد الائتمان» as saved (empty → 0; Arabic digits and «٫» read too).
num parseDistributorCreditLimit(String? raw) => parseDecimalInput(raw) ?? 0;

/// «المدير المالك» is offered only to a login that sees every distributor
/// (owner / co-owner / «مدير عام») and may read the managers list — the
/// same rule as the subscriber form's «المدير المسؤول».
bool canPickDistributorOwner(AppPermissions p) =>
    (p.isOwnerLike || p.isSuperAdmin) && canPickResponsibleManager(p);

/// Credit-limit hint: the server enforces it as a hard debt cap.
const kDistributorCreditLimitHint =
    'أقصى دين مسموح للموزّع؛ يُمنع تسجيل دين يتجاوزه. 0 = بلا حدّ';

class DistributorFormScreen extends ConsumerStatefulWidget {
  const DistributorFormScreen({super.key, this.distributorId});

  /// Null = «إضافة موزع»; an id = «تعديل الموزع» (PATCH).
  final int? distributorId;

  @override
  ConsumerState<DistributorFormScreen> createState() =>
      _DistributorFormScreenState();
}

class _DistributorFormScreenState extends ConsumerState<DistributorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _displayName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _creditLimit = TextEditingController(text: '0');
  final _notes = TextEditingController();
  final _portalPassword = TextEditingController();

  final Set<String> _permissions = {'cards.read', 'cards.sell'};
  String _status = 'active';
  bool _scopeAll = false;
  Map<String, dynamic> _existingScope = const {};
  int? _adminId;

  /// Edit: the owner was picked by hand (only then is `admin_id` sent — a
  /// summary without `admin_id` must never wipe the current owner).
  bool _adminTouched = false;
  int? _loadedId;
  bool _saving = false;
  bool _obscurePortal = true;

  bool get _isEdit => widget.distributorId != null;

  static const _permissionOptions = [
    _PermissionOption(
      key: 'cards.read',
      label: 'عرض الكروت والحزم',
      description: 'يسمح للموزع برؤية الحزم المرتبطة به ومتابعة حالتها.',
    ),
    _PermissionOption(
      key: 'cards.sell',
      label: 'بيع الكروت',
      description: 'يسمح بتنفيذ عمليات البيع ضمن الحزم المسموحة فقط.',
    ),
    _PermissionOption(
      key: 'cards.check',
      label: 'فحص كروت (بوابة الموزّع)',
      description: 'بوابة قراءة فقط على /portal/distributor — يدخل الموزّع '
          'باسم الدخول وكلمة مرور البوابة، يفحص حالة الكروت دون أي تعديل.',
    ),
  ];

  @override
  void dispose() {
    _name.dispose();
    _displayName.dispose();
    _email.dispose();
    _phone.dispose();
    _creditLimit.dispose();
    _notes.dispose();
    _portalPassword.dispose();
    super.dispose();
  }

  void _fill(Distributor d) {
    if (_loadedId == d.id) return;
    _loadedId = d.id;
    _name.text = d.name;
    _displayName.text = d.displayName;
    _email.text = d.email;
    _phone.text = d.phone;
    _creditLimit.text = _plainNumber(d.creditLimit);
    _notes.text = d.notes;
    _status = d.status.trim().isEmpty ? 'active' : d.status.trim();
    _permissions
      ..clear()
      ..addAll(d.permissions);
    _existingScope = d.scope;
    _scopeAll = d.checksAllBatches;
    _adminId = d.adminId;
  }

  static String _plainNumber(num v) =>
      v == v.roundToDouble() ? '${v.toInt()}' : '$v';

  @override
  Widget build(BuildContext context) {
    if (!_isEdit) return _form(context);
    final id = widget.distributorId!;
    return ref.watch(distributorSummaryProvider(id)).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => EmptyState(
            icon: Icons.error_outline,
            title: 'تعذر جلب الموزع',
            subtitle: visibleErrorMessage(e),
            action: OutlinedButton.icon(
              onPressed: () => ref.invalidate(distributorSummaryProvider(id)),
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ),
          data: (summary) {
            _fill(summary.distributor);
            return _form(context);
          },
        );
  }

  /// The managers list when the «المدير المالك» picker is offered and
  /// readable; null = no picker (and `admin_id` is never sent).
  AsyncValue<List<Admin>>? _ownerList() {
    if (!canPickDistributorOwner(ref.watch(permissionsProvider))) return null;
    final admins = ref.watch(adminsListProvider);
    if (admins.hasError &&
        admins.error is ApiException &&
        (admins.error as ApiException).status == 403) {
      return null;
    }
    return admins;
  }

  Widget _form(BuildContext context) {
    final owners = _ownerList();
    final checks = _permissions.contains('cards.check');
    final nameField = TextFormField(
      controller: _name,
      enabled: !_isEdit,
      maxLength: 80,
      decoration: InputDecoration(
        labelText: 'اسم الدخول',
        counterText: '',
        helperText: _isEdit
            ? 'اسم الدخول لا يتغيّر بعد الإنشاء.'
            : 'اسم قصير تستخدمه الإدارة لتتبع الموزع داخليًا.',
      ),
      validator: (value) =>
          (value ?? '').trim().isEmpty ? 'اكتب اسم الدخول' : null,
    );
    final displayNameField = TextFormField(
      controller: _displayName,
      maxLength: 120,
      decoration: const InputDecoration(
        labelText: 'الاسم الظاهر',
        counterText: '',
      ),
    );
    final phoneField = TextFormField(
      controller: _phone,
      maxLength: 40,
      keyboardType: TextInputType.phone,
      decoration: const InputDecoration(
        labelText: 'رقم الهاتف',
        counterText: '',
      ),
    );
    final emailField = TextFormField(
      controller: _email,
      maxLength: 160,
      keyboardType: TextInputType.emailAddress,
      decoration: const InputDecoration(
        labelText: 'البريد الإلكتروني',
        counterText: '',
      ),
      validator: validateOptionalEmail,
    );
    const knownStatuses = ['active', 'inactive', 'blocked'];
    final statusField = DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: _status,
      decoration: const InputDecoration(labelText: 'الحالة'),
      items: [
        const DropdownMenuItem(value: 'active', child: Text('مفعّل')),
        const DropdownMenuItem(value: 'inactive', child: Text('غير مفعّل')),
        const DropdownMenuItem(value: 'blocked', child: Text('محظور')),
        // A stored status the form does not offer (e.g. suspended) stays.
        if (!knownStatuses.contains(_status))
          DropdownMenuItem(
            value: _status,
            child: Text(distributorStatusLabel(_status)),
          ),
      ],
      onChanged: (value) => setState(() => _status = value ?? 'active'),
    );
    final creditField = TextFormField(
      controller: _creditLimit,
      keyboardType: decimalKeyboard,
      inputFormatters: numberFieldFormatters,
      decoration: const InputDecoration(labelText: 'حد الائتمان'),
      validator: validateDistributorCreditLimit,
    );
    const creditHint = Text(
      kDistributorCreditLimitHint,
      style: TextStyle(color: AppTokens.textMuted, fontSize: 12),
    );
    final ownerField = owners?.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text(
        'تعذّر جلب قائمة المدراء: ${visibleErrorMessage(e)}',
        style: const TextStyle(color: AppTokens.redInk, fontSize: 12.5),
      ),
      data: (list) => DropdownButtonFormField<int?>(
        key: const ValueKey('distributor-owner'),
        isExpanded: true,
        initialValue: _adminId,
        decoration: const InputDecoration(
          labelText: 'المدير المالك',
          helperText: 'الموزع يتبع لهذا المدير ويظهر ضمن نطاقه فقط.',
        ),
        items: [
          const DropdownMenuItem<int?>(
            value: null,
            child: Text('— بدون مالك —'),
          ),
          for (final a in list)
            DropdownMenuItem<int?>(
              value: a.id,
              child: Text(a.fullName.isEmpty ? a.username : a.fullName),
            ),
          if (_adminId != null && !list.any((a) => a.id == _adminId))
            DropdownMenuItem<int?>(
              value: _adminId,
              child: Text('مدير #$_adminId'),
            ),
        ],
        onChanged: (v) => setState(() {
          _adminId = v;
          _adminTouched = true;
        }),
      ),
    );
    final permissions = _ChoiceSection(
      title: 'صلاحيات الموزع',
      subtitle: 'اختر ما يستطيع الموزع عمله بدل كتابة رموز تقنية.',
      children: [
        for (final option in _permissionOptions)
          HubSwitchRow(
            dense: true,
            label: option.label,
            subtitle: option.description,
            value: _permissions.contains(option.key),
            onChanged: (checked) {
              setState(() {
                if (checked) {
                  _permissions.add(option.key);
                } else {
                  _permissions.remove(option.key);
                }
              });
            },
          ),
      ],
    );
    final Widget scope = checks
        ? _ChoiceSection(
            title: 'نطاق الفحص',
            subtitle: 'يُطبَّق النطاق فورًا على بوابة الفحص الخاصة بالموزع.',
            children: [
              _ScopeOption(
                key: const ValueKey('scope-assigned'),
                title: 'حزم معيّنة فقط',
                description: 'يفحص فقط كروت الحزم المربوطة به — اربط الحزم '
                    'من صفحة تفاصيل الموزع.',
                selected: !_scopeAll,
                onTap: () => setState(() => _scopeAll = false),
              ),
              const SizedBox(height: AppTokens.s4),
              _ScopeOption(
                key: const ValueKey('scope-all'),
                title: 'كل الحزم',
                description:
                    'يفحص أي كرت في النظام دون التقيد بالحزم المربوطة به.',
                selected: _scopeAll,
                onTap: () => setState(() => _scopeAll = true),
              ),
            ],
          )
        : const _ChoiceSection(
            title: 'نطاق البيانات',
            subtitle: 'النظام يعرض للموزع الحزم التي تربطها به الإدارة فقط.',
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.verified_user_outlined,
                    size: 20,
                    color: AppTokens.brandInk,
                  ),
                  SizedBox(width: AppTokens.s8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الحزم المعيّنة فقط',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'لتوسيع وصول الموزع، اربط حزمًا إضافية من صفحة تفاصيل الموزع.',
                          style: TextStyle(
                            color: AppTokens.textMuted,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
    final portalField = checks
        ? TextFormField(
            key: const ValueKey('portal-password'),
            controller: _portalPassword,
            obscureText: _obscurePortal,
            maxLength: 120,
            autofillHints: const [AutofillHints.newPassword],
            decoration: InputDecoration(
              labelText: 'كلمة مرور بوابة الفحص',
              counterText: '',
              hintText: _isEdit
                  ? 'اتركها فارغة للإبقاء على الحالية — املأها لضبطها أو تغييرها'
                  : null,
              helperText: 'تُستخدم مع اسم الدخول أعلاه لدخول بوابة الفحص. '
                  'لا تُعرض الكلمة الحالية أبدًا.',
              helperMaxLines: 2,
              suffixIcon: IconButton(
                tooltip: _obscurePortal ? 'إظهار' : 'إخفاء',
                onPressed: () =>
                    setState(() => _obscurePortal = !_obscurePortal),
                icon: Icon(
                  _obscurePortal
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
          )
        : null;
    final notesField = TextFormField(
      controller: _notes,
      minLines: 2,
      maxLines: 4,
      maxLength: 500,
      decoration: const InputDecoration(labelText: 'ملاحظات'),
    );
    final saveLabel = _isEdit ? 'حفظ التعديلات' : 'حفظ الموزع';
    final saveItem = ActionItem(
      icon: Icons.save,
      label: _saving ? 'جار الحفظ' : saveLabel,
      primary: true,
      onPressed: _saving ? null : _save,
    );
    void back() {
      if (_isEdit) {
        context.goNamed(
          'distributor-detail',
          pathParameters: {'id': '${widget.distributorId}'},
        );
      } else {
        context.goNamed('distributors');
      }
    }

    return Form(
      key: _formKey,
      // Errors re-check while typing: «اكتب اسم الدخول» no longer stays
      // after the field is filled.
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            title: _isEdit ? 'تعديل الموزع' : 'إضافة موزع',
            inlineActions: true,
            leading: IconButton(
              tooltip: 'رجوع',
              onPressed: _saving ? null : back,
              icon: const Icon(Icons.arrow_back),
            ),
            actions: [
              SizedBox(
                width: 96,
                child: HubActionButton(
                  item: ActionItem(
                    icon: Icons.save,
                    label: 'حفظ',
                    primary: true,
                    onPressed: _saving ? null : _save,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTokens.s12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth > 760;
                  if (!wide) {
                    // Phones: short fields in pairs to halve the height.
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        nameField,
                        const SizedBox(height: AppTokens.s12),
                        FormFieldPair(
                          first: displayNameField,
                          second: phoneField,
                        ),
                        const SizedBox(height: AppTokens.s12),
                        emailField,
                        const SizedBox(height: AppTokens.s12),
                        FormFieldPair(first: statusField, second: creditField),
                        const SizedBox(height: AppTokens.s4),
                        creditHint,
                        if (ownerField != null) ...[
                          const SizedBox(height: AppTokens.s12),
                          ownerField,
                        ],
                        const SizedBox(height: AppTokens.s12),
                        permissions,
                        if (portalField != null) ...[
                          const SizedBox(height: AppTokens.s12),
                          portalField,
                        ],
                        const SizedBox(height: AppTokens.s12),
                        scope,
                        const SizedBox(height: AppTokens.s12),
                        notesField,
                      ],
                    );
                  }
                  return Wrap(
                    spacing: AppTokens.s16,
                    runSpacing: AppTokens.s16,
                    children: [
                      _Box(wide: wide, child: nameField),
                      _Box(wide: wide, child: displayNameField),
                      _Box(wide: wide, child: phoneField),
                      _Box(wide: wide, child: emailField),
                      _Box(wide: wide, child: statusField),
                      _Box(
                        wide: wide,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            creditField,
                            const SizedBox(height: AppTokens.s4),
                            creditHint,
                          ],
                        ),
                      ),
                      if (ownerField != null)
                        _Box(wide: wide, child: ownerField),
                      SizedBox(width: double.infinity, child: permissions),
                      if (portalField != null)
                        SizedBox(width: double.infinity, child: portalField),
                      SizedBox(width: double.infinity, child: scope),
                      SizedBox(width: double.infinity, child: notesField),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: AppTokens.s12),
          ActionBar(items: [saveItem]),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_permissions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر صلاحية واحدة على الأقل للموزع.')),
      );
      return;
    }
    // `admin_id` only when the picker was offered AND its list loaded (and,
    // on edit, the owner was actually changed) — never a blind null that
    // would drop the current owner.
    final owners = _ownerList();
    final includeAdmin =
        owners != null && owners.hasValue && (!_isEdit || _adminTouched);
    final permissions = _permissions.toList()..sort();
    final scope =
        distributorScopePayload(all: _scopeAll, existing: _existingScope);
    final creditLimit = parseDistributorCreditLimit(_creditLimit.text);
    final portalPassword =
        _permissions.contains('cards.check') ? _portalPassword.text.trim() : '';
    setState(() => _saving = true);
    try {
      final repo = ref.read(distributorsRepositoryProvider);
      final int? id;
      if (_isEdit) {
        id = widget.distributorId;
        await repo.update(
          id!,
          distributorPatchBody(
            displayName: _displayName.text.trim(),
            phone: _phone.text.trim(),
            email: _email.text.trim(),
            status: _status,
            creditLimit: creditLimit,
            notes: _notes.text.trim(),
            permissions: permissions,
            scope: scope,
            includeAdmin: includeAdmin,
            adminId: _adminId,
            portalPassword: portalPassword,
          ),
        );
        ref.invalidate(distributorSummaryProvider(id));
      } else {
        final created = await repo.create(
          Distributor(
            name: _name.text.trim(),
            displayName: _displayName.text.trim(),
            email: _email.text.trim(),
            phone: _phone.text.trim(),
            status: _status,
            permissions: permissions,
            scope: scope,
            creditLimit: creditLimit,
            notes: _notes.text.trim(),
            adminId: includeAdmin ? _adminId : null,
          ),
          portalPassword: portalPassword,
        );
        id = created.id;
      }
      ref.invalidate(distributorsListProvider);
      if (mounted) {
        context.goNamed(
          'distributor-detail',
          pathParameters: {'id': '$id'},
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(visibleErrorMessage(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _ChoiceSection extends StatelessWidget {
  const _ChoiceSection({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTokens.bg,
        borderRadius: BorderRadius.circular(AppTokens.r12),
        border: Border.all(color: AppTokens.border),
      ),
      // Transparent Material so child ListTiles have a Material ancestor for
      // their ink without painting over the DecoratedBox background.
      child: Material(
        type: MaterialType.transparency,
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.s12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppTokens.sidebarBg,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppTokens.textMuted,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: AppTokens.s4),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

/// One «نطاق الفحص» choice (radio-like row).
class _ScopeOption extends StatelessWidget {
  const _ScopeOption({
    super.key,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppTokens.brandSoft : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.r10),
        side: BorderSide(
          color: selected ? AppTokens.brand : AppTokens.border,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.r10),
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.s8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                size: 18,
                color: selected ? AppTokens.brandInk : AppTokens.textMuted,
              ),
              const SizedBox(width: AppTokens.s8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      description,
                      style: const TextStyle(
                        color: AppTokens.textMuted,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionOption {
  const _PermissionOption({
    required this.key,
    required this.label,
    required this.description,
  });

  final String key;
  final String label;
  final String description;
}

class _Box extends StatelessWidget {
  const _Box({required this.wide, required this.child});

  final bool wide;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: wide ? 320 : double.infinity,
      child: child,
    );
  }
}
