import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ring_design_system/ring_design_system.dart';

import '../app_state.dart';
import '../localized_copy.dart';
import '../sync_progress.dart';

/// Persistent feedback for the actual ring operation, not a simulated loading
/// percentage. Timer labels are deliberately outside the live announcement.
class RingSyncStatusCard extends StatelessWidget {
  const RingSyncStatusCard({
    required this.pairing,
    this.demo = false,
    this.onRetry,
    this.onHelp,
    super.key,
  });

  final RingPairingState pairing;
  final bool demo;
  final VoidCallback? onRetry;
  final VoidCallback? onHelp;

  @override
  Widget build(BuildContext context) {
    final progress = pairing.syncProgress;
    final active = pairing.syncInProgress;
    if (demo || (!active && progress == null && pairing.syncError == null)) {
      return const SizedBox.shrink();
    }
    final stage =
        progress?.stage ??
        (active ? RingSyncStage.finding : RingSyncStage.failed);
    final stalled = active && progress?.isStalled == true;
    final failed = !active && stage == RingSyncStage.failed;
    final partial = !active && stage == RingSyncStage.partial;
    final complete = !active && stage == RingSyncStage.completed;
    final endedAt = progress == null
        ? null
        : DateFormat(
            'd MMM, HH:mm',
            Localizations.localeOf(context).toString(),
          ).format(progress.startedAtUtc.add(progress.elapsed).toLocal());
    final warning = stalled || failed || partial;
    final text = _stageCopy(context, stage);
    final title = stalled
        ? copyFor(
            context,
            'Sync is taking longer',
            'A sincronização está a demorar',
          )
        : text.$1;
    final description = stalled
        ? '${text.$1}. ${copyFor(context, 'Waiting for this step to respond. Keep your ring nearby and LibreRing open.', 'À espera de uma resposta nesta etapa. Mantenha o anel perto e o LibreRing aberto.')}'
        : failed || partial
        ? _syncErrorCopy(context, pairing.syncError, text.$2)
        : complete && pairing.lastSyncRecordCount == 0
        ? copyFor(
            context,
            'Your ring responded, but there are no readings to show yet. Wear it and sync again later.',
            'O anel respondeu, mas ainda não há leituras para mostrar. Use-o e volte a sincronizar mais tarde.',
          )
        : text.$2;
    final color = warning ? LibreRingTokens.accent : LibreRingTokens.sage;
    final checkedDays =
        active &&
        const {
          RingSyncStage.activity,
          RingSyncStage.heartRate,
          RingSyncStage.stress,
          RingSyncStage.hrv,
        }.contains(stage) &&
        progress?.completedUnits != null &&
        progress?.totalUnits != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: LibreRingCard(
        key: const Key('ring-sync-status'),
        backgroundColor: warning
            ? LibreRingTokens.accentSoft
            : LibreRingTokens.sageSoft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              key: const Key('ring-sync-announcement'),
              container: true,
              liveRegion: true,
              label: '$title. $description',
              excludeSemantics: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child:
                        active &&
                            !stalled &&
                            !MediaQuery.disableAnimationsOf(context)
                        ? SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(
                              key: const Key('ring-sync-spinner'),
                              strokeWidth: 2,
                              color: color,
                            ),
                          )
                        : Icon(
                            warning
                                ? Icons.sync_problem_rounded
                                : complete
                                ? Icons.check_circle_outline_rounded
                                : Icons.sync_rounded,
                            key: const Key('ring-sync-static-icon'),
                            size: 24,
                            color: color,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          key: const Key('ring-sync-stage'),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          description,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: LibreRingTokens.foreground,
                                height: 1.45,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (progress != null) ...[
              const SizedBox(height: 12),
              Semantics(
                container: true,
                liveRegion: false,
                child: Wrap(
                  spacing: 14,
                  runSpacing: 6,
                  children: [
                    if (!active)
                      Text(
                        copyFor(context, 'Ended $endedAt', 'Terminou $endedAt'),
                        key: const Key('ring-sync-ended-at'),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    Text(
                      active
                          ? copyFor(
                              context,
                              'Elapsed ${_duration(progress.elapsed)}',
                              'Decorrido ${_duration(progress.elapsed)}',
                            )
                          : copyFor(
                              context,
                              'Duration ${_duration(progress.elapsed)}',
                              'Duração ${_duration(progress.elapsed)}',
                            ),
                      key: const Key('ring-sync-elapsed'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (checkedDays)
                      Text(
                        copyFor(
                          context,
                          '${progress.completedUnits} of ${progress.totalUnits} days checked',
                          '${progress.completedUnits} de ${progress.totalUnits} dias verificados',
                        ),
                        key: const Key('ring-sync-days'),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    if (stalled)
                      Text(
                        copyFor(
                          context,
                          'No progress for ${_duration(progress.sinceLastProgress)}',
                          'Sem progresso há ${_duration(progress.sinceLastProgress)}',
                        ),
                        key: const Key('ring-sync-stalled-time'),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: LibreRingTokens.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
            if (stalled) ...[
              const SizedBox(height: 10),
              Text(
                copyFor(
                  context,
                  'Close QRing or any other app connected to the ring. If this still doesn’t move, close and reopen LibreRing before trying again. Previously saved readings stay on this phone.',
                  'Feche o QRing ou outra aplicação ligada ao anel. Se continuar sem progresso, feche e volte a abrir o LibreRing antes de tentar novamente. As leituras já guardadas continuam neste telemóvel.',
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if ((failed || partial) && onRetry != null ||
                warning && onHelp != null) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  if (!active && (failed || partial) && onRetry != null)
                    TextButton.icon(
                      key: const Key('ring-sync-retry'),
                      onPressed: onRetry,
                      icon: const Icon(Icons.sync_rounded, size: 18),
                      label: Text(
                        copyFor(context, 'Try again', 'Tentar novamente'),
                      ),
                    ),
                  if (warning && onHelp != null)
                    TextButton(
                      key: const Key('ring-sync-status-help'),
                      onPressed: onHelp,
                      child: Text(
                        copyFor(
                          context,
                          'Sync help',
                          'Ajuda com a sincronização',
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _syncErrorCopy(BuildContext context, String? error, String fallback) {
  if (!isPortuguese(context)) return error ?? fallback;
  return switch (error) {
    'More than one R12 was found. Use device setup to choose one.' => 'Foi encontrado mais de um R12. Abra a configuração do anel para escolher um.',
    'The R12 is connected elsewhere or is not advertising. Force-close QRing, wake the ring, and try again.' => 'O R12 está ligado a outra aplicação ou não está visível. Feche completamente o QRing, ative o anel e tente novamente.',
    'A nearby QRing-family device was seen, but it did not advertise its R12 identity. Keep it close and try again.' => 'Foi detetado um dispositivo da família QRing, mas não foi possível confirmar que é um R12. Mantenha-o perto e tente novamente.',
    'Sync stopped safely. Existing local data was not replaced.' ||
    'The quick sync stopped safely. Existing local data was preserved.' => 'A sincronização parou em segurança. O histórico já guardado neste telemóvel foi preservado.',
    'Some ring data could not be read. Available records were saved; try syncing again.' => 'Não foi possível ler todos os dados do anel. Os registos disponíveis foram guardados; tente sincronizar novamente.',
    _ => fallback,
  };
}

String _duration(Duration value) {
  final seconds = value.inSeconds.clamp(0, 86400 * 365);
  if (seconds < 60) return '${seconds}s';
  if (seconds < 3600) return '${seconds ~/ 60}m ${seconds % 60}s';
  return '${seconds ~/ 3600}h ${(seconds % 3600) ~/ 60}m';
}

(String, String) _stageCopy(BuildContext context, RingSyncStage stage) {
  final english = switch (stage) {
    RingSyncStage.finding => (
      'Finding your ring',
      'Looking for your COLMI R12 over Bluetooth. Keep it close to your phone.',
    ),
    RingSyncStage.connecting => (
      'Connecting to your ring',
      'Opening a Bluetooth connection and checking the ring’s services.',
    ),
    RingSyncStage.metadata => (
      'Checking your ring',
      'Reading the device details before requesting your history.',
    ),
    RingSyncStage.battery => (
      'Reading battery level',
      'Checking the charge reported by your ring.',
    ),
    RingSyncStage.activity => (
      'Reading activity',
      'Checking retained days for steps, distance and activity records.',
    ),
    RingSyncStage.heartRate => (
      'Reading pulse history',
      'Checking the pulse readings stored on your ring.',
    ),
    RingSyncStage.sleep => (
      'Reading sleep history',
      'Receiving the sleep sessions retained by your ring.',
    ),
    RingSyncStage.oxygen => (
      'Reading blood oxygen',
      'Receiving the oxygen readings retained by your ring.',
    ),
    RingSyncStage.stress => (
      'Reading stress index',
      'Checking your ring’s recorded stress index history.',
    ),
    RingSyncStage.hrv => (
      'Reading firmware HRV index',
      'Checking the index reported by your ring, not a clinical HRV measurement.',
    ),
    RingSyncStage.normalising => (
      'Preparing your readings',
      'Organising the received history for your daily views.',
    ),
    RingSyncStage.saving => (
      'Saving on your phone',
      'Merging the received records with your existing local history.',
    ),
    RingSyncStage.finishing => (
      'Finishing sync',
      'Closing the Bluetooth connection before another sync can start.',
    ),
    RingSyncStage.completed => (
      'Sync complete',
      'Your ring check finished. Available history is saved on this phone.',
    ),
    RingSyncStage.partial => (
      'Some data saved',
      'Some readings could not be received. Available records were saved; you can try again.',
    ),
    RingSyncStage.failed => (
      'Sync couldn’t finish',
      'Your existing saved readings are safe. Keep the ring nearby and try again.',
    ),
  };
  if (!isPortuguese(context)) return english;
  return switch (stage) {
    RingSyncStage.finding => (
      'A procurar o anel',
      'À procura do seu COLMI R12 por Bluetooth. Mantenha-o perto do telemóvel.',
    ),
    RingSyncStage.connecting => (
      'A ligar ao anel',
      'A abrir uma ligação Bluetooth e a verificar os serviços do anel.',
    ),
    RingSyncStage.metadata => (
      'A verificar o anel',
      'A ler os detalhes do dispositivo antes de pedir o histórico.',
    ),
    RingSyncStage.battery => (
      'A ler a bateria',
      'A verificar a carga indicada pelo anel.',
    ),
    RingSyncStage.activity => (
      'A ler a atividade',
      'A verificar os dias guardados para passos, distância e atividade.',
    ),
    RingSyncStage.heartRate => (
      'A ler o histórico de pulso',
      'A verificar as leituras de pulso guardadas no anel.',
    ),
    RingSyncStage.sleep => (
      'A ler o histórico de sono',
      'A receber as sessões de sono guardadas no anel.',
    ),
    RingSyncStage.oxygen => (
      'A ler o oxigénio no sangue',
      'A receber as leituras de oxigénio guardadas no anel.',
    ),
    RingSyncStage.stress => (
      'A ler o índice de stress',
      'A verificar o histórico do índice de stress do anel.',
    ),
    RingSyncStage.hrv => (
      'A ler o índice HRV do firmware',
      'A verificar o índice do anel, não uma medição clínica de HRV.',
    ),
    RingSyncStage.normalising => (
      'A preparar as leituras',
      'A organizar o histórico recebido para os resumos diários.',
    ),
    RingSyncStage.saving => (
      'A guardar no telemóvel',
      'A combinar os registos recebidos com o histórico local existente.',
    ),
    RingSyncStage.finishing => (
      'A terminar a sincronização',
      'A fechar a ligação Bluetooth antes de permitir uma nova sincronização.',
    ),
    RingSyncStage.completed => (
      'Sincronização concluída',
      'A verificação terminou. O histórico disponível está guardado neste telemóvel.',
    ),
    RingSyncStage.partial => (
      'Alguns dados guardados',
      'Não foi possível receber todas as leituras. Os registos disponíveis foram guardados; pode tentar novamente.',
    ),
    RingSyncStage.failed => (
      'Não foi possível concluir',
      'As leituras já guardadas estão seguras. Mantenha o anel perto e tente novamente.',
    ),
  };
}
