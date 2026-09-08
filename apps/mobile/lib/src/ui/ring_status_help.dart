import 'package:flutter/material.dart';
import 'package:ring_core/ring_core.dart';
import 'package:ring_design_system/ring_design_system.dart';

import '../localized_copy.dart';
import 'app_chrome.dart';

/// Status education stays available before, during and after a sync. Battery
/// uses saved metadata, never a generated value or a fabricated read timestamp.
class RingStatusHelp extends StatelessWidget {
  const RingStatusHelp({this.dataset, this.demo = false, super.key});

  final RingSyncDataset? dataset;
  final bool demo;

  @override
  Widget build(BuildContext context) {
    final reported = dataset?.batteryLevel;
    final battery = reported != null && reported >= 0 && reported <= 100
        ? reported
        : null;
    String copy(String en, String pt) => copyFor(context, en, pt);
    final batteryLabel = demo
        ? copy('Example battery', 'Bateria de exemplo')
        : copy('Ring battery', 'Bateria do anel');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (dataset != null)
            TextButton.icon(
              key: const Key('ring-battery-help'),
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                alignment: Alignment.centerLeft,
              ),
              icon: Icon(
                battery == null
                    ? Icons.battery_unknown_outlined
                    : battery <= 20
                    ? Icons.battery_alert_outlined
                    : Icons.battery_5_bar_outlined,
                color: battery != null && battery <= 20
                    ? LibreRingTokens.accent
                    : LibreRingTokens.sage,
                size: 20,
              ),
              label: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$batteryLabel ${battery == null ? '—' : '$battery%'}'),
                  Text(
                    battery == null
                        ? copy('No saved value', 'Sem valor guardado')
                        : demo
                        ? copy('Sample value', 'Valor de exemplo')
                        : copy(
                            'Last reported · not live',
                            'Último registo · não é em direto',
                          ),
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(fontSize: 10),
                  ),
                ],
              ),
              onPressed: () => showRingInfo(
                context,
                title: copy('Your ring’s battery', 'A bateria do seu anel'),
                closeLabel: copy('Got it', 'Entendido'),
                body:
                    '${demo ? copy('Example data, not your ring\nThis value belongs to the sample dataset.\n\n', 'Dados de exemplo, não do seu anel\nEste valor pertence aos dados de demonstração.\n\n') : ''}${battery == null ? copy('No saved battery value\nThe charge is unavailable. This does not mean the battery is at zero.\n\n', 'Sem valor de bateria guardado\nA carga está indisponível. Isto não significa que a bateria está a zero.\n\n') : copy('What does $battery% mean?\nIt is the charge reported by the ring, not your phone’s battery and not sync progress. It does not mean $battery hours of use remain.\n\n', 'O que significa $battery%?\nÉ a carga indicada pelo anel, não a bateria do telemóvel nem o progresso da sincronização. Não significa que restam $battery horas de utilização.\n\n')}${copy(_batteryEnglish, _batteryPortuguese)}',
              ),
            ),
          TextButton.icon(
            key: const Key('ring-sync-explained'),
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            icon: const Icon(Icons.info_outline_rounded, size: 18),
            label: Text(copy('About sync', 'Sobre a sincronização')),
            onPressed: () => showRingInfo(
              context,
              title: copy('How syncing works', 'Como funciona a sincronização'),
              closeLabel: copy('Got it', 'Entendido'),
              body: copy(_syncEnglish, _syncPortuguese),
            ),
          ),
        ],
      ),
    );
  }
}

const _batteryEnglish = '''Is this the level right now?
Not necessarily. It is the latest saved report, not a live feed. Charge can change while the ring is disconnected. If a sync does not return a new battery value, an older value can remain visible.

Why no precise reading time?
This version stores the last sync time, but not a separate timestamp for the battery reading. Those are not interchangeable, so LibreRing does not invent a battery-reading time.

How to check again
Keep the ring nearby and tap Sync. A successful battery read updates this value; if it cannot be read, the previous saved value may remain. Charge the ring when needed, and do not use the percentage as a remaining-runtime estimate.''';

