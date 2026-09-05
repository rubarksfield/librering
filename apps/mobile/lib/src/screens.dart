import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:ring_core/ring_core.dart';
import 'package:ring_design_system/ring_design_system.dart';
import 'package:share_plus/share_plus.dart';

import 'app_state.dart';
import 'ble/r12_pairing_client.dart';
import 'localized_copy.dart';
import 'ring_analytics.dart';
import 'ring_data_view.dart';
import 'ring_product_view.dart';
import 'storage/journal_repository.dart';
import 'storage/data_export_service.dart';
import 'storage/preferences_repository.dart';
import 'ui/app_chrome.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) => _OnboardingScreen(
    key: const Key('screen-welcome'),
    top: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        const LibreRingWordmark(),
        TextButton(
          onPressed: () => context.go('/today'),
          child: Text(copyFor(context, 'Skip', 'Saltar')),
        ),
      ],
    ),
    art: LibreRingArtwork(
      kind: LibreRingArtworkKind.ring,
      size: 300,
      semanticLabel: copyFor(
        context,
        'Matte silver LibreRing illustration',
        'Ilustração de um LibreRing prateado mate',
      ),
    ),
    title: copyFor(
      context,
      'Know what your ring knows.',
      'Saiba o que o seu anel sabe.',
    ),
    subtitle: copyFor(
      context,
      'Clear daily signals, with the evidence kept close.',
      'Sinais diários claros, com a evidência sempre por perto.',
    ),
    action: LibreRingPrimaryButton(
      key: const Key('welcome-start'),
      label: copyFor(context, 'Set up LibreRing', 'Configurar o LibreRing'),
      onPressed: () => context.go('/privacy'),
    ),
  );
}

class PrivacyPromiseScreen extends StatelessWidget {
  const PrivacyPromiseScreen({super.key});

  @override
  Widget build(BuildContext context) => _OnboardingScreen(
    key: const Key('screen-privacy-promise'),
    top: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        const LibreRingWordmark(),
        _BackButton(
          label: copyFor(context, 'Back to welcome', 'Voltar ao início'),
          fallbackPath: '/welcome',
        ),
      ],
    ),
    art: const LibreRingArtwork(kind: LibreRingArtworkKind.privacy, size: 268),
    title: copyFor(
      context,
      'Your body data stays yours.',
      'Os dados do seu corpo continuam seus.',
    ),
    subtitle: copyFor(
      context,
      'Stored on this device by default. Sharing always requires a clear choice.',
      'Guardados neste dispositivo por predefinição. Partilhar exige sempre uma escolha clara.',
    ),
    action: LibreRingPrimaryButton(
      key: const Key('privacy-continue'),
      label: copyFor(context, 'Continue privately', 'Continuar em privado'),
      onPressed: () => context.go('/pairing/scan'),
    ),
  );
}

class RingScanScreen extends ConsumerWidget {
  const RingScanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demo = ref.watch(isDemoModeProvider);
    final pairing = ref.watch(ringPairingProvider);

    final productionSubtitle = switch (pairing.phase) {
      RingPairingPhase.idle => copyFor(
        context,
        'Bluetooth starts only when you choose Scan. Nearby identifiers stay in memory and raw packets are not retained.',
        'O Bluetooth só começa quando escolher Pesquisar. Os identificadores próximos ficam em memória e os pacotes brutos não são guardados.',
      ),
      RingPairingPhase.scanning => copyFor(
        context,
        'Looking for a nearby COLMI R12…',
        'A procurar um COLMI R12 próximo…',
      ),
      RingPairingPhase.found => copyFor(
        context,
        pairing.selected == null
            ? '${pairing.candidates.where((candidate) => candidate.exact).length} COLMI R12 rings found. Choose the one you own.'
            : '${pairing.selected!.advertisement.name} is ready for a non-destructive service check.',
        pairing.selected == null
            ? '${pairing.candidates.where((candidate) => candidate.exact).length} anéis COLMI R12 encontrados. Escolha o seu.'
            : '${pairing.selected!.advertisement.name} está pronto para uma verificação não destrutiva dos serviços.',
      ),
      RingPairingPhase.connecting => copyFor(
        context,
        'Confirming the ring service profile. No health or settings command is being sent.',
        'A confirmar o perfil de serviços do anel. Não está a ser enviado qualquer comando de saúde ou de definições.',
      ),
      RingPairingPhase.failed => copyFor(
        context,
        pairing.message ?? 'The ring could not be verified. Try again.',
        'Não foi possível verificar o anel. Feche o QRing e tente novamente.',
      ),
      RingPairingPhase.unavailable => copyFor(
        context,
        'Bluetooth is unavailable in this build.',
        'O Bluetooth não está disponível nesta versão.',
      ),
      RingPairingPhase.connected => copyFor(
        context,
        'Ring service profile verified.',
        'Perfil de serviços do anel verificado.',
      ),
    };
    final actionLabel = switch (pairing.phase) {
      RingPairingPhase.scanning => copyFor(
        context,
        'Scanning…',
        'A pesquisar…',
      ),
      RingPairingPhase.found => copyFor(
        context,
        pairing.selected == null
            ? 'Choose a ring above'
            : 'Verify ${pairing.selected!.advertisement.name}',
        pairing.selected == null
            ? 'Escolha um anel acima'
            : 'Verificar ${pairing.selected!.advertisement.name}',
      ),
      RingPairingPhase.connecting => copyFor(
        context,
        'Verifying…',
        'A verificar…',
      ),
      RingPairingPhase.failed => copyFor(
        context,
        'Try scan again',
        'Pesquisar novamente',
      ),
      _ => copyFor(context, 'Scan for ring', 'Pesquisar anel'),
    };
    return _OnboardingScreen(
      key: const Key('screen-ring-scan'),
      top: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          _BackButton(
            label: copyFor(context, 'Back to privacy', 'Voltar à privacidade'),
            fallbackPath: '/privacy',
          ),
          LibreRingEyebrow(copyFor(context, 'Pairing', 'Emparelhamento')),
          const SizedBox(width: 48),
        ],
      ),
      art: const LibreRingArtwork(kind: LibreRingArtworkKind.scan, size: 286),
      title: copyFor(context, 'Bring your ring close', 'Aproxime o seu anel'),
      subtitle: demo
          ? copyFor(
              context,
              'Demo pairing is local and deterministic. No health data leaves this phone.',
              'O emparelhamento de demonstração é local. Nenhum dado de saúde sai deste telemóvel.',
            )
          : productionSubtitle,
      detail: !demo && pairing.candidates.length > 1
          ? _RingCandidateList(
              candidates: pairing.candidates,
              selected: pairing.selected,
              onSelected: ref
                  .read(ringPairingProvider.notifier)
                  .selectCandidate,
            )
          : null,
      action: LibreRingPrimaryButton(
        key: const Key('scan-now'),
        label: demo
            ? copyFor(
                context,
                'Run demo scan',
                'Executar pesquisa de demonstração',
              )
            : actionLabel,
        onPressed: demo
            ? () => context.go('/pairing/found')
            : switch (pairing.phase) {
                RingPairingPhase.idle || RingPairingPhase.failed =>
                  ref.read(ringPairingProvider.notifier).scan,
                RingPairingPhase.found when pairing.selected != null =>
                  () async {
                    await ref.read(ringPairingProvider.notifier).connect();
                    if (context.mounted &&
                        ref.read(ringPairingProvider).phase ==
                            RingPairingPhase.connected) {
                      context.go('/pairing/found');
                    }
                  },
                _ => null,
              },
      ),
    );
  }
}

