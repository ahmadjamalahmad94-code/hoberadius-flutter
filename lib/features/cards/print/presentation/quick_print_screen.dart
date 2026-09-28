import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/hub_switch_row.dart';
import '../application/quick_print_controller.dart';
import '../data/quick_print_repository.dart';
import 'print_job_flow.dart';

/// «طباعة الكروت» — the web «منشئ كروت PDF» in the app.
///
/// Layout (owner's pick): live preview first in its own card, then the saved
/// designs as chips, then the settings sections. Every pixel of the preview
/// comes from the server's print engine (see [QuickPrintController]).
class QuickPrintScreen extends ConsumerStatefulWidget {
  const QuickPrintScreen({super.key, required this.batchId});
  final int batchId;

  @override
  ConsumerState<QuickPrintScreen> createState() => _QuickPrintScreenState();
}

class _QuickPrintScreenState extends ConsumerState<QuickPrintScreen> {
  int get batchId => widget.batchId;

  /// The in-page preview card; when it scrolls out of sight a floating copy
  /// pins under the top bar (owner request: see every edit without scrolling
  /// back up).
  final _previewKey = GlobalKey();
  final _floating = OverlayPortalController();
  ScrollPosition? _position;
  Rect? _viewport;
  double _cardLeft = 0;
  double _cardWidth = 0;
  bool _dismissed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final pos = Scrollable.maybeOf(context)?.position;
    if (pos != _position) {
      _position?.removeListener(_onScroll);
      _position = pos?..addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    _position?.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    final scrollBox =
        Scrollable.maybeOf(context)?.context.findRenderObject() as RenderBox?;
    final cardBox =
        _previewKey.currentContext?.findRenderObject() as RenderBox?;
    if (scrollBox == null || cardBox == null || !cardBox.attached) return;
    final vpTop = scrollBox.localToGlobal(Offset.zero);
    final cardTop = cardBox.localToGlobal(Offset.zero);
    final cardBottom = cardTop.dy + cardBox.size.height;
    // Float once most of the card is above the visible area.
    final hidden = cardBottom < vpTop.dy + 120;
    _viewport = vpTop & scrollBox.size;
    _cardLeft = cardTop.dx;
    _cardWidth = cardBox.size.width;
    if (!hidden) _dismissed = false;
    final show = hidden && !_dismissed;
    if (show && !_floating.isShowing) {
      _floating.show();
    } else if (!show && _floating.isShowing) {
      _floating.hide();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = quickPrintControllerProvider(batchId);
    final st = ref.watch(provider);
    final ctl = ref.read(provider.notifier);

    if (st.loading) {
      return const Padding(
        padding: EdgeInsets.all(48),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (st.error.isNotEmpty) {
      return _Message(
        icon: Icons.print_disabled_outlined,
        text: st.error,
        onBack: () => _back(context),
      );
    }

    return OverlayPortal(
      controller: _floating,
      overlayLocation: OverlayChildLocation.rootOverlay,
      // The shell's pages live inside one scroll view (and its navigator's
      // overlay scrolls with them) — pin to the app-wide overlay instead.
      overlayChildBuilder: (_) => _FloatingPreview(
        batchId: batchId,
        viewport: _viewport,
        left: _cardLeft,
        width: _cardWidth,
        onClose: () {
          _dismissed = true;
          _floating.hide();
        },
        onJumpUp: () => _position?.animateTo(
          0,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            subtitle: 'حزمة ${st.batchCode}'
                '${st.batchCards > 0 ? ' · ${st.batchCards} كرت' : ''}',
            onBack: () => _back(context),
            onPrint:
                st.saving ? null : () => runPrintFlow(context, ref, batchId),
          ),
          const SizedBox(height: AppTokens.s12),
          KeyedSubtree(
            key: _previewKey,
            child: _PreviewCard(st: st, ctl: ctl),
          ),
          const SizedBox(height: AppTokens.s12),
          _DesignCard(st: st, ctl: ctl),
          const SizedBox(height: AppTokens.s12),
          _CredentialsCard(st: st, ctl: ctl),
          const SizedBox(height: AppTokens.s12),
          _PositionsCard(st: st, ctl: ctl),
          const SizedBox(height: AppTokens.s12),
          _SheetCard(st: st, ctl: ctl),
          const SizedBox(height: AppTokens.s16),
          _SaveButton(st: st, ctl: ctl),
          const SizedBox(height: AppTokens.s16),
        ],
      ),
    );
  }

  void _back(BuildContext context) {
    final r = GoRouter.of(context);
    if (r.canPop()) {
      r.pop();
    } else {
      context.goNamed(
        'card-batch-detail',
        pathParameters: {'id': '$batchId'},
      );
    }
  }
}

// ─── header ──────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.subtitle,
    required this.onBack,
    required this.onPrint,
  });
  final String subtitle;
  final VoidCallback onBack;
  final VoidCallback? onPrint;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        IconButton(
          tooltip: 'رجوع',
          onPressed: onBack,
          icon: const Icon(Icons.arrow_forward),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'طباعة الكروت',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTokens.sidebarBg,
                ),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.bodySmall?.copyWith(color: AppTokens.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppTokens.s8),
        FilledButton.icon(
          onPressed: onPrint,
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(horizontal: 18),
            shape: const StadiumBorder(),
            textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          icon: const Icon(Icons.print_outlined, size: 20),
          label: const Text('طباعة'),
        ),
      ],
    );
  }
}

