# Flutter Integration Guide

How to integrate the backend with your Flutter mobile app.

## Setup

### 1. Add HTTP Package

Add to `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  shared_preferences: ^2.0.0  # For token storage
  intl: ^0.18.0  # For date formatting
```

Install packages:
```bash
flutter pub get
```

### 2. Create API Service

Create `lib/services/api_service.dart`:

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.1.100:5000/api';
  static String? _token;

  // Store token
  static Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  // Retrieve token
  static Future<String?> getToken() async {
    if (_token != null) return _token;
    
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('jwt_token');
    return _token;
  }

  // Clear token on logout
  static Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

  // Generic GET request
  static Future<dynamic> get(String endpoint) async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('GET request failed: $e');
    }
  }

  // Generic POST request
  static Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('POST request failed: $e');
    }
  }

  // Generic PUT request
  static Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    try {
      final token = await getToken();
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('PUT request failed: $e');
    }
  }

  // Generic DELETE request
  static Future<dynamic> delete(String endpoint) async {
    try {
      final token = await getToken();
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('DELETE request failed: $e');
    }
  }

  // Handle response
  static dynamic _handleResponse(http.Response response) {
    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else if (response.statusCode == 401) {
      // Token expired - clear and redirect to login
      clearToken();
      throw Exception('Session expired. Please login again.');
    } else {
      throw Exception(data['message'] ?? 'API Error: ${response.statusCode}');
    }
  }
}
```

### 3. Create Auth Service

Create `lib/services/auth_service.dart`:

```dart
import 'api_service.dart';

class AuthService {
  // Register
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await ApiService.post('/auth/register', {
      'name': name,
      'email': email,
      'password': password,
    });

    if (response['success']) {
      await ApiService.setToken(response['token']);
      return response['user'];
    }
    throw Exception(response['message']);
  }

  // Login
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await ApiService.post('/auth/login', {
      'email': email,
      'password': password,
    });

    if (response['success']) {
      await ApiService.setToken(response['token']);
      return response['user'];
    }
    throw Exception(response['message']);
  }

  // Get current user
  static Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await ApiService.get('/auth/me');
    if (response['success']) {
      return response['user'];
    }
    throw Exception(response['message']);
  }

  // Update profile
  static Future<Map<String, dynamic>> updateProfile({
    String? name,
    int? age,
    int? weight,
    int? height,
    String? activityLevel,
    int? dailyCalorieGoal,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (age != null) body['age'] = age;
    if (weight != null) body['weight'] = weight;
    if (height != null) body['height'] = height;
    if (activityLevel != null) body['activityLevel'] = activityLevel;
    if (dailyCalorieGoal != null) body['dailyCalorieGoal'] = dailyCalorieGoal;

    final response = await ApiService.put('/auth/profile', body);
    if (response['success']) {
      return response['user'];
    }
    throw Exception(response['message']);
  }

  // Logout
  static Future<void> logout() async {
    await ApiService.clearToken();
  }
}
```

### 4. Create Meal Service

Create `lib/services/meal_service.dart`:

```dart
import 'api_service.dart';

class MealService {
  // Save meal from results_screen.dart
  static Future<Map<String, dynamic>> saveMeal({
    required String foodName,
    required int calories,
    required int protein,
    required int carbohydrates,
    required int fat,
    required int estimatedWeight,
    String? mealType,
    double? confidence,
    String? imageUrl,
    String? notes,
  }) async {
    final response = await ApiService.post('/meals', {
      'foodName': foodName,
      'nutrition': {
        'calories': calories,
        'protein': protein,
        'carbohydrates': carbohydrates,
        'fat': fat,
      },
      'estimatedWeight': estimatedWeight,
      'mealType': mealType ?? 'other',
      'confidence': confidence,
      'imageUrl': imageUrl,
      'notes': notes,
    });

    if (response['success']) {
      return response['meal'];
    }
    throw Exception(response['message']);
  }

  // Get meal history
  static Future<List<Map<String, dynamic>>> getMealHistory({
    String? startDate,
    String? endDate,
    int limit = 50,
    int offset = 0,
  }) async {
    String query = '/meals?limit=$limit&offset=$offset';
    if (startDate != null) query += '&startDate=$startDate';
    if (endDate != null) query += '&endDate=$endDate';

    final response = await ApiService.get(query);
    if (response['success']) {
      return List<Map<String, dynamic>>.from(response['meals']);
    }
    throw Exception(response['message']);
  }

  // Get single meal
  static Future<Map<String, dynamic>> getMeal(String mealId) async {
    final response = await ApiService.get('/meals/$mealId');
    if (response['success']) {
      return response['meal'];
    }
    throw Exception(response['message']);
  }

  // Delete meal
  static Future<void> deleteMeal(String mealId) async {
    final response = await ApiService.delete('/meals/$mealId');
    if (!response['success']) {
      throw Exception(response['message']);
    }
  }
}
```

### 5. Create Statistics Service

Create `lib/services/stats_service.dart`:

```dart
import 'api_service.dart';

class StatsService {
  // Get daily stats for home_screen.dart
  static Future<Map<String, dynamic>> getDailyStats({String? date}) async {
    String query = '/stats/daily';
    if (date != null) query += '?date=$date';

    final response = await ApiService.get(query);
    if (response['success']) {
      return response;
    }
    throw Exception(response['message']);
  }

  // Get weekly stats for home_screen.dart charts
  static Future<Map<String, dynamic>> getWeeklyStats({String? startDate}) async {
    String query = '/stats/weekly';
    if (startDate != null) query += '?startDate=$startDate';

    final response = await ApiService.get(query);
    if (response['success']) {
      return response;
    }
    throw Exception(response['message']);
  }

  // Get calorie summary for donut chart
  static Future<Map<String, dynamic>> getCalorieSummary({String? date}) async {
    String query = '/stats/summary';
    if (date != null) query += '?date=$date';

    final response = await ApiService.get(query);
    if (response['success']) {
      return response;
    }
    throw Exception(response['message']);
  }

  // Get nutritional insights
  static Future<Map<String, dynamic>> getNutritionalInsights({int days = 7}) async {
    final response = await ApiService.get('/stats/insights?days=$days');
    if (response['success']) {
      return response;
    }
    throw Exception(response['message']);
  }
}
```

## Integration with Existing Screens

### 1. results_screen.dart - Save Meal

```dart
// In your results screen after displaying the food analysis
import 'package:health_app/services/meal_service.dart';

class ResultsScreen extends StatefulWidget {
  final RecognitionResult result;

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  bool _isSaving = false;

  Future<void> _saveMeal() async {
    setState(() => _isSaving = true);

    try {
      await MealService.saveMeal(
        foodName: widget.result.foodName,
        calories: widget.result.calories.toInt(),
        protein: widget.result.protein.toInt(),
        carbohydrates: widget.result.carbohydrates.toInt(),
        fat: widget.result.fat.toInt(),
        estimatedWeight: widget.result.estimatedWeight.toInt(),
        confidence: widget.result.confidence,
        mealType: _selectedMealType,
        notes: _notesController.text,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Meal saved successfully!')),
      );

      // Navigate back
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving meal: $e')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Food Analysis')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ... existing result display
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveMeal,
              child: _isSaving
                  ? CircularProgressIndicator()
                  : Text('Save Meal'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 2. home_screen.dart - Display Statistics

```dart
import 'package:health_app/services/stats_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<Map<String, dynamic>> _dailyStatsFuture;
  late Future<Map<String, dynamic>> _weeklySummaryFuture;

  @override
  void initState() {
    super.initState();
    _dailyStatsFuture = StatsService.getDailyStats();
    _weeklySummaryFuture = StatsService.getWeeklyStats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Health Dashboard')),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _dailyStatsFuture = StatsService.getDailyStats();
            _weeklySummaryFuture = StatsService.getWeeklyStats();
          });
        },
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Daily Calorie Stats
              FutureBuilder<Map<String, dynamic>>(
                future: _dailyStatsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }

                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }

                  final data = snapshot.data!;
                  final dailyGoal = data['dailyGoal'];
                  final totalCalories = data['totals']['calories'];
                  final percentage = data['percentageReached'] / 100;

                  return Column(
                    children: [
                      Text(
                        'Today\'s Calories',
                        style: Theme.of(context).textTheme.headline6,
                      ),
                      SizedBox(height: 16),
                      // Use percent_indicator for donut chart
                      CircularPercentIndicator(
                        radius: 120.0,
                        lineWidth: 10.0,
                        percent: percentage,
                        center: Text(
                          '$totalCalories\nKCal',
                          textAlign: TextAlign.center,
                        ),
                        progressColor: Colors.green,
                      ),
                      SizedBox(height: 16),
                      Text('Goal: $dailyGoal KCal'),
                    ],
                  );
                },
              ),

              SizedBox(height: 32),

              // Weekly Chart
              FutureBuilder<Map<String, dynamic>>(
                future: _weeklySummaryFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }

                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }

                  final data = snapshot.data!;
                  final dailyStats = List<Map<String, dynamic>>.from(
                    data['dailyStats'],
                  );

                  return Column(
                    children: [
                      Text(
                        'This Week',
                        style: Theme.of(context).textTheme.headline6,
                      ),
                      // Build chart using dailyStats
                      // Use fl_chart or similar package
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### 3. Authentication Flow

```dart
// In your login/register screen
import 'package:health_app/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _login() async {
    try {
      final user = await AuthService.login(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // Navigate to home screen
      Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _login,
                child: Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

## Network Configuration

### iOS - Allow Local Network

Add to `ios/Runner/Info.plist`:

```xml
<key>NSLocalNetworkUsageDescription</key>
<string>This app needs access to local network for backend communication</string>
<key>NSBonjourServices</key>
<array>
  <string>_health-api._tcp</string>
</array>
```

### Android - Allow HTTP (During Development)

Modify `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

For production, use HTTPS and add proper certificate pinning.

## Error Handling Best Practices

```dart
try {
  final meals = await MealService.getMealHistory();
} on SocketException {
  // Network error
  print('Network error: Unable to connect to server');
} on TimeoutException {
  // Timeout error
  print('Request timeout: Server took too long to respond');
} on Exception catch (e) {
  // API or other errors
  if (e.toString().contains('Session expired')) {
    // Redirect to login
    Navigator.of(context).pushReplacementNamed('/login');
  } else {
    // Show error message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}
```

## Testing API Endpoints

Use Postman or curl to test before integrating:

```bash
# Register
curl -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","email":"test@test.com","password":"pass123"}'

# Save meal
curl -X POST http://localhost:5000/api/meals \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "foodName":"ไข่ดาว",
    "nutrition":{"calories":540,"protein":15,"carbohydrates":5,"fat":45},
    "estimatedWeight":300,
    "mealType":"breakfast"
  }'

# Get daily stats
curl -X GET "http://localhost:5000/api/stats/daily" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

