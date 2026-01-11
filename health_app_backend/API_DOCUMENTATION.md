# Health App Backend - API Documentation

## Base URL

```
http://localhost:5000/api
```

## Authentication

All protected endpoints require a JWT token in the `Authorization` header:

```
Authorization: Bearer <your_jwt_token>
```

---

## Authentication Endpoints

### 1. Register User

**POST** `/auth/register`

Create a new user account.

**Request Body:**

```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "securePassword123"
}
```

**Response (201):**

```json
{
  "success": true,
  "message": "User registered successfully",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "_id": "507f1f77bcf86cd799439011",
    "name": "John Doe",
    "email": "john@example.com",
    "age": null,
    "weight": null,
    "height": null,
    "dailyCalorieGoal": 2000,
    "activityLevel": "moderate",
    "createdAt": "2024-01-11T10:00:00Z",
    "updatedAt": "2024-01-11T10:00:00Z"
  }
}
```

---

### 2. Login User

**POST** `/auth/login`

Authenticate and get JWT token.

**Request Body:**

```json
{
  "email": "john@example.com",
  "password": "securePassword123"
}
```

**Response (200):**

```json
{
  "success": true,
  "message": "Login successful",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "_id": "507f1f77bcf86cd799439011",
    "name": "John Doe",
    "email": "john@example.com",
    "dailyCalorieGoal": 2000,
    "createdAt": "2024-01-11T10:00:00Z"
  }
}
```

---

### 3. Get Current User

**GET** `/auth/me`

Get logged-in user's profile.

**Headers:**
```
Authorization: Bearer <token>
```

**Response (200):**

```json
{
  "success": true,
  "user": {
    "_id": "507f1f77bcf86cd799439011",
    "name": "John Doe",
    "email": "john@example.com",
    "age": 25,
    "weight": 75,
    "height": 180,
    "activityLevel": "moderate",
    "dailyCalorieGoal": 2200,
    "createdAt": "2024-01-11T10:00:00Z"
  }
}
```

---

### 4. Update User Profile

**PUT** `/auth/profile`

Update user information.

**Headers:**
```
Authorization: Bearer <token>
```

**Request Body:**

```json
{
  "name": "John Doe Updated",
  "age": 26,
  "weight": 76,
  "height": 181,
  "activityLevel": "active",
  "dailyCalorieGoal": 2300
}
```

**Response (200):**

```json
{
  "success": true,
  "message": "Profile updated successfully",
  "user": {
    "_id": "507f1f77bcf86cd799439011",
    "name": "John Doe Updated",
    "age": 26,
    "weight": 76,
    "height": 181,
    "dailyCalorieGoal": 2300
  }
}
```

---

### 5. Change Password

**POST** `/auth/change-password`

Change user password.

**Headers:**
```
Authorization: Bearer <token>
```

**Request Body:**

```json
{
  "currentPassword": "securePassword123",
  "newPassword": "newSecurePassword456"
}
```

**Response (200):**

```json
{
  "success": true,
  "message": "Password changed successfully"
}
```

---

## Meal Endpoints

### 1. Save Meal Result

**POST** `/meals`

Save a meal analysis result from the Flutter app.

**Headers:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**

```json
{
  "foodName": "ไข่ดาว",
  "nutrition": {
    "calories": 540,
    "protein": 15,
    "carbohydrates": 5,
    "fat": 45,
    "fiber": 0,
    "sodium": 200
  },
  "estimatedWeight": 300,
  "mealType": "breakfast",
  "confidence": 0.95,
  "imageUrl": "https://example.com/image.jpg",
  "notes": "Fried egg with butter"
}
```

**Response (201):**

```json
{
  "success": true,
  "message": "Meal saved successfully",
  "meal": {
    "_id": "507f1f77bcf86cd799439012",
    "userId": "507f1f77bcf86cd799439011",
    "foodName": "ไข่ดาว",
    "nutrition": {
      "calories": 540,
      "protein": 15,
      "carbohydrates": 5,
      "fat": 45
    },
    "estimatedWeight": 300,
    "mealType": "breakfast",
    "confidence": 0.95,
    "mealTime": "2024-01-11T08:30:00Z",
    "createdAt": "2024-01-11T10:00:00Z"
  }
}
```