// ─── shared section shell ────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.child,
    this.icon,
    this.subtitle,
    this.trailing,
  });
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppTokens.s16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTokens.brandLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTokens.brandSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppTokens.brand, size: 22),
                ),
                const SizedBox(width: AppTokens.s12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppTokens.sidebarBg,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: text.bodySmall?.copyWith(
                          color: AppTokens.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: AppTokens.s12),
          child,
        ],
      ),
    );
  }
}

// ─── floating preview (pinned while editing further down) ─────────────

class _FloatingPreview extends ConsumerWidget {
  const _FloatingPreview({
    required this.batchId,
    required this.viewport,
    required this.left,
    required this.width,
    required this.onClose,
    required this.onJumpUp,
  });
  final int batchId;
  final Rect? viewport;
  final double left;
  final double width;
  final VoidCallback onClose;
  final VoidCallback onJumpUp;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vp = viewport;
    if (vp == null || width <= 0) return const SizedBox.shrink();
    final st = ref.watch(quickPrintControllerProvider(batchId));
    final png = st.previewPng;
    final card = st.mode == PreviewMode.card;
    // A third of the visible area at most, so the settings stay usable.
    final maxH = (vp.height * (card ? 0.34 : 0.4)).clamp(140.0, 300.0);
    return Positioned(
      top: vp.top + 6,
      left: left,
      width: width,
      child: Material(
        color: Colors.white,
        elevation: 10,
        shadowColor: const Color(0x55000000),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.visibility_outlined,
                    size: 18,
                    color: AppTokens.brand,
                  ),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'المعاينة الحية',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppTokens.sidebarBg,
                      ),
                    ),
                  ),
                  if (st.previewBusy)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  IconButton(
                    tooltip: 'للأعلى',
                    visualDensity: VisualDensity.compact,
                    onPressed: onJumpUp,
                    icon: const Icon(Icons.vertical_align_top, size: 20),
                  ),
                  IconButton(
                    tooltip: 'إخفاء',
                    visualDensity: VisualDensity.compact,
                    onPressed: onClose,
                    icon: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
              Container(
                height: maxH,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTokens.surfaceTinted,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(8),
                child: png == null
                    ? const Icon(
                        Icons.image_outlined,
                        color: AppTokens.textMuted,
                      )
                    : card
                        ? _DraggableCard(
                            st: st,
                            ctl: ref.read(
                              quickPrintControllerProvider(batchId).notifier,
                            ),
                            maxHeight: maxH - 16,
                          )
                        : AnimatedOpacity(
                            duration: const Duration(milliseconds: 150),
                            opacity: st.previewBusy ? 0.6 : 1,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(card ? 8 : 2),
                              child: Image.memory(
                                png,
                                fit: BoxFit.contain,
                                gaplessPlayback: true,
                                filterQuality: FilterQuality.medium,
                              ),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 1. live preview ─────────────────────────────────────────────────

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.st, required this.ctl});
  final QuickPrintState st;
  final QuickPrintController ctl;

  @override
  Widget build(BuildContext context) {
    final card = st.mode == PreviewMode.card;
    final png = st.previewPng;
    final maxH = card ? 340.0 : 520.0;
    String? templateName;
    for (final t in st.templates) {
      if ('${t['id']}' == '${st.templateId}') templateName = '${t['name']}';
    }
    return _Section(
      icon: Icons.visibility_outlined,
      title: 'المعاينة الحية',
      subtitle: 'غيّر التصميم وشاهد النتيجة فورًا — نفس ما سيُطبع',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<PreviewMode>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: PreviewMode.card,
                icon: Icon(Icons.credit_card, size: 18),
                label: Text('الكرت'),
              ),
              ButtonSegment(
                value: PreviewMode.page,
                icon: Icon(Icons.description_outlined, size: 18),
                label: Text('الصفحة'),
              ),
            ],
            selected: {st.mode},
            onSelectionChanged: (s) => ctl.setMode(s.first),
          ),
          const SizedBox(height: AppTokens.s12),
          Container(
            constraints: BoxConstraints(minHeight: 180, maxHeight: maxH),
            alignment: Alignment.center,
            padding: const EdgeInsets.all(AppTokens.s12),
            decoration: BoxDecoration(
              color: AppTokens.surfaceTinted,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (png != null && card)
                  _DraggableCard(st: st, ctl: ctl, maxHeight: maxH - 24),
                if (png != null && !card)
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 150),
                    opacity: st.previewBusy ? 0.55 : 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(card ? 10 : 2),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 14,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(card ? 10 : 2),
                        child: Image.memory(
                          png,
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                          filterQuality: FilterQuality.medium,
                        ),
                      ),
                    ),
                  ),
                if (st.previewBusy)
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                if (!st.previewBusy && png == null && st.previewError.isEmpty)
                  const Icon(
                    Icons.image_outlined,
                    color: AppTokens.textMuted,
                    size: 40,
                  ),
              ],
            ),
          ),
          if (st.previewError.isNotEmpty) ...[
            const SizedBox(height: AppTokens.s8),
            Text(
              st.previewError,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTokens.red),
            ),
          ],
          const SizedBox(height: AppTokens.s12),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppTokens.brandSoft,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                st.templateId == 0
                    ? 'تصميم جديد (غير محفوظ)'
                    : 'القالب: ${templateName ?? ''}${st.dirty ? ' • معدّل' : ''}',
                style: const TextStyle(
                  color: AppTokens.brandInk,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 2. design: saved templates, name, image, orientation ────────────

class _DesignCard extends StatefulWidget {
  const _DesignCard({required this.st, required this.ctl});
  final QuickPrintState st;
  final QuickPrintController ctl;

  @override
  State<_DesignCard> createState() => _DesignCardState();
}

class _DesignCardState extends State<_DesignCard> {
  late final TextEditingController _name =
      TextEditingController(text: widget.st.form.name);
  bool _picking = false;

  @override
  void didUpdateWidget(covariant _DesignCard old) {
    super.didUpdateWidget(old);
    if (old.st.templateId != widget.st.templateId &&
        _name.text != widget.st.form.name) {
      _name.text = widget.st.form.name;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    setState(() => _picking = true);
    try {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp'],
        withData: true,
      );
      final file = res?.files.single;
      final bytes = file?.bytes;
      if (file == null || bytes == null) return;
      final ext = (file.extension ?? '').toLowerCase();
      final mime = ext == 'png'
          ? 'image/png'
          : ext == 'webp'
              ? 'image/webp'
              : 'image/jpeg';
      final err = await widget.ctl.setImage(bytes, file.name, mime);
      if (err != null && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(err)));
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = widget.st;
    final ctl = widget.ctl;
    return _Section(
      icon: Icons.style_outlined,
      title: 'التصميم',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppTokens.s8,
            runSpacing: AppTokens.s8,
            children: [
              for (final t in st.templates)
                _ChoiceChip(
                  label: '${t['name']}',
                  selected: '${t['id']}' == '${st.templateId}',
                  onTap: () => ctl.selectTemplate(
                    int.tryParse('${t['id']}') ?? 0,
                  ),
                ),
              _ChoiceChip(
                label: 'تصميم جديد',
                icon: Icons.add,
                selected: st.templateId == 0,
                onTap: () => ctl.selectTemplate(0),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s12),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'اسم القالب'),
            onChanged: (v) => ctl.updateForm((f) => f.copyWith(name: v)),
          ),
          const SizedBox(height: AppTokens.s12),
          OutlinedButton.icon(
            onPressed: _picking ? null : _pickImage,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
              shape: const StadiumBorder(),
            ),
            icon: _picking
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_outlined),
            label: Text(
              st.form.hasImage ? 'تغيير صورة الكارت' : 'رفع صورة الكارت',
            ),
          ),
          const SizedBox(height: AppTokens.s12),
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: true,
                icon: Icon(Icons.stay_current_portrait, size: 18),
                label: Text('عمودي'),
              ),
              ButtonSegment(
                value: false,
                icon: Icon(Icons.stay_current_landscape, size: 18),
                label: Text('أفقي'),
              ),
            ],
            selected: {st.form.vertical},
            onSelectionChanged: (s) =>
                ctl.updateForm((f) => f.withOrientation(s.first)),
          ),
        ],
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppTokens.brandInk : AppTokens.textSecondary;
    return Material(
      color: selected ? AppTokens.brandSoft : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? AppTokens.brand : AppTokens.borderStrong,
          width: selected ? 1.6 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected || icon != null) ...[
                Icon(selected ? Icons.check : icon, size: 16, color: fg),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(color: fg, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 3. username / password / QR ────────────────────────────────────

const _surfaceSwatches = [
  '#e8f7fb',
  '#ffffff',
  '#fde68a',
  '#dcfce7',
  '#fee2e2',
  '#ede9fe',
  '#0f172a',
];

class _CredentialsCard extends StatelessWidget {
  const _CredentialsCard({required this.st, required this.ctl});
  final QuickPrintState st;
  final QuickPrintController ctl;

  @override
  Widget build(BuildContext context) {
    final f = st.form;
    return _Section(
      icon: Icons.pin_outlined,
      title: 'اليوزر والباسورد',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SliderRow(
            label: 'حجم خط اسم المستخدم',
            value: f.usernameFontSize,
            min: 0,
            max: 36,
            divisions: 72,
            display: f.usernameFontSize == 0
                ? 'تلقائي'
                : '${_trim(f.usernameFontSize)} pt',
            onChanged: (v) =>
                ctl.updateForm((x) => x.copyWith(usernameFontSize: v)),
          ),
          if (!st.noPassword)
            _SliderRow(
              label: 'حجم خط كلمة المرور',
              value: f.passwordFontSize,
              min: 0,
              max: 36,
              divisions: 72,
              display: f.passwordFontSize == 0
                  ? 'تلقائي'
                  : '${_trim(f.passwordFontSize)} pt',
              onChanged: (v) =>
                  ctl.updateForm((x) => x.copyWith(passwordFontSize: v)),
            ),
          HubSwitchRow(
            dense: true,
            icon: Icons.qr_code_2,
            label: 'إظهار QR',
            value: f.showQr,
            onChanged: (v) => ctl.updateForm((x) => x.copyWith(showQr: v)),
          ),
          if (f.showQr) _LoginUrlField(st: st, ctl: ctl),
          HubSwitchRow(
            dense: true,
            icon: Icons.sell_outlined,
            label: 'إظهار السعر',
            value: f.showPrice,
            onChanged: (v) => ctl.updateForm((x) => x.copyWith(showPrice: v)),
          ),
          HubSwitchRow(
            dense: true,
            icon: Icons.format_color_fill,
            label: 'خلفية خلف الأرقام',
            value: f.surfaceOn,
            onChanged: (v) => ctl.updateForm((x) => x.copyWith(surfaceOn: v)),
          ),
          if (f.surfaceOn) ...[
            const SizedBox(height: AppTokens.s4),
            Wrap(
              spacing: AppTokens.s8,
              runSpacing: AppTokens.s8,
              children: [
                for (final hex in _surfaceSwatches)
                  _Swatch(
                    hex: hex,
                    selected: f.usernameSurfaceColor.toLowerCase() == hex,
                    onTap: () => ctl.updateForm((x) => x.withSurfaceColor(hex)),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LoginUrlField extends StatefulWidget {
  const _LoginUrlField({required this.st, required this.ctl});
  final QuickPrintState st;
  final QuickPrintController ctl;

  @override
  State<_LoginUrlField> createState() => _LoginUrlFieldState();
}

class _LoginUrlFieldState extends State<_LoginUrlField> {
  late final TextEditingController _c =
      TextEditingController(text: widget.st.form.hotspotLoginUrl);

  @override
  void didUpdateWidget(covariant _LoginUrlField old) {
    super.didUpdateWidget(old);
    if (old.st.templateId != widget.st.templateId) {
      _c.text = widget.st.form.hotspotLoginUrl;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final empty = widget.st.form.hotspotLoginUrl.trim().isEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _c,
            textDirection: TextDirection.ltr,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'رابط دخول الهوت سبوت (للـQR)',
              hintText: '10.5.50.1',
            ),
            onChanged: (v) =>
                widget.ctl.updateForm((f) => f.copyWith(hotspotLoginUrl: v)),
          ),
          if (empty)
            Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTokens.amberSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'بدون رابط الدخول لن يدخل الزبون تلقائيًا عند مسح QR.',
                style: TextStyle(color: AppTokens.amberInk, fontSize: 12.5),
              ),
            ),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.hex,
    required this.selected,
    required this.onTap,
  });
  final String hex;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse('FF${hex.substring(1)}', radix: 16));
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? AppTokens.brand : AppTokens.borderStrong,
            width: selected ? 3 : 1,
          ),
        ),
        child: selected
            ? Icon(
                Icons.check,
                size: 18,
                color: color.computeLuminance() > 0.5
                    ? AppTokens.brandInk
                    : Colors.white,
              )
            : null,
      ),
    );
  }
}

