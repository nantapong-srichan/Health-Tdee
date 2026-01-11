# Backend Implementation Reference

Complete reference for all components of the health app backend.

## Table of Contents
1. [Project Structure](#project-structure)
2. [API Endpoints](#api-endpoints)
3. [Database Models](#database-models)
4. [Authentication Flow](#authentication-flow)
5. [Error Handling](#error-handling)
6. [Request/Response Examples](#requestresponse-examples)

---

## Project Structure

### Entry Point: `server.js`

```javascript
// Initializes Express app
// Connects to MongoDB
// Mounts all routes
// Starts listening on PORT
```

**Key Responsibilities:**
- Load environment variables
- Connect to database
- Setup middleware (CORS, helmet, body parser)
- Mount routes
- Error handling

---

## API Endpoints

### Authentication Routes (`/api/auth`)

#### 1. POST `/auth/register`

**Description:** Create a new user account

**Request:**
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
    "dailyCalorieGoal": 2000,
    "createdAt": "2024-01-11T10:00:00Z"
  }
}
```

**Error Cases:**
- 400: Email already exists
- 400: Validation error (email format, password length)

**Code Flow:**
```
POST /register
    ↓
validateRegister middleware
    ↓
Check email not duplicate
    ↓
Hash password with bcrypt
    ↓
Create user in MongoDB
    ↓
Generate JWT token
    ↓
Return token + user
```

---

#### 2. POST `/auth/login`

**Description:** Authenticate user and get JWT token

**Request:**
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
    "email": "john@example.com"
  }
}
```

**Error Cases:**
- 400: Email/password missing
- 401: Invalid email or password

**Code Flow:**
```
POST /login
    ↓
Validate input
    ↓
Find user by email
    ↓
Compare password with hash
    ↓
Generate JWT token
    ↓
Return token + user
```

---

#### 3. GET `/auth/me` (Protected)

**Description:** Get current logged-in user's profile

**Headers:**
```
Authorization: Bearer <jwt_token>
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
    "dailyCalorieGoal": 2200
  }
}
```

**Code Flow:**
```
GET /me
    ↓
Verify JWT token
    ↓
Extract userId from token
    ↓
Query User by ID
    ↓
Return user (without password)
```

---

### Meal Routes (`/api/meals`)

#### 1. POST `/meals` (Protected)

**Description:** Save a meal result from the Flutter app

**Headers:**
```
Authorization: Bearer <jwt_token>
Content-Type: application/json
```

**Request:**
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
    "nutrition": {...},
    "mealTime": "2024-01-11T08:30:00Z",
    "createdAt": "2024-01-11T10:00:00Z"
  }
}
```

**Validation:**
- `foodName`: required, string
- `nutrition.calories`: required, integer ≥ 0
- `nutrition.protein`: required, integer ≥ 0
- `nutrition.carbohydrates`: required, integer ≥ 0
- `nutrition.fat`: required, integer ≥ 0
- `estimatedWeight`: required, integer ≥ 1

**Code Flow:**
```
POST /meals
    ↓
Verify JWT token
    ↓
Validate input
    ↓
Create Meal document
    ↓
Link to current user (userId)
    ↓
Save to MongoDB
    ↓
Return saved meal
```

---

#### 2. GET `/meals` (Protected)

**Description:** Get user's meal history with pagination and filtering

**Query Parameters:**
- `startDate`: YYYY-MM-DD (optional)
- `endDate`: YYYY-MM-DD (optional)
- `limit`: number (default: 50, max: 1000)
- `offset`: number (default: 0)

**Example:**
```
GET /meals?startDate=2024-01-01&endDate=2024-01-31&limit=20&offset=0
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
      "nutrition": {...},
      "mealType": "breakfast",
      "mealTime": "2024-01-11T08:30:00Z"
    }
  ]
}
```

**Code Flow:**
```
GET /meals
    ↓
Verify JWT token
    ↓
Parse query parameters
    ↓
Build MongoDB filter query
    ↓
Query Meal collection
    ↓
Sort by mealTime (newest first)
    ↓
Apply pagination (limit + skip)
    ↓
