import 'package:flutter/widgets.dart';

import '../../features/calculators/age/age_screen.dart';
import '../../features/calculators/bmi/bmi_screen.dart';
import '../../features/calculators/discount/discount_screen.dart';
import '../../features/calculators/percentage/percentage_screen.dart';
import '../../features/calculators/rule_of_three/rule_of_three_screen.dart';
import '../../features/converters/currency/currency_screen.dart';
import '../../features/converters/length/length_screen.dart';
import '../../features/converters/mass/mass_screen.dart';
import '../../features/converters/temperature/temperature_screen.dart';
import '../../features/converters/volume/volume_screen.dart';
import '../../features/organization/checklists/checklists_screen.dart';
import '../../features/organization/notes/notes_screen.dart';
import '../../features/organization/tasks/tasks_screen.dart';
import '../../features/utilities/countdown/countdown_screen.dart';
import '../../features/utilities/date_difference/date_difference_screen.dart';
import '../../features/utilities/qr_code/qr_code_screen.dart';
import '../../features/calculators/fuel/fuel_screen.dart';
import '../../features/converters/cooking/cooking_screen.dart';
import '../../features/converters/sizes/sizes_screen.dart';
import '../../features/utilities/timezone/timezone_screen.dart';
import '../../features/organization/expenses/expenses_screen.dart';

/// Mapa id da ferramenta -> tela. Todo id do catálogo deve existir aqui.
final Map<String, WidgetBuilder> toolScreens = {
  'percentage': (_) => const PercentageScreen(),
  'discount': (_) => const DiscountScreen(),
  'rule_of_three': (_) => const RuleOfThreeScreen(),
  'bmi': (_) => const BmiScreen(),
  'age': (_) => const AgeScreen(),
  'currency': (_) => const CurrencyScreen(),
  'length': (_) => const LengthScreen(),
  'mass': (_) => const MassScreen(),
  'temperature': (_) => const TemperatureScreen(),
  'volume': (_) => const VolumeScreen(),
  'tasks': (_) => const TasksScreen(),
  'checklists': (_) => const ChecklistsScreen(),
  'notes': (_) => const NotesScreen(),
  'date_difference': (_) => const DateDifferenceScreen(),
  'countdown': (_) => const CountdownScreen(),
  'qr_code': (_) => const QrCodeScreen(),
  'fuel': (_) => const FuelScreen(),
  'cooking': (_) => const CookingScreen(),
  'sizes': (_) => const SizesScreen(),
  'timezone': (_) => const TimezoneScreen(),
  'expenses': (_) => const ExpensesScreen(),
};