// ─── 4. element positions: sliders from the REAL place + drag ─────────

class _PositionsCard extends StatelessWidget {
  const _PositionsCard({required this.st, required this.ctl});
  final QuickPrintState st;
  final QuickPrintController ctl;

  @override
  Widget build(BuildContext context) {
    final f = st.form;
    return _Section(
      icon: Icons.open_with,
      title: 'أماكن العناصر',
      subtitle: 'اسحب العنصر بإصبعك على المعاينة، أو حرّك الشريط',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ElementSliders(
            st: st,
            ctl: ctl,
            name: 'username',
            label: 'اسم المستخدم',
            x: f.usernameX,
            y: f.usernameY,
          ),
          if (!st.noPassword)
            _ElementSliders(
              st: st,
              ctl: ctl,
              name: 'password',
              label: 'كلمة المرور',
              x: f.passwordX,
              y: f.passwordY,
            ),
          if (f.showQr) ...[
            _ElementSliders(
              st: st,
              ctl: ctl,
              name: 'qr',
              label: 'QR',
              x: f.qrX,
              y: f.qrY,
            ),
            _SliderRow(
              label: 'حجم الباركود',
              value: f.qrSizePct,
              min: 0,
              max: 48,
              divisions: 96,
              display: f.qrSizePct == 0 ? 'تلقائي' : '${_trim(f.qrSizePct)}٪',
              onChanged: (v) => ctl.updateForm((q) => q.copyWith(qrSizePct: v)),
            ),
          ],
        ],
      ),
    );
  }
}

