# System Architecture Diagrams

Visual representations of the health app backend system architecture.

## 1. Complete System Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                     FLUTTER MOBILE APP                             │
│  (iOS & Android with TFLite Food Recognition Model)                │
│                                                                      │
│  • results_screen.dart → POST /meals (save food analysis)          │
│  • home_screen.dart → GET /stats (fetch statistics)                │
└──────────────────────────┬──────────────────────────────────────────┘
                           │ HTTPS/REST API
                           │ (JWT Token in header)
                           ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    PRODUCTION DEPLOYMENT                            │
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │ Nginx/Reverse Proxy                                         │   │
│  │ • SSL/TLS Termination                                       │   │
│  │ • Load Balancing (multiple instances)                       │   │
│  │ • Request Compression                                       │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                           │                                         │
│  ┌────────────────────────┼────────────────────────┐               │
│  ▼                        ▼                        ▼               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐            │
│  │  Node.js     │  │  Node.js     │  │  Node.js     │            │
│  │  Instance 1  │  │  Instance 2  │  │  Instance 3  │            │
│  │              │  │              │  │              │            │
│  │ Express.js   │  │ Express.js   │  │ Express.js   │            │
│  │ Port 5000    │  │ Port 5001    │  │ Port 5002    │            │
│  └──────────────┘  └──────────────┘  └──────────────┘            │
│                           │                                         │
│                    Connection Pool                                 │
│                      (Mongoose)                                    │
│                           │                                         │
└───────────────────────────┼─────────────────────────────────────────┘
                            │
                    ┌───────▼────────┐
                    │ MongoDB Atlas  │
                    │                │
                    │ Collections:   │
                    │ • users        │
                    │ • meals        │
                    │ • indexes      │
                    │                │
                    │ Backup: Daily  │
                    └────────────────┘
```

---

## 2. Request Flow Architecture

```
CLIENT REQUEST (Flutter App)
    │
    │ POST /api/meals
    │ Headers: Authorization: Bearer <jwt>
    │ Body: { foodName, nutrition, ... }
    │
    ▼
NGINX Reverse Proxy
    │
    ├─ Extract host/path
    ├─ Check SSL certificate
    └─ Forward to Express instance
    │
    ▼
EXPRESS SERVER
    │
    ├─ Middleware Stack
    │  ├─ helmet() [security headers]
    │  ├─ cors() [CORS validation]
    │  ├─ express.json() [parse JSON]
    │  ├─ morgan() [logging]
    │  └─ authenticate [JWT verification]
    │
    ▼
JWT VERIFICATION
    │
    ├─ Extract token from Authorization header
    ├─ Verify signature with JWT_SECRET
    ├─ Check expiration time
    └─ Extract userId and attach to req
    │
    ▼
INPUT VALIDATION (express-validator)
    │
    ├─ Validate foodName (string, not empty)
    ├─ Validate nutrition.calories (number, >= 0)
    ├─ Validate nutrition.protein (number, >= 0)
    ├─ Validate nutrition.carbohydrates (number, >= 0)
    ├─ Validate nutrition.fat (number, >= 0)
    └─ Validate estimatedWeight (number, >= 1)
    │
    ▼
MEAL CONTROLLER
    │
    ├─ Create meal object with userId
    ├─ Set mealTime to current time
    ├─ Call Meal.create() via Mongoose
    │
    ▼
MONGOOSE MODEL
    │
    ├─ Validate data against schema
    ├─ Run pre-save hooks
    ├─ Convert to BSON format
    │
    ▼
MONGODB
    │
    ├─ Insert document into meals collection
    ├─ Update indexes
    ├─ Return with _id
    │
    ▼
RESPONSE BUILDER
    │
    ├─ Status: 201 Created
    ├─ Body: { success, message, meal }
    │
    ▼
CLIENT
    │
    └─ Save response and update UI
```

---

## 3. Authentication Flow

```
REGISTRATION
    │
    ├─ User submits: name, email, password
    ▼
Validate Input
    │
    ├─ Email format valid?
    ├─ Password length >= 6?
    ├─ Name length >= 2?
    │
    └─ If invalid → 400 error
    │
    ▼
