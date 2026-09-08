import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ring_design_system/ring_design_system.dart';

/// Shared navigation and spacing keep every part of the app feeling familiar.
class RingPageScaffold extends StatelessWidget {
  const RingPageScaffold({
    required this.children,
    this.activePath,
    this.scrollKey,
    this.onRefresh,
    super.key,
  });
  final List<Widget> children;
  final String? activePath;
  final String? scrollKey;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    Widget content = SingleChildScrollView(
      key: PageStorageKey(
        scrollKey ?? key?.toString() ?? activePath ?? 'detail',
      ),
      physics: const AlwaysScrollableScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ),
    );
    if (onRefresh != null) {
      content = RefreshIndicator.adaptive(
        onRefresh: onRefresh!,
        color: LibreRingTokens.sage,
        child: content,
      );
    }
    return Scaffold(
      body: SafeArea(bottom: activePath == null, child: content),
      bottomNavigationBar: activePath == null
          ? null
          : RingBottomNav(activePath: activePath!),
    );
  }
}

class RingBottomNav extends StatelessWidget {
  const RingBottomNav({required this.activePath, super.key});
  final String activePath;

  @override
  Widget build(BuildContext context) {
    const items = <(String, String, IconData, IconData)>[
      ('/today', 'Today', Icons.wb_sunny_outlined, Icons.wb_sunny_rounded),
      (
        '/vitals',
        'Vitals',
        Icons.favorite_border_rounded,
        Icons.favorite_rounded,
      ),
      ('/trends', 'Trends', Icons.insights_outlined, Icons.insights_rounded),
      ('/you', 'You', Icons.person_outline_rounded, Icons.person_rounded),
    ];
    final portuguese = Localizations.localeOf(context).languageCode == 'pt';
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Material(
            color: LibreRingTokens.foreground,
            borderRadius: BorderRadius.circular(26),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Row(
                children: List.generate(items.length, (index) {
                  final item = items[index];
                  final selected =
                      activePath == item.$1 ||
                      (index == 1 && activePath == '/metrics');
                  final label = portuguese
                      ? <String>[
                          'Hoje',
                          'Sinais',
                          'Tendências',
                          'Perfil',
                        ][index]
                      : item.$2;
                  void activate() {
                    final shell = StatefulNavigationShell.maybeOf(context);
                    if (shell != null) {
                      if (shell.currentIndex == index) return;
                      RingHaptics.selection();
                      shell.goBranch(index);
                    } else if (!selected ||
                        GoRouterState.of(context).uri.path != item.$1) {
                      RingHaptics.selection();
                      context.go(item.$1);
                    }
                  }

                  return Expanded(
                    child: Semantics(
                      label: label,
                      selected: selected,
                      button: true,
                      onTap: activate,
                      child: ExcludeSemantics(
                        child: InkWell(
                          key: Key('tab-${item.$2.toLowerCase()}'),
                          borderRadius: BorderRadius.circular(20),
                          enableFeedback: false,
                          onTap: activate,
                          child: AnimatedContainer(
                            duration: MediaQuery.disableAnimationsOf(context)
                                ? Duration.zero
                                : LibreRingTokens.fast,
                            curve: LibreRingTokens.curve,
                            constraints: BoxConstraints(
                              minHeight: scale > 1.4 ? 78 : 62,
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 2,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFF3A493E)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  selected ? item.$4 : item.$3,
                                  color: selected
                                      ? Colors.white
                                      : const Color(0xFFBCC5BD),
                                  size: 21,
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  label,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: selected
                                        ? Colors.white
                                        : const Color(0xFFD2D8D1),
                                    fontSize: 11,
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RingSectionHeader extends StatelessWidget {
  const RingSectionHeader({
    required this.title,
    this.action,
    this.onAction,
    super.key,
  });
  final String title;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4, bottom: 12),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final heading = Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -.35,
          ),
        );
        final button = action == null
            ? null
            : TextButton(
                style: TextButton.styleFrom(enableFeedback: false),
                onPressed: onAction == null
                    ? null
                    : () {
                        RingHaptics.action();
                        onAction!();
                      },
                child: Text(action!, style: const TextStyle(fontSize: 12)),
              );
        if (constraints.maxWidth < 400 &&
            MediaQuery.textScalerOf(context).scale(14) > 18) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [heading, ?button],
          );
        }
        return Row(
          children: [
            Expanded(child: heading),
            ?button,
          ],
        );
      },
    ),
  );
}

class RingDaySelector extends StatelessWidget {
  const RingDaySelector({
    required this.selectedDay,
    required this.earliestDay,
    required this.latestDay,
    required this.onChanged,
    super.key,
  });
  final DateTime selectedDay;
  final DateTime earliestDay;
  final DateTime latestDay;
  final ValueChanged<DateTime> onChanged;
  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
  @override
  Widget build(BuildContext context) {
    final selected = _day(selectedDay);
    final last = _day(latestDay);
    final first = _day(earliestDay).isAfter(last) ? last : _day(earliestDay);
    return Row(
      children: [
        IconButton(
          key: const Key('previous-day'),
          tooltip: 'Previous day',
          enableFeedback: false,
          onPressed: selected.isAfter(first)
              ? () {
                  RingHaptics.selection();
                  onChanged(
                    DateTime(selected.year, selected.month, selected.day - 1),
                  );
                }
              : null,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Expanded(
          child: TextButton.icon(
            key: const Key('select-day'),
            style: TextButton.styleFrom(enableFeedback: false),
            icon: const Icon(Icons.calendar_today_outlined, size: 15),
            onPressed: () async {
              RingHaptics.action();
              final date = await showDatePicker(
                context: context,
                initialDate: selected.isBefore(first) ? first : selected,
                firstDate: first,
                lastDate: last,
                helpText: 'Choose a day',
              );
              if (!context.mounted || date == null || date == selected) return;
              RingHaptics.selection();
              onChanged(date);
            },
            label: Text(
              '${selected == last ? 'Today, ' : ''}${DateFormat('d MMM').format(selected)}',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        IconButton(
          key: const Key('next-day'),
          tooltip: 'Next day',
          enableFeedback: false,
          onPressed: selected.isBefore(last)
              ? () {
                  RingHaptics.selection();
                  onChanged(
                    DateTime(selected.year, selected.month, selected.day + 1),
                  );
                }
              : null,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

class RingEmptyState extends StatelessWidget {
  const RingEmptyState({
    required this.title,
    required this.body,
    this.icon = Icons.sensors_outlined,
    this.action,
    this.onAction,
    super.key,
  });
  final String title;
  final String body;
  final IconData icon;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => LibreRingCard(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: LibreRingTokens.sageSoft,
            ),
            child: Icon(icon, color: LibreRingTokens.sage, size: 28),
          ),
          const SizedBox(height: 22),
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              letterSpacing: -.6,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: LibreRingTokens.muted),
          ),
          if (action != null) ...[
            const SizedBox(height: 20),
            LibreRingPrimaryButton(label: action!, onPressed: onAction),
          ],
        ],
      ),
    ),
  );
}

class RingLoadingState extends StatelessWidget {
  const RingLoadingState({super.key});
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Loading your saved ring data',
    liveRegion: true,
    child: ExcludeSemantics(
      child: Column(
        children: [
          for (final height in <double>[220, 132, 132])
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  color: LibreRingTokens.soft,
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

Future<void> showRingInfo(
  BuildContext context, {
  required String title,
  required String body,
  String closeLabel = 'Got it',
  bool hapticsEnabled = true,
}) {
  RingHaptics.action(enabled: hapticsEnabled);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    sheetAnimationStyle: MediaQuery.disableAnimationsOf(context)
        ? AnimationStyle.noAnimation
        : null,
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w500,
                letterSpacing: -.6,
              ),
            ),
            const SizedBox(height: 16),
            Text(body, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 24),
            LibreRingPrimaryButton(
              label: closeLabel,
              icon: Icons.check_rounded,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    ),
  );
}
