import 'package:flutter/material.dart';

import '../localized_copy.dart';
import 'app_chrome.dart';

/// Describes the received R12 field without inventing a physiological formula.
class StressEducationPrompt extends StatelessWidget {
  const StressEducationPrompt({this.days = 1, super.key});
  final int days;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        copyFor(
          context,
          'A number calculated by your ring—not a percentage of stress or a measure of how you feel.',
          'Um número calculado pelo anel—não é uma percentagem de stress nem uma medida de como se sente.',
        ),
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      const SizedBox(height: 8),
      Text(
        copyFor(
          context,
          'Its formula and scale have not been independently verified. A value such as 49 does not tell us whether your stress is low or high.',
          'A fórmula e a escala não foram verificadas de forma independente. Um valor como 49 não permite saber se o seu stress é baixo ou elevado.',
        ),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: 8),
      Text(
        days == 1
            ? copyFor(
                context,
                'Day shows the latest captured value, not a live reading.',
                'Dia apresenta o último valor registado, não uma leitura em direto.',
              )
            : copyFor(
                context,
                'The headline is the median of captured samples; the chart shows each day’s median.',
                'O valor principal é a mediana das amostras registadas; o gráfico apresenta a mediana de cada dia.',
              ),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      TextButton.icon(
        key: const Key('stress-education-open'),
        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
        icon: const Icon(Icons.info_outline_rounded, size: 20),
        label: Text(
          copyFor(
            context,
            'What does this number mean?',
            'O que significa este número?',
          ),
        ),
        onPressed: () => showStressEducation(context),
      ),
    ],
  );
}

void showStressEducation(BuildContext context) => showRingInfo(
  context,
  title: copyFor(
    context,
    'Stress index, explained',
    'Índice de stress, explicado',
  ),
  closeLabel: copyFor(context, 'Got it', 'Entendido'),
  body: copyFor(context, _englishGuide, _portugueseGuide),
);

const _englishGuide = '''What the number means
This is the COLMI R12’s firmware-reported stress index. For example, 49 means the ring returned an index value of 49. It does not mean 49% stressed, 49 beats per minute, or a clinical stress measurement. Its scale and useful thresholds have not been verified, so LibreRing does not label it relaxed, normal or high.

How is it calculated?
The calculation happens inside the ring. LibreRing receives the finished number, not a documented formula or the underlying inputs needed to reproduce it. We cannot confirm which signals are used, how they are weighted, or what a change means. We do not substitute a made-up formula.

What am I looking at?
Day shows the latest captured value on the selected date—not a live measurement. Week and Month show the median of all captured samples in the selected period: the middle value when sorted, or the mean of the two middle values, rounded to a whole number. Their charts show a separate median for each recorded day, so the headline is not an average of the chart points.

What about gaps or missing readings?
A gap means no usable reading was received; it is not zero stress or a relaxed period. No data stays empty. More samples do not prove the index is more accurate.

How can I use it?
You can inspect what your ring recorded, alongside your own notes. This index cannot tell you that you have had a tough day, explain why you feel a certain way, or establish whether you should train or rest. LibreRing does not use it for health labels or automatic wellbeing advice.

Source: R12 protocol and capability review in LibreRing. The firmware data field is documented; its physiological meaning, formula and thresholds remain unverified.''';

const _portugueseGuide = '''O que significa o número
Este é o índice de stress comunicado pelo firmware do COLMI R12. Por exemplo, 49 significa que o anel devolveu um índice de 49. Não significa 49% de stress, 49 batimentos por minuto nem uma medição clínica de stress. A escala e os limiares úteis não foram verificados, pelo que o LibreRing não o classifica como relaxado, normal ou elevado.

Como é calculado?
O cálculo é feito dentro do anel. O LibreRing recebe o número final, não uma fórmula documentada nem os dados de base necessários para a reproduzir. Não podemos confirmar quais os sinais usados, o peso de cada um ou o significado de uma alteração. Não substituímos essa informação por uma fórmula inventada.

O que estou a ver?
Dia apresenta o último valor registado na data selecionada—não uma medição em direto. Semana e Mês apresentam a mediana de todas as amostras registadas no período: o valor central quando ordenadas, ou a média dos dois valores centrais, arredondada para um número inteiro. Os gráficos apresentam uma mediana por cada dia com registos, pelo que o valor principal não é uma média dos pontos do gráfico.

E as lacunas ou leituras em falta?
Uma lacuna significa que não foi recebida uma leitura utilizável; não significa zero stress nem um período de relaxamento. Sem dados, o campo fica vazio. Ter mais amostras não prova que o índice seja mais preciso.

Como posso utilizá-lo?
Pode consultar o que o anel registou, em conjunto com as suas próprias notas. Este índice não permite concluir que teve um dia difícil, explicar como se sente ou decidir se deve treinar ou descansar. O LibreRing não o usa para avaliar a saúde nem para sugestões automáticas de bem-estar.

Fonte: revisão do protocolo e das capacidades do R12 no LibreRing. O campo de dados do firmware está documentado; o significado fisiológico, a fórmula e os limiares continuam por verificar.''';