Check Email Uniqueness
    │
    ├─ Query: User.findOne({ email })
    │
    └─ If exists → 400 "Email already registered"
    │
    ▼
Hash Password (bcrypt)
    │
    ├─ Generate salt (10 rounds)
    ├─ Hash password + salt
    │
    └─ Store hashed version (NOT original)
    │
    ▼
Create User in DB
    │
    ├─ Insert into users collection
    │
    └─ Return new user _id
    │
    ▼
Generate JWT Token
    │
    ├─ Payload: { userId, iat, exp }
    ├─ Sign with JWT_SECRET
    ├─ Expires in 7 days
    │
    └─ Return token to client
    │
    ▼
CLIENT RECEIVES
    │
    ├─ JWT token
    ├─ User data
    │
    └─ Store token in SharedPreferences (Flutter)


LOGIN
    │
    ├─ User submits: email, password
    ▼
Find User by Email
    │
    ├─ Query: User.findOne({ email }).select('+password')
    │
    └─ If not found → 401 "Invalid credentials"
    │
    ▼
Compare Passwords
    │
    ├─ Use bcrypt.compare(inputPassword, storedHash)
    │
    └─ If no match → 401 "Invalid credentials"
    │
    ▼
Generate JWT Token
    │
    ├─ Same as registration
    │
    └─ Return token + user
    │
    ▼
CLIENT STORES TOKEN


PROTECTED REQUESTS
    │
    ├─ Every request includes: Authorization: Bearer <token>
    │
    ▼
Verify Token
    │
    ├─ Extract token from header
    ├─ Verify signature matches JWT_SECRET
    ├─ Check expiration date
    │
    ├─ If valid → Extract userId from payload
    ├─ If invalid → 401 "Invalid token"
    ├─ If expired → 401 "Token has expired"
    │
    └─ Attach userId to request object
    │
    ▼
CONTINUE REQUEST
    │
    └─ Process as authenticated user
```

---

## 4. Database Query Flow

```
GET /meals (with date filter)
    │
    │ Query: { startDate: "2024-01-01", endDate: "2024-01-31", limit: 20 }
    │
    ▼
Build MongoDB Filter
    │
    ├─ { userId: req.userId }                    ← Always include
    │
    ├─ IF startDate provided:
    │  └─ { mealTime: { $gte: startDate } }
    │
    ├─ IF endDate provided:
    │  └─ { mealTime: { $lte: endDate } }
    │
    └─ Final filter: { userId, mealTime: { $gte, $lte } }
    │
    ▼
Query MongoDB
    │
    ├─ USE INDEX: { userId: 1, mealTime: -1 }
    │     ↑                    ↑
    │     └─ Fast user lookup  └─ Sorted newest first
    │
    ├─ Sort by mealTime descending
    ├─ Limit 20 documents
    ├─ Skip 0 documents (offset)
    │
    └─ MongoDB returns matching documents
    │
    ▼
Return to Controller
    │
    ├─ Parse result
    ├─ Count total matching documents
    │
    └─ Format response
    │
    ▼
CLIENT RECEIVES
    │
    ├─ Array of 20 meals
    ├─ Total count (for pagination)
    │
    └─ Display in home_screen.dart


GET /stats/daily (with date)
    │
    │ Query: { date: "2024-01-11" }
    │
    ▼
Determine Date Range
    │
    ├─ startOfDay: 2024-01-11 00:00:00
    ├─ endOfDay: 2024-01-11 23:59:59
    │
    ▼
Query All Meals for That Day
    │
    ├─ Filter: { userId, mealTime: { $gte: startOfDay, $lte: endOfDay } }
    │
    └─ Result: Array of meals
    │
    ▼
Calculate Totals (in-memory)
    │
    ├─ For each meal:
    │  ├─ totalCalories += meal.nutrition.calories
    │  ├─ totalProtein += meal.nutrition.protein
    │  ├─ totalCarbs += meal.nutrition.carbohydrates
    │  ├─ totalFat += meal.nutrition.fat
    │
    ▼
