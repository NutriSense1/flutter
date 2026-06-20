class AppConstants {
  AppConstants._();

  // API
  // Render deployment URL. NOTE: the FastAPI backend mounts every route
  // under the `/api/v1` prefix (see backend/app/core/config.py ->
  // api_v1_prefix and backend/app/main.py -> app.include_router(...,
  // prefix=prefix)) — only the bare `/` and `/health` routes are
  // unprefixed. That prefix MUST be included here, or every request
  // from ApiService (which appends paths like `/users/onboarding`)
  // 404s against the backend.
  static const String baseUrl = 'https://nutrisense-api-qdjj.onrender.com/api/v1';
  static const String openFoodFactsUrl = 'https://world.openfoodfacts.org/api/v3';

  // Storage keys
  static const String keyOnboardingDone = 'onboarding_done';
  static const String keyUserId = 'user_id';
  static const String keyUserProfile = 'user_profile';
  static const String keyAuthToken = 'auth_token';
  static const String keyDailyCalorieGoal = 'daily_calorie_goal';

  // Timeouts
  static const int requestTimeoutSeconds = 30;
  static const int scanTimeoutSeconds = 45;

  // Pagination
  static const int defaultPageSize = 20;

  // Health Score thresholds
  static const double scoreExcellent = 80.0;
  static const double scoreGood = 60.0;
  static const double scoreFair = 40.0;

  // Water
  static const double defaultWaterGoalLiters = 2.5;
  static const double waterIncrementLiters = 0.25;

  // Activity levels
  static const List<String> activityLevels = [
    'Sedentary',
    'Lightly Active',
    'Moderately Active',
    'Very Active',
    'Extremely Active',
  ];

  static const Map<String, double> activityMultipliers = {
    'Sedentary': 1.2,
    'Lightly Active': 1.375,
    'Moderately Active': 1.55,
    'Very Active': 1.725,
    'Extremely Active': 1.9,
  };

  // Goals
  static const List<String> goals = [
    'Lose Weight',
    'Maintain Weight',
    'Gain Weight',
    'Build Muscle',
    'Improve Health',
    'Eat Healthier',
  ];

  static const Map<String, int> goalCalorieAdjustment = {
    'Lose Weight': -500,
    'Maintain Weight': 0,
    'Gain Weight': 500,
    'Build Muscle': 300,
    'Improve Health': 0,
    'Eat Healthier': 0,
  };

  // Dietary preferences
  static const List<String> dietaryPreferences = [
    'No Restriction',
    'Vegetarian',
    'Vegan',
    'Keto',
    'Paleo',
    'Gluten-Free',
    'Dairy-Free',
    'Low Carb',
    'Mediterranean',
    'Intermittent Fasting',
  ];

  // Common allergens
  static const List<String> allergens = [
    'Gluten',
    'Dairy',
    'Eggs',
    'Nuts',
    'Peanuts',
    'Soy',
    'Shellfish',
    'Fish',
    'Sesame',
    'Sulfites',
  ];

  // Meal types
  static const List<String> mealTypes = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snack',
  ];

  // Gamification
  static const int xpPerScan = 10;
  static const int xpPerLog = 5;
  static const int xpPerWaterLog = 3;
  static const int xpPerWeightLog = 8;
  static const int xpPerStreak = 20;

  // Premium scan limit (free tier)
  static const int freeTierScanLimit = 5;
}
