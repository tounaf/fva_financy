import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palette & tokens alignés sur le design Stitch FVA Financy.
class AppColors {
  static const Color primary = Color(0xFF1A2B4C);
  static const Color primaryDark = Color(0xFF031636);
  static const Color success = Color(0xFF1B6D24);
  static const Color successSoft = Color(0xFFA0F399);
  static const Color income = Color(0xFF1B6D24);
  static const Color expense = Color(0xFFBA1A1A);
  static const Color warning = Color(0xFFE65100);
  static const Color warningSoft = Color(0xFFFFF3E0);
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Colors.white;
  static const Color onSurface = Color(0xFF191C1D);
  static const Color onSurfaceVariant = Color(0xFF44474E);
  static const Color outline = Color(0xFFC5C6CF);
}

class AppRadii {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.success,
        surface: AppColors.surface,
        error: AppColors.expense,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.background,
    );

    return base.copyWith(
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).apply(
        bodyColor: AppColors.onSurface,
        displayColor: AppColors.onSurface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          side: const BorderSide(color: AppColors.outline, width: 0.6),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF3F4F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
      ),
    );
  }
}

class FvaCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? accent;
  final Color? color;

  const FvaCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.accent,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (accent != null)
                Container(width: 4, color: accent),
              Expanded(
                child: Padding(padding: padding, child: child),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FvaPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;
  final bool loading;

  const FvaPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.color,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? AppColors.primary,
          disabledBackgroundColor: Colors.grey.shade400,
        ),
        icon: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(icon ?? Icons.arrow_forward),
        label: Text(label),
      ),
    );
  }
}

class FvaSummaryTile extends StatelessWidget {
  final String title;
  final String value;
  final Color accent;
  final bool emphasized;

  const FvaSummaryTile({
    super.key,
    required this.title,
    required this.value,
    required this.accent,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    if (emphasized) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ],
        ),
      );
    }

    return FvaCard(
      accent: accent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: accent,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class FvaModificationBanner extends StatelessWidget {
  final String message;

  const FvaModificationBanner({
    super.key,
    this.message =
        'Efa misy data ity daty ity — Mode modification. Modifiez puis resynchronisez.',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.warning,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FvaBrandHeader extends StatelessWidget {
  final String? subtitle;
  final List<Widget>? actions;

  const FvaBrandHeader({super.key, this.subtitle, this.actions});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(18),
          ),
          alignment: Alignment.center,
          child: const Text(
            'F',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FVA Financy',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        ...?actions,
      ],
    );
  }
}

/// Bandeau compact miditra | dépenses | net.
class FvaCompactSummary extends StatelessWidget {
  final String miditraLabel;
  final String miditraValue;
  final String expenseLabel;
  final String expenseValue;
  final String netLabel;
  final String netValue;

  const FvaCompactSummary({
    super.key,
    required this.miditraLabel,
    required this.miditraValue,
    required this.expenseLabel,
    required this.expenseValue,
    required this.netLabel,
    required this.netValue,
  });

  @override
  Widget build(BuildContext context) {
    return FvaCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: _Cell(
              label: miditraLabel,
              value: miditraValue,
              color: AppColors.income,
            ),
          ),
          Container(width: 1, height: 36, color: AppColors.outline.withValues(alpha: 0.5)),
          Expanded(
            child: _Cell(
              label: expenseLabel,
              value: expenseValue,
              color: AppColors.expense,
            ),
          ),
          Container(width: 1, height: 36, color: AppColors.outline.withValues(alpha: 0.5)),
          Expanded(
            child: _Cell(
              label: netLabel,
              value: netValue,
              color: AppColors.primary,
              emphasized: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool emphasized;

  const _Cell({
    required this.label,
    required this.value,
    required this.color,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: emphasized ? 13 : 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

enum FvaStatusKind { completed, pending, synced }

class FvaStatusChip extends StatelessWidget {
  final String label;
  final FvaStatusKind kind;

  const FvaStatusChip({
    super.key,
    required this.label,
    required this.kind,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final IconData icon;
    switch (kind) {
      case FvaStatusKind.completed:
        bg = AppColors.success.withValues(alpha: 0.12);
        fg = AppColors.success;
        icon = Icons.lock;
      case FvaStatusKind.pending:
        bg = AppColors.warningSoft;
        fg = AppColors.warning;
        icon = Icons.sync_problem;
      case FvaStatusKind.synced:
        bg = AppColors.primary.withValues(alpha: 0.1);
        fg = AppColors.primary;
        icon = Icons.check_circle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class FvaEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const FvaEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Icon(icon, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class FvaConfirm {
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirmer',
    String cancelLabel = 'Annuler',
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text(message, style: GoogleFonts.poppins(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(cancelLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: destructive ? AppColors.expense : AppColors.primary,
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class FvaQuantityStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int>? onChanged;
  final bool enabled;

  const FvaQuantityStepper({
    super.key,
    required this.value,
    this.onChanged,
    this.enabled = true,
  });

  Future<void> _openPad(BuildContext context) async {
    if (!enabled || onChanged == null) return;
    final next = await FvaQuantityPad.show(context, initial: value);
    if (next != null) onChanged!(next);
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F5),
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StepBtn(
              icon: Icons.remove,
              onTap: enabled && onChanged != null
                  ? () {
                      HapticFeedback.selectionClick();
                      onChanged!(value > 0 ? value - 1 : 0);
                    }
                  : null,
            ),
            InkWell(
              onTap: enabled ? () => _openPad(context) : null,
              borderRadius: BorderRadius.circular(AppRadii.sm),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                child: Center(
                  child: Text(
                    '$value',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                  ),
                ),
              ),
            ),
            _StepBtn(
              icon: Icons.add,
              onTap: enabled && onChanged != null
                  ? () {
                      HapticFeedback.selectionClick();
                      onChanged!(value + 1);
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StepBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        color: AppColors.primary,
        padding: EdgeInsets.zero,
      ),
    );
  }
}

class FvaQuantityPad {
  static Future<int?> show(BuildContext context, {required int initial}) {
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
      ),
      builder: (ctx) => _QuantityPadSheet(initial: initial),
    );
  }
}

class _QuantityPadSheet extends StatefulWidget {
  final int initial;

  const _QuantityPadSheet({required this.initial});

  @override
  State<_QuantityPadSheet> createState() => _QuantityPadSheetState();
}

class _QuantityPadSheetState extends State<_QuantityPadSheet> {
  late String _digits;

  @override
  void initState() {
    super.initState();
    _digits = widget.initial.toString();
  }

  void _press(String key) {
    HapticFeedback.selectionClick();
    setState(() {
      if (key == 'C') {
        _digits = '0';
      } else if (key == '⌫') {
        _digits = _digits.length <= 1 ? '0' : _digits.substring(0, _digits.length - 1);
      } else {
        if (_digits == '0') {
          _digits = key;
        } else if (_digits.length < 5) {
          _digits = '$_digits$key';
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', 'C', '0', '⌫'];
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Isa / Quantité',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _digits,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            childAspectRatio: 1.6,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: keys.map((k) {
              return Material(
                color: const Color(0xFFF3F4F5),
                borderRadius: BorderRadius.circular(AppRadii.md),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  onTap: () => _press(k),
                  child: Center(
                    child: Text(
                      k,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          FvaPrimaryButton(
            label: 'Ampiditra',
            icon: Icons.check,
            color: AppColors.success,
            onPressed: () => Navigator.of(context).pop(int.tryParse(_digits) ?? 0),
          ),
        ],
      ),
    );
  }
}
