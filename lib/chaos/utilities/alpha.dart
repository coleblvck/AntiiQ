double getAlphaPercentage(double minimumAlpha, double chaosLevel) {
  final clampedChaos = chaosLevel.clamp(0.0, 1.0);
  return 1.0 - (clampedChaos * (1.0 - minimumAlpha));
}