class RingFoundScreen extends ConsumerWidget {
  const RingFoundScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demo = ref.watch(isDemoModeProvider);
    final captureMode = ref.watch(isProtocolCaptureModeProvider);
    final pairing = ref.watch(ringPairingProvider);
    final evidence = pairing.evidence;
    final metadata = pairing.metadata;
    final suite = pairing.approvedSuite;
    final serviceStatus = evidence == null
        ? copyFor(
            context,
            'Return to pairing to verify an exact R12 service profile.',
            'Volte ao emparelhamento para verificar um perfil de serviços R12 exato.',
          )
        : copyFor(
            context,
            evidence.supportsBigData
                ? 'Command and history services confirmed · No commands sent'
                : 'Command service confirmed · History service unavailable · No commands sent',
            evidence.supportsBigData
                ? 'Serviços de comandos e histórico confirmados · Nenhum comando enviado'
                : 'Serviço de comandos confirmado · Serviço de histórico indisponível · Nenhum comando enviado',
          );
    final metadataStatus = metadata == null
        ? serviceStatus
        : copyFor(
            context,
            'Battery ${metadata.batteryLevel}%${metadata.charging ? ' · Charging' : ''} · Firmware ${metadata.firmwareVersion ?? 'not exposed'}',
            'Bateria ${metadata.batteryLevel}%${metadata.charging ? ' · A carregar' : ''} · Firmware ${metadata.firmwareVersion ?? 'não exposto'}',
          );
    final productionStatus = pairing.syncInProgress
        ? copyFor(
            context,
            'Reading verified history and storing it on this phone…',
            'A ler o histórico verificado e a guardá-lo neste telemóvel…',
          )
        : pairing.syncError ??
              (pairing.lastSyncedAtUtc == null
                  ? metadataStatus
                  : copyFor(
                      context,
                      '${pairing.lastSyncRecordCount ?? 0} records stored locally · Recovery scoring remains unavailable',
                      '${pairing.lastSyncRecordCount ?? 0} registos guardados localmente · A pontuação de recuperação continua indisponível',
                    ));
    return _OnboardingScreen(
      key: const Key('screen-ring-found'),
      top: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          const Expanded(child: LibreRingWordmark()),
          const SizedBox(width: 16),
          LibreRingEyebrow(
            demo
                ? copyFor(context, 'Demo connected', 'Demonstração ligada')
                : copyFor(context, 'Verified', 'Verificado'),
          ),
        ],
      ),
      art: const LibreRingArtwork(kind: LibreRingArtworkKind.ring, size: 210),
      preTitle: const Icon(
        Icons.check,
        color: LibreRingTokens.onForeground,
        size: 28,
      ),
      title: demo
          ? copyFor(context, 'LibreRing found', 'LibreRing encontrado')
          : evidence?.name ??
                copyFor(context, 'Ring not verified', 'Anel não verificado'),
      subtitle: demo
          ? copyFor(
              context,
              'Simulated signal strong · Demo battery 78%',
              'Sinal simulado forte · Bateria de demonstração 78%',
            )
          : captureMode
          ? metadataStatus
          : productionStatus,
      detail: captureMode && !demo
          ? Text(
              pairing.approvedSuiteInProgress
                  ? copyFor(
                      context,
                      'Capturing every supported read-only R12 channel and retained history. Keep the ring on and stay still; this can take up to five minutes.',
                      'A capturar todos os canais R12 só de leitura suportados e todo o histórico retido. Mantenha o anel colocado e fique imóvel; pode demorar até cinco minutos.',
                    )
                  : pairing.approvedSuiteError ??
                        (suite == null
                            ? copyFor(
                                context,
                                'One tap captures device details, read-only configuration, 7–8 days of activity, pulse, stress and firmware “HRV”, all retained sleep and SpO₂, then live pulse and SpO₂. Identifiers are excluded.',
                                'Um toque captura detalhes do dispositivo, configuração só de leitura, 7–8 dias de atividade, pulso, stress e “HRV” do firmware, todo o sono e SpO₂ retidos e, depois, pulso e SpO₂ em direto. Os identificadores são excluídos.',
                              )
                            : copyFor(
                                context,
                                'Full local capture saved. ${suite.statuses.values.where((status) => status == 'complete' || status == 'noData').length} of ${suite.statuses.length} sections completed or returned no data.',
                                'Captura local completa guardada. ${suite.statuses.values.where((status) => status == 'complete' || status == 'noData').length} de ${suite.statuses.length} secções concluíram ou não tinham dados.',
                              )),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            )
          : null,
      centered: true,
      action: captureMode && !demo
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                LibreRingPrimaryButton(
                  key: const Key('capture-approved-suite'),
                  label: pairing.approvedSuiteInProgress
                      ? copyFor(
                          context,
                          'Capturing everything…',
                          'A capturar tudo…',
                        )
                      : suite == null
                      ? copyFor(context, 'Capture everything', 'Capturar tudo')
                      : copyFor(
                          context,
                          'Capture everything again',
                          'Capturar tudo novamente',
                        ),
                  onPressed: pairing.approvedSuiteInProgress
                      ? null
                      : ref
                            .read(ringPairingProvider.notifier)
                            .captureApprovedSuite,
                ),
                const SizedBox(height: 8),
                TextButton(
                  key: const Key('found-view-today'),
                  onPressed: () => context.go('/today'),
                  child: Text(
                    copyFor(context, 'View today', 'Ver o dia de hoje'),
                  ),
                ),
              ],
            )
          : demo
          ? LibreRingPrimaryButton(
              key: const Key('found-view-today'),
              label: copyFor(context, 'View today', 'Ver o dia de hoje'),
              onPressed: () => context.go('/today'),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                LibreRingPrimaryButton(
                  key: const Key('sync-ring-data'),
                  label: pairing.syncInProgress
                      ? copyFor(context, 'Syncing…', 'A sincronizar…')
                      : pairing.lastSyncedAtUtc == null
                      ? copyFor(context, 'Sync ring data', 'Sincronizar dados')
                      : copyFor(context, 'Sync again', 'Sincronizar novamente'),
                  onPressed: pairing.syncInProgress
                      ? null
                      : ref.read(ringPairingProvider.notifier).sync,
                ),
                if (pairing.lastSyncedAtUtc != null) ...<Widget>[
                  const SizedBox(height: 8),
                  TextButton(
                    key: const Key('found-view-today'),
                    onPressed: () => context.go('/today'),
                    child: Text(
                      copyFor(
                        context,
                        'View synced data',
                        'Ver dados sincronizados',
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _RingCandidateList extends StatelessWidget {
  const _RingCandidateList({
    required this.candidates,
    required this.selected,
    required this.onSelected,
  });

  final List<RingPairingCandidate> candidates;
  final RingPairingCandidate? selected;
  final ValueChanged<RingPairingCandidate> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final candidate in candidates)
          ChoiceChip(
            label: Text(
              candidate.advertisement.name.trim().isEmpty
                  ? copyFor(
                      context,
                      'Unnamed QRing candidate',
                      'Candidato QRing sem nome',
                    )
                  : candidate.exact
                  ? candidate.advertisement.name
                  : copyFor(
                      context,
                      '${candidate.advertisement.name} · unconfirmed',
                      '${candidate.advertisement.name} · não confirmado',
                    ),
            ),
            selected:
                selected?.advertisement.deviceId ==
                candidate.advertisement.deviceId,
            onSelected: candidate.exact ? (_) => onSelected(candidate) : null,
          ),
      ],
    );
  }
}

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen>
    with WidgetsBindingObserver {
  bool _autoRefreshEvaluated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      setState(() => _autoRefreshEvaluated = false);
    }
  }

  Future<void> _maybeAutoRefresh(RingSyncDataset dataset) async {
    if (ref.read(isDemoModeProvider) ||
        ref.read(ringPairingClientProvider) == null ||
        ref.read(ringPairingProvider).syncInProgress) {
      return;
    }
    final age = ref
        .read(currentLocalTimeProvider)
        .toUtc()
        .difference(dataset.lastSyncedAtUtc);
    if (age.isNegative || age < const Duration(minutes: 10)) return;
    await ref.read(ringPairingProvider.notifier).quickSync();
  }

  @override
  Widget build(BuildContext context) {
    final demo = ref.watch(isDemoModeProvider);
    final snapshot = ref.watch(dailySnapshotProvider);
    final dataset = demo ? null : ref.watch(ringDataProvider).value;
    if (!_autoRefreshEvaluated && dataset != null) {
      _autoRefreshEvaluated = true;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _maybeAutoRefresh(dataset),
      );
    }
    final product = dataset == null
        ? null
        : RingProductView.fromDataset(
            dataset,
            localNow: ref.watch(currentLocalTimeProvider),
          );
    final analytics = dataset == null
        ? null
        : RingAnalytics.fromDataset(
            dataset,
            localNow: ref.watch(currentLocalTimeProvider),
          );
    final pairing = ref.watch(ringPairingProvider);
    return _AppScreen(
      key: const Key('screen-today'),
      activePath: '/today',
      children: <Widget>[
        _TopBar(
          leading: const LibreRingWordmark(),
          trailing: TextButton(
            key: const Key('today-quick-sync'),
            onPressed: demo || pairing.syncInProgress
                ? null
                : () async {
                    await ref.read(ringPairingProvider.notifier).quickSync();
                    if (!context.mounted) return;
                    final result = ref.read(ringPairingProvider);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          result.syncError ??
                              copyFor(
                                context,
                                'Ring data refreshed locally.',
                                'Dados do anel atualizados localmente.',
                              ),
                        ),
                      ),
                    );
                  },
            child: pairing.syncInProgress
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 1.5),
                  )
                : Text(
                    demo
                        ? copyFor(
                            context,
                            'Illustrative sample',
                            'Amostra ilustrativa',
                          )
                        : dataset == null
                        ? copyFor(context, 'Sync ring', 'Sincronizar anel')
                        : copyFor(
                            context,
                            'Synced ${RingDashboardView.clockLabel(dataset.lastSyncedAtUtc)}',
                            'Sincronizado ${RingDashboardView.clockLabel(dataset.lastSyncedAtUtc)}',
                          ),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 20),
        _DateLabel(
          dataset != null
              ? copyFor(
                  context,
                  'Last sync ${RingDashboardView.clockLabel(dataset.lastSyncedAtUtc)} · Stored locally',
                  'Última sincronização ${RingDashboardView.clockLabel(dataset.lastSyncedAtUtc)} · Guardado localmente',
                )
              : snapshot == null
              ? copyFor(
                  context,
                  'Production mode · No device data',
                  'Modo de produção · Sem dados do dispositivo',
                )
              : copyFor(
                  context,
                  'Monday, 24 August · Demo data',
                  'Segunda-feira, 24 de agosto · Dados de demonstração',
                ),
        ),
        const SizedBox(height: 36),
        if (snapshot == null && dataset == null)
          _UnavailableDataCard()
        else if (product != null) ...<Widget>[
          _DailySignalCard(
            signal: product.dailySignal,
            onTap: product.dailySignal.actionRoute == '/today'
                ? pairing.syncInProgress
                      ? null
                      : ref.read(ringPairingProvider.notifier).quickSync
                : () => context.go(product.dailySignal.actionRoute),
          ),
          const SizedBox(height: 14),
          _DailyDecodeStrip(analytics: analytics!),
          const SizedBox(height: 30),
          _SectionHeading(
            title: copyFor(context, 'Today at a glance', 'Hoje em resumo'),
            action: copyFor(context, 'All signals', 'Todos os sinais'),
            onAction: () => context.go('/vitals'),
          ),
          const SizedBox(height: 12),
          for (final domain in <ProductDomain>[
            ProductDomain.movement,
            ProductDomain.sleep,
          ].map(product.domain)) ...<Widget>[
            _DomainSummaryCard(
              summary: domain,
              onTap: () => context.go(domain.route),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 18),
          _SectionHeading(
            title: copyFor(context, 'Measured signals', 'Sinais medidos'),
          ),
          const SizedBox(height: 6),
          for (final domain in <ProductDomain>[
            ProductDomain.heart,
            ProductDomain.oxygen,
          ].map(product.domain))
            _DataRow(
              icon: domain.domain == ProductDomain.heart
                  ? Icons.favorite_outline
                  : Icons.water_drop_outlined,
              title: domain.label,
              meta: '${domain.explanation} · ${domain.source}',
              value: domain.value,
              onTap: () => context.go(domain.route),
            ),
          const SizedBox(height: 24),
          _SectionHeading(
            title: copyFor(
              context,
              'Exploratory firmware fields',
              'Campos exploratórios do firmware',
            ),
          ),
          const SizedBox(height: 6),
          _VendorSignalRow(
            dataset: dataset!,
            kind: RingVendorIndexKind.firmwareHrv,
            label: copyFor(
              context,
              'Firmware HRV index',
              'Índice HRV do firmware',
            ),
            route: '/signals/hrv-index',
          ),
          _VendorSignalRow(
            dataset: dataset,
            kind: RingVendorIndexKind.stress,
            label: copyFor(
              context,
              'Firmware stress index',
              'Índice de stress do firmware',
            ),
            route: '/signals/stress-index',
          ),
          _DataRow(
            icon: Icons.directions_run_outlined,
            title: copyFor(context, 'Sport record', 'Registo desportivo'),
            meta: copyFor(
              context,
              'Manual activities · kept separate',
              'Atividades manuais · mantidas separadas',
            ),
            onTap: () => context.go('/sport'),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            key: const Key('today-add-context'),
            onPressed: () => context.go('/journal'),
            icon: const Icon(Icons.add, size: 18),
            label: Text(copyFor(context, 'Add context', 'Adicionar contexto')),
          ),
        ] else ...<Widget>[
          const LibreRingEyebrow('Today'),
          const SizedBox(height: 8),
          Text(
            copyFor(
              context,
              'Your body looks ready for a demanding day.',
              'O seu corpo parece pronto para um dia exigente.',
            ),
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              color: LibreRingTokens.accent,
              fontSize: 46,
              height: 1,
              letterSpacing: -2.2,
            ),
          ),
          const SizedBox(height: 26),
          Semantics(
            label:
                '${copyFor(context, 'Illustrative readiness score', 'Pontuação de prontidão ilustrativa')} ${snapshot!.recoveryScore}',
            child: ExcludeSemantics(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    '${snapshot.recoveryScore}',
                    textScaler: TextScaler.noScaling,
                    style: const TextStyle(
                      fontSize: 82,
                      height: .82,
                      fontWeight: FontWeight.w200,
                      letterSpacing: -5,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        copyFor(
                          context,
                          'Concept readiness\nIllustrative only',
                          'Prontidão conceptual\nApenas ilustrativa',
                        ),
                        style: const TextStyle(
                          fontSize: 11,
                          color: LibreRingTokens.muted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          const Divider(),
          const SizedBox(height: 18),
          Text(
            copyFor(
              context,
              'Longer sleep and an earlier-settling resting pulse did most of the work in this illustrative concept. Use how you feel as the final check.',
              'Um sono mais longo e um pulso em repouso estabilizado mais cedo tiveram maior peso neste conceito ilustrativo. Use como se sente como verificação final.',
            ),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 22),
          LibreRingCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  copyFor(
                    context,
                    'Your normal plan looks reasonable.',
                    'O seu plano normal parece razoável.',
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  copyFor(
                    context,
                    'Symptoms, illness, or injury should always take priority over a score.',
                    'Sintomas, doença ou lesão devem sempre ter prioridade sobre uma pontuação.',
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _SectionHeading(
            title: copyFor(context, 'What changed', 'O que mudou'),
            action: copyFor(context, 'Timeline', 'Cronologia'),
            onAction: () => context.go('/day-timeline'),
          ),
          const SizedBox(height: 4),
          _DataRow(
            icon: Icons.bedtime_outlined,
            title: copyFor(
              context,
              "Last night's sleep",
              'Sono da última noite',
            ),
            meta: copyFor(
              context,
              'Longer and well timed · Demo data',
              'Mais longo e bem sincronizado · Dados de demonstração',
            ),
            value: '7:42',
            onTap: () => context.go('/sleep'),
          ),
          _DataRow(
            icon: Icons.timeline,
            title: copyFor(
              context,
              'Your day in context',
              'O seu dia em contexto',
            ),
            meta: copyFor(
              context,
              'Pulse, movement, sleep, and activities together',
              'Pulso, movimento, sono e atividades em conjunto',
            ),
            value: copyFor(context, 'Open', 'Abrir'),
            onTap: () => context.go('/day-timeline'),
          ),
        ],
      ],
    );
  }
}

class MetricsScreen extends ConsumerWidget {
  const MetricsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demo = ref.watch(isDemoModeProvider);
    final snapshot = ref.watch(dailySnapshotProvider);
    final dataset = demo ? null : ref.watch(ringDataProvider).value;
    final view = dataset == null
        ? null
        : RingDashboardView.fromDataset(
            dataset,
            localNow: ref.watch(currentLocalTimeProvider),
          );
    final metrics = view?.metrics ?? snapshot?.metrics;
    final largeText = MediaQuery.textScalerOf(context).scale(1) >= 1.5;
    return _AppScreen(
      key: const Key('screen-metrics'),
      activePath: '/vitals',
      children: <Widget>[
        _TopBar(
          leading: const LibreRingWordmark(),
          trailing: Text(
            copyFor(context, 'Limits stay visible', 'Limites visíveis'),
            style: const TextStyle(fontSize: 10, color: LibreRingTokens.muted),
          ),
        ),
        const SizedBox(height: 20),
        _DateLabel(
          dataset != null
              ? copyFor(
                  context,
                  'Last sync ${RingDashboardView.clockLabel(dataset.lastSyncedAtUtc)} · Ring data',
                  'Última sincronização ${RingDashboardView.clockLabel(dataset.lastSyncedAtUtc)} · Dados do anel',
                )
              : snapshot == null
              ? copyFor(context, 'No device data', 'Sem dados do dispositivo')
              : copyFor(
                  context,
                  'Last sync 08:42 · Demo data',
                  'Última sincronização 08:42 · Demonstração',
                ),
        ),
        const SizedBox(height: 4),
        _Heading(
          copyFor(
            context,
            'Your most useful signals,\nwith their limits.',
            'Os sinais mais úteis,\ncom os seus limites.',
          ),
        ),
        const SizedBox(height: 12),
        Text(
          copyFor(
            context,
            'Measured signals lead. Experimental, unavailable, and unsupported interpretations stay visibly separate.',
            'Os sinais medidos vêm primeiro. Interpretações experimentais, indisponíveis e não suportadas permanecem separadas.',
          ),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 32),
        if (metrics == null)
          _UnavailableDataCard()
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: metrics.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: largeText ? 1 : 2,
              mainAxisExtent: largeText ? 280 : 222,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (BuildContext context, int index) {
              final metric = metrics[index];
              return _MetricCard(
                metric: metric,
                onTap: () => context.go(switch (metric.label) {
                  'Steps' || 'Distance' || 'Firmware energy' => '/activity',
                  'Latest pulse' => '/heart',
                  'Sleep' => '/sleep',
                  'Oxygen range' => '/oxygen',
                  _ => '/trends',
                }),
              );
            },
          ),
        if (dataset != null) ...<Widget>[
          const SizedBox(height: 30),
          _SectionHeading(
            title: copyFor(
              context,
              'More from this firmware',
              'Mais deste firmware',
            ),
          ),
          const SizedBox(height: 6),
          _VendorSignalRow(
            dataset: dataset,
            kind: RingVendorIndexKind.firmwareHrv,
            label: copyFor(
              context,
              'Firmware HRV index',
              'Índice HRV do firmware',
            ),
            route: '/signals/hrv-index',
          ),
          _VendorSignalRow(
            dataset: dataset,
            kind: RingVendorIndexKind.stress,
            label: copyFor(
              context,
              'Firmware stress index',
              'Índice de stress do firmware',
            ),
            route: '/signals/stress-index',
          ),
          _DataRow(
            icon: Icons.directions_run_outlined,
            title: copyFor(context, 'Sport record', 'Registo desportivo'),
            meta: copyFor(
              context,
              'Manual context · local only',
              'Contexto manual · apenas local',
            ),
            onTap: () => context.go('/sport'),
          ),
        ],
      ],
    );
  }
}