---

### 2. Get Meal History

**GET** `/meals`

Retrieve user's meal history with pagination.

**Headers:**
```
Authorization: Bearer <token>
```

**Query Parameters:**
- `startDate` (optional): YYYY-MM-DD format
- `endDate` (optional): YYYY-MM-DD format
- `limit` (optional, default: 50): Number of records
- `offset` (optional, default: 0): Pagination offset

**Example:**
```
GET /meals?startDate=2024-01-01&endDate=2024-01-11&limit=20&offset=0
```

**Response (200):**

```json
{
  "success": true,
  "total": 150,
  "count": 20,
  "meals": [
    {
      "_id": "507f1f77bcf86cd799439012",
      "foodName": "ไข่ดาว",
      "nutrition": {
        "calories": 540,
        "protein": 15,
        "carbohydrates": 5,
        "fat": 45
      },
      "mealType": "breakfast",
      "mealTime": "2024-01-11T08:30:00Z",
      "createdAt": "2024-01-11T10:00:00Z"
    }
  ]
}
```

---

### 3. Get Single Meal

**GET** `/meals/:id`

Get details of a specific meal.

**Headers:**
```
Authorization: Bearer <token>
```

**Response (200):**

```json
{
  "success": true,
  "meal": {
    "_id": "507f1f77bcf86cd799439012",
    "userId": "507f1f77bcf86cd799439011",
    "foodName": "ไข่ดาว",
    "nutrition": {
      "calories": 540,
      "protein": 15,
      "carbohydrates": 5,
      "fat": 45,
      "fiber": 0,
      "sodium": 200
    },
    "estimatedWeight": 300,
    "mealType": "breakfast",
    "confidence": 0.95,
    "imageUrl": "https://example.com/image.jpg",
    "mealTime": "2024-01-11T08:30:00Z",
    "createdAt": "2024-01-11T10:00:00Z"
  }
}
```

---

### 4. Update Meal

**PUT** `/meals/:id`

Update a meal record.

**Headers:**
```
Authorization: Bearer <token>
```

**Request Body:**

```json
{
  "foodName": "ไข่ดาว (2 eggs)",
  "nutrition": {
    "calories": 1080,
    "protein": 30,
    "carbohydrates": 10,
    "fat": 90
  },
  "estimatedWeight": 600,
  "mealType": "breakfast",
  "notes": "Updated: 2 eggs instead of 1"
}
```

**Response (200):**

```json
{
  "success": true,
  "message": "Meal updated successfully",
  "meal": {
    "_id": "507f1f77bcf86cd799439012",
    "foodName": "ไข่ดาว (2 eggs)",
    "nutrition": {
      "calories": 1080,
      "protein": 30,
      "carbohydrates": 10,
      "fat": 90
    }
  }
}
```

---

### 5. Delete Meal

**DELETE** `/meals/:id`

Delete a meal record.

**Headers:**
```
Authorization: Bearer <token>
```

**Response (200):**

```json
{
  "success": true,
  "message": "Meal deleted successfully"
}
```

---

## Statistics Endpoints

### 1. Get Daily Statistics

**GET** `/stats/daily`

Get daily calorie breakdown and nutritional totals.

**Headers:**
```
Authorization: Bearer <token>
```

**Query Parameters:**
- `date` (optional): YYYY-MM-DD format (defaults to today)

**Example:**
```
GET /stats/daily?date=2024-01-11
```

**Response (200):**

```json
{
  "success": true,
  "date": "2024-01-11",
  "dailyGoal": 2200,
  "totals": {
    "calories": 1850,
    "protein": 120,
    "carbohydrates": 150,
    "fat": 65,
    "meals": [
      {
        "id": "507f1f77bcf86cd799439012",
        "foodName": "ไข่ดาว",
        "calories": 540,
        "mealType": "breakfast",
        "mealTime": "2024-01-11T08:30:00Z"
      }
    ]
  },
  "remaining": 350,
  "percentageReached": 84
}
```

---

### 2. Get Weekly Statistics

**GET** `/stats/weekly`

Get week-by-week calorie breakdown.

**Headers:**
```
Authorization: Bearer <token>
```

**Query Parameters:**
- `startDate` (optional): YYYY-MM-DD format (defaults to this week)

