import 'package:flutter/material.dart';

import '../localized_copy.dart';
import 'app_chrome.dart';

/// General HRV education is separate from the R12's unverified vendor index.
/// Sources and wording boundaries: docs/science/hrv-education.md.
class HrvEducationPrompt extends StatelessWidget {
  const HrvEducationPrompt({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        copyFor(
          context,
          'HRV means heart rate variability: the small changes in time between heartbeats.',
          'HRV significa variabilidade da frequência cardíaca: as pequenas diferenças no tempo entre batimentos.',
        ),
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      const SizedBox(height: 8),
      Text(
        copyFor(
          context,
          'Reliable HRV trends can give context about sleep and recovery. This ring’s index cannot yet support those conclusions.',
          'Tendências de HRV fiáveis podem dar contexto sobre o sono e a recuperação. O índice deste anel ainda não permite tirar essas conclusões.',
        ),
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      const SizedBox(height: 8),
      Text(
        copyFor(
          context,
          'The ring reports this as an HRV index. The unit is unverified, so it is not shown in milliseconds.',
          'O anel apresenta este valor como um índice de HRV. A unidade não está verificada, pelo que não é apresentado em milissegundos.',
        ),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      TextButton.icon(
        key: const Key('hrv-education-open'),
        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
        icon: const Icon(Icons.info_outline_rounded, size: 20),
        label: Text(copyFor(context, 'What is HRV?', 'O que é a HRV?')),
        onPressed: () => showHrvEducation(context),
      ),
    ],
  );
}

void showHrvEducation(BuildContext context) => showRingInfo(
  context,
  title: copyFor(context, 'HRV, explained', 'HRV, sem complicações'),
  closeLabel: copyFor(context, 'Got it', 'Entendido'),
  body: copyFor(context, _englishGuide, _portugueseGuide),
);

const _englishGuide = '''What your ring shows
The number on this screen is the COLMI R12’s firmware index. Its unit and calculation have not been verified. It is not a confirmed HRV measurement in milliseconds, and LibreRing does not use it to calculate recovery or label your health.

The timing, not the pulse
Heart rate counts beats per minute. HRV describes how the gaps between normal heartbeats vary. Your heart does not beat like a perfectly regular clock. Many HRV measurements are expressed in milliseconds.

Why people track it
HRV reflects the nervous system that helps your body respond to demands and settle afterwards. When measured reliably over time, it can provide context about sleep, physical stress and recovery from training. It does not directly measure your mood or tell you why a change happened.

What is a good number?
There is no universal target. With a reliable HRV measurement, compare your own pattern under similar conditions, using the same device and method—not someone else’s score. Higher is not always better, and one low reading is not a diagnosis. These interpretations cannot be assumed for this ring’s index.

How HRV is measured
An ECG records heartbeat timing; optical wearables estimate it from the pulse. Calculations summarise variation between beats, and different methods can produce different numbers. LibreRing receives the R12 index, not the beat-to-beat intervals needed to verify an HRV calculation.

Medical background: Cleveland Clinic, “Heart Rate Variability”; Harvard Health, “What is heart rate variability?”; Oura Member Care, “Heart Rate Variability”. These sources explain HRV generally; they do not validate the R12.''';

const _portugueseGuide = '''O que o seu anel apresenta
O número neste ecrã é o índice do firmware do COLMI R12. A unidade e o cálculo não foram verificados. Não é uma medição de HRV confirmada em milissegundos, e o LibreRing não o usa para calcular a recuperação nem avaliar a sua saúde.

O intervalo, não o pulso
A frequência cardíaca conta os batimentos por minuto. A HRV descreve como variam os intervalos entre batimentos cardíacos normais. O coração não bate como um relógio perfeitamente regular. Muitas medições de HRV são expressas em milissegundos.

Porque é útil acompanhar
A HRV reflete o sistema nervoso que ajuda o corpo a responder às exigências e a voltar a acalmar. Quando medida de forma fiável ao longo do tempo, pode dar contexto sobre o sono, o stress físico e a recuperação do treino. Não mede diretamente o seu estado de espírito nem explica a causa de uma alteração.

O que é um bom valor?
Não existe um objetivo universal. Com uma medição fiável de HRV, compare o seu próprio padrão em condições semelhantes, com o mesmo dispositivo e método—não o valor de outra pessoa. Mais alto nem sempre é melhor, e uma leitura baixa isolada não é um diagnóstico. Estas interpretações não podem ser assumidas para o índice deste anel.

Como se mede a HRV
Um ECG regista o momento de cada batimento; os dispositivos óticos estimam-no a partir do pulso. Os cálculos resumem a variação entre batimentos, e métodos diferentes podem produzir valores diferentes. O LibreRing recebe o índice do R12, não os intervalos entre batimentos necessários para verificar um cálculo de HRV.

Fontes de informação médica: Cleveland Clinic, “Heart Rate Variability”; Harvard Health, “What is heart rate variability?”; Oura Member Care, “Heart Rate Variability”. Estas fontes explicam a HRV em geral; não validam o R12.''';
