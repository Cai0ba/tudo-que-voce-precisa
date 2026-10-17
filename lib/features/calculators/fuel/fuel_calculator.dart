import 'package:decimal/decimal.dart';

import '../shared/calc_support.dart';

/// Resultado da comparação etanol × gasolina.
class FuelComparison {
  const FuelComparison({
    required this.ratioPercent,
    required this.ethanolWins,
    this.ethanolCostPerKm,
    this.gasolineCostPerKm,
    this.byCostPerKm = false,
  });

  /// Preço do etanol como % do preço da gasolina (1 casa).
  final Decimal ratioPercent;

  /// Verdadeiro se o etanol compensa.
  final bool ethanolWins;

  /// Custo por km (3 casas), só quando o consumo foi informado.
  final Decimal? ethanolCostPerKm;
  final Decimal? gasolineCostPerKm;

  /// Verdadeiro se a decisão veio do custo por km, e não do limite.
  final bool byCostPerKm;
}

class TripResult {
  const TripResult({
    required this.distance,
    required this.liters,
    required this.cost,
  });

  /// Distância total considerada (km), já dobrada se ida e volta.
  final Decimal distance;
  final Decimal liters;
  final Decimal cost;
}

/// Domínio puro de combustível.
abstract final class FuelCalculator {
  static final Decimal defaultLimitPercent = Decimal.fromInt(70);

  static Decimal _positive(Decimal v, String message) {
    if (v <= Decimal.zero) throw CalcException(message);
    return v;
  }

  /// Regra do limite (padrão 70%): etanol compensa se
  /// preço_etanol / preço_gasolina <= limite. Sem divisões na decisão.
  /// Se [ethanolKmPerL] e [gasolineKmPerL] forem informados, decide pelo
  /// custo por km (empate favorece o etanol).
  static FuelComparison compare({
    required Decimal ethanolPrice,
    required Decimal gasolinePrice,
    Decimal? limitPercent,
    Decimal? ethanolKmPerL,
    Decimal? gasolineKmPerL,
  }) {
    _positive(ethanolPrice, 'O preço do etanol deve ser maior que zero.');
    _positive(gasolinePrice, 'O preço da gasolina deve ser maior que zero.');
    final limit = limitPercent ?? defaultLimitPercent;
    if (limit <= Decimal.zero || limit > Decimal.fromInt(100)) {
      throw const CalcException('O limite deve ficar entre 0 e 100%.');
    }
    if ((ethanolKmPerL == null) != (gasolineKmPerL == null)) {
      throw const CalcException(
        'Informe o consumo dos dois combustíveis, ou deixe os dois vazios.',
      );
    }
    final ratio = roundTo(
      divide(ethanolPrice * Decimal.fromInt(100), gasolinePrice),
      1,
    );
    if (ethanolKmPerL == null || gasolineKmPerL == null) {
      return FuelComparison(
        ratioPercent: ratio,
        ethanolWins:
            ethanolPrice * Decimal.fromInt(100) <= gasolinePrice * limit,
      );
    }
    _positive(ethanolKmPerL, 'O consumo com etanol deve ser maior que zero.');
    _positive(
      gasolineKmPerL,
      'O consumo com gasolina deve ser maior que zero.',
    );
    return FuelComparison(
      ratioPercent: ratio,
      // pE/cE <= pG/cG  <=>  pE*cG <= pG*cE
      ethanolWins:
          ethanolPrice * gasolineKmPerL <= gasolinePrice * ethanolKmPerL,
      ethanolCostPerKm: roundTo(divide(ethanolPrice, ethanolKmPerL), 3),
      gasolineCostPerKm: roundTo(divide(gasolinePrice, gasolineKmPerL), 3),
      byCostPerKm: true,
    );
  }

  /// Consumo em km/l (2 casas).
  static Decimal consumption(Decimal distanceKm, Decimal liters) {
    _positive(distanceKm, 'A distância deve ser maior que zero.');
    _positive(liters, 'Os litros devem ser maiores que zero.');
    return roundTo(divide(distanceKm, liters), 2);
  }

  /// Litros (2 casas) e custo total (2 casas, calculado sem arredondar litros).
  static TripResult trip({
    required Decimal distanceKm,
    required Decimal kmPerL,
    required Decimal pricePerLiter,
    bool roundTrip = false,
  }) {
    _positive(distanceKm, 'A distância deve ser maior que zero.');
    _positive(kmPerL, 'O consumo deve ser maior que zero.');
    _positive(pricePerLiter, 'O preço do litro deve ser maior que zero.');
    final total = roundTrip ? distanceKm * Decimal.fromInt(2) : distanceKm;
    final liters = divide(total, kmPerL);
    return TripResult(
      distance: total,
      liters: roundTo(liters, 2),
      cost: roundTo(liters * pricePerLiter, 2),
    );
  }
}
