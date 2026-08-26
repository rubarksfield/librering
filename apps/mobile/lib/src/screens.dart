import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ring_core/ring_core.dart';
import 'package:ring_design_system/ring_design_system.dart';

import 'app_state.dart';
import 'ble/r12_pairing_client.dart';
import 'localized_copy.dart';
import 'ring_data_view.dart';

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

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demo = ref.watch(isDemoModeProvider);
    final snapshot = ref.watch(dailySnapshotProvider);
    final dataset = demo ? null : ref.watch(ringDataProvider).value;
    final view = dataset == null
        ? null
        : RingDashboardView.fromDataset(dataset);
    return _AppScreen(
      key: const Key('screen-today'),
      activePath: '/today',
      children: <Widget>[
        _TopBar(
          leading: const LibreRingWordmark(),
          trailing: IconButton(
            tooltip: copyFor(
              context,
              'Privacy controls',
              'Controlos de privacidade',
            ),
            onPressed: () => context.go('/privacy/cycle'),
            icon: const Icon(Icons.lock_outline, size: 20),
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
        else if (view != null) ...<Widget>[
          _Heading(
            copyFor(
              context,
              'Ring data synced.',
              'Dados do anel sincronizados.',
            ),
            fontSize: 48,
          ),
          const SizedBox(height: 18),
          Text(
            copyFor(
              context,
              'Measured history is stored on this phone. Recovery scoring is unavailable until its inputs and method are validated.',
              'O histórico medido está guardado neste telemóvel. A pontuação de recuperação está indisponível até os dados e o método serem validados.',
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
                    'Local ring history',
                    'Histórico local do anel',
                  ),
                  action: copyFor(context, 'View metrics', 'Ver métricas'),
                  onAction: () => context.go('/metrics'),
                ),
                const SizedBox(height: 22),
                Text(
                  '${dataset!.recordCount}',
                  style: const TextStyle(
                    fontSize: 64,
                    height: .9,
                    fontWeight: FontWeight.w200,
                    letterSpacing: -4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  copyFor(
                    context,
                    'deduplicated records · battery ${dataset.batteryLevel == null ? 'unavailable' : '${dataset.batteryLevel}%'}',
                    'registos sem duplicados · bateria ${dataset.batteryLevel == null ? 'indisponível' : '${dataset.batteryLevel}%'}',
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (view.pulseTrend.length >= 2) ...<Widget>[
            const SizedBox(height: 24),
            _DataRow(
              icon: Icons.favorite_outline,
              title: copyFor(
                context,
                'Measured pulse history',
                'Histórico de pulso medido',
              ),
              meta: copyFor(
                context,
                '${view.pulseTrend.length} samples · Ring source',
                '${view.pulseTrend.length} amostras · Origem no anel',
              ),
              onTap: () => context.go('/trends'),
            ),
          ],
        ] else ...<Widget>[
          Semantics(
            label: '${snapshot!.recoveryScore}, ${snapshot.recoveryLabel}',
            child: ExcludeSemantics(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      '${snapshot.recoveryScore}',
                      style: const TextStyle(
                        fontSize: 112,
                        height: .82,
                        fontWeight: FontWeight.w200,
                        letterSpacing: -7,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        copyFor(context, snapshot.recoveryLabel, 'Pronta'),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            copyFor(
              context,
              snapshot.recoverySummary,
              'A recuperação está estável. O sono recente e o pulso em repouso apoiam um dia normal.',
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 34),
          _SectionHeading(
            title: copyFor(
              context,
              'Eight-week recovery',
              'Recuperação em oito semanas',
            ),
            action: copyFor(context, 'View metrics', 'Ver métricas'),
            onAction: () => context.go('/metrics'),
          ),
          const SizedBox(height: 12),
          Semantics(
            button: true,
            label: copyFor(
              context,
              'Open eight-week recovery trend',
              'Abrir tendência de recuperação de oito semanas',
            ),
            child: InkWell(
              onTap: () => context.go('/trends'),
              borderRadius: BorderRadius.circular(12),
              child: _Heatmap(levels: snapshot.recoveryHistory),
            ),
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
        : RingDashboardView.fromDataset(dataset);
    final metrics = view?.metrics ?? snapshot?.metrics;
    final largeText = MediaQuery.textScalerOf(context).scale(1) >= 1.5;
    return _AppScreen(
      key: const Key('screen-metrics'),
      activePath: '/metrics',
      children: <Widget>[
        _TopBar(
          leading: const LibreRingWordmark(),
          trailing: LibreRingEyebrow(copyFor(context, 'Today', 'Hoje')),
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
            'Four signals.\nNothing extra.',
            'Quatro sinais.\nNada a mais.',
          ),
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
                onTap: metric.label == 'Sleep'
                    ? () => context.go('/sleep')
                    : () => context.go('/trends'),
              );
            },
          ),
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
      activePath: '/metrics',
      children: <Widget>[
        _TopBar(
          leading: _BackButton(
            label: copyFor(context, 'Back to metrics', 'Voltar às métricas'),
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
      activePath: '/metrics',
      children: <Widget>[
        _TopBar(
          leading: _BackButton(
            label: copyFor(context, 'Back to sleep', 'Voltar ao sono'),
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

class TrendsScreen extends ConsumerWidget {
  const TrendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demo = ref.watch(isDemoModeProvider);
    final snapshot = ref.watch(dailySnapshotProvider);
    final dataset = demo ? null : ref.watch(ringDataProvider).value;
    final view = dataset == null
        ? null
        : RingDashboardView.fromDataset(dataset);
    final values = view?.pulseTrend ?? snapshot?.hrvTrend;
    final average = view?.averagePulse ?? 62;
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

  @override
  void dispose() {
    _duration.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final saved = ref.watch(swimEntryProvider);
    return _AppScreen(
      key: const Key('screen-swim'),
      activePath: '/trends',
      children: <Widget>[
        _TopBar(
          leading: _BackButton(
            label: copyFor(context, 'Back to trend', 'Voltar à tendência'),
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
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
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
          onChanged: (String? value) => setState(() => _pool = value ?? _pool),
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
          onSelectionChanged: (Set<String> value) =>
              setState(() => _effort = value.first),
        ),
        const SizedBox(height: 24),
        LibreRingPrimaryButton(
          key: const Key('save-swim'),
          label: copyFor(context, 'Save locally', 'Guardar localmente'),
          icon: Icons.check,
          onPressed: () {
            final duration = int.tryParse(_duration.text);
            if (duration == null || duration < 1 || duration > 300) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    copyFor(
                      context,
                      'Enter 1–300 minutes.',
                      'Introduza 1–300 minutos.',
                    ),
                  ),
                ),
              );
              return;
            }
            ref
                .read(swimEntryProvider.notifier)
                .save(
                  durationMinutes: duration,
                  poolLength: _pool,
                  effort: _effort,
                );
          },
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            saved == null
                ? copyFor(context, 'Not yet saved', 'Ainda não guardado')
                : copyFor(
                    context,
                    'Saved locally · Manual source',
                    'Guardado localmente · Origem manual',
                  ),
            key: const Key('swim-save-status'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class CyclePrivacyScreen extends ConsumerWidget {
  const CyclePrivacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(privacySettingsProvider);
    final controller = ref.read(privacySettingsProvider.notifier);
    final ringDataset = ref.watch(ringDataProvider).value;
    return _AppScreen(
      key: const Key('screen-cycle-privacy'),
      activePath: '/privacy/cycle',
      children: <Widget>[
        _TopBar(
          leading: _BackButton(
            label: copyFor(context, 'Back to today', 'Voltar a hoje'),
          ),
          center: LibreRingEyebrow(copyFor(context, 'Privacy', 'Privacidade')),
          trailing: const SizedBox(width: 48),
        ),
        const SizedBox(height: 20),
        _DateLabel(copyFor(context, 'Cycle data', 'Dados do ciclo')),
        const SizedBox(height: 4),
        _Heading(
          copyFor(
            context,
            'Choose what stays available',
            'Escolha o que fica disponível',
          ),
        ),
        const SizedBox(height: 10),
        Text(
          copyFor(
            context,
            'Cycle entries are optional, stored locally, and excluded from recovery scoring.',
            'Os registos do ciclo são opcionais, locais e excluídos da pontuação de recuperação.',
          ),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 36),
        _PrivacyRow(
          title: copyFor(
            context,
            'Keep cycle entries on this phone',
            'Manter registos do ciclo neste telemóvel',
          ),
          body: copyFor(
            context,
            'Turning this off removes local entries from future views.',
            'Desativar remove os registos locais das vistas futuras.',
          ),
          value: settings.keepLocal,
          onChanged: controller.setKeepLocal,
          key: const Key('privacy-keep-local'),
        ),
        _PrivacyRow(
          title: copyFor(
            context,
            'Use for personal trend context',
            'Usar como contexto de tendência pessoal',
          ),
          body: copyFor(
            context,
            'Shows context beside trends. Never changes measured values.',
            'Mostra contexto junto às tendências. Nunca altera valores medidos.',
          ),
          value: settings.useAsContext,
          onChanged: settings.keepLocal ? controller.setUseAsContext : null,
          key: const Key('privacy-use-context'),
        ),
        _PrivacyRow(
          title: copyFor(context, 'Allow export', 'Permitir exportação'),
          body: copyFor(
            context,
            'Requires a separate confirmation for every export.',
            'Exige uma confirmação separada para cada exportação.',
          ),
          value: settings.allowExport,
          onChanged: settings.keepLocal ? controller.setAllowExport : null,
          key: const Key('privacy-allow-export'),
        ),
        const SizedBox(height: 24),
        _AccentNote(
          copyFor(
            context,
            'No cycle data is shared by changing these controls.',
            'Nenhum dado do ciclo é partilhado ao alterar estes controlos.',
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
            onPressed: () async {
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
              if (confirmed == true) {
                await ref.read(ringDataProvider.notifier).deleteAll();
              }
            },
            child: Text(
              copyFor(
                context,
                'Delete local ring data',
                'Eliminar dados locais do anel',
              ),
            ),
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
    return Scaffold(
      body: Stack(
        children: <Widget>[
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                24,
                20,
                24,
                activePath == null ? 36 : 116,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ),
          if (activePath != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _BottomNav(activePath: activePath!),
            ),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.activePath});

  final String activePath;

  @override
  Widget build(BuildContext context) {
    const items = <(String, IconData, String)>[
      ('/today', Icons.home_outlined, 'Today'),
      ('/metrics', Icons.grid_view_outlined, 'Metrics'),
      ('/trends', Icons.trending_up, 'Trends'),
      ('/privacy/cycle', Icons.lock_outline, 'Privacy'),
    ];
    return ColoredBox(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 14),
        child: Center(
          heightFactor: 1,
          child: Container(
            width: 244,
            height: 64,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: LibreRingTokens.foreground,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: items.map(((String, IconData, String) item) {
                final selected = activePath == item.$1;
                return Semantics(
                  selected: selected,
                  label: item.$3,
                  button: true,
                  child: IconButton(
                    onPressed: () => context.go(item.$1),
                    color: selected ? Colors.white : const Color(0xFFC5C2BC),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(54, 50),
                      backgroundColor: selected
                          ? const Color(0xFF42423E)
                          : Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: Icon(item.$2, size: 20),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
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
  const _BackButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: label,
    onPressed: () => context.canPop() ? context.pop() : context.go('/welcome'),
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

class _Heatmap extends StatelessWidget {
  const _Heatmap({required this.levels});

  final List<int> levels;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints constraints) {
      final width = math.min(constraints.maxWidth, 276.0);
      final cell = (width - 35) / 8;
      return Center(
        child: SizedBox(
          width: width,
          child: Wrap(
            spacing: 5,
            runSpacing: 5,
            children: levels.map((int level) {
              final colors = <Color>[
                LibreRingTokens.surface,
                const Color(0xFFDCA999),
                const Color(0xFFD17B63),
                LibreRingTokens.accent,
              ];
              return Container(
                width: cell,
                height: cell,
                decoration: BoxDecoration(
                  color: colors[level.clamp(0, 3)],
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }).toList(),
          ),
        ),
      );
    },
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
  Widget build(BuildContext context) => InkWell(
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
  );
}

class _Confidence extends StatelessWidget {
  const _Confidence(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 28),
    padding: const EdgeInsets.symmetric(horizontal: 9),
    alignment: Alignment.center,
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

class _PrivacyRow extends StatelessWidget {
  const _PrivacyRow({
    required this.title,
    required this.body,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String title;
  final String body;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 96),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: LibreRingTokens.border)),
    ),
    child: Row(
      children: <Widget>[
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
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
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.45,
                    color: LibreRingTokens.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Switch(value: value, onChanged: onChanged),
      ],
    ),
  );
}
