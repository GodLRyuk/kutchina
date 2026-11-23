import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';

// ---------------------------------------------------------------------------
// Base card
// ---------------------------------------------------------------------------

/// White rounded card with soft shadow.
class AreaWhiteCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const AreaWhiteCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.commandCentreText.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

/// Blue gradient banner.
class AreaHeaderCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const AreaHeaderCard({
    super.key,
    required this.title,
    this.subtitle = 'Area dashboard · Area Sales Manager',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.buttonGradient,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filters
// ---------------------------------------------------------------------------

/// Small label above a field. Shows a red * when [required].
class AreaFieldLabel extends StatelessWidget {
  final String text;
  final bool required;

  const AreaFieldLabel(this.text, {super.key, this.required = false});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: text,
        style: const TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 12,
          color: AppColors.ink,
        ),
        children: [
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: AppColors.red),
            ),
        ],
      ),
    );
  }
}

/// One selectable chip (Today / Week / Month).
class AreaPeriodChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const AreaPeriodChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        height: 45,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.commandCentreText : AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected ? AppColors.commandCentreText : AppColors.line,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.display,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? AppColors.white : AppColors.navNormal,
          ),
        ),
      ),
    );
  }
}

/// Row of [AreaPeriodChip]s sharing the width equally.
class AreaPeriodSelector extends StatelessWidget {
  final List<String> periods;
  final String selected;
  final ValueChanged<String> onChanged;

  const AreaPeriodSelector({
    super.key,
    required this.periods,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < periods.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: AreaPeriodChip(
              label: periods[i],
              selected: selected == periods[i],
              onTap: () => onChanged(periods[i]),
            ),
          ),
        ],
      ],
    );
  }
}

/// "Select" dropdown for the Scope field. Shows [errorText] in red
/// under the field when it is not null.
class AreaScopeDropdown extends StatelessWidget {
  final List<String> scopes;
  final String? value;
  final String? errorText;
  final ValueChanged<String?> onChanged;

  const AreaScopeDropdown({
    super.key,
    required this.scopes,
    required this.value,
    required this.onChanged,
    this.errorText,
  });

  OutlineInputBorder _border(Color c, {double width = 1}) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadius.md),
    borderSide: BorderSide(color: c, width: width),
  );

  @override
  
Widget build(BuildContext context) {
  return DropdownMenu<String>(
    initialSelection: value,
    expandedInsets: EdgeInsets.zero,   
    hintText: 'Select',
    errorText: errorText,
    requestFocusOnTap: false,
    menuHeight: 220,
    textStyle: const TextStyle(
      fontFamily: AppFonts.body,
      fontSize: 13,
      color: AppColors.ink,
    ),
    inputDecorationTheme: InputDecorationTheme(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      hintStyle: const TextStyle(
        fontFamily: AppFonts.body,
        fontSize: 13,
        color: AppColors.steel,
      ),
      errorStyle: const TextStyle(
        fontFamily: AppFonts.body,
        fontSize: 11,
        color: AppColors.red,
      ),
      border: _border(AppColors.line),
      enabledBorder: _border(AppColors.line),
      focusedBorder: _border(AppColors.topAreaBg, width: 1.8),
      errorBorder: _border(AppColors.red),
      focusedErrorBorder: _border(AppColors.red, width: 1.8),
    ),
    menuStyle: MenuStyle(
      backgroundColor: const WidgetStatePropertyAll(AppColors.white),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: const BorderSide(color: AppColors.line),
        ),
      ),
    ),
    dropdownMenuEntries: scopes
        .map((s) => DropdownMenuEntry<String>(value: s, label: s))
        .toList(),
    onSelected: onChanged,
  );
  
}
}

/// Card holding the Period chips and the Scope dropdown.
class AreaFiltersCard extends StatelessWidget {
  final List<String> periods;
  final String selectedPeriod;
  final ValueChanged<String> onPeriodChanged;

  final List<String> scopes;
  final String? selectedScope;
  final String? scopeError;
  final ValueChanged<String?> onScopeChanged;

  const AreaFiltersCard({
    super.key,
    required this.periods,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    required this.scopes,
    required this.selectedScope,
    required this.onScopeChanged,
    this.scopeError,
  });

  @override
  Widget build(BuildContext context) {
    return AreaWhiteCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 22, 14, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
           
            const AreaFieldLabel('Period'),
            const SizedBox(height: 8),
            AreaPeriodSelector(
              periods: periods,
              selected: selectedPeriod,
              onChanged: onPeriodChanged,
            ),
            const SizedBox(height: 16),
            const AreaFieldLabel('Scope', required: true),
            const SizedBox(height: 8),
            AreaScopeDropdown(
              scopes: scopes,
              value: selectedScope,
              errorText: scopeError,
              onChanged: onScopeChanged,
            ),
        
            SizedBox(height: 15,)
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Result
// ---------------------------------------------------------------------------

/// One row inside the result card: coloured icon box + title + subtitle.
class AreaResultRow extends StatelessWidget {
  final Color iconBg;
  final Widget icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const AreaResultRow({
    super.key,
    required this.iconBg,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 76,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: icon,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: AppFonts.display,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 11,
                      color: AppColors.steel,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Result" label + card with the value row and the report row.
class AreaResultCard extends StatelessWidget {
  final String title;
  final String value;
  final VoidCallback? onOpenReport;

  const AreaResultCard({
    super.key,
    required this.title,
    required this.value,
    this.onOpenReport,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            'Result',
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 12,
              color: AppColors.steel,
            ),
          ),
        ),
        AreaWhiteCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Column(
            children: [
              AreaResultRow(
                iconBg: AppColors.rupeeIconBg,
                icon: const Icon(
                  Icons.bar_chart_rounded,
                  size: 20,
                  color: AppColors.regionBlue,
                ),
                title: title,
                subtitle: value,
              ),
              const Divider(height: 1, thickness: 1, color: AppColors.line),
              AreaResultRow(
                iconBg: AppColors.amberLight,
                icon: const Icon(
                  Icons.description_outlined,
                  size: 20,
                  color: AppColors.productOvens,
                ),
                title: 'Compared with last period',
                subtitle: 'Open Reports for full trend',
                onTap: onOpenReport,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Buttons
// ---------------------------------------------------------------------------

/// Gradient primary button (Submit). Shows a spinner while [loading].
class AreaGradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  const AreaGradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return Opacity(
      opacity: enabled || loading ? 1 : 0.55,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          height: 54,
          decoration: BoxDecoration(
            gradient: AppColors.buttonGradient,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: AppColors.white,
                      ),
                    )
                  : Text(
                      label,
                      style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Solid navy secondary button (Cancel).
class AreaCancelButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const AreaCancelButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.highPerformersBg,
          foregroundColor: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: AppFonts.display,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
