class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://restaurant.universaltechnologiesafrica.com/api',
  );
}