class SleepScreen extends ConsumerWidget {
  const SleepScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demo = ref.watch(isDemoModeProvider);
    final dataset = demo ? null : ref.watch(ringDataProvider).value;
    final view = dataset == null
        ? null
        : RingDashboardView.fromDataset(dataset);
    final session = view?.latestSleep;
    final duration = session?.endedAtUtc.difference(session.startedAtUtc);
    return _AppScreen(
      key: const Key('screen-sleep'),
      activePath: '/today',
      children: <Widget>[
        _TopBar(
          leading: _BackButton(
            label: copyFor(context, 'Back to metrics', 'Voltar às métricas'),
            fallbackPath: '/metrics',
          ),
          center: LibreRingEyebrow(copyFor(context, 'Sleep', 'Sono')),
          trailing: IconButton(
            tooltip: copyFor(
              context,
              'View sleep evidence',
              'Ver evidência do sono',
            ),
            onPressed: () => context.go('/sleep/evidence'),
            icon: const Icon(Icons.description_outlined, size: 20),
          ),
        ),
        const SizedBox(height: 20),
        _DateLabel(
          demo
              ? copyFor(
                  context,
                  'Last night · Demo data',
                  'Noite passada · Demonstração',
                )
              : copyFor(
                  context,
                  'Latest firmware sleep session · Ring data',
                  'Última sessão de sono do firmware · Dados do anel',
                ),
        ),
        const SizedBox(height: 4),
        _Heading(
          demo
              ? copyFor(context, 'Well-timed rest', 'Descanso no momento certo')
              : copyFor(context, 'Recorded sleep', 'Sono registado'),
        ),
        const SizedBox(height: 38),
        if (!demo && session == null)
          _UnavailableDataCard()
        else ...<Widget>[
          Semantics(
            label: demo
                ? copyFor(
                    context,
                    'Seven hours and forty-two minutes asleep',
                    'Sete horas e quarenta e dois minutos de sono',
                  )
                : '${RingDashboardView.durationLabel(duration!)} recorded by ring firmware',
            child: ExcludeSemantics(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      demo
                          ? '7:42'
                          : RingDashboardView.durationLabel(duration!),
                      style: const TextStyle(
                        fontSize: 92,
                        height: .82,
                        fontWeight: FontWeight.w200,
                        letterSpacing: -5,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 5),
                      child: Text(
                        demo ? 'asleep' : 'recorded',
                        style: const TextStyle(
                          fontSize: 13,
                          color: LibreRingTokens.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            demo
                ? copyFor(
                    context,
                    'A consistent bedtime and fewer interruptions supported this result.',
                    'Uma hora de deitar consistente e menos interrupções apoiaram este resultado.',
                  )
                : copyFor(
                    context,
                    'This is firmware-derived history, not a diagnosis or a LibreRing sleep score.',
                    'Este é um histórico derivado do firmware, não um diagnóstico nem uma pontuação de sono LibreRing.',
                  ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 32),
          LibreRingCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: <Widget>[
                _SectionHeading(
                  title: copyFor(
                    context,
                    'Sleep continuity',
                    'Continuidade do sono',
                  ),
                  action: demo
                      ? '22:48–06:57'
                      : '${RingDashboardView.clockLabel(session!.startedAtUtc)}–${RingDashboardView.clockLabel(session.endedAtUtc)}',
                ),
                const SizedBox(height: 20),
                demo ? const _SleepBars() : _SleepStageBars(session!.stages),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        demo
                            ? '22:48'
                            : RingDashboardView.clockLabel(
                                session!.startedAtUtc,
                              ),
                        style: _axisStyle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        demo
                            ? '06:57'
                            : RingDashboardView.clockLabel(session!.endedAtUtc),
                        textAlign: TextAlign.end,
                        style: _axisStyle,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 18),
        _DataRow(
          icon: Icons.description_outlined,
          title: copyFor(
            context,
            'How this was calculated',
            'Como foi calculado',
          ),
          meta: copyFor(
            context,
            'Signals, confidence, and source',
            'Sinais, confiança e origem',
          ),
          onTap: () => context.go('/sleep/evidence'),
        ),
      ],
    );
  }
}

class EvidenceScreen extends ConsumerWidget {
  const EvidenceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demo = ref.watch(isDemoModeProvider);
    final dataset = demo ? null : ref.watch(ringDataProvider).value;
    final sleep = dataset == null
        ? null
        : RingDashboardView.fromDataset(dataset).latestSleep;
    final duration = sleep == null
        ? null
        : RingDashboardView.durationLabel(
            sleep.endedAtUtc.difference(sleep.startedAtUtc),
          );
    return _AppScreen(
      key: const Key('screen-evidence'),
      activePath: '/today',
      children: <Widget>[
        _TopBar(
          leading: _BackButton(
            label: copyFor(context, 'Back to sleep', 'Voltar ao sono'),
            fallbackPath: '/sleep',
          ),
          center: LibreRingEyebrow(copyFor(context, 'Evidence', 'Evidência')),
          trailing: _Confidence(
            demo
                ? copyFor(context, 'Good confidence', 'Boa confiança')
                : copyFor(context, 'Firmware source', 'Origem no firmware'),
          ),
        ),
        const SizedBox(height: 20),
        _DateLabel(
          copyFor(
            context,
            demo
                ? 'Sleep result · 23–24 August'
                : 'Latest stored sleep session',
            demo
                ? 'Resultado do sono · 23–24 de agosto'
                : 'Última sessão de sono guardada',
          ),
        ),
        const SizedBox(height: 4),
        _Heading(
          demo
              ? copyFor(context, 'What supports 7:42', 'O que sustenta 7:42')
              : sleep == null
              ? copyFor(context, 'No sleep evidence', 'Sem evidência de sono')
              : copyFor(
                  context,
                  'What the firmware reported for $duration',
                  'O que o firmware indicou para $duration',
                ),
        ),
        const SizedBox(height: 10),
        Text(
          copyFor(
            context,
            demo
                ? 'LibreRing combines available ring signals. It does not diagnose a sleep condition.'
                : 'LibreRing preserves the R12 firmware session and stage runs without turning them into a diagnosis or recovery score.',
            demo
                ? 'O LibreRing combina os sinais disponíveis do anel. Não diagnostica problemas de sono.'
                : 'O LibreRing preserva a sessão e as fases indicadas pelo firmware R12 sem as transformar num diagnóstico ou pontuação de recuperação.',
          ),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 34),
        if (demo)
          _DataRow(
            icon: Icons.sensors_outlined,
            title: copyFor(
              context,
              'Motion continuity',
              'Continuidade do movimento',
            ),
            meta: copyFor(
              context,
              'LibreRing IMU · complete',
              'IMU LibreRing · completa',
            ),
            value: copyFor(context, 'Primary', 'Principal'),
          )
        else
          _DataRow(
            icon: Icons.bedtime_outlined,
            title: copyFor(
              context,
              'Firmware sleep session',
              'Sessão de sono do firmware',
            ),
            meta: sleep == null
                ? copyFor(context, 'No retained session', 'Sem sessão retida')
                : copyFor(
                    context,
                    '${sleep.stages.length} stage-duration runs · Stored locally',
                    '${sleep.stages.length} períodos de fases · Guardado localmente',
                  ),
            value: sleep == null ? '—' : duration,
          ),
        _DataRow(
          icon: Icons.trending_up,
          title: copyFor(context, 'Pulse history', 'Histórico de pulso'),
          meta: copyFor(
            context,
            demo
                ? 'Optical pulse · 94% coverage'
                : '${dataset?.heartRate.length ?? 0} measured samples stored',
            demo
                ? 'Pulso ótico · cobertura de 94%'
                : '${dataset?.heartRate.length ?? 0} amostras medidas guardadas',
          ),
          value: copyFor(context, 'Supporting', 'Apoio'),
        ),
        if (demo)
          _DataRow(
            icon: Icons.edit_outlined,
            title: copyFor(
              context,
              'User correction',
              'Correção do utilizador',
            ),
            meta: copyFor(context, 'None recorded', 'Nenhuma registada'),
            value: '—',
          )
        else
          _DataRow(
            icon: Icons.sensors_off_outlined,
            title: copyFor(context, 'Raw motion', 'Movimento em bruto'),
            meta: copyFor(
              context,
              'Not exposed by the verified R12 protocol',
              'Não exposto pelo protocolo R12 verificado',
            ),
            value: copyFor(context, 'Unavailable', 'Indisponível'),
          ),
        _DataRow(
          icon: Icons.sensors_off_outlined,
          title: copyFor(
            context,
            'Unsupported reading example',
            'Exemplo de leitura não suportada',
          ),
          meta: copyFor(
            context,
            'See how missing evidence is handled',
            'Veja como tratamos evidência em falta',
          ),
          onTap: () => context.go('/no-result'),
        ),
        const SizedBox(height: 24),
        _AccentNote(
          copyFor(
            context,
            'Source records remain attached so later corrections do not erase the original evidence.',
            'Os registos de origem ficam associados para que correções posteriores não apaguem a evidência original.',
          ),
        ),
      ],
    );
  }
}

class NoResultScreen extends StatelessWidget {
  const NoResultScreen({super.key});

  @override
  Widget build(BuildContext context) => _AppScreen(
    key: const Key('screen-no-result'),
    children: <Widget>[
      _TopBar(
        leading: _BackButton(
          label: copyFor(context, 'Back to evidence', 'Voltar à evidência'),
          fallbackPath: '/sleep/evidence',
        ),
        center: LibreRingEyebrow(
          copyFor(context, 'Sensor limit', 'Limite do sensor'),
        ),
        trailing: const SizedBox(width: 48),
      ),
      const SizedBox(height: 54),
      const Center(
        child: LibreRingArtwork(
          kind: LibreRingArtworkKind.unsupported,
          size: 216,
        ),
      ),
      const SizedBox(height: 58),
      _Heading(
        copyFor(
          context,
          'No reading is the right result.',
          'Sem leitura é o resultado certo.',
        ),
        fontSize: 44,
      ),
      const SizedBox(height: 14),
      Text(
        copyFor(
          context,
          'A live SpO₂ request can return no stable reading even when stored hourly oxygen history exists. LibreRing will not estimate or fill the gap.',
          'Um pedido de SpO₂ em direto pode não devolver uma leitura estável mesmo quando existe histórico horário guardado. O LibreRing não estima nem preenche a lacuna.',
        ),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: 8),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          key: const Key('supported-trend-link'),
          onPressed: () => context.go('/trends'),
          child: Text(
            copyFor(
              context,
              'View measured pulse history',
              'Ver histórico de pulso medido',
            ),
          ),
        ),
      ),
    ],
  );
}

class RecoveryScreen extends ConsumerWidget {
  const RecoveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demo = ref.watch(isDemoModeProvider);
    final snapshot = ref.watch(dailySnapshotProvider);
    final dataset = demo ? null : ref.watch(ringDataProvider).value;
    final product = dataset == null
        ? null
        : RingProductView.fromDataset(dataset);
    return _AppScreen(
      key: const Key('screen-recovery'),
      activePath: '/today',
      children: <Widget>[
        _TopBar(
          leading: _BackButton(
            label: copyFor(context, 'Back to today', 'Voltar a hoje'),
          ),
          center: LibreRingEyebrow(copyFor(context, 'Recovery', 'Recuperação')),
          trailing: _Confidence(
            demo
                ? copyFor(context, 'Demo', 'Demonstração')
                : copyFor(context, 'Protected', 'Protegido'),
          ),
        ),
        const SizedBox(height: 24),
        if (demo && snapshot != null) ...<Widget>[
          _DateLabel(
            copyFor(context, 'Fictional demo', 'Demonstração fictícia'),
          ),
          const SizedBox(height: 6),
          _Heading(
            copyFor(context, snapshot.recoveryLabel, 'Pronta'),
            fontSize: 52,
          ),
          const SizedBox(height: 14),
          Text(snapshot.recoverySummary),
        ] else ...<Widget>[
          _DateLabel(
            copyFor(
              context,
              'Evidence boundary · Current R12 firmware',
              'Limite de evidência · Firmware R12 atual',
            ),
          ),
          const SizedBox(height: 6),
          _Heading(
            copyFor(
              context,
              'No Recovery score is the honest result.',
              'Sem pontuação de Recuperação é o resultado honesto.',
            ),
            fontSize: 44,
          ),
          const SizedBox(height: 14),
          Text(
            product?.domain(ProductDomain.recovery).explanation ??
                copyFor(
                  context,
                  'Pair and sync a verified R12 before inspecting recovery evidence.',
                  'Emparelhe e sincronize um R12 verificado antes de inspecionar a evidência de recuperação.',
                ),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 30),
          LibreRingCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _SectionHeading(
                  title: copyFor(
                    context,
                    'What remains useful',
                    'O que continua útil',
                  ),
                ),
                const SizedBox(height: 16),
                _CompactEvidenceRow(
                  title: copyFor(context, 'Recorded sleep', 'Sono registado'),
                  value: product?.domain(ProductDomain.sleep).value ?? '—',
                  detail: copyFor(
                    context,
                    'Firmware estimate · shown separately',
                    'Estimativa do firmware · mostrada separadamente',
                  ),
                ),
                _CompactEvidenceRow(
                  title: copyFor(context, 'Measured pulse', 'Pulso medido'),
                  value: product?.domain(ProductDomain.heart).value ?? '—',
                  detail: copyFor(
                    context,
                    'Available as history, not interpreted as readiness',
                    'Disponível como histórico, não interpretado como prontidão',
                  ),
                ),
                _CompactEvidenceRow(
                  title: copyFor(
                    context,
                    'Firmware HRV / stress',
                    'VFC / stress do firmware',
                  ),
                  value: copyFor(context, 'Excluded', 'Excluído'),
                  detail: copyFor(
                    context,
                    'Semantics and units remain unvalidated',
                    'Semântica e unidades continuam por validar',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _AccentNote(
            copyFor(
              context,
              'LibreRing will add Recovery only after enough independently validated inputs exist. Until then, precise-looking numbers would be false confidence.',
              'O LibreRing só adicionará Recuperação quando existirem dados suficientes validados de forma independente. Até lá, números precisos seriam falsa confiança.',
            ),
          ),
        ],
      ],
    );
  }
}

class MovementScreen extends ConsumerWidget {
  const MovementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demo = ref.watch(isDemoModeProvider);
    final dataset = demo ? null : ref.watch(ringDataProvider).value;
    final product = dataset == null
        ? null
        : RingProductView.fromDataset(dataset);
    final movement = product?.domain(ProductDomain.movement);
    final swims = ref
        .watch(journalProvider)
        .value
        ?.where((entry) => entry.kind == JournalEntryKind.swim)
        .toList(growable: false);
    return _AppScreen(
      key: const Key('screen-movement'),
      activePath: '/today',
      children: <Widget>[
        _TopBar(
          leading: _BackButton(
            label: copyFor(context, 'Back to today', 'Voltar a hoje'),
          ),
          center: LibreRingEyebrow(copyFor(context, 'Movement', 'Movimento')),
          trailing: _Confidence(
            copyFor(context, 'Ring estimate', 'Estimativa do anel'),
          ),
        ),
        const SizedBox(height: 24),
        _DateLabel(copyFor(context, 'Today', 'Hoje')),
        const SizedBox(height: 6),
        _Heading(
          movement?.value == null || movement!.value == '—'
              ? copyFor(
                  context,
                  'Movement will appear after sync.',
                  'O movimento aparecerá após sincronizar.',
                )
              : copyFor(
                  context,
                  '${movement.value} steps',
                  '${movement.value} passos',
                ),
          fontSize: 48,
        ),
        const SizedBox(height: 12),
        Text(
          movement?.explanation ??
              copyFor(
                context,
                'No supported movement bucket is available yet.',
                'Ainda não existe um intervalo de movimento suportado.',
              ),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 30),
        LibreRingCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _SectionHeading(
                title: copyFor(
                  context,
                  'Activity context',
                  'Contexto de atividade',
                ),
              ),
              const SizedBox(height: 18),
              _CompactEvidenceRow(
                title: copyFor(context, 'Steps', 'Passos'),
                value: movement?.value ?? '—',
                detail: copyFor(
                  context,
                  'Ring firmware estimate',
                  'Estimativa do firmware do anel',
                ),
              ),
              _CompactEvidenceRow(
                title: copyFor(context, 'Manual swims', 'Natações manuais'),
                value: '${swims?.length ?? 0}',
                detail: copyFor(
                  context,
                  'Stored separately · never converted into ring steps',
                  'Guardadas separadamente · nunca convertidas em passos do anel',
                ),
              ),
              _CompactEvidenceRow(
                title: copyFor(context, 'Calories', 'Calorias'),
                value: copyFor(context, 'Hidden', 'Ocultas'),
                detail: copyFor(
                  context,
                  'Firmware estimate is retained for export, not promoted',
                  'A estimativa do firmware é mantida para exportação, não promovida',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        LibreRingPrimaryButton(
          key: const Key('movement-add-swim'),
          label: copyFor(context, 'Add a swim', 'Adicionar uma natação'),
          icon: Icons.pool_outlined,
          onPressed: () => context.go('/journal/swim'),
        ),
      ],
    );
  }
}

class HeartDetailScreen extends ConsumerWidget {
  const HeartDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataset = ref.watch(isDemoModeProvider)
        ? null
        : ref.watch(ringDataProvider).value;
    final samples = dataset?.heartRate.toList(growable: false)
      ?..sort(
        (left, right) => left.measuredAtUtc.compareTo(right.measuredAtUtc),
      );
    final values = samples?.map((sample) => sample.bpm.toDouble()).toList();
    final average = values == null || values.isEmpty
        ? null
        : (values.reduce((left, right) => left + right) / values.length)
              .round();
    final minimum = values == null || values.isEmpty
        ? null
        : values.reduce(math.min).round();
    final maximum = values == null || values.isEmpty
        ? null
        : values.reduce(math.max).round();
    return _AppScreen(
      key: const Key('screen-heart'),
      activePath: '/today',
      children: <Widget>[
        _TopBar(
          leading: _BackButton(
            label: copyFor(context, 'Back to today', 'Voltar a hoje'),
          ),
          center: LibreRingEyebrow(copyFor(context, 'Heart', 'Coração')),
          trailing: _Confidence(copyFor(context, 'Measured', 'Medido')),
        ),
        const SizedBox(height: 24),
        _DateLabel(
          copyFor(
            context,
            '${samples?.length ?? 0} retained samples',
            '${samples?.length ?? 0} amostras retidas',
          ),
        ),
        const SizedBox(height: 6),
        _Heading(
          average == null
              ? copyFor(
                  context,
                  'No measured pulse yet',
                  'Ainda sem pulso medido',
                )
              : copyFor(
                  context,
                  '$average bpm average',
                  '$average bpm em média',
                ),
          fontSize: 48,
        ),
        const SizedBox(height: 12),
        Text(
          copyFor(
            context,
            average == null
                ? 'Sync the ring to load supported pulse history.'
                : 'Measured samples range from $minimum to $maximum bpm. LibreRing does not label this healthy or unhealthy.',
            average == null
                ? 'Sincronize o anel para carregar o histórico de pulso suportado.'
                : 'As amostras medidas variam entre $minimum e $maximum bpm. O LibreRing não classifica isto como saudável ou não saudável.',
          ),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 30),
        if (values != null && values.length > 1)
          LibreRingCard(
            child: Semantics(
              label:
                  '${values.length} pulse samples, ranging from $minimum to $maximum beats per minute',
              child: ExcludeSemantics(
                child: SizedBox(
                  height: 220,
                  width: double.infinity,
                  child: CustomPaint(painter: _TrendPainter(values)),
                ),
              ),
            ),
          )
        else
          _UnavailableDataCard(),
        const SizedBox(height: 18),
        _AccentNote(
          copyFor(
            context,
            'These are retained spot measurements. They are not a continuous ECG or a medical rhythm assessment.',
            'Estas são medições pontuais retidas. Não são um ECG contínuo nem uma avaliação médica do ritmo.',
          ),
        ),
      ],
    );
  }
}

class OxygenDetailScreen extends ConsumerWidget {
  const OxygenDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataset = ref.watch(isDemoModeProvider)
        ? null
        : ref.watch(ringDataProvider).value;
    final ranges = dataset?.oxygen.toList(growable: false)
      ?..sort(
        (left, right) =>
            left.hourStartedAtUtc.compareTo(right.hourStartedAtUtc),
      );
    final minimum = ranges == null || ranges.isEmpty
        ? null
        : ranges.map((range) => range.minimumPercent).reduce(math.min);
    final maximum = ranges == null || ranges.isEmpty
        ? null
        : ranges.map((range) => range.maximumPercent).reduce(math.max);
    return _AppScreen(
      key: const Key('screen-oxygen'),
      activePath: '/today',
      children: <Widget>[
        _TopBar(
          leading: _BackButton(
            label: copyFor(context, 'Back to today', 'Voltar a hoje'),
          ),
          center: LibreRingEyebrow(copyFor(context, 'Oxygen', 'Oxigénio')),
          trailing: _Confidence(
            copyFor(context, 'Hourly ranges', 'Intervalos horários'),
          ),
        ),
        const SizedBox(height: 24),
        _DateLabel(
          copyFor(
            context,
            '${ranges?.length ?? 0} retained hourly ranges',
            '${ranges?.length ?? 0} intervalos horários retidos',
          ),
        ),
        const SizedBox(height: 6),
        _Heading(
          minimum == null
              ? copyFor(
                  context,
                  'No oxygen history yet',
                  'Ainda sem histórico de oxigénio',
                )
              : '$minimum–$maximum%',
          fontSize: 52,
        ),
        const SizedBox(height: 12),
        Text(
          copyFor(
            context,
            'The R12 reports minimum–maximum ranges by hour. LibreRing keeps the range intact instead of inventing an average.',
            'O R12 indica intervalos mínimo–máximo por hora. O LibreRing mantém o intervalo intacto em vez de inventar uma média.',
          ),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 30),
        if (ranges != null && ranges.isNotEmpty)
          LibreRingCard(
            child: SizedBox(
              height: 230,
              width: double.infinity,
              child: _OxygenRangeChart(ranges: ranges.take(30).toList()),
            ),
          )
        else
          _UnavailableDataCard(),
        const SizedBox(height: 18),
        _AccentNote(
          copyFor(
            context,
            'Stored oxygen history is not the same as a stable live reading and is not a diagnosis.',
            'O histórico de oxigénio guardado não é o mesmo que uma leitura em direto estável e não é um diagnóstico.',
          ),
        ),
      ],
    );
  }
}

class TrendsScreen extends ConsumerStatefulWidget {
  const TrendsScreen({super.key});