class _ElementSliders extends StatelessWidget {
  const _ElementSliders({
    required this.st,
    required this.ctl,
    required this.name,
    required this.label,
    required this.x,
    required this.y,
  });
  final QuickPrintState st;
  final QuickPrintController ctl;
  final String name;
  final String label;

  /// Saved values; 0 = automatic.
  final double x;
  final double y;

  @override
  Widget build(BuildContext context) {
    final els = st.elements;
    final box = els?.boxes[name];
    final auto = x == 0 && y == 0;
    // Start from where the element really is (automatic place included).
    final effX = x > 0 ? x : (box?.x ?? 0.5);
    final effY = y > 0 ? y : (box?.y ?? 0.5);
    final cardW = els?.widthMm ?? st.form.cardWidthMm;
    final cardH = els?.heightMm ?? st.form.cardHeightMm;
    final maxX = (cardW - (box?.w ?? 4)).clamp(1.0, 200.0);
    final maxY = (cardH - (box?.h ?? 4)).clamp(1.0, 200.0);
    int div(double max) => ((max - 0.5) * 2).round().clamp(1, 800);
    return Container(
      margin: const EdgeInsets.only(bottom: AppTokens.s8),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      decoration: BoxDecoration(
        color: AppTokens.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              if (auto)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTokens.brandSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'تلقائي',
                    style: TextStyle(
                      color: AppTokens.brandInk,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                )
              else
                TextButton.icon(
                  onPressed: () => ctl.resetElement(name),
                  icon: const Icon(Icons.restart_alt, size: 18),
                  label: const Text('تلقائي'),
                ),
            ],
          ),
          _SliderRow(
            label: 'أفقي',
            value: effX,
            min: 0.5,
            max: maxX,
            divisions: div(maxX),
            display: '${_trim(effX)} ملم',
            onChanged: (v) => ctl.moveElement(name, v, effY),
          ),
          _SliderRow(
            label: 'رأسي',
            value: effY,
            min: 0.5,
            max: maxY,
            divisions: div(maxY),
            display: '${_trim(effY)} ملم',
            onChanged: (v) => ctl.moveElement(name, effX, v),
          ),
        ],
      ),
    );
  }
}