Get User's Daily Goal
    │
    ├─ Query: User.findById(userId)
    │
    └─ Get: dailyCalorieGoal (default: 2000)
    │
    ▼
Calculate Stats
    │
    ├─ remaining = max(0, dailyGoal - totalCalories)
    ├─ percentageReached = (totalCalories / dailyGoal) * 100
    │
    ▼
RESPONSE
    │
    ├─ date
    ├─ dailyGoal
    ├─ totals { calories, protein, carbs, fat, meals }
    ├─ remaining
    ├─ percentageReached
    │
    └─ Use for donut chart in home_screen.dart
```

---

## 5. Security Layers

```
ATTACK VECTOR              DEFENSE MECHANISM          LOCATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Network Layer
  ├─ Man-in-the-middle      SSL/TLS (HTTPS)            Nginx + Let's Encrypt
  ├─ Unencrypted traffic     Helmet headers             Express middleware
  └─ Clickjacking            X-Frame-Options            helmet() middleware

Transport Layer
  ├─ Unauthorized access     Authentication (JWT)      middleware/auth.js
  ├─ Expired token          Token expiration           JWT verification
  └─ Token tampering        Signature verification    jwt.verify()

Application Layer
  ├─ SQL Injection           Mongoose (ORM)            models/*.js
  ├─ XSS attacks            Input sanitization        express-validator
  ├─ Invalid data           Type validation           Mongoose schema
  ├─ Weak passwords         bcrypt hashing (10 rounds) User.js pre-save
  └─ Brute force            No rate limiting* (TODO)   Would add rate-limit

Authorization Layer
  ├─ Cross-user access      User ID check             Controllers
  ├─ Unauthorized edits     Ownership verification     mealController.js
  └─ Privilege escalation    Role checks (future)      Not implemented yet

Database Layer
  ├─ Password leaks         Passwords excluded        User schema (select: false)
  ├─ Duplicate emails       Unique index              db.users.createIndex
  └─ Deleted data recovery  Backups (MongoDB Atlas)   Automated daily

Deployment
  ├─ Exposed secrets        Environment variables     .env (not in git)
  ├─ Debug mode             NODE_ENV=production       .env
  └─ Vulnerable deps        npm audit, dependabot     CI/CD
```

---

## 6. Data Flow: Save Meal to Display on Home Screen

```
FLUTTER APP (results_screen.dart)
    │
    │ Food recognized: ไข่ดาว
    │ Calories: 540 KCal
    │ Protein: 15g
    │ Carbs: 5g
    │ Fat: 45g
    │ Weight: 300g
    │ Confidence: 0.95
    │
    ▼
[Save Meal Button Pressed]
    │
    ├─ Get JWT token from SharedPreferences
    │
    ▼
POST /api/meals
    │
    ├─ URL: http://your-domain.com/api/meals
    ├─ Headers: Authorization: Bearer <token>
    ├─ Body: {
    │   foodName: "ไข่ดาว",
    │   nutrition: {
    │     calories: 540,
    │     protein: 15,
    │     carbohydrates: 5,
    │     fat: 45
    │   },
    │   estimatedWeight: 300,
    │   mealType: "breakfast",
    │   confidence: 0.95
    │ }
    │
    ▼
BACKEND (mealController.saveMeal)
    │
    ├─ Validate all fields
    ├─ Create Meal document with userId
    ├─ Set mealTime to now
    ├─ Save to MongoDB
    │
    ▼
MongoDB meals collection
    │
    ├─ Document inserted:
    │ {
    │   _id: ObjectId,
    │   userId: ObjectId,
    │   foodName: "ไข่ดาว",
    │   nutrition: { calories: 540, ... },
    │   estimatedWeight: 300,
    │   mealTime: 2024-01-11T14:30:00Z,
    │   createdAt: 2024-01-11T14:30:00Z
    │ }
    │
    └─ Response: 201 { success, meal }
    │
    ▼
FLUTTER APP (receives response)
    │
    ├─ Navigate to home_screen.dart
    │
    ▼
HOME SCREEN (initState)
    │
    ├─ Call: StatsService.getDailyStats()
    │
    ▼
GET /api/stats/daily?date=2024-01-11
    │
    ├─ Query meals for today from this user
    │
    ▼
BACKEND (statsController.getDailyStats)
    │
    ├─ Find all meals for userId on 2024-01-11
    │ Query: { userId, mealTime: { $gte: today, $lte: tomorrow } }
    │
    ├─ Loop through and sum:
    │  totalCalories = 540
    │  totalProtein = 15
    │  totalCarbs = 5
    │  totalFat = 45
    │
    ├─ Get user's dailyGoal = 2200
    │
    ├─ Calculate:
    │  remaining = 2200 - 540 = 1660
    │  percentageReached = 540/2200 * 100 = 24.5%
    │
    └─ Response: { dailyGoal, totals, remaining, percentageReached, meals }
    │
    ▼
FLUTTER APP (home_screen.dart)
    │
    ├─ Receive stats
    │
    ├─ Build CircularPercentIndicator:
    │  ├─ Progress: 24.5%
    │  ├─ Center text: "540\nKCal"
    │  ├─ Goal: "2200 KCal"
    │  └─ Remaining: "1660 KCal"
    │
    ├─ List meals eaten today:
    │  ├─ ไข่ดาว - 540 KCal - 14:30
    │
    └─ Display complete!
```

---

## 7. Scaling Architecture

```
CURRENT (Small Scale)
    Flutter App → Backend Server → MongoDB
    
    Capacity: ~1000 users

─────────────────────────────────────────────────────────

PHASE 1: Load Balancing (10K+ users)
    
    Flutter App
         ↓
    ┌────┴────┐
    Nginx (Load Balancer)
    ├────┬────┤
    ▼    ▼    ▼
    API1 API2 API3
    └────┬────┘
         ▼
    MongoDB Atlas
    
    Capacity: ~100K users

─────────────────────────────────────────────────────────

PHASE 2: Caching (100K+ users)
    
    Flutter App
         ↓
    Nginx (Load Balancer)
         ↓
    ┌────┴────┐
    ▼    ▼    ▼
    API1 API2 API3
         ↓
    ┌────┴────┐
    Redis Cache (Session, Stats)
         ↓
    MongoDB Atlas + Replica Set
    
    Capacity: ~1M users

─────────────────────────────────────────────────────────

PHASE 3: Database Sharding (1M+ users)
    
    Flutter App
         ↓
    CDN + Nginx
         ↓
    API Load Balancer
    ┌────┬────┐
    ▼    ▼    ▼
    API1 API2 API3
         ↓
    Redis Cluster
         ↓
    ┌────┬────┐
    Shard1  Shard2  Shard3
    (users) (meals) (stats)
```

---

## 8. Error Flow

```
CLIENT REQUEST
    │
    ▼
VALIDATION ERROR?
    │
    ├─ Yes → 400 Bad Request
    │        { success: false, errors: [...] }
    │
    └─ No → Continue
    │
    ▼
AUTHENTICATION ERROR?
    │
    ├─ Missing token → 401 Unauthorized
    │                  "No token provided"
    │
    ├─ Invalid token → 401 Unauthorized
    │                  "Invalid token"
    │
    ├─ Token expired → 401 Unauthorized
    │                  "Token has expired"
    │
    └─ Valid token → Continue
    │
    ▼
DATABASE ERROR?
    │
    ├─ Duplicate email → 400 Bad Request
    │                    "Email already registered"
    │
    ├─ Record not found → 404 Not Found
    │                     "Meal not found"
    │
    ├─ Query failed → 500 Server Error
    │                 "Internal Server Error"
    │
    └─ Success → Continue
    │
    ▼
AUTHORIZATION ERROR?
    │
    ├─ User doesn't own record → 403 Forbidden
    │                            "Not authorized"
    │
    └─ User owns record → Continue
    │
    ▼
SUCCESS
    │
    └─ 200 OK / 201 Created / 204 No Content
       { success: true, data: {...} }
```

---

This architecture supports production use and scales as your user base grows!