  @override
  ConsumerState<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends ConsumerState<TrendsScreen> {
  int _days = 30;

  @override
  Widget build(BuildContext context) {
    final demo = ref.watch(isDemoModeProvider);
    final snapshot = ref.watch(dailySnapshotProvider);
    final dataset = demo ? null : ref.watch(ringDataProvider).value;
    final view = dataset == null
        ? null
        : RingDashboardView.fromDataset(dataset);
    final product = dataset == null
        ? null
        : RingProductView.fromDataset(dataset);
    final values = view?.pulseTrend ?? snapshot?.hrvTrend;
    final average = view?.averagePulse ?? 62;
    if (!demo) return _production(context, product);
    return _AppScreen(
      key: const Key('screen-trends'),
      activePath: '/trends',
      children: <Widget>[
        _TopBar(
          leading: _BackButton(
            label: copyFor(context, 'Back to today', 'Voltar a hoje'),
          ),
          center: LibreRingEyebrow(copyFor(context, 'Trend', 'Tendência')),
          trailing: _Confidence(copyFor(context, 'Measured', 'Medido')),
        ),
        const SizedBox(height: 20),
        _DateLabel(
          copyFor(
            context,
            demo
                ? 'Heart-rate variability · Demo data'
                : 'Pulse · Measured ring history',
            demo
                ? 'Variabilidade da frequência cardíaca · Demonstração'
                : 'Pulso · Histórico medido pelo anel',
          ),
        ),
        const SizedBox(height: 4),
        _Heading(
          copyFor(
            context,
            demo ? 'Stable over eight weeks' : 'Measured pulse history',
            demo ? 'Estável durante oito semanas' : 'Histórico de pulso medido',
          ),
        ),
        const SizedBox(height: 34),
        if (values == null || values.isEmpty)
          _UnavailableDataCard()
        else ...<Widget>[
          Semantics(
            label: copyFor(
              context,
              demo
                  ? '62 milliseconds average'
                  : '$average beats per minute average',
              demo
                  ? 'Média de 62 milissegundos'
                  : 'Média de $average batimentos por minuto',
            ),
            child: ExcludeSemantics(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      '$average',
                      style: const TextStyle(
                        fontSize: 92,
                        height: .82,
                        fontWeight: FontWeight.w200,
                        letterSpacing: -5,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 5),
                      child: Text(
                        demo ? 'ms average' : 'bpm average',
                        style: const TextStyle(
                          fontSize: 13,
                          color: LibreRingTokens.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Semantics(
            label: copyFor(
              context,
              demo
                  ? 'Eight week HRV trend ranging from 55 to 68 milliseconds'
                  : 'Measured pulse history with ${values.length} samples',
              demo
                  ? 'Tendência de VFC de oito semanas entre 55 e 68 milissegundos'
                  : 'Histórico de pulso medido com ${values.length} amostras',
            ),
            child: ExcludeSemantics(
              child: SizedBox(
                height: 250,
                width: double.infinity,
                child: CustomPaint(painter: _TrendPainter(values)),
              ),
            ),
          ),
          if (demo) const _TrendRange(),
          const SizedBox(height: 22),
          LibreRingPrimaryButton(
            key: const Key('trend-add-context'),
            label: copyFor(
              context,
              'Add swim context',
              'Adicionar contexto de natação',
            ),
            onPressed: () => context.go('/journal/swim'),
          ),
        ],
      ],
    );
  }

  Widget _production(BuildContext context, RingProductView? product) {
    final days = product?.range(_days) ?? const <RingTrendDay>[];
    final availableDays = days.where((day) => day.hasData).length;
    return _AppScreen(
      key: const Key('screen-trends'),
      activePath: '/trends',
      children: <Widget>[
        _TopBar(
          leading: const LibreRingWordmark(),
          trailing: IconButton(
            tooltip: copyFor(context, 'Add context', 'Adicionar contexto'),
            onPressed: () => context.go('/journal'),
            icon: const Icon(Icons.edit_note_outlined, size: 22),
          ),
        ),
        const SizedBox(height: 20),
        _DateLabel(copyFor(context, 'Your history', 'O seu histórico')),
        const SizedBox(height: 4),
        _Heading(
          copyFor(
            context,
            'Patterns, without guesswork.',
            'Padrões, sem adivinhações.',
          ),
        ),
        const SizedBox(height: 10),
        Text(
          product == null
              ? copyFor(
                  context,
                  'No ring history is stored on this phone yet.',
                  'Ainda não existe histórico do anel guardado neste telefone.',
                )
              : copyFor(
                  context,
                  '$availableDays of the last $_days days contain supported ring history. Missing days stay visibly missing.',
                  '$availableDays dos últimos $_days dias contêm histórico compatível do anel. Os dias em falta permanecem visíveis.',
                ),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 24),
        _HistoryRangeSelector(
          selected: _days,
          onChanged: (value) => setState(() => _days = value),
        ),
        const SizedBox(height: 28),
        if (product == null)
          _UnavailableDataCard()
        else ...<Widget>[
          _MeasuredTrendCard(
            key: const Key('trend-sleep'),
            title: copyFor(context, 'Sleep duration', 'Duração do sono'),
            value: _latestLabel(
              days.map((day) => day.sleepMinutes?.toDouble()).toList(),
              (value) => RingProductView.durationLabel(
                Duration(minutes: value.round()),
              ),
            ),
            unit: copyFor(
              context,
              'firmware interval',
              'intervalo do firmware',
            ),
            values: days.map((day) => day.sleepMinutes?.toDouble()).toList(),
            source: copyFor(
              context,
              'Ring-estimated · gaps preserved',
              'Estimado pelo anel · lacunas preservadas',
            ),
          ),
          const SizedBox(height: 12),
          _MeasuredTrendCard(
            key: const Key('trend-pulse'),
            title: copyFor(context, 'Pulse', 'Pulso'),
            value: _latestLabel(
              days.map((day) => day.averagePulse?.toDouble()).toList(),
              (value) => '${value.round()} bpm',
            ),
            unit: copyFor(
              context,
              'daily measured average',
              'média diária medida',
            ),
            values: days.map((day) => day.averagePulse?.toDouble()).toList(),
            source: copyFor(
              context,
              'Measured samples · not resting pulse',
              'Amostras medidas · não é pulso em repouso',
            ),
          ),
          const SizedBox(height: 12),
          _MeasuredTrendCard(
            key: const Key('trend-movement'),
            title: copyFor(context, 'Movement', 'Movimento'),
            value: _latestLabel(
              days
                  .map((day) => day.steps == 0 ? null : day.steps.toDouble())
                  .toList(),
              (value) => copyFor(
                context,
                '${value.round()} steps',
                '${value.round()} passos',
              ),
            ),
            unit: copyFor(
              context,
              'daily ring estimate',
              'estimativa diária do anel',
            ),
            values: days
                .map((day) => day.steps == 0 ? null : day.steps.toDouble())
                .toList(),
            source: copyFor(
              context,
              'Ring-estimated · zero is treated as missing',
              'Estimado pelo anel · zero é tratado como em falta',
            ),
          ),
          const SizedBox(height: 12),
          _MeasuredTrendCard(
            key: const Key('trend-oxygen'),
            title: copyFor(
              context,
              'Oxygen range minimum',
              'Mínimo do intervalo de oxigénio',
            ),
            value: _latestLabel(
              days.map((day) => day.minimumOxygen?.toDouble()).toList(),
              (value) => '${value.round()}%',
            ),
            unit: copyFor(
              context,
              'hourly history minimum',
              'mínimo do histórico horário',
            ),
            values: days.map((day) => day.minimumOxygen?.toDouble()).toList(),
            source: copyFor(
              context,
              'Historical ranges · not a live reading',
              'Intervalos históricos · não é uma leitura em direto',
            ),
          ),
          const SizedBox(height: 24),
          LibreRingPrimaryButton(
            key: const Key('trend-add-context'),
            label: copyFor(context, 'Add context', 'Adicionar contexto'),
            onPressed: () => context.go('/journal'),
          ),
        ],
      ],
    );
  }

  String _latestLabel(
    List<double?> values,
    String Function(double value) format,
  ) {
    for (final value in values.reversed) {
      if (value != null) return format(value);
    }
    return '—';
  }
}

class SwimEntryScreen extends ConsumerStatefulWidget {
  const SwimEntryScreen({super.key});

  @override
  ConsumerState<SwimEntryScreen> createState() => _SwimEntryScreenState();
}

class _SwimEntryScreenState extends ConsumerState<SwimEntryScreen> {
  final _duration = TextEditingController(text: '42');
  String _pool = '25 metres';
  String _effort = 'steady';
  bool _saving = false;
  bool _saved = false;
  String? _error;
  String? _durationError;

  void _changed() {
    _saved = false;
    _error = null;
    _durationError = null;
  }

  Future<void> _save() async {
    if (_saving || _saved) return;
    final duration = int.tryParse(_duration.text.trim());
    if (duration == null || duration < 1 || duration > 300) {
      setState(
        () => _durationError = copyFor(
          context,
          'Enter 1–300 minutes.',
          'Introduza 1–300 minutos.',
        ),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
      _durationError = null;
    });
    try {
      await ref
          .read(journalProvider.notifier)
          .saveSwim(
            durationMinutes: duration,
            environment: _pool,
            effort: _effort,
          );
      if (mounted) setState(() => _saved = true);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = copyFor(
            context,
            'Could not save your swim. Your details are still here. Try again.',
            'Não foi possível guardar a natação. Os dados continuam aqui. Tente novamente.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _duration.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final journal = ref.watch(journalProvider);
    return _AppScreen(
      key: const Key('screen-swim'),
      activePath: '/trends',
      children: <Widget>[
        _TopBar(
          leading: _BackButton(
            label: copyFor(context, 'Back to trend', 'Voltar à tendência'),
            fallbackPath: '/trends',
          ),
          center: LibreRingEyebrow(
            copyFor(context, 'Manual context', 'Contexto manual'),
          ),
          trailing: const SizedBox(width: 48),
        ),
        const SizedBox(height: 20),
        _DateLabel(copyFor(context, 'Activity entry', 'Registo de atividade')),
        const SizedBox(height: 4),
        _Heading(copyFor(context, 'Add a swim', 'Adicionar uma natação')),
        const SizedBox(height: 10),
        Text(
          copyFor(
            context,
            'Manual context is stored separately from ring measurements and can be deleted on its own.',
            'O contexto manual é guardado separadamente das medições do anel e pode ser eliminado isoladamente.',
          ),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 34),
        _FieldLabel(copyFor(context, 'Duration', 'Duração')),
        TextField(
          key: const Key('swim-duration'),
          controller: _duration,
          enabled: !_saving,
          onChanged: (_) => setState(_changed),
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            errorText: _durationError,
            suffixText: copyFor(context, 'minutes', 'minutos'),
            filled: true,
            fillColor: LibreRingTokens.soft,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                LibreRingTokens.controlRadius,
              ),
              borderSide: const BorderSide(color: LibreRingTokens.border),
            ),
          ),
        ),
        const SizedBox(height: 18),
        _FieldLabel(copyFor(context, 'Pool length', 'Comprimento da piscina')),
        DropdownButtonFormField<String>(
          key: const Key('swim-pool'),
          initialValue: _pool,
          decoration: InputDecoration(
            filled: true,
            fillColor: LibreRingTokens.soft,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                LibreRingTokens.controlRadius,
              ),
              borderSide: const BorderSide(color: LibreRingTokens.border),
            ),
          ),
          items: const <DropdownMenuItem<String>>[
            DropdownMenuItem(value: '25 metres', child: Text('25 metres')),
            DropdownMenuItem(value: '50 metres', child: Text('50 metres')),
            DropdownMenuItem(value: 'Open water', child: Text('Open water')),
          ],
          onChanged: _saving
              ? null
              : (String? value) => setState(() {
                  _changed();
                  _pool = value ?? _pool;
                }),
        ),
        const SizedBox(height: 18),
        _FieldLabel(copyFor(context, 'Effort', 'Esforço')),
        SegmentedButton<String>(
          key: const Key('swim-effort'),
          showSelectedIcon: false,
          segments: <ButtonSegment<String>>[
            ButtonSegment(
              value: 'easy',
              label: Text(copyFor(context, 'Easy', 'Leve')),
            ),
            ButtonSegment(
              value: 'steady',
              label: Text(copyFor(context, 'Steady', 'Constante')),
            ),
            ButtonSegment(
              value: 'hard',
              label: Text(copyFor(context, 'Hard', 'Intenso')),
            ),
          ],
          selected: <String>{_effort},
          onSelectionChanged: _saving
              ? null
              : (Set<String> value) => setState(() {
                  _changed();
                  _effort = value.first;
                }),
        ),
        const SizedBox(height: 24),
        LibreRingPrimaryButton(
          key: const Key('save-swim'),
          label: _saving
              ? copyFor(context, 'Saving…', 'A guardar…')
              : _saved
              ? copyFor(context, 'Saved', 'Guardado')
              : copyFor(context, 'Save locally', 'Guardar localmente'),
          icon: Icons.check,
          onPressed: journal.isLoading || _saving || _saved ? null : _save,
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            _error ??
                (_saved
                    ? copyFor(
                        context,
                        'Saved locally · Manual source',
                        'Guardado localmente · Origem manual',
                      )
                    : copyFor(context, 'Not yet saved', 'Ainda não guardado')),
            key: const Key('swim-save-status'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  String? _deletingId;

  Future<void> _delete(JournalEntry entry) async {
    if (_deletingId != null) return;
    setState(() => _deletingId = entry.id);
    try {
      await ref.read(journalProvider.notifier).delete(entry.id);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            copyFor(
              context,
              'Could not delete this entry. It is still in your journal.',
              'Não foi possível eliminar este registo. Continua no diário.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _deletingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final journal = ref.watch(journalProvider);
    final entries = journal.value ?? const <JournalEntry>[];
    return _AppScreen(
      key: const Key('screen-journal'),
      activePath: '/you',
      children: <Widget>[
        _TopBar(
          leading: _BackButton(
            label: copyFor(context, 'Back to You', 'Voltar ao perfil'),
            fallbackPath: '/you',
          ),
          center: LibreRingEyebrow(copyFor(context, 'Context', 'Contexto')),
          trailing: const SizedBox(width: 48),
        ),
        const SizedBox(height: 24),
        _DateLabel(
          copyFor(
            context,
            'Manual entries · Stored separately',
            'Registos manuais · Guardados separadamente',
          ),
        ),
        const SizedBox(height: 6),
        _Heading(
          copyFor(context, 'Your journal', 'O seu diário'),
          fontSize: 34,
        ),
        const SizedBox(height: 12),
        Text(
          copyFor(
            context,
            'Your notes and activities stay on this phone. Export or delete them separately from ring measurements.',
            'As notas e atividades ficam neste telemóvel. Exporte-as ou elimine-as separadamente das medições do anel.',
          ),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 28),
        _ActionTile(
          key: const Key('journal-add-check-in'),
          icon: Icons.add_reaction_outlined,
          title: copyFor(context, 'Quick check-in', 'Registo rápido'),
          body: copyFor(
            context,
            'Add a tag or note without changing ring data',
            'Adicione uma etiqueta ou nota sem alterar os dados do anel',
          ),
          onTap: () => context.go('/journal/check-in'),
        ),
        _ActionTile(
          key: const Key('journal-add-swim'),
          icon: Icons.pool_outlined,
          title: copyFor(context, 'Log a swim', 'Registar uma natação'),
          body: copyFor(
            context,
            'Pool or open water · duration · effort',
            'Piscina ou águas abertas · duração · esforço',
          ),
          onTap: () => context.go('/journal/swim'),
        ),
        const SizedBox(height: 30),
        _SectionHeading(
          title: copyFor(context, 'Recent context', 'Contexto recente'),
          action: '${entries.length}',
        ),
        const SizedBox(height: 8),
        if (journal.isLoading)
          const Center(child: CircularProgressIndicator())
        else if (journal.hasError)
          _AccentNote(
            copyFor(
              context,
              'Journal storage could not be read. Existing files were not overwritten.',
              'Não foi possível ler o armazenamento do diário. Os ficheiros existentes não foram substituídos.',
            ),
          )
        else if (entries.isEmpty)
          LibreRingCard(
            child: Text(
              copyFor(
                context,
                'No manual context yet. Ring measurements remain complete without it.',
                'Ainda sem contexto manual. As medições do anel continuam completas sem ele.',
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          )
        else
          for (final entry in entries)
            _JournalRow(
              entry: entry,
              deleting: _deletingId == entry.id,
              onDelete: _deletingId != null ? null : () => _delete(entry),
            ),
      ],
    );
  }
}

class CheckInScreen extends ConsumerStatefulWidget {
  const CheckInScreen({super.key});

  @override
  ConsumerState<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends ConsumerState<CheckInScreen> {
  static const _tags = <String>[
    'Exercise',
    'Late meal',
    'Alcohol',
    'Travel',
    'Illness',
    'Meditation',
  ];
  final _note = TextEditingController();
  final _selected = <String>{};
  bool _saved = false;
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    if (_saving || _saved || (_selected.isEmpty && _note.text.trim().isEmpty)) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(journalProvider.notifier)
          .saveCheckIn(tags: _selected.toList(), note: _note.text);
      if (mounted) setState(() => _saved = true);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = copyFor(
            context,
            'Could not save your check-in. Your note is still here. Try again.',
            'Não foi possível guardar o registo. A nota continua aqui. Tente novamente.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final journal = ref.watch(journalProvider);
    return _AppScreen(
      key: const Key('screen-check-in'),
      activePath: '/you',
      children: <Widget>[
        _TopBar(
          leading: _BackButton(
            label: copyFor(context, 'Back to Journal', 'Voltar ao diário'),
            fallbackPath: '/journal',
          ),
          center: LibreRingEyebrow(copyFor(context, 'Check-in', 'Registo')),
          trailing: _Confidence(copyFor(context, 'Manual', 'Manual')),
        ),
        const SizedBox(height: 24),
        _DateLabel(copyFor(context, 'Optional context', 'Contexto opcional')),
        const SizedBox(height: 6),
        _Heading(
          copyFor(context, 'What shaped today?', 'O que marcou o seu dia?'),
          fontSize: 46,
        ),
        const SizedBox(height: 12),
        Text(
          copyFor(
            context,
            'Choose only what matters. This stays manual, local, and separate from ring measurements.',
            'Escolha apenas o que importa. Isto permanece manual, local e separado das medições do anel.',
          ),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 28),
        _FieldLabel(copyFor(context, 'Tags', 'Etiquetas')),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _tags
              .map((tag) {
                final selected = _selected.contains(tag);
                return FilterChip(
                  key: Key(
                    'check-in-${tag.toLowerCase().replaceAll(' ', '-')}',
                  ),
                  label: Text(_checkInTagLabel(context, tag)),
                  selected: selected,
                  showCheckmark: false,
                  onSelected: _saving
                      ? null
                      : (value) => setState(() {
                          _saved = false;
                          _error = null;
                          value ? _selected.add(tag) : _selected.remove(tag);
                        }),
                );
              })
              .toList(growable: false),
        ),
        const SizedBox(height: 24),
        _FieldLabel(copyFor(context, 'Note', 'Nota')),
        TextField(
          key: const Key('check-in-note'),
          controller: _note,
          enabled: !_saving,
          minLines: 3,
          maxLines: 5,
          maxLength: 280,
          onTapOutside: (_) => FocusScope.of(context).unfocus(),
          onChanged: (_) => setState(() {
            _saved = false;
            _error = null;
          }),
          decoration: InputDecoration(
            hintText: copyFor(
              context,
              'Anything useful to remember?',
              'Algo útil para recordar?',
            ),
            filled: true,
            fillColor: LibreRingTokens.soft,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                LibreRingTokens.controlRadius,
              ),
              borderSide: const BorderSide(color: LibreRingTokens.border),
            ),
          ),
        ),
        const SizedBox(height: 22),
        LibreRingPrimaryButton(
          key: const Key('save-check-in'),
          label: _saving
              ? copyFor(context, 'Saving…', 'A guardar…')
              : _saved
              ? copyFor(context, 'Saved', 'Guardado')
              : copyFor(context, 'Save check-in', 'Guardar registo'),
          icon: Icons.check,
          onPressed:
              journal.isLoading ||
                  _saving ||
                  _saved ||
                  (_selected.isEmpty && _note.text.trim().isEmpty)
              ? null
              : _save,
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            _error ??
                (_saved
                    ? copyFor(
                        context,
                        'Saved locally · Manual source',
                        'Guardado localmente · Origem manual',
                      )
                    : copyFor(
                        context,
                        'Nothing saved yet',
                        'Ainda nada guardado',
                      )),
            key: const Key('check-in-save-status'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class YouScreen extends ConsumerWidget {
  const YouScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataset = ref.watch(isDemoModeProvider)
        ? null
        : ref.watch(ringDataProvider).value;
    final journalCount = ref.watch(journalProvider).value?.length ?? 0;
    final preferences = ref.watch(appPreferencesProvider);
    final profile = preferences.value ?? const AppPreferences();
    return _AppScreen(
      key: const Key('screen-you'),
      activePath: '/you',
      children: <Widget>[
        const SizedBox(height: 8),
        _Heading(copyFor(context, 'You', 'Perfil'), fontSize: 34),
        const SizedBox(height: 6),
        Text(
          copyFor(
            context,
            'Make LibreRing yours.',
            'O LibreRing, à sua medida.',
          ),
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: LibreRingTokens.muted),
        ),
        const SizedBox(height: 24),
        LibreRingCard(
          backgroundColor: LibreRingTokens.sageSoft,
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: LibreRingTokens.sage,
                foregroundColor: Colors.white,
                child: profile.displayName.isEmpty
                    ? const Icon(Icons.person_outline_rounded)
                    : Text(profile.displayName.characters.first.toUpperCase()),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.displayName.isEmpty
                          ? copyFor(
                              context,
                              'Your personal space',
                              'O seu espaço pessoal',
                            )
                          : profile.displayName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      copyFor(
                        context,
                        'No account. No subscription.',
                        'Sem conta. Sem subscrição.',
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _ActionTile(
          key: const Key('you-profile'),
          icon: Icons.tune,
          title: copyFor(
            context,
            'Profile and preferences',
            'Perfil e preferências',
          ),
          body: copyFor(
            context,
            'Name, distance units, and personal goals',
            'Nome, unidades de distância e objetivos pessoais',
          ),
          onTap: () => context.push('/you/profile'),
        ),
        _ActionTile(
          key: const Key('you-ring'),
          icon: Icons.radio_button_checked,
          title: copyFor(context, 'Ring', 'Anel'),
          body: dataset == null
              ? copyFor(
                  context,
                  'No stored device history',
                  'Sem histórico do dispositivo',
                )
              : copyFor(
                  context,
                  'COLMI R12 · last reported battery ${dataset.batteryLevel == null ? 'unavailable' : '${dataset.batteryLevel}%'}',
                  'COLMI R12 · última bateria ${dataset.batteryLevel == null ? 'indisponível' : '${dataset.batteryLevel}%'}',
                ),
          onTap: () => context.push('/you/ring'),
        ),
        _ActionTile(
          key: const Key('you-setup'),
          icon: Icons.auto_awesome_outlined,
          title: copyFor(context, 'Setup walkthrough', 'Guia de configuração'),
          body: copyFor(
            context,
            'Pairing, privacy, and first sync',
            'Emparelhamento, privacidade e primeira sincronização',
          ),
          onTap: () => context.push('/onboarding'),
        ),
        _ActionTile(
          key: const Key('you-journal'),
          icon: Icons.edit_note_outlined,
          title: copyFor(context, 'Journal', 'Diário'),
          body: copyFor(
            context,
            '$journalCount manual entries · kept separate from ring data',
            '$journalCount registos manuais · separados dos dados do anel',
          ),
          onTap: () => context.push('/journal'),
        ),
        _ActionTile(
          key: const Key('you-data'),
          icon: Icons.folder_outlined,
          title: copyFor(context, 'Data and export', 'Dados e exportação'),
          body: copyFor(
            context,
            '${dataset?.recordCount ?? 0} ring records · $journalCount manual entries',
            '${dataset?.recordCount ?? 0} registos do anel · $journalCount registos manuais',
          ),
          onTap: () => context.push('/you/data'),
        ),
        _ActionTile(
          key: const Key('you-about'),
          icon: Icons.info_outline,
          title: copyFor(context, 'About LibreRing', 'Sobre o LibreRing'),
          body: copyFor(
            context,
            'Supported features, privacy, and open source',
            'Funcionalidades, privacidade e código aberto',
          ),
          onTap: () => context.push('/you/about'),
        ),
      ],
    );
  }
}

class RingDeviceScreen extends ConsumerStatefulWidget {
  const RingDeviceScreen({super.key});

  @override
  ConsumerState<RingDeviceScreen> createState() => _RingDeviceScreenState();
}

class _RingDeviceScreenState extends ConsumerState<RingDeviceScreen> {
  bool _refreshing = false;

  Future<void> _refresh() async {
    if (_refreshing ||
        ref.read(ringPairingProvider).syncInProgress ||
        ref.read(ringPairingClientProvider) == null) {
      return;
    }
    setState(() => _refreshing = true);
    String? message;
    try {
      await ref.read(ringPairingProvider.notifier).quickSync();
      if (!mounted) return;
      final result = ref.read(ringPairingProvider);
      message =
          result.syncError ??
          (result.lastSyncedAtUtc != null
              ? copyFor(
                  context,
                  'Ring history updated.',
                  'Histórico do anel atualizado.',
                )
              : copyFor(
                  context,
                  'The ring has not synced yet. Try again or open setup.',
                  'O anel ainda não foi sincronizado. Tente novamente ou abra a configuração.',
                ));
    } catch (_) {
      if (!mounted) return;
      message = copyFor(
        context,
        'Could not sync right now. Keep the ring nearby and try again.',
        'Não foi possível sincronizar agora. Mantenha o anel por perto e tente novamente.',
      );
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final demo = ref.watch(isDemoModeProvider);
    final ring = ref.watch(ringDataProvider);
    final dataset = demo ? null : ring.value;
    final pairing = ref.watch(ringPairingProvider);
    final canRefresh =
        !demo &&
        !ref.watch(isProtocolCaptureModeProvider) &&
        ref.watch(ringPairingClientProvider) != null;
    final busy = _refreshing || pairing.syncInProgress;
    final status = demo
        ? copyFor(context, 'Preview', 'Pré-visualização')
        : busy
        ? copyFor(context, 'Syncing', 'A sincronizar')
        : pairing.phase == RingPairingPhase.connected
        ? copyFor(context, 'Connected', 'Ligado')
        : ring.hasError
        ? copyFor(
            context,
            'Storage needs attention',
            'O armazenamento precisa de atenção',
          )
        : ring.isLoading
        ? copyFor(context, 'Loading history', 'A carregar histórico')
        : dataset == null
        ? copyFor(context, 'Not synced yet', 'Ainda não sincronizado')
        : copyFor(
            context,
            'History saved on this phone',
            'Histórico guardado neste telemóvel',
          );
    return _AppScreen(
      key: const Key('screen-ring-device'),
      activePath: '/you',
      children: <Widget>[
        _TopBar(
          leading: _BackButton(
            label: copyFor(context, 'Back to You', 'Voltar ao perfil'),
            fallbackPath: '/you',
          ),
          center: LibreRingEyebrow(copyFor(context, 'Your ring', 'O seu anel')),
          trailing: const SizedBox(width: 48),
        ),
        const SizedBox(height: 20),
        const Center(
          child: LibreRingArtwork(kind: LibreRingArtworkKind.ring, size: 144),
        ),
        const SizedBox(height: 20),
        const _Heading('COLMI R12', fontSize: 34),
        const SizedBox(height: 8),
        Semantics(
          liveRegion: true,
          child: Text(
            status,
            key: const Key('ring-connection-status'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: ring.hasError
                  ? Theme.of(context).colorScheme.error
                  : LibreRingTokens.sage,
            ),
          ),
        ),
        const SizedBox(height: 22),
        LibreRingCard(
          child: Column(
            children: <Widget>[
              _CompactEvidenceRow(
                title: copyFor(context, 'Battery', 'Bateria'),
                value: dataset?.batteryLevel == null
                    ? '—'
                    : '${dataset!.batteryLevel}%',
                detail: dataset?.charging == true
                    ? copyFor(
                        context,
                        'Charging at the last sync',
                        'A carregar na última sincronização',
                      )
                    : copyFor(
                        context,
                        'Last reported level',
                        'Último nível registado',
                      ),
              ),
              _CompactEvidenceRow(
                title: copyFor(context, 'Last sync', 'Última sincronização'),
                value: dataset == null
                    ? '—'
                    : DateFormat('d MMM, HH:mm')
                          .format(dataset.lastSyncedAtUtc.toLocal()),
                detail: copyFor(
                  context,
                  'A new sync refreshes your history',
                  'Uma nova sincronização atualiza o histórico',
                ),
              ),
              _CompactEvidenceRow(
                title: copyFor(context, 'Firmware', 'Firmware'),
                value: dataset?.source.firmwareVersion ?? '—',
                detail: copyFor(
                  context,
                  'Version reported by your ring',
                  'Versão indicada pelo anel',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        LibreRingPrimaryButton(
          key: const Key('ring-device-sync'),
          label: busy
              ? copyFor(context, 'Syncing…', 'A sincronizar…')
              : copyFor(context, 'Sync ring', 'Sincronizar anel'),
          icon: Icons.sync,
          onPressed: !canRefresh || busy ? null : _refresh,
        ),
        const SizedBox(height: 8),
        Text(
          copyFor(
            context,
            'LibreRing connects during sync, then releases the ring. Your history stays available offline.',
            'O LibreRing liga durante a sincronização e depois liberta o anel. O histórico continua disponível sem ligação.',
          ),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 20),
        _ActionTile(
          key: const Key('ring-capabilities'),
          icon: Icons.health_and_safety_outlined,
          title: copyFor(
            context,
            'Supported features',
            'Funcionalidades disponíveis',
          ),
          body: copyFor(
            context,
            'What this ring can share with LibreRing',
            'O que este anel pode partilhar com o LibreRing',
          ),
          onTap: () => context.push('/you/ring/capabilities'),
        ),
        _ActionTile(
          key: const Key('ring-sync-help'),
          icon: Icons.help_outline,
          title: copyFor(context, 'Sync help', 'Ajuda com a sincronização'),
          body:
              pairing.syncError ??
              copyFor(
                context,
                'Connection tips and retry',
                'Sugestões de ligação e nova tentativa',
              ),
          onTap: () => context.push('/you/ring/sync-issue'),
        ),
        _ActionTile(
          key: const Key('ring-device-setup'),
          icon: Icons.bluetooth_searching_rounded,
          title: copyFor(context, 'Ring setup', 'Configurar anel'),
          body: copyFor(
            context,
            'Find and verify a nearby COLMI R12',
            'Encontrar e verificar um COLMI R12 próximo',
          ),
          onTap: busy ? null : () => context.push('/pairing/scan'),
        ),
      ],
    );
  }
}

class DataHubScreen extends ConsumerStatefulWidget {
  const DataHubScreen({super.key});

  @override
  ConsumerState<DataHubScreen> createState() => _DataHubScreenState();
}

class _DataHubScreenState extends ConsumerState<DataHubScreen> {
  String? _busy;
  String? _message;
  bool _failed = false;

  void _feedback(String message, {bool failed = false}) {
    if (!mounted) return;
    setState(() {
      _message = message;
      _failed = failed;
    });
  }

  void _begin(String action) {
    setState(() {
      _busy = action;
      _message = null;
      _failed = false;
    });
  }

  void _finish() {
    if (mounted) setState(() => _busy = null);
  }

  Future<void> _createExport() async {
    if (_busy != null) return;
    _begin('export');
    try {
      await ref.read(dataExportProvider.notifier).create();
    } catch (_) {
      if (!mounted) return;
      _feedback(
        copyFor(
          context,
          'Could not create the export. Your records are still on this phone. Try again.',
          'Não foi possível criar a exportação. Os registos continuam neste telemóvel. Tente novamente.',
        ),
        failed: true,
      );
    } finally {
      _finish();
    }
  }

  Future<void> _share(LocalExportResult result) async {
    if (_busy != null) return;
    _begin('share');
    try {
      final box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          subject: copyFor(
            context,
            'LibreRing data export',
            'Exportação de dados LibreRing',
          ),
          text: copyFor(
            context,
            '${result.rowCount} records exported from this phone.',
            '${result.rowCount} registos exportados deste telemóvel.',
          ),
          files: <XFile>[
            XFile(result.jsonFile.path),
            XFile(result.csvFile.path),
          ],
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      _feedback(
        copyFor(
          context,
          'Could not open sharing. Your export is still available; try again.',
          'Não foi possível abrir a partilha. A exportação continua disponível; tente novamente.',
        ),
        failed: true,
      );
    } finally {
      _finish();
    }
  }

  Future<void> _deleteManual() async {
    if (_busy != null || ref.read(ringPairingProvider).syncInProgress) return;
    final unreadable = ref.read(journalProvider).hasError;
    _begin('manual');
    try {
      final confirmed = await _confirm(
        context,
        title: unreadable
            ? copyFor(
                context,
                'Delete unreadable manual context?',
                'Eliminar contexto manual ilegível?',
              )
            : copyFor(
                context,
                'Delete all manual context?',
                'Eliminar todo o contexto manual?',
              ),
        body: unreadable
            ? copyFor(
                context,
                'The saved journal file cannot be read, so its contents cannot be previewed. Deleting it cannot be undone. Ring measurements and existing exports are kept.',
                'O ficheiro do diário não pode ser lido, pelo que não é possível pré-visualizar o conteúdo. A eliminação não pode ser anulada. As medições do anel e exportações existentes são mantidas.',
              )
            : copyFor(
                context,
                'Ring measurements and files you already exported remain on this phone.',
                'As medições do anel e os ficheiros já exportados permanecem neste telemóvel.',
              ),
      );
      if (!confirmed || !mounted) return;
      if (ref.read(ringPairingProvider).syncInProgress) {
        _feedback(
          copyFor(
            context,
            'A sync has started. Wait for it to finish, then try deleting again.',
            'Foi iniciada uma sincronização. Aguarde o fim e tente eliminar novamente.',
          ),
        );
        return;
      }
      await ref.read(journalProvider.notifier).deleteAll();
      if (!mounted) return;
      _feedback(
        copyFor(
          context,
          'Manual context deleted.',
          'Contexto manual eliminado.',
        ),
      );
    } catch (_) {
      if (!mounted) return;
      _feedback(
        unreadable
            ? copyFor(
                context,
                'Could not delete unreadable manual context. The file has been kept; try again.',
                'Não foi possível eliminar o contexto manual ilegível. O ficheiro foi mantido; tente novamente.',
              )
            : copyFor(
                context,
                'Could not delete manual context. Your entries are still available; try again.',
                'Não foi possível eliminar o contexto manual. Os registos continuam disponíveis; tente novamente.',
              ),
        failed: true,
      );
    } finally {
      _finish();
    }
  }

  Future<void> _deleteRing() async {
    if (_busy != null) return;
    if (ref.read(ringPairingProvider).syncInProgress) {
      _feedback(
        copyFor(
          context,
          'Wait for the current sync to finish.',
          'Aguarde o fim da sincronização.',
        ),
      );
      return;
    }
    final unreadable = ref.read(ringDataProvider).hasError;
    _begin('ring');
    try {
      final confirmed = await _confirm(
        context,
        title: unreadable
            ? copyFor(
                context,
                'Delete unreadable ring history?',
                'Eliminar histórico ilegível do anel?',
              )
            : copyFor(
                context,
                'Delete all local ring history?',
                'Eliminar todo o histórico local do anel?',
              ),
        body: unreadable
            ? copyFor(
                context,
                'The saved ring-history file cannot be read, so its contents cannot be previewed. Deleting it cannot be undone. Manual context and existing exports are kept. The ring itself is not erased.',
                'O ficheiro de histórico do anel não pode ser lido, pelo que não é possível pré-visualizar o conteúdo. A eliminação não pode ser anulada. O contexto manual e exportações existentes são mantidos. O anel não é apagado.',
              )
            : copyFor(
                context,
                'This removes ring records from LibreRing on this phone. Manual context and files you already exported stay in place. The ring itself is not erased.',
                'Isto remove os registos do anel neste telemóvel. O contexto manual e os ficheiros já exportados permanecem. O anel não é apagado.',
              ),
      );
      if (!confirmed || !mounted) return;
      if (ref.read(ringPairingProvider).syncInProgress) {
        _feedback(
          copyFor(
            context,
            'A sync has started. Wait for it to finish, then try deleting again.',
            'Foi iniciada uma sincronização. Aguarde o fim e tente eliminar novamente.',
          ),
        );
        return;
      }
      await ref.read(ringDataProvider.notifier).deleteAll();
      if (!mounted) return;
      _feedback(
        copyFor(
          context,
          'Local ring history deleted.',
          'Histórico local do anel eliminado.',
        ),
      );
    } catch (_) {
      if (!mounted) return;
      _feedback(
        unreadable
            ? copyFor(
                context,
                'Could not delete unreadable ring history. The file has been kept; try again.',
                'Não foi possível eliminar o histórico ilegível do anel. O ficheiro foi mantido; tente novamente.',
              )
            : copyFor(
                context,
                'Could not delete ring history. Your records are still available; try again.',
                'Não foi possível eliminar o histórico do anel. Os registos continuam disponíveis; tente novamente.',
              ),
        failed: true,
      );
    } finally {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final demo = ref.watch(isDemoModeProvider);
    final ring = ref.watch(ringDataProvider);
    final dataset = demo ? null : ring.value;
    final journal = ref.watch(journalProvider);
    final export = ref.watch(dataExportProvider);
    final result = export.value;
    final syncing = ref.watch(ringPairingProvider).syncInProgress;
    final canExport =
        !demo &&
        dataset != null &&
        !ring.isLoading &&
        !ring.hasError &&
        !journal.isLoading &&
        !journal.hasError &&
        ref.watch(dataExportServiceProvider) != null;
    final ringCount = demo
        ? copyFor(context, 'Preview', 'Pré-visualização')
        : ring.isLoading
        ? copyFor(context, 'Loading…', 'A carregar…')
        : ring.hasError
        ? copyFor(context, 'Unavailable', 'Indisponível')
        : dataset == null
        ? copyFor(context, 'No records', 'Sem registos')
        : '${dataset.recordCount}';
    final journalCount = journal.isLoading
        ? copyFor(context, 'Loading…', 'A carregar…')
        : journal.hasError
        ? copyFor(context, 'Unavailable', 'Indisponível')
        : '${journal.value?.length ?? 0}';
    return _AppScreen(
      key: const Key('screen-data-hub'),
      activePath: '/you',
      children: <Widget>[
        _TopBar(
          leading: _BackButton(
            label: copyFor(context, 'Back to You', 'Voltar ao perfil'),
            fallbackPath: '/you',
          ),
          center: LibreRingEyebrow(
            copyFor(context, 'Your data', 'Os seus dados'),
          ),
          trailing: const Icon(Icons.lock_outline_rounded, size: 19),
        ),
        const SizedBox(height: 24),
        _Heading(
          copyFor(
            context,
            'Your data, in your hands.',
            'Os seus dados, nas suas mãos.',
          ),
          fontSize: 32,
        ),
        const SizedBox(height: 10),
        Text(
          copyFor(
            context,
            'Export a copy or remove records from this phone.',
            'Exporte uma cópia ou remova registos deste telemóvel.',
          ),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        LibreRingCard(
          child: Column(
            children: <Widget>[
              _CompactEvidenceRow(
                title: copyFor(context, 'Ring history', 'Histórico do anel'),
                value: ringCount,
                detail: copyFor(
                  context,
                  'Stored on this phone',
                  'Guardado neste telemóvel',
                ),
              ),
              _CompactEvidenceRow(
                title: copyFor(context, 'Manual context', 'Contexto manual'),
                value: journalCount,
                detail: copyFor(
                  context,
                  'Your journal and activity entries',
                  'Os seus registos de diário e atividade',
                ),
              ),
              _CompactEvidenceRow(
                title: copyFor(
                  context,
                  'Device identity',
                  'Identidade do dispositivo',
                ),
                value: copyFor(context, 'Private', 'Privada'),
                detail: copyFor(
                  context,
                  'No Bluetooth identifier in your export',
                  'Sem identificador Bluetooth na exportação',
                ),
              ),
            ],
          ),
        ),
        if (!demo && (ring.hasError || journal.hasError)) ...<Widget>[
          const SizedBox(height: 16),
          _AccentNote(
            copyFor(
              context,
              'Some saved records could not be read. Existing files have been kept.',
              'Não foi possível ler alguns registos. Os ficheiros existentes foram mantidos.',
            ),
          ),
          TextButton(
            key: const Key('retry-data-stores'),
            onPressed: _busy != null
                ? null
                : () {
                    if (ring.hasError) ref.invalidate(ringDataProvider);
                    if (journal.hasError) ref.invalidate(journalProvider);
                  },
            child: Text(
              copyFor(
                context,
                'Try loading again',
                'Tentar carregar novamente',
              ),
            ),
          ),
        ],
        const SizedBox(height: 22),
        LibreRingPrimaryButton(
          key: const Key('create-data-export'),
          label: _busy == 'export' || export.isLoading
              ? copyFor(context, 'Creating export…', 'A criar exportação…')
              : copyFor(
                  context,
                  'Create JSON + CSV export',
                  'Criar exportação JSON + CSV',
                ),
          icon: Icons.download_outlined,
          onPressed: !canExport || _busy != null || export.isLoading
              ? null
              : _createExport,
        ),
        if (!demo &&
            !ring.isLoading &&
            !ring.hasError &&
            dataset == null) ...<Widget>[
          const SizedBox(height: 12),
          Text(
            copyFor(
              context,
              'Sync your ring to create an export. Journal-only exports are not available yet.',
              'Sincronize o anel para criar uma exportação. A exportação apenas do diário ainda não está disponível.',
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        if (_message != null) ...<Widget>[
          const SizedBox(height: 16),
          Semantics(
            liveRegion: true,
            child: Text(
              _message!,
              key: const Key('data-hub-feedback'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _failed
                    ? Theme.of(context).colorScheme.error
                    : LibreRingTokens.sage,
              ),
            ),
          ),
        ],
        if (result != null) ...<Widget>[
          const SizedBox(height: 18),
          LibreRingCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _SectionHeading(
                  title: copyFor(context, 'Export ready', 'Exportação pronta'),
                  action: copyFor(
                    context,
                    '${result.rowCount} rows',
                    '${result.rowCount} linhas',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  copyFor(
                    context,
                    'Created ${DateFormat('d MMM, HH:mm').format(result.createdAtUtc.toLocal())} · JSON and CSV',
                    'Criado ${DateFormat('d MMM, HH:mm').format(result.createdAtUtc.toLocal())} · JSON e CSV',
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  key: const Key('share-data-export'),
                  onPressed: _busy != null ? null : () => _share(result),
                  icon: const Icon(Icons.ios_share, size: 18),
                  label: Text(
                    _busy == 'share'
                        ? copyFor(
                            context,
                            'Opening share…',
                            'A abrir partilha…',
                          )
                        : copyFor(
                            context,
                            'Share files',
                            'Partilhar ficheiros',
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 30),
        _SectionHeading(
          title: copyFor(
            context,
            'Remove local records',
            'Remover registos locais',
          ),
        ),
        _ActionTile(
          key: const Key('delete-manual-context'),
          icon: Icons.delete_outline,
          title: _busy == 'manual'
              ? copyFor(context, 'Please wait…', 'Aguarde…')
              : journal.hasError
              ? copyFor(
                  context,
                  'Delete unreadable manual context',
                  'Eliminar contexto manual ilegível',
                )
              : copyFor(
                  context,
                  'Delete manual context',
                  'Eliminar contexto manual',
                ),
          body: syncing
              ? copyFor(
                  context,
                  'Available after the current sync finishes',
                  'Disponível após a sincronização atual',
                )
              : journal.hasError
              ? copyFor(
                  context,
                  'Cannot preview this file · deletion cannot be undone',
                  'Não é possível pré-visualizar · a eliminação não pode ser anulada',
                )
              : copyFor(
                  context,
                  'Keeps ring measurements and prior exports',
                  'Mantém medições do anel e exportações anteriores',
                ),
          onTap:
              _busy != null ||
                  syncing ||
                  journal.isLoading ||
                  (journal.hasError &&
                      ref.watch(journalRepositoryProvider) == null) ||
                  (!journal.hasError && (journal.value?.isEmpty ?? true))
              ? null
              : _deleteManual,
        ),
        _ActionTile(
          key: const Key('delete-ring-history-hub'),
          icon: Icons.delete_forever_outlined,
          title: _busy == 'ring'
              ? copyFor(context, 'Please wait…', 'Aguarde…')
              : ring.hasError
              ? copyFor(
                  context,
                  'Delete unreadable ring history',
                  'Eliminar histórico ilegível do anel',
                )
              : copyFor(
                  context,
                  'Delete ring history',
                  'Eliminar histórico do anel',
                ),
          body: syncing
              ? copyFor(
                  context,
                  'Available after the current sync finishes',
                  'Disponível após a sincronização atual',
                )
              : ring.hasError
              ? copyFor(
                  context,
                  'Cannot preview this file · deletion cannot be undone',
                  'Não é possível pré-visualizar · a eliminação não pode ser anulada',
                )
              : copyFor(
                  context,
                  'Keeps manual context and exported files',
                  'Mantém contexto manual e ficheiros exportados',
                ),
          onTap:
              _busy != null ||
                  syncing ||
                  ring.isLoading ||
                  (ring.hasError &&
                      ref.watch(ringDataRepositoryProvider) == null) ||
                  (!ring.hasError && dataset == null)
              ? null
              : _deleteRing,
        ),
        const SizedBox(height: 8),
        Text(
          copyFor(
            context,
            'Exported files are separate copies. Deleting records here does not remove copies you have saved or shared.',
            'Os ficheiros exportados são cópias separadas. Eliminar registos aqui não remove cópias guardadas ou partilhadas.',
          ),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) => _AppScreen(
    key: const Key('screen-about'),
    activePath: '/you',
    children: <Widget>[
      _TopBar(
        leading: _BackButton(
          label: copyFor(context, 'Back to You', 'Voltar ao perfil'),
          fallbackPath: '/you',
        ),
        center: LibreRingEyebrow(copyFor(context, 'About', 'Sobre')),
        trailing: const SizedBox(width: 48),
      ),
      const SizedBox(height: 30),
      const LibreRingWordmark(),
      const SizedBox(height: 22),
      _Heading(
        copyFor(
          context,
          'Built around your privacy.',
          'Feito a pensar na sua privacidade.',
        ),
        fontSize: 34,
      ),
      const SizedBox(height: 16),
      Text(
        copyFor(
          context,
          'LibreRing is an open-source wellness application. It is not a medical device and does not diagnose, prevent, monitor, treat, or cure a condition.',
          'O LibreRing é uma aplicação de bem-estar de código aberto. Não é um dispositivo médico e não diagnostica, previne, monitoriza, trata ou cura qualquer condição.',
        ),
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      const SizedBox(height: 30),
      _CompactEvidenceRow(
        title: copyFor(context, 'Application', 'Aplicação'),
        value: '1.1.0 (5)',
        detail: copyFor(
          context,
          'Local-first product preview',
          'Pré-visualização com prioridade local',
        ),
      ),
      _CompactEvidenceRow(
        title: copyFor(context, 'Health model', 'Modelo de saúde'),
        value: copyFor(context, 'Evidence first', 'Evidência primeiro'),
        detail: copyFor(
          context,
          'No opaque production score',
          'Sem pontuação de produção opaca',
        ),
      ),
      _CompactEvidenceRow(
        title: copyFor(context, 'Licence', 'Licença'),
        value: 'Apache-2.0',
        detail: copyFor(
          context,
          'Original LibreRing code',
          'Código original do LibreRing',
        ),
      ),
      const SizedBox(height: 24),
      _AccentNote(
        copyFor(
          context,
          'Consumer smart-ring measurements can be incomplete or inaccurate. Seek qualified medical advice for health concerns.',
          'As medições de anéis inteligentes de consumo podem estar incompletas ou incorretas. Procure aconselhamento médico qualificado para questões de saúde.',
        ),
      ),
    ],
  );
}

class CyclePrivacyScreen extends ConsumerStatefulWidget {
  const CyclePrivacyScreen({super.key});

  @override
  ConsumerState<CyclePrivacyScreen> createState() => _CyclePrivacyScreenState();
}

class _CyclePrivacyScreenState extends ConsumerState<CyclePrivacyScreen> {
  bool _deleting = false;

  Future<void> _deleteRingData() async {
    if (_deleting || ref.read(ringPairingProvider).syncInProgress) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          copyFor(
            dialogContext,
            'Delete local ring data?',
            'Eliminar dados locais do anel?',
          ),
        ),
        content: Text(
          copyFor(
            dialogContext,
            'This removes stored history from this phone. It does not erase the ring.',
            'Isto remove o histórico guardado neste telemóvel. Não apaga o anel.',
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(copyFor(dialogContext, 'Cancel', 'Cancelar')),
          ),
          FilledButton(
            key: const Key('confirm-delete-ring-data'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(copyFor(dialogContext, 'Delete', 'Eliminar')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    // Sync may have started while the confirmation was open.
    if (ref.read(ringPairingProvider).syncInProgress) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            copyFor(
              context,
              'Let your ring finish syncing before deleting its history.',
              'Deixe o anel terminar a sincronização antes de eliminar o histórico.',
            ),
          ),
        ),
      );
      return;
    }
    setState(() => _deleting = true);
    try {
      await ref.read(ringDataProvider.notifier).deleteAll();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            copyFor(
              context,
              'Could not delete local history. Your stored data is still available.',
              'Não foi possível eliminar o histórico local. Os dados guardados continuam disponíveis.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ringDataset = ref.watch(ringDataProvider).value;
    final syncing = ref.watch(ringPairingProvider).syncInProgress;
    return _AppScreen(
      key: const Key('screen-cycle-privacy'),
      activePath: '/you',
      children: <Widget>[
        _TopBar(
          leading: _BackButton(
            label: copyFor(context, 'Back to You', 'Voltar ao perfil'),
            fallbackPath: '/you',
          ),
          center: LibreRingEyebrow(copyFor(context, 'Privacy', 'Privacidade')),
          trailing: const SizedBox(width: 48),
        ),
        const SizedBox(height: 20),
        _DateLabel(copyFor(context, 'Cycle context', 'Contexto do ciclo')),
        const SizedBox(height: 4),
        _Heading(copyFor(context, 'Not available yet', 'Ainda não disponível')),
        const SizedBox(height: 10),
        Text(
          copyFor(
            context,
            'Cycle tracking is not part of LibreRing yet. No cycle entries are collected, and there are no cycle predictions or export settings to enable.',
            'O LibreRing ainda não inclui acompanhamento do ciclo. Não são recolhidos registos do ciclo e não existem previsões nem definições de exportação para ativar.',
          ),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 28),
        LibreRingCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Icon(Icons.lock_outline, size: 26),
              const SizedBox(height: 14),
              Text(
                copyFor(
                  context,
                  'Your existing data stays yours',
                  'Os seus dados continuam a ser seus',
                ),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                copyFor(
                  context,
                  'Manage the ring history and journal entries that are actually stored on this phone.',
                  'Faça a gestão do histórico do anel e dos registos do diário guardados neste telemóvel.',
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                key: const Key('cycle-data-controls'),
                onPressed: () => context.go('/you/data'),
                icon: const Icon(Icons.folder_outlined),
                label: Text(
                  copyFor(
                    context,
                    'Open data controls',
                    'Abrir controlos de dados',
                  ),
                ),
              ),
            ],
          ),
        ),
        if (ringDataset != null) ...<Widget>[
          const SizedBox(height: 34),
          _SectionHeading(
            title: copyFor(context, 'Local ring data', 'Dados locais do anel'),
            action: copyFor(
              context,
              '${ringDataset.recordCount} records',
              '${ringDataset.recordCount} registos',
            ),
          ),
          const SizedBox(height: 10),
          Text(
            copyFor(
              context,
              'Deletes the versioned ring history store on this phone. The ring itself is not changed.',
              'Elimina o histórico versionado do anel neste telemóvel. O anel não é alterado.',
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            key: const Key('delete-ring-data'),
            onPressed: syncing || _deleting ? null : _deleteRingData,
            child: Text(
              copyFor(
                context,
                _deleting ? 'Deleting…' : 'Delete local ring data',
                _deleting ? 'A eliminar…' : 'Eliminar dados locais do anel',
              ),
            ),
          ),
          if (syncing)
            Text(
              copyFor(
                context,
                'Available after your ring finishes syncing.',
                'Disponível quando o anel terminar a sincronização.',
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
        const SizedBox(height: 24),
        LibreRingPrimaryButton(
          label: copyFor(context, 'Done', 'Concluído'),
          onPressed: () => context.go('/today'),
        ),
      ],
    );
  }
}

class _OnboardingScreen extends StatelessWidget {
  const _OnboardingScreen({
    required this.top,
    required this.art,
    required this.title,
    required this.subtitle,
    required this.action,
    this.preTitle,
    this.detail,
    this.centered = false,
    super.key,
  });

  final Widget top;
  final Widget art;
  final String title;
  final String subtitle;
  final Widget action;
  final Widget? preTitle;
  final Widget? detail;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: centered
                        ? CrossAxisAlignment.center
                        : CrossAxisAlignment.start,
                    children: <Widget>[
                      top,
                      Expanded(child: Center(child: art)),
                      if (preTitle != null)
                        Container(
                          width: 52,
                          height: 52,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: const BoxDecoration(
                            color: LibreRingTokens.accent,
                            shape: BoxShape.circle,
                          ),
                          child: preTitle,
                        ),
                      Text(
                        title,
                        textAlign: centered ? TextAlign.center : TextAlign.left,
                        style: Theme.of(context).textTheme.displayMedium
                            ?.copyWith(
                              fontSize: 48,
                              height: 1.04,
                              letterSpacing: -1.7,
                            ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        subtitle,
                        textAlign: centered ? TextAlign.center : TextAlign.left,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(fontSize: 15),
                      ),
                      if (detail != null) ...<Widget>[
                        const SizedBox(height: 16),
                        detail!,
                      ],
                      const SizedBox(height: 22),
                      action,
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AppScreen extends StatelessWidget {
  const _AppScreen({required this.children, this.activePath, super.key});

  final List<Widget> children;
  final String? activePath;

  @override
  Widget build(BuildContext context) {
    return RingPageScaffold(
      activePath: activePath,
      scrollKey: key?.toString(),
      children: children,
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.leading, required this.trailing, this.center});

  final Widget leading;
  final Widget? center;
  final Widget trailing;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Align(alignment: Alignment.centerLeft, child: leading),
        ?center,
        Align(alignment: Alignment.centerRight, child: trailing),
      ],
    ),
  );
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.label, this.fallbackPath = '/today'});

  final String label;
  final String fallbackPath;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: label,
    onPressed: () =>
        context.canPop() ? context.pop() : context.go(fallbackPath),
    icon: const Icon(Icons.arrow_back, size: 20),
  );
}

class _Heading extends StatelessWidget {
  const _Heading(this.text, {this.fontSize = 36});

  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(context).textTheme.displayMedium
        ?.copyWith(fontSize: fontSize, height: 1.08, letterSpacing: -1.1),
  );
}

class _DateLabel extends StatelessWidget {
  const _DateLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 12,
      letterSpacing: .5,
      color: LibreRingTokens.muted,
    ),
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final titleWidget = Text(
      title,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    );
    final actionWidget = action == null
        ? null
        : onAction == null
        ? Text(
            action!,
            style: const TextStyle(fontSize: 11, color: LibreRingTokens.muted),
          )
        : TextButton(onPressed: onAction, child: Text(action!));
    if (MediaQuery.textScalerOf(context).scale(1) >= 1.5) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[titleWidget, ?actionWidget],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Flexible(child: titleWidget),
        ?actionWidget,
      ],
    );
  }
}

class _DailySignalCard extends StatelessWidget {
  const _DailySignalCard({required this.signal, required this.onTap});

  final DailySignalView signal;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: onTap != null,
    label: '${signal.eyebrow}. ${signal.headline} ${signal.body}',
    child: ExcludeSemantics(
      child: InkWell(
        key: const Key('daily-signal'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(LibreRingTokens.controlRadius),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(0, 4, 0, 22),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: LibreRingTokens.border)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      signal.eyebrow.toUpperCase(),
                      style: const TextStyle(
                        color: LibreRingTokens.foreground,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: .9,
                      ),
                    ),
                  ),
                  _DarkConfidence(confidence: signal.confidence),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                signal.headline,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: LibreRingTokens.accent,
                  fontSize: 44,
                  height: 1.01,
                  letterSpacing: -2,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                signal.body,
                style: const TextStyle(
                  color: LibreRingTokens.foreground,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      signal.actionLabel,
                      maxLines: 2,
                      style: const TextStyle(
                        color: LibreRingTokens.foreground,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward,
                    color: LibreRingTokens.accent,
                    size: 18,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _DomainSummaryCard extends StatelessWidget {
  const _DomainSummaryCard({required this.summary, required this.onTap});

  final ProductDomainSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label:
        '${summary.label}. ${summary.value}. ${summary.status}. ${summary.explanation}. ${summary.source}.',
    child: ExcludeSemantics(
      child: InkWell(
        key: Key('domain-${summary.domain.name}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(LibreRingTokens.controlRadius),
        child: Container(
          constraints: const BoxConstraints(minHeight: 86),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: LibreRingTokens.border)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            summary.label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _ConfidenceDot(confidence: summary.confidence),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      summary.status,
                      style: const TextStyle(
                        fontSize: 10,
                        color: LibreRingTokens.muted,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      summary.explanation,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    summary.value,
                    style: const TextStyle(
                      fontSize: 28,
                      height: 1,
                      fontWeight: FontWeight.w300,
                      letterSpacing: -1.4,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    summary.source,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontSize: 9,
                      color: LibreRingTokens.muted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _DarkConfidence extends StatelessWidget {
  const _DarkConfidence({required this.confidence});

  final ProductConfidence confidence;

  @override
  Widget build(BuildContext context) => Text(
    switch (confidence) {
      ProductConfidence.high => 'HIGH',
      ProductConfidence.moderate => 'MODERATE',
      ProductConfidence.limited => 'LIMITED',
      ProductConfidence.unavailable => 'UNAVAILABLE',
    },
    style: const TextStyle(
      color: LibreRingTokens.muted,
      fontSize: 9,
      fontWeight: FontWeight.w600,
      letterSpacing: .6,
    ),
  );
}

class _ConfidenceDot extends StatelessWidget {
  const _ConfidenceDot({required this.confidence});

  final ProductConfidence confidence;

  @override
  Widget build(BuildContext context) => Container(
    width: 7,
    height: 7,
    decoration: BoxDecoration(
      color: switch (confidence) {
        ProductConfidence.high => const Color(0xFF558871),
        ProductConfidence.moderate => LibreRingTokens.accent,
        ProductConfidence.limited => const Color(0xFFB88B45),
        ProductConfidence.unavailable => LibreRingTokens.muted,
      },
      shape: BoxShape.circle,
    ),
  );
}

class _CompactEvidenceRow extends StatelessWidget {
  const _CompactEvidenceRow({
    required this.title,
    required this.value,
    required this.detail,
  });

  final String title;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 66),
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: LibreRingTokens.border)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                detail,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(fontSize: 10.5),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.body,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String body;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$title. $body',
    button: onTap != null,
    child: ExcludeSemantics(
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 78),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: LibreRingTokens.border)),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: LibreRingTokens.surface,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      body,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              if (onTap != null) const Icon(Icons.arrow_forward, size: 18),
            ],
          ),
        ),
      ),
    ),
  );
}

class _JournalRow extends StatelessWidget {
  const _JournalRow({
    required this.entry,
    required this.onDelete,
    this.deleting = false,
  });

  final JournalEntry entry;
  final VoidCallback? onDelete;
  final bool deleting;

  @override
  Widget build(BuildContext context) => Container(
    key: Key('journal-entry-${entry.id}'),
    constraints: const BoxConstraints(minHeight: 82),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: LibreRingTokens.border)),
    ),
    child: Row(
      children: <Widget>[
        Icon(switch (entry.kind) {
          JournalEntryKind.swim => Icons.pool_outlined,
          JournalEntryKind.checkIn => Icons.add_reaction_outlined,
          JournalEntryKind.note => Icons.notes_outlined,
        }, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                entry.kind == JournalEntryKind.checkIn
                    ? entry.title
                          .split(' · ')
                          .map((tag) => _checkInTagLabel(context, tag))
                          .join(' · ')
                    : entry.title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 3),
              Text(entry.details, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 4),
              Text(
                '${MaterialLocalizations.of(context).formatShortDate(entry.occurredAtUtc.toLocal())} · '
                '${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(entry.occurredAtUtc.toLocal()))}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
        IconButton(
          key: Key('delete-journal-${entry.id}'),
          tooltip: copyFor(context, 'Delete entry', 'Eliminar registo'),
          onPressed: onDelete,
          icon: deleting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.delete_outline, size: 19),
        ),
      ],
    ),
  );
}

String _checkInTagLabel(BuildContext context, String tag) => switch (tag) {
  'Exercise' => copyFor(context, tag, 'Exercício'),
  'Late meal' => copyFor(context, tag, 'Refeição tardia'),
  'Alcohol' => copyFor(context, tag, 'Álcool'),
  'Travel' => copyFor(context, tag, 'Viagem'),
  'Illness' => copyFor(context, tag, 'Doença'),
  'Meditation' => copyFor(context, tag, 'Meditação'),
  'Note' => copyFor(context, tag, 'Nota'),
  _ => tag,
};

class _OxygenRangeChart extends StatelessWidget {
  const _OxygenRangeChart({required this.ranges});

  final List<RingOxygenRange> ranges;

  @override
  Widget build(BuildContext context) => Semantics(
    label:
        '${ranges.length} hourly oxygen ranges from ${ranges.map((value) => value.minimumPercent).reduce(math.min)} to ${ranges.map((value) => value.maximumPercent).reduce(math.max)} percent',
    child: ExcludeSemantics(
      child: CustomPaint(painter: _OxygenRangePainter(ranges)),
    ),
  );
}

class _OxygenRangePainter extends CustomPainter {
  _OxygenRangePainter(this.ranges);

  final List<RingOxygenRange> ranges;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()..color = LibreRingTokens.border;
    for (final y in <double>[.2, .5, .8]) {
      canvas.drawLine(
        Offset(0, size.height * y),
        Offset(size.width, size.height * y),
        grid,
      );
    }
    if (ranges.isEmpty) return;
    final width = size.width / ranges.length;
    final paint = Paint()
      ..color = LibreRingTokens.accent
      ..strokeWidth = math.min(6, width * .55)
      ..strokeCap = StrokeCap.round;
    double yFor(int value) => size.height * (.88 - ((value - 85) / 15) * .7);
    for (var index = 0; index < ranges.length; index++) {
      final range = ranges[index];
      final x = width * index + width / 2;
      canvas.drawLine(
        Offset(x, yFor(range.minimumPercent)),
        Offset(x, yFor(range.maximumPercent)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_OxygenRangePainter oldDelegate) =>
      oldDelegate.ranges != ranges;
}

Future<bool> _confirm(
  BuildContext context, {
  required String title,
  required String body,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(copyFor(dialogContext, 'Cancel', 'Cancelar')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(copyFor(dialogContext, 'Delete', 'Eliminar')),
          ),
        ],
      ),
    ) ??
    false;

class _UnavailableDataCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => LibreRingCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Icon(Icons.sensors_off_outlined),
        const SizedBox(height: 24),
        Text(
          copyFor(
            context,
            'No production data yet',
            'Ainda sem dados de produção',
          ),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          copyFor(
            context,
            'Pair the verified R12 and sync it. LibreRing never substitutes demo values in production.',
            'Emparelhe o R12 verificado e sincronize-o. O LibreRing nunca substitui valores de demonstração em produção.',
          ),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric, required this.onTap});

  final MetricSummary metric;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    label:
        '${metric.label}, ${metric.value} ${metric.unit}. ${metric.context}. ${metric.origin == DataOrigin.demo ? 'Demo data' : 'Ring data'}.',
    button: true,
    child: ExcludeSemantics(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(LibreRingTokens.cardRadius),
        child: LibreRingCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Flexible(
                    child: Text(
                      metric.label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                  ),
                  if (metric.unit == 'ms')
                    const Icon(
                      Icons.show_chart,
                      size: 22,
                      color: LibreRingTokens.accent,
                    ),
                ],
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      color: LibreRingTokens.foreground,
                      fontFamily: 'Helvetica Neue',
                      fontFamilyFallback: <String>['Arial', 'sans-serif'],
                    ),
                    children: <InlineSpan>[
                      TextSpan(
                        text: metric.value,
                        style: const TextStyle(
                          fontSize: 60,
                          fontWeight: FontWeight.w200,
                          letterSpacing: -4,
                        ),
                      ),
                      if (metric.unit.isNotEmpty)
                        TextSpan(
                          text: ' ${metric.unit}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: LibreRingTokens.muted,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Text(
                metric.context,
                style: const TextStyle(
                  fontSize: 11,
                  color: LibreRingTokens.muted,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

const _axisStyle = TextStyle(
  fontSize: 10,
  color: LibreRingTokens.muted,
  fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
);

class _SleepBars extends StatelessWidget {
  const _SleepBars();

  @override
  Widget build(BuildContext context) {
    const heights = <double>[.66, .84, .92, .76, .96, .88, .62, .78];
    const opacity = <double>[.44, .65, 1, .74, 1, .84, .54, .72];
    return SizedBox(
      height: 118,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List<Widget>.generate(
          heights.length,
          (int index) => Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: FractionallySizedBox(
                heightFactor: heights[index],
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: LibreRingTokens.accent.withValues(
                      alpha: opacity[index],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SleepStageBars extends StatelessWidget {
  const _SleepStageBars(this.stages);

  final List<RingSleepStageSpan> stages;

  @override
  Widget build(BuildContext context) {
    if (stages.isEmpty) {
      return SizedBox(
        height: 72,
        child: Center(
          child: Text(
            copyFor(
              context,
              'No stage-duration runs were retained.',
              'Não foram retidos períodos de fases.',
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
    }
    return Semantics(
      label: '${stages.length} firmware sleep stage runs',
      child: ExcludeSemantics(
        child: SizedBox(
          height: 72,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: stages
                .map(
                  (span) => Expanded(
                    flex: math.max(1, span.durationMinutes),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: switch (span.stage) {
                            RingSleepStage.deep => LibreRingTokens.accent,
                            RingSleepStage.rem => const Color(0xFFD17B63),
                            RingSleepStage.light => const Color(0xFFDCA999),
                            RingSleepStage.awake => LibreRingTokens.surface,
                          },
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ),
      ),
    );
  }
}

class _DailyDecodeStrip extends StatelessWidget {
  const _DailyDecodeStrip({required this.analytics});

  final RingAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final activity = analytics.activityFor(analytics.selectedDay);
    final pulse = analytics.pulseFor(analytics.selectedDay);
    final oxygen = analytics.oxygenFor(analytics.selectedDay);
    return LibreRingCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: Row(
        children: <Widget>[
          _DecodeValue(
            value: RingProductView.distanceLabel(activity.distanceMeters),
            label: copyFor(context, 'Distance', 'Distância'),
          ),
          _DecodeValue(
            value: '${activity.firmwareCalories}',
            label: copyFor(context, 'Firmware kcal', 'kcal firmware'),
          ),
          _DecodeValue(
            value: '${pulse.samples.length + oxygen.ranges.length}',
            label: copyFor(context, 'Vital records', 'Registos vitais'),
          ),
        ],
      ),
    );
  }
}

class _DecodeValue extends StatelessWidget {
  const _DecodeValue({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            maxLines: 1,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w300,
              letterSpacing: -.6,
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(fontSize: 8.5, color: LibreRingTokens.muted),
        ),
      ],
    ),
  );
}

class _VendorSignalRow extends StatelessWidget {
  const _VendorSignalRow({
    required this.dataset,
    required this.kind,
    required this.label,
    required this.route,
  });

  final RingSyncDataset dataset;
  final RingVendorIndexKind kind;
  final String label;
  final String route;

  @override
  Widget build(BuildContext context) {
    final values =
        dataset.vendorIndexes
            .where((sample) => sample.kind == kind)
            .toList(growable: false)
          ..sort(
            (left, right) => left.measuredAtUtc.compareTo(right.measuredAtUtc),
          );
    return _DataRow(
      icon: kind == RingVendorIndexKind.stress
          ? Icons.spa_outlined
          : Icons.monitor_heart_outlined,
      title: label,
      meta: copyFor(
        context,
        '${values.length} values · unit and thresholds unvalidated',
        '${values.length} valores · unidade e limites não validados',
      ),
      value: values.isEmpty ? '—' : '${values.last.value}',
      onTap: () => context.go(route),
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({
    required this.icon,
    required this.title,
    required this.meta,
    this.value,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String meta;
  final String? value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$title. $meta${value == null ? '' : '. $value'}',
    button: onTap != null,
    child: ExcludeSemantics(
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 68),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: LibreRingTokens.border)),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: LibreRingTokens.surface,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      meta,
                      style: const TextStyle(
                        fontSize: 11,
                        color: LibreRingTokens.muted,
                      ),
                    ),
                  ],
                ),
              ),
              if (value != null)
                Text(
                  value!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: LibreRingTokens.muted,
                  ),
                ),
              if (onTap != null) const Icon(Icons.arrow_forward, size: 18),
            ],
          ),
        ),
      ),
    ),
  );
}

class _Confidence extends StatelessWidget {
  const _Confidence(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
    decoration: BoxDecoration(
      color: LibreRingTokens.surface,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w600,
        letterSpacing: .6,
      ),
    ),
  );
}

class _AccentNote extends StatelessWidget {
  const _AccentNote(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.only(left: 14),
    decoration: const BoxDecoration(
      border: Border(left: BorderSide(color: LibreRingTokens.accent, width: 2)),
    ),
    child: Text(text, style: Theme.of(context).textTheme.bodySmall),
  );
}

class _TrendRange extends StatefulWidget {
  const _TrendRange();

  @override
  State<_TrendRange> createState() => _TrendRangeState();
}

class _TrendRangeState extends State<_TrendRange> {
  String selected = '8 weeks';

  @override
  Widget build(BuildContext context) => SegmentedButton<String>(
    showSelectedIcon: false,
    segments: <ButtonSegment<String>>[
      ButtonSegment(
        value: '7 days',
        label: Text(copyFor(context, '7 days', '7 dias')),
      ),
      ButtonSegment(
        value: '8 weeks',
        label: Text(copyFor(context, '8 weeks', '8 semanas')),
      ),
      ButtonSegment(
        value: '6 months',
        label: Text(copyFor(context, '6 months', '6 meses')),
      ),
    ],
    selected: <String>{selected},
    onSelectionChanged: (Set<String> value) =>
        setState(() => selected = value.first),
  );
}

class _HistoryRangeSelector extends StatelessWidget {
  const _HistoryRangeSelector({
    required this.selected,
    required this.onChanged,
  });

  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => SegmentedButton<int>(
    key: const Key('trend-range-selector'),
    showSelectedIcon: false,
    segments: <ButtonSegment<int>>[
      ButtonSegment(
        value: 7,
        label: Text(copyFor(context, '7 days', '7 dias')),
      ),
      ButtonSegment(
        value: 30,
        label: Text(copyFor(context, '30 days', '30 dias')),
      ),
      ButtonSegment(
        value: 90,
        label: Text(copyFor(context, '90 days', '90 dias')),
      ),
    ],
    selected: <int>{selected},
    onSelectionChanged: (value) => onChanged(value.first),
  );
}

class _MeasuredTrendCard extends StatelessWidget {
  const _MeasuredTrendCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.values,
    required this.source,
    super.key,
  });

  final String title;
  final String value;
  final String unit;
  final List<double?> values;
  final String source;

  @override
  Widget build(BuildContext context) {
    final count = values.whereType<double>().length;
    return LibreRingCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 34,
                        height: .95,
                        fontWeight: FontWeight.w200,
                        letterSpacing: -1.7,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      unit,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(fontSize: 10.5),
                    ),
                  ],
                ),
              ),
              _Confidence(
                count == 0
                    ? copyFor(context, 'Unavailable', 'Indisponível')
                    : copyFor(context, '$count days', '$count dias'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Semantics(
            label: count == 0
                ? '$title has no retained values in this period'
                : '$title has $count retained daily values in this period. Missing days are shown as gaps.',
            child: ExcludeSemantics(
              child: TweenAnimationBuilder<double>(
                key: ValueKey<String>('trend-$title-${values.length}-$count'),
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 520),
                curve: LibreRingTokens.curve,
                tween: Tween<double>(begin: 0, end: 1),
                builder: (context, progress, child) => SizedBox(
                  height: 76,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _MeasuredTrendPainter(values, progress: progress),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            source,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _MeasuredTrendPainter extends CustomPainter {
  _MeasuredTrendPainter(this.values, {required this.progress});

  final List<double?> values;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()..color = LibreRingTokens.border;
    for (final y in <double>[.2, .5, .8]) {
      canvas.drawLine(
        Offset(0, size.height * y),
        Offset(size.width, size.height * y),
        grid,
      );
    }
    final present = values.whereType<double>().toList(growable: false);
    if (present.isEmpty) return;
    final minValue = present.reduce(math.min);
    final maxValue = present.reduce(math.max);
    final range = math.max(1, maxValue - minValue);
    final count = math.max(2, values.length);
    final line = Paint()
      ..color = LibreRingTokens.foreground
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.25
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final dot = Paint()..color = LibreRingTokens.accent;
    Path? run;
    var runPoints = 0;
    for (var index = 0; index < values.length; index++) {
      final value = values[index];
      if (value == null) {
        if (run != null && runPoints > 1) canvas.drawPath(run, line);
        run = null;
        runPoints = 0;
        continue;
      }
      final x = size.width * index / (count - 1);
      if (x > size.width * progress) break;
      final y = size.height * (.82 - ((value - minValue) / range) * .64);
      run ??= Path()..moveTo(x, y);
      if (runPoints > 0) run.lineTo(x, y);
      runPoints += 1;
      canvas.drawCircle(Offset(x, y), 2.7, dot);
    }
    if (run != null && runPoints > 1) canvas.drawPath(run, line);
  }

  @override
  bool shouldRepaint(_MeasuredTrendPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.progress != progress;
}

class _TrendPainter extends CustomPainter {
  _TrendPainter(this.values);

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()..color = LibreRingTokens.border;
    for (final y in <double>[.22, .5, .78]) {
      canvas.drawLine(
        Offset(0, size.height * y),
        Offset(size.width, size.height * y),
        grid,
      );
    }
    if (values.length < 2) return;
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final range = math.max(1, maxValue - minValue);
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y = size.height * (.82 - ((values[i] - minValue) / range) * .62);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final area = Path.from(path)
      ..lineTo(size.width, size.height * .9)
      ..lineTo(0, size.height * .9)
      ..close();
    canvas.drawPath(
      area,
      Paint()..color = LibreRingTokens.accent.withValues(alpha: .2),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = LibreRingTokens.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_TrendPainter oldDelegate) => oldDelegate.values != values;
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    ),
  );
}