Return meals + total count
```

---

#### 3. GET `/meals/:id` (Protected)

**Description:** Get a single meal's details

**Response (200):**
```json
{
  "success": true,
  "meal": {
    "_id": "507f1f77bcf86cd799439012",
    "userId": "507f1f77bcf86cd799439011",
    "foodName": "ไข่ดาว",
    "nutrition": {...},
    "estimatedWeight": 300,
    "confidence": 0.95,
    "imageUrl": "https://...",
    "notes": "Fried egg",
    "mealTime": "2024-01-11T08:30:00Z"
  }
}
```

**Error Cases:**
- 404: Meal not found
- 403: User doesn't own this meal

**Authorization Check:**
```javascript
if (meal.userId.toString() !== req.userId) {
  return res.status(403).json({ message: 'Not authorized' });
}
```

---

#### 4. PUT `/meals/:id` (Protected)

**Description:** Update a meal

**Request:**
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
  "notes": "Updated: 2 eggs"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Meal updated successfully",
  "meal": {...}
}
```

---

#### 5. DELETE `/meals/:id` (Protected)

**Description:** Delete a meal

**Response (200):**
```json
{
  "success": true,
  "message": "Meal deleted successfully"
}
```

---

### Statistics Routes (`/api/stats`)

#### 1. GET `/stats/daily` (Protected)

**Description:** Get daily calorie breakdown

**Query Parameters:**
- `date`: YYYY-MM-DD (defaults to today)

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

**Calculations:**
```javascript
remaining = max(0, dailyGoal - totalCalories)
percentageReached = (totalCalories / dailyGoal) * 100
```

**Code Flow:**
```
GET /stats/daily
    ↓
Parse date parameter
    ↓
Query meals for that day
    ↓
Sum all nutrition values
    ↓
Get user's dailyCalorieGoal
    ↓
Calculate remaining calories
    ↓
Return stats object
```

---

#### 2. GET `/stats/weekly` (Protected)

**Description:** Get week-by-week breakdown

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
      "meals": [...]
    },
    ...7 days total
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

#### 3. GET `/stats/summary` (Protected)

**Description:** Macronutrient breakdown for donut/pie chart

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

**Calorie Calculations:**
- Protein: grams × 4 calories/gram
- Carbohydrates: grams × 4 calories/gram
- Fat: grams × 9 calories/gram

---

#### 4. GET `/stats/insights` (Protected)

**Description:** AI-generated nutritional insights

**Query Parameters:**
- `days`: number (default: 7)

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
      "type": "warning",
      "message": "Your average fat intake might be high."
    },
    {
      "type": "success",
      "message": "You've logged 18 meals in the last 7 days."
    }
  ]
}
```

**Insight Rules:**
- If avgCalories > 2500: warning
- If avgProtein < 50: info (low protein)
- If avgFat > 80: warning (high fat)
- Always: success (meal count)

---

## Database Models

### User Schema

```javascript
{
  _id: ObjectId,
  name: String (required, 2+ chars),
  email: String (required, unique, valid email),
  password: String (required, hashed, select: false),
  age: Number (1-150),
  weight: Number (kg),
  height: Number (cm),
  activityLevel: String (enum: sedentary|light|moderate|active|veryActive),
  dailyCalorieGoal: Number (default: 2000),
  isVerified: Boolean (default: false),
  createdAt: Date (default: now),
  updatedAt: Date (default: now)
}
```

**Indexes:**
```javascript
db.users.createIndex({ email: 1 }, { unique: true })
```

**Pre-save Hook:**
```javascript
// Automatically hashes password if modified
userSchema.pre('save', async function(next) {
  if (!this.isModified('password')) return next();
  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
  next();
});
```

---

### Meal Schema

```javascript
{
  _id: ObjectId,
  userId: ObjectId (required, ref: User, indexed),
  foodName: String (required),
  description: String,
  nutrition: {
    calories: Number (required, ≥0),
    protein: Number (required, ≥0),
    carbohydrates: Number (required, ≥0),
    fat: Number (required, ≥0),
    fiber: Number (default: 0),
    sodium: Number (default: 0)
  },
  estimatedWeight: Number (required, ≥1),
  confidence: Number (0-1),
  mealType: String (enum: breakfast|lunch|dinner|snack|other),
  mealTime: Date (required),
  imageUrl: String,
  notes: String,
  createdAt: Date (default: now),
  updatedAt: Date (default: now)
}
```

**Indexes:**
```javascript
db.meals.createIndex({ userId: 1, mealTime: -1 })
db.meals.createIndex({ userId: 1, createdAt: -1 })
db.meals.createIndex({ userId: 1 })
```

**Why Multiple Indexes?**
- `userId + mealTime`: Most queries (get meals by date range)
- `userId + createdAt`: Alternative sorting
- `userId` alone: User's total meal count queries

---

## Authentication Flow

### JWT Structure

```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9
.eyJ1c2VySWQiOiI1MDdmMWY3N2JjZjg2Y2Q3OTk0MzkwMTEiLCJpYXQiOjE3MDUwMDAwMDAsImV4cCI6MTcwNTYwNDgwMH0
.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c

