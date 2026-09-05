import 'package:flutter/material.dart';

import '../localized_copy.dart';
import 'app_chrome.dart';

/// Keep the unverified firmware value distinct from validated calorie metrics.
class CalorieEducationPrompt extends StatelessWidget {
  const CalorieEducationPrompt({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        copyFor(
          context,
          'The ring’s energy value is unverified. We cannot confirm its calorie scale or whether it includes resting energy, so it is not labelled active calories.',
          'O valor de energia do anel não está verificado. Não podemos confirmar a escala em calorias nem se inclui energia em repouso, pelo que não é apresentado como calorias ativas.',
        ),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      TextButton.icon(
        key: const Key('calorie-education-open'),
        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
        icon: const Icon(Icons.info_outline_rounded, size: 20),
        label: Text(
          copyFor(
            context,
            'Can I trust the calorie figure?',
            'Posso confiar no valor de calorias?',
          ),
        ),
        onPressed: () => showCalorieEducation(context),
      ),
    ],
  );
}

void showCalorieEducation(BuildContext context) => showRingInfo(
  context,
  title: copyFor(
    context,
    'Ring energy, explained',
    'Energia do anel, explicada',
  ),
  closeLabel: copyFor(context, 'Got it', 'Entendido'),
  body: copyFor(context, _englishGuide, _portugueseGuide),
);

const _englishGuide = '''Can I trust this figure?
Not as a confirmed calorie count. The R12 sends an energy field with its activity records, but the unit scale, calculation and accuracy have not been verified. The value may look too large or too small; LibreRing cannot yet tell whether the cause is the scale, the ring’s estimate or another firmware assumption. Changing the number to look plausible would hide that uncertainty.

What do active, resting and food calories mean?
Calories are a unit of energy, often written as kcal. Active energy refers to energy used through movement above resting needs. Resting energy supports your body’s basic functions, even when you are not exercising. Food energy is energy you take in from food and drink; a ring does not measure what you eat.

Which one does this ring provide?
That has not been confirmed for this firmware. We preserve the received field as “Ring energy value”, with unverified firmware units, instead of presenting it as active calories or total daily expenditure. It is not a calorie goal or a food allowance.

How is the total shown?
LibreRing adds the values from the activity records received for the selected period. The chart preserves the recorded hours or days. Missing records stay missing—not zero energy—and incomplete coverage can leave a partial total. We do not fill gaps with invented values or correct the scale without evidence.

What should I use it for?
You can inspect the ring’s recorded values, but do not use them to set food intake, compensate for eating or decide exercise intensity. These values do not drive LibreRing’s daily suggestions or recovery scores.

Sources: LibreRing’s R12 protocol and capability review; NHS, “Understanding calories”; Apple HealthKit documentation, “activeEnergyBurned” and “basalEnergyBurned”, for general energy terminology. These sources do not validate this ring’s data.''';

const _portugueseGuide = '''Posso confiar neste valor?
Não como uma contagem confirmada de calorias. O R12 envia um campo de energia com os registos de atividade, mas a escala, o cálculo e a precisão não foram verificados. O valor pode parecer demasiado alto ou baixo; o LibreRing ainda não consegue distinguir se a causa é a escala, a estimativa do anel ou outro pressuposto do firmware. Alterar o número para parecer plausível esconderia essa incerteza.

O que são calorias ativas, em repouso e dos alimentos?
As calorias são uma unidade de energia, muitas vezes escrita como kcal. A energia ativa refere-se à energia usada no movimento, acima das necessidades em repouso. A energia em repouso mantém as funções básicas do corpo, mesmo sem exercício. A energia dos alimentos é a que ingere através da comida e da bebida; um anel não mede o que come.

Qual destes valores fornece este anel?
Isso não está confirmado para este firmware. Preservamos o campo recebido como “Valor de energia do anel”, em unidades do firmware não verificadas, em vez de o apresentar como calorias ativas ou gasto diário total. Não é um objetivo de calorias nem uma indicação de quanto pode comer.

Como é apresentado o total?
O LibreRing soma os valores dos registos de atividade recebidos para o período selecionado. O gráfico preserva as horas ou os dias registados. Registos em falta continuam em falta—não são energia zero—e uma cobertura incompleta pode deixar um total parcial. Não preenchemos lacunas com valores inventados nem corrigimos a escala sem provas.

Para que devo utilizá-lo?
Pode consultar os valores registados pelo anel, mas não os use para definir a alimentação, compensar o que comeu ou decidir a intensidade do exercício. Estes valores não são usados nas sugestões diárias nem nos índices de recuperação do LibreRing.

Fontes: revisão do protocolo e das capacidades do R12 no LibreRing; NHS, “Understanding calories”; documentação Apple HealthKit, “activeEnergyBurned” e “basalEnergyBurned”, para terminologia geral sobre energia. Estas fontes não validam os dados deste anel.''';
