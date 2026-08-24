import 'package:flutter/widgets.dart';

bool isPortuguese(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'pt';

String copyFor(BuildContext context, String english, String portuguese) =>
    isPortuguese(context) ? portuguese : english;
