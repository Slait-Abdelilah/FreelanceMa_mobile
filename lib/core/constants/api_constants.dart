class ApiConstants {
  static const String baseUrl = 'http://192.168.43.130:8080';

  // Auth
  static const String register = '/api/auth/register';
  static const String login = '/api/auth/login';
  static const String refresh = '/api/auth/refresh';
  static const String logout = '/api/auth/logout';
  static const String verifyAccount = '/api/auth/verify-account';
  static const String resendCode = '/api/auth/resend-code';
  static const String forgotPassword = '/api/auth/forgot-password';
  static const String verifyResetCode = '/api/auth/verify-reset-code';
  static const String resetPassword = '/api/auth/reset-password';
  static const String changePassword = '/api/auth/change-password';
  static const String deleteAccount = '/api/auth/account';

  // Profile & Settings
  static const String profile = '/api/profile';
  static const String freelancers = '/api/profile/freelancers';
  static const String settings = '/api/settings';
  static const String settingsAccount = '/api/settings/account';
  static const String settingsPrivacy = '/api/settings/privacy';

  // Portfolio
  static const String portfolio = '/api/portfolio';

  // Wallet
  static const String wallet = '/api/wallet';
  static const String transactions = '/api/wallet/transactions';
  static const String withdraw = '/api/wallet/withdraw';
  static const String deposit  = '/api/wallet/deposit';

  // Offers & Applications
  static const String offers = '/api/offers';
  static const String myOffers = '/api/offers/my';
  static const String applications = '/api/applications';
  static const String myApplications = '/api/applications/my';
  static const String offerApplications = '/api/applications/offer';

  // Favorites
  static const String favorites = '/api/favorites';

  // Notifications
  static const String notifications = '/api/notifications';
  static const String notificationsUnread = '/api/notifications/unread-count';
  static const String notificationsReadAll = '/api/notifications/read-all';

  // Messages
  static const String messageHistory = '/api/messages/history';
  static const String messageUnreadCount = '/api/messages/unread-count';

  // WebSocket — connexion directe au job-service (hors gateway)
  static const String wsJobServiceUrl = 'ws://192.168.43.130:8083/ws/websocket';
}