[Header].[Payload].[Signature]
```

**Payload Decoded:**
```json
{
  "userId": "507f1f77bcf86cd799439011",
  "iat": 1705000000,      // issued at
  "exp": 1705604800       // expires (7 days later)
}
```

### Token Generation

```javascript
const generateToken = (userId) => {
  return jwt.sign({ userId }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRE || '7d',
  });
};
```

### Token Verification Middleware

```javascript
const authenticate = (req, res, next) => {
  try {
    const token = req.headers.authorization?.split(' ')[1];
    if (!token) return res.status(401).json({ message: 'No token' });
    
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.userId = decoded.userId;
    next();
  } catch (error) {
    res.status(401).json({ message: 'Invalid token' });
  }
};
```

### Usage in Routes

```javascript
// Protected route
router.post('/meals', authenticate, mealController.saveMeal);
//                    ^^^^^^^^^^^
// Middleware verifies token and sets req.userId
```

---

## Error Handling

### Error Types

#### 1. Validation Errors (400)

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

#### 2. Authentication Errors (401)

```json
{
  "success": false,
  "message": "Invalid token"
}
```

```json
{
  "success": false,
  "message": "Token has expired"
}
```

#### 3. Authorization Errors (403)

```json
{
  "success": false,
  "message": "Not authorized to access this meal"
}
```

#### 4. Not Found Errors (404)

```json
{
  "success": false,
  "message": "Meal not found"
}
```

#### 5. Database Errors (400/500)

```json
{
  "success": false,
  "message": "email already exists"
}
```

---

## Request/Response Examples

### Complete Flow: Register → Save Meal → Get Stats

#### Step 1: Register

```bash
curl -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Alice",
    "email": "alice@example.com",
    "password": "securePass123"
  }'
```

**Response:**
```json
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "_id": "507f1f77bcf86cd799439011",
    "name": "Alice",
    "email": "alice@example.com",
    "dailyCalorieGoal": 2000
  }
}
```

**Store this token for next requests:**
```bash
TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

---

#### Step 2: Save Meal

```bash
curl -X POST http://localhost:5000/api/meals \
  -H "Authorization: Bearer $TOKEN" \
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
    "mealType": "breakfast",
    "confidence": 0.95
  }'
```

**Response:**
```json
{
  "success": true,
  "message": "Meal saved successfully",
  "meal": {
    "_id": "507f1f77bcf86cd799439012",
    "userId": "507f1f77bcf86cd799439011",
    "foodName": "ไข่ดาว",
    "nutrition": {...},
    "mealTime": "2024-01-11T14:30:00Z"
  }
}
```

---

#### Step 3: Get Daily Stats

```bash
curl -X GET "http://localhost:5000/api/stats/daily?date=2024-01-11" \
  -H "Authorization: Bearer $TOKEN"
```

**Response:**
```json
{
  "success": true,
  "date": "2024-01-11",
  "dailyGoal": 2000,
  "totals": {
    "calories": 540,
    "protein": 15,
    "carbohydrates": 5,
    "fat": 45,
    "meals": [
      {
        "id": "507f1f77bcf86cd799439012",
        "foodName": "ไข่ดาว",
        "calories": 540,
        "mealType": "breakfast",
        "mealTime": "2024-01-11T14:30:00Z"
      }
    ]
  },
  "remaining": 1460,
  "percentageReached": 27
}
```

---

This completes the backend implementation! All components are production-ready and documented.

