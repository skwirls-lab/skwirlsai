// Copy this file to google_oauth_config.dart and fill in your credentials.
// google_oauth_config.dart is gitignored and will NOT be committed.
//
// To get credentials:
// 1. Go to https://console.cloud.google.com
// 2. Create a project (or select existing)
// 3. Enable "Google Drive API"
// 4. APIs & Services > OAuth consent screen > External > Create
// 5. APIs & Services > Credentials > + Create Credentials > OAuth client ID
// 6. Application type: Desktop app
// 7. Copy the Client ID and Client Secret below

class GoogleOAuthConfig {
  GoogleOAuthConfig._();

  static const String clientId = 'YOUR_CLIENT_ID_HERE';
  static const String clientSecret = 'YOUR_CLIENT_SECRET_HERE';

  static const int callbackPort = 43823;
  static const String redirectUri = 'http://localhost:43823/callback';
}