/// The card preview with its username / password / QR draggable by finger.
/// The image is the server's card PDF (card-sized page), so mm ↔ px is a
/// single scale; a drop writes the same mm anchor the web designer writes.
class _DraggableCard extends StatefulWidget {
  const _DraggableCard({
    required this.st,
    required this.ctl,
    required this.maxHeight,
  });
  final QuickPrintState st;
  final QuickPrintController ctl;
  final double maxHeight;

  @override
  State<_DraggableCard> createState() => _DraggableCardState();
}

class _DraggableCardState extends State<_DraggableCard> {
  String? _active;
  Offset _drag = Offset.zero; // px while dragging
  final Map<String, Offset> _dropped = {}; // mm, until the server catches up

  @override
  void didUpdateWidget(covariant _DraggableCard old) {
    super.didUpdateWidget(old);
    if (!identical(old.st.elements, widget.st.elements)) _dropped.clear();
  }

  @override
  Widget build(BuildContext context) {
    final st = widget.st;
    final png = st.previewPng;
    final els = st.elements;
    if (png == null) return const SizedBox.shrink();
    final wMm = els?.widthMm ?? st.form.cardWidthMm;
    final hMm = els?.heightMm ?? st.form.cardHeightMm;
    final aspect = wMm / hMm;
    final names = [
      'username',
      if (!st.noPassword) 'password',
      if (st.form.showQr) 'qr',
    ];
    return LayoutBuilder(
      builder: (context, c) {
        var w = c.maxWidth;
        var h = w / aspect;
        if (h > widget.maxHeight) {
          h = widget.maxHeight;
          w = h * aspect;
        }
        final k = w / wMm; // px per mm
        return Center(
          child: SizedBox(
            width: w,
            height: h,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 14,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 150),
                        opacity: st.previewBusy ? 0.6 : 1,
                        child: Image.memory(
                          png,
                          fit: BoxFit.fill,
                          gaplessPlayback: true,
                          filterQuality: FilterQuality.medium,
                        ),
                      ),
                    ),
                  ),
                ),
                if (els != null)
                  for (final name in names)
                    if (els.boxes[name] != null)
                      _handle(name, els.boxes[name]!, k, wMm, hMm),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _handle(
    String name,
    ElementBox box,
    double k,
    double wMm,
    double hMm,
  ) {
    final base = _dropped[name] ?? Offset(box.x, box.y);
    final active = _active == name;
    var left = base.dx * k + (active ? _drag.dx : 0);
    var top = base.dy * k + (active ? _drag.dy : 0);
    left = left.clamp(0.0, (wMm - box.w) * k);
    top = top.clamp(0.0, (hMm - box.h) * k);
    return Positioned(
      left: left,
      top: top,
      width: box.w * k,
      height: box.h * k,
      child: RawGestureDetector(
        // Grab the touch at once so the page scroll doesn't steal the drag.
        gestures: {
          ImmediateMultiDragGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<
                  ImmediateMultiDragGestureRecognizer>(
            ImmediateMultiDragGestureRecognizer.new,
            (r) => r.onStart = (_) {
              setState(() {
                _active = name;
                _drag = Offset.zero;
              });
              return _ElementDrag(
                onUpdate: (d) => setState(() => _drag += d),
                onEnd: () {
                  // Read the drag NOW (the closure was built before it).
                  final xMm =
                      ((base.dx * k + _drag.dx) / k).clamp(0.5, wMm - box.w);
                  final yMm =
                      ((base.dy * k + _drag.dy) / k).clamp(0.5, hMm - box.h);
                  setState(() {
                    _dropped[name] = Offset(xMm, yMm);
                    _active = null;
                    _drag = Offset.zero;
                  });
                  widget.ctl.moveElement(name, xMm, yMm);
                },
              );
            },
          ),
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: active
                ? AppTokens.brand.withValues(alpha: 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: active
                  ? AppTokens.brand
                  : Colors.white.withValues(alpha: 0.9),
              width: active ? 2 : 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _ElementDrag extends Drag {
  _ElementDrag({required this.onUpdate, required this.onEnd});
  final ValueChanged<Offset> onUpdate;
  final VoidCallback onEnd;

  @override
  void update(DragUpdateDetails details) => onUpdate(details.delta);

  @override
  void end(DragEndDetails details) => onEnd();

  @override
  void cancel() => onEnd();
}

// ─── 5. sheet layout ─────────────────────────────────────────────────

class _SheetCard extends StatelessWidget {
  const _SheetCard({required this.st, required this.ctl});
  final QuickPrintState st;
  final QuickPrintController ctl;

  @override
  Widget build(BuildContext context) {
    final s = st.sheet;
    return _Section(
      icon: Icons.grid_view_outlined,
      title: 'توزيع الورقة (A4)',
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppTokens.brandSoft,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          '${s.perPage} كرت/صفحة',
          style: const TextStyle(
            color: AppTokens.brandInk,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SliderRow(
            label: 'عدد البطاقات بالعرض',
            value: s.columns.toDouble(),
            min: 1,
            max: 8,
            divisions: 7,
            display: '${s.columns}',
            onChanged: (v) =>
                ctl.updateSheet((x) => x.copyWith(columns: v.round())),
          ),
          _SliderRow(
            label: 'عدد البطاقات بالطول',
            value: s.rows.toDouble(),
            min: 1,
            max: 12,
            divisions: 11,
            display: '${s.rows}',
            onChanged: (v) =>
                ctl.updateSheet((x) => x.copyWith(rows: v.round())),
          ),
          const SizedBox(height: AppTokens.s4),
          const Text(
            'المسافة بين البطاقات',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppTokens.s8),
          SegmentedButton<double>(
            showSelectedIcon: false,
            segments: [
              for (final g in {1.0, 2.0, 3.0, 4.0, s.gapMm}.toList()..sort())
                ButtonSegment(value: g, label: Text('${_trim(g)} ملم')),
            ],
            selected: {s.gapMm},
            onSelectionChanged: (v) =>
                ctl.updateSheet((x) => x.copyWith(gapMm: v.first)),
          ),
          const SizedBox(height: AppTokens.s12),
          _SliderRow(
            label: 'الهوامش حول الورقة',
            value: s.marginMm,
            min: 0,
            max: 40,
            divisions: 80,
            display: '${_trim(s.marginMm)} ملم',
            onChanged: (v) => ctl.updateSheet((x) => x.copyWith(marginMm: v)),
          ),
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: false,
                icon: Icon(Icons.crop_portrait, size: 18),
                label: Text('طولي'),
              ),
              ButtonSegment(
                value: true,
                icon: Icon(Icons.crop_landscape, size: 18),
                label: Text('أفقي'),
              ),
            ],
            selected: {s.landscape},
            onSelectionChanged: (v) =>
                ctl.updateSheet((x) => x.copyWith(landscape: v.first)),
          ),
          const SizedBox(height: AppTokens.s4),
          HubSwitchRow(
            dense: true,
            icon: Icons.content_cut,
            label: 'خطوط القصّ بين البطاقات',
            value: s.cutLines,
            onChanged: (v) => ctl.updateSheet((x) => x.copyWith(cutLines: v)),
          ),
        ],
      ),
    );
  }
}

// ─── bits ────────────────────────────────────────────────────────────

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.display,
    required this.onChanged,
  });
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String display;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: AppTokens.surfaceTinted,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                display,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 5,
            activeTrackColor: AppTokens.brand,
            inactiveTrackColor: AppTokens.brandSoft2,
            thumbColor: AppTokens.brand,
            overlayColor: AppTokens.brand.withValues(alpha: 0.12),
            // No tick dots: dozens of steps turn the track into a dotted line.
            tickMarkShape: SliderTickMarkShape.noTickMark,
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.st, required this.ctl});
  final QuickPrintState st;
  final QuickPrintController ctl;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: st.saving
          ? null
          : () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                await ctl.save();
                messenger.showSnackBar(
                  const SnackBar(content: Text('تم حفظ التصميم')),
                );
              } catch (e) {
                messenger.showSnackBar(SnackBar(content: Text('$e')));
              }
            },
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: const StadiumBorder(),
        side: const BorderSide(color: AppTokens.brand),
      ),
      icon: st.saving
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.save_outlined),
      label: Text(st.templateId == 0 ? 'حفظ كتصميم جديد' : 'حفظ التصميم'),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.text,
    required this.onBack,
  });
  final IconData icon;
  final String text;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppTokens.textMuted),
          const SizedBox(height: AppTokens.s12),
          Text(text, textAlign: TextAlign.center),
          const SizedBox(height: AppTokens.s16),
          OutlinedButton(onPressed: onBack, child: const Text('رجوع')),
        ],
      ),
    );
  }
}

String _trim(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