const _batteryPortuguese = '''É a carga neste momento?
Não necessariamente. É o último valor guardado, não uma leitura em direto. A carga pode mudar enquanto o anel está desligado. Se uma sincronização não devolver um novo valor de bateria, o anterior pode continuar visível.

Porque não aparece a hora exata da leitura?
Esta versão guarda a hora da última sincronização, mas não uma hora separada para a leitura da bateria. Não são a mesma coisa, por isso o LibreRing não inventa uma hora de leitura.

Como voltar a verificar
Mantenha o anel perto e toque em Sincronizar. Uma leitura de bateria bem-sucedida atualiza este valor; se não for possível lê-lo, o valor anterior pode permanecer. Carregue o anel quando necessário e não use a percentagem como estimativa de autonomia.''';

const _syncEnglish = '''Bringing saved readings to your phone
The ring collects readings while you wear it. Sync connects over Bluetooth, requests the available history and saves what was received on this phone. It is not continuous live monitoring.

Refresh or Sync?
Pull down on a readings page to reload data already saved on your phone. This does not connect to the ring. Tap the Sync button to fetch new readings over Bluetooth. Saved results appear automatically when the sync finishes; you do not need to pull again.

What the status means
The status names the actual step: finding the ring, connecting, reading a type of history, saving, or finishing. Keep the ring nearby and LibreRing open until it finishes. A day count means days checked, not a percentage of the whole sync.

Processing or stuck?
The elapsed timer is time spent, not a countdown. If a step stops reporting progress, the app shows “Sync is taking longer” and how long it has been waiting. Silence is not proof the ring is broken. Follow the visible help; avoid starting a second sync while one is running.

Finished is not always complete
“Sync complete” means the operation finished and received data was saved. Some fields may have no readings. “Some data saved” means usable results were kept but part of the request was unavailable. A failed sync does not erase previously saved readings. Use Try again when offered or open sync help.

The battery percentage is separate
It is the ring’s last reported charge, not a completion indicator. Example mode uses sample data and does not contact a ring.''';

const _syncPortuguese = '''Trazer leituras guardadas para o telemóvel
O anel recolhe leituras enquanto o usa. A sincronização liga-se por Bluetooth, pede o histórico disponível e guarda o que recebeu neste telemóvel. Não é monitorização contínua em direto.

Atualizar ou Sincronizar?
Puxe para baixo numa página de leituras para voltar a carregar os dados já guardados no telemóvel. Isto não liga ao anel. Toque no botão Sincronizar para obter novas leituras por Bluetooth. Os resultados guardados aparecem automaticamente quando a sincronização termina; não precisa de puxar novamente.

O que significa o estado
O estado identifica a etapa real: procurar o anel, ligar, ler um tipo de histórico, guardar ou terminar. Mantenha o anel perto e o LibreRing aberto até terminar. A contagem de dias indica dias verificados, não uma percentagem da sincronização completa.

A processar ou bloqueado?
O temporizador mostra o tempo decorrido, não uma contagem decrescente. Se uma etapa deixar de comunicar progresso, a aplicação mostra que a sincronização está a demorar e há quanto tempo espera. A ausência de resposta não prova que o anel está avariado. Siga a ajuda apresentada; evite iniciar outra sincronização enquanto uma estiver em curso.

Terminar nem sempre significa receber tudo
“Sincronização concluída” significa que a operação terminou e os dados recebidos foram guardados. Alguns campos podem não ter leituras. “Alguns dados guardados” significa que foram preservados resultados úteis, mas parte do pedido ficou indisponível. Uma falha não apaga leituras já guardadas. Use Tentar novamente quando disponível ou abra a ajuda.

A percentagem de bateria é separada
É a última carga comunicada pelo anel, não um indicador de conclusão. O modo de exemplo usa dados de demonstração e não contacta um anel.''';
