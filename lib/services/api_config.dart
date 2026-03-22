class ApiConfig {
  // Backend API base URL
  // For local development: http://localhost:5000
  // For Android emulator: http://10.0.2.2:5000
  // For physical device: http://YOUR_COMPUTER_IP:5000
  
  static const String baseUrl = 'http://10.0.2.2:5000/api';
  //static const String baseUrl = 'https://health-app-backup.onrender.com/api';

  // static const String baseUrl = 'https://suboceanic-unelusively-lue.ngrok-free.dev/api';
  
  // Change this to your actual backend URL when deploying
  // Example: 'https://health-app-backend.railway.app/api'
  
  // Endpoints
  static const String authRegister = '$baseUrl/auth/register';
  static const String authLogin = '$baseUrl/auth/login';
  static const String authProfile = '$baseUrl/auth/me';
  static const String authProfileUpdate = '$baseUrl/auth/profile';
  static const String authChangePassword = '$baseUrl/auth/change-password';
  static const String authChangeEmail = '$baseUrl/auth/change-email';
  static const String authUploadProfileImage = '$baseUrl/auth/upload-profile-image';
  
  static const String mealSave = '$baseUrl/meals';
  static const String mealHistory = '$baseUrl/meals';
  static const String mealDetail = '$baseUrl/meals';
  static const String mealUpdate = '$baseUrl/meals';
  static const String mealDelete = '$baseUrl/meals';
  
  static const String statsDaily = '$baseUrl/stats/daily';
  static const String statsWeekly = '$baseUrl/stats/weekly';
  static const String statsSummary = '$baseUrl/stats/summary';
  static const String statsInsights = '$baseUrl/stats/insights';
}
