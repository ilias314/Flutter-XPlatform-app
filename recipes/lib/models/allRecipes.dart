enum AllRecipesMode {
  newest,
  topWeek,
  topMonth,
  diet,
}

class AllRecipesArgs {
  final AllRecipesMode mode;
  final String dietPreference;

  AllRecipesArgs({
    required this.mode,
    this.dietPreference = 'Alles',
  });
}