**Response (200):**

```json
{
  "success": true,
  "weekStart": "2024-01-08",
  "weekEnd": "2024-01-14",
  "dailyGoal": 2200,
  "dailyStats": [
    {
      "date": "2024-01-08",
      "dayName": "Mon",
      "calories": 2150,
      "protein": 130,
      "carbohydrates": 200,
      "fat": 75,
      "meals": [
        {
          "foodName": "ไข่ดาว",
          "calories": 540
        }
      ]
    },
    {
      "date": "2024-01-09",
      "dayName": "Tue",
      "calories": 1900,
      "protein": 115,
      "carbohydrates": 160,
      "fat": 65,
      "meals": []
    }
  ],
  "weeklyTotals": {
    "calories": 15050,
    "protein": 850,
    "carbohydrates": 1200,
    "fat": 520
  },
  "averageDailyCalories": 2150
}
```

---

### 3. Get Calorie Summary (for Donut Chart)

**GET** `/stats/summary`

Get macronutrient breakdown for pie/donut chart.

**Headers:**
```
Authorization: Bearer <token>
```

**Query Parameters:**
- `date` (optional): YYYY-MM-DD format

**Response (200):**

```json
{
  "success": true,
  "date": "2024-01-11",
  "macros": {
    "protein": 120,
    "carbohydrates": 150,
    "fat": 65
  },
  "calorieBreakdown": {
    "protein": {
      "grams": 120,
      "calories": 480,
      "percentage": 26
    },
    "carbohydrates": {
      "grams": 150,
      "calories": 600,
      "percentage": 32
    },
    "fat": {
      "grams": 65,
      "calories": 585,
      "percentage": 32
    }
  },
  "totalCalories": 1665
}
```

---

### 4. Get Nutritional Insights

**GET** `/stats/insights`

Get AI-generated nutritional insights based on meal history.

**Headers:**
```
Authorization: Bearer <token>
```

**Query Parameters:**
- `days` (optional, default: 7): Number of days to analyze

**Example:**
```
GET /stats/insights?days=14
```

**Response (200):**

```json
{
  "success": true,
  "period": "Last 7 days",
  "mealCount": 18,
  "averages": {
    "calories": 1950,
    "protein": 115,
    "carbohydrates": 180,
    "fat": 72
  },
  "insights": [
    {
      "type": "info",
      "message": "Consider increasing protein intake (current: 115g/meal)."
    },
    {
      "type": "success",
      "message": "You've logged 18 meals in the last 7 days."
    }
  ]
}
```

---

## Error Responses

### 400 - Bad Request

```json
{
  "success": false,
  "message": "Validation errors",
  "errors": [
    {
      "location": "body",
      "msg": "Calories must be a non-negative number",
      "param": "nutrition.calories"
    }
  ]
}
```

### 401 - Unauthorized

```json
{
  "success": false,
  "message": "Invalid token"
}
```

### 403 - Forbidden

```json
{
  "success": false,
  "message": "Not authorized to access this meal"
}
```

### 404 - Not Found

```json
{
  "success": false,
  "message": "Meal not found"
}
```

### 500 - Server Error

```json
{
  "success": false,
  "message": "Internal Server Error"
}
```

---

## Rate Limiting & Best Practices

1. **Token Expiration**: JWT tokens expire in 7 days
2. **Request Size**: Maximum 10MB payload
3. **Pagination**: Use limit and offset for large datasets
4. **Date Format**: Always use YYYY-MM-DD format
5. **Time Zones**: All times are in UTC/ISO 8601 format

---

## Testing with cURL

### Register

```bash
curl -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "email": "john@example.com",
    "password": "securePassword123"
  }'
```

### Login

```bash
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "password": "securePassword123"
  }'
```

### Save Meal

```bash
curl -X POST http://localhost:5000/api/meals \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "foodName": "ไข่ดาว",
    "nutrition": {
      "calories": 540,
      "protein": 15,
      "carbohydrates": 5,
      "fat": 45
    },
    "estimatedWeight": 300,
    "mealType": "breakfast"
  }'
```

### Get Daily Stats

```bash
curl -X GET "http://localhost:5000/api/stats/daily?date=2024-01-11" \
  -H "Authorization: Bearer <TOKEN>"
```

