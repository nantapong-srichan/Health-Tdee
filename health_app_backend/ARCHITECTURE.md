# Architecture & Security Guide

## Backend Architecture

### Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter Mobile App                       │
│              (iOS/Android with TFLite Model)                │
└──────────────────────────┬──────────────────────────────────┘
                           │ HTTPS/REST API
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                   Express.js Server                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │   Routes    │  │ Controllers  │  │  Middleware  │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
│  • Auth          • Authentication    • JWT Verify        │
│  • Meals         • Meal Operations   • Error Handler      │
│  • Statistics    • Data Processing   • CORS              │
└──────────────────┬─────────────────────────────────────────┘
                   │ Mongoose ODM
                   ▼
┌─────────────────────────────────────────────────────────────┐
│                 MongoDB Atlas                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │ Users        │  │ Meals        │  │ Indexes      │     │
│  │ Collection   │  │ Collection   │  │ & Queries    │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└─────────────────────────────────────────────────────────────┘
```

### Layer Breakdown

#### 1. **Routes Layer** (`routes/`)
- Defines API endpoints
- Applies validation & middleware
- Routes requests to controllers

#### 2. **Controllers Layer** (`controllers/`)
- Business logic implementation
- Data processing
- Response formatting
- Communicates with database via Models

#### 3. **Models Layer** (`models/`)
- Mongoose schemas definition
- Data validation at DB level
- Indexes for performance
- Pre/post hooks for data transformation

#### 4. **Middleware Layer** (`middleware/`)
- JWT authentication
- Global error handling
- CORS configuration
- Request logging

#### 5. **Utilities Layer** (`utils/`)
- Input validation rules
- Helper functions
- Constants

---

## MongoDB Schema Design

### User Collection

```javascript
{
  _id: ObjectId,
  
  // Basic Info
  name: String,
  email: String (unique),
  password: String (hashed),
  
  // Profile
  age: Number,
  weight: Number (kg),
  height: Number (cm),
  activityLevel: String (enum),
  
  // Goals
  dailyCalorieGoal: Number,
  
  // Metadata
  isVerified: Boolean,
  createdAt: Date,
  updatedAt: Date
}
```

**Indexes:**
```javascript
db.users.createIndex({ email: 1 }, { unique: true })
```

### Meal Collection

```javascript
{
  _id: ObjectId,
  
  // Reference
  userId: ObjectId (ref: User),
  
  // Meal Info
  foodName: String,
  description: String,
  
  // Nutrition
  nutrition: {
    calories: Number,
    protein: Number (g),
    carbohydrates: Number (g),
    fat: Number (g),
    fiber: Number (g),
    sodium: Number (mg)
  },
  
  // Weight & Confidence
  estimatedWeight: Number (g),
  confidence: Number (0-1),
  
  // Classification
  mealType: String (breakfast|lunch|dinner|snack|other),
  mealTime: Date,
  
  // Media
  imageUrl: String,
  
  // Extra
  notes: String,
  createdAt: Date,
  updatedAt: Date
}
```

**Indexes:**
```javascript
db.meals.createIndex({ userId: 1, mealTime: -1 })
db.meals.createIndex({ userId: 1, createdAt: -1 })
db.meals.createIndex({ userId: 1 })
```

**Rationale:**
- Compound index on `userId + mealTime` for efficient time-range queries
- Separate index on `userId` for user queries
- `mealTime` sorted descending for latest-first results

---

## JWT Authentication Flow

### 1. Registration Flow

```
User Input (email, password)
        ▼
Validate Input
        ▼
Check if Email Exists
        ▼
Hash Password (bcrypt + salt)
        ▼
Create User in Database
        ▼
Generate JWT Token
        ▼
Return Token + User Data
```

**JWT Structure:**
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9  ← Header
.
eyJ1c2VySWQiOiI1MDdmMWY3N2JjZjg2Y2Q3OTk0MzkwMTEiLCJpYXQiOjE3MDUwMDAwMDAsImV4cCI6MTcwNTYwNDgwMH0  ← Payload
.
SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c  ← Signature
```

**Payload Structure:**
```json
{
  "userId": "507f1f77bcf86cd799439011",
  "iat": 1705000000,      // issued at
  "exp": 1705604800       // expires in 7 days
}
```

### 2. Protected Request Flow

```
Client Request + JWT Token
        ▼
Extract Token from Authorization Header
        ▼
Verify Token Signature
        ▼
Check Token Expiration
        ▼
Extract userId from Payload
        ▼
Attach to Request Object (req.userId)
        ▼
Proceed to Route Handler
        ▼
Return Data (Filtered by userId)
```

### 3. Token Refresh Strategy

```
Token Expired (401)
        ▼
Mobile App catches 401 error
        ▼
Call /auth/login with stored credentials
        ▼
Get New Token
        ▼
Retry Original Request with New Token
```

---

## Security Best Practices

### 1. **Password Security**

✅ **Implemented:**
```javascript
// Hashing with bcrypt (10 rounds)
const salt = await bcrypt.genSalt(10);
this.password = await bcrypt.hash(this.password, salt);

// Password comparison
const isValid = await bcrypt.compare(inputPassword, hashedPassword);
```

**Why bcrypt?**
- Adaptive: increases rounds over time as computers get faster
- Salted: prevents rainbow table attacks
- Slow: ~100ms per hash (deters brute force)

### 2. **JWT Token Security**

✅ **Implemented:**
```javascript
// Strong secret (should be 32+ characters)
JWT_SECRET=your_super_secret_jwt_key_change_this_in_production_with_strong_random_string

// Short expiration time
JWT_EXPIRE=7d

// Verify before processing
const decoded = jwt.verify(token, process.env.JWT_SECRET);
```

**Best Practices:**
- Use environment variables for secrets
- Rotate secrets periodically
- Don't include sensitive data in payload
- Use HTTPS only (no HTTP)

### 3. **Data Validation**

✅ **Implemented:**
```javascript
// Input validation with express-validator
body('email').isEmail().normalizeEmail(),
body('password').isLength({ min: 6 }),
body('nutrition.calories').isNumeric().isInt({ min: 0 })
```

**Defense Against:**
- SQL Injection (via Mongoose with proper queries)
- XSS (via input sanitization)
- Invalid data types

### 4. **Database Security**

✅ **Implemented:**
```javascript
// Unique index prevents duplicate emails
db.users.createIndex({ email: 1 }, { unique: true })

// Password never returned by default
password: {
  type: String,
  select: false  // ← Only include when explicitly selected
}
```

### 5. **Access Control (Authorization)**

✅ **Implemented:**
```javascript
// Check userId matches
if (meal.userId.toString() !== req.userId) {
  return res.status(403).json({ message: 'Not authorized' });
}
```

**Prevents:**
- User A viewing User B's meal data
- User A deleting User B's meals
- Privilege escalation attacks

### 6. **CORS Protection**

✅ **Implemented:**
```javascript
app.use(cors({
  origin: process.env.CORS_ORIGIN?.split(',') || '*',
  credentials: true
}));
```

### 7. **HTTP Security Headers**

✅ **Implemented:**
```javascript
app.use(helmet());  // Sets multiple security headers
```

**Headers Added:**
- `X-Frame-Options`: Prevents clickjacking
- `X-Content-Type-Options`: Prevents MIME sniffing
- `Strict-Transport-Security`: Forces HTTPS
- `Content-Security-Policy`: Prevents XSS

### 8. **Rate Limiting** (Recommended)

```bash
npm install express-rate-limit
```

```javascript
const rateLimit = require('express-rate-limit');

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});

app.use('/api/', limiter);
```

---

## Production Deployment Checklist

### Pre-Deployment

- [ ] Set strong `JWT_SECRET` (32+ random characters)
- [ ] Update MongoDB connection string to production Atlas
- [ ] Set `NODE_ENV=production`
- [ ] Enable HTTPS certificates (SSL/TLS)
- [ ] Configure `CORS_ORIGIN` for mobile app domain
- [ ] Set up environment variables in production
- [ ] Run database indexes
- [ ] Test with actual mobile app

### Server Configuration

```bash
# Use environment variables
export JWT_SECRET="your-very-long-random-secret-key-32-chars-minimum"
export MONGODB_URI="mongodb+srv://prod-user:prod-pass@prod-cluster.mongodb.net/health_app"
export NODE_ENV="production"
export PORT="443"
```

### Monitoring & Logging

```javascript
// Install monitoring
npm install pm2 winston

// Use PM2 for process management
pm2 start server.js --name health-api --instances max

// Log to file
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.json(),
  transports: [
    new winston.transports.File({ filename: 'error.log', level: 'error' }),
    new winston.transports.File({ filename: 'combined.log' })
  ]
});
```

### Backup Strategy

```bash
# Daily MongoDB backups
mongodump --uri="mongodb+srv://user:pass@cluster.mongodb.net/health_app" \
  --out=/backups/$(date +%Y%m%d)
```

---

## Scalability Considerations

### 1. **Database Optimization**

- **Indexes**: Already set on `userId`, `mealTime`, and `createdAt`
- **Query Optimization**: Use projection to limit fields returned
- **Connection Pooling**: Mongoose handles this automatically

### 2. **Caching Strategy**

```javascript
// Install Redis for caching
npm install redis

// Cache user profile (expires in 1 hour)
const getCachedUser = async (userId) => {
  const cached = await redis.get(`user:${userId}`);
  if (cached) return JSON.parse(cached);
  
  const user = await User.findById(userId);
  await redis.setex(`user:${userId}`, 3600, JSON.stringify(user));
  return user;
};
```

### 3. **Load Balancing**

Deploy multiple instances behind a load balancer:
```
┌────────────────┐
│ Load Balancer  │
└────────┬───────┘
         │
    ┌────┼────┐
    ▼    ▼    ▼
  API1 API2 API3
    │    │    │
    └────┼────┘
         ▼
    MongoDB Atlas
```

### 4. **API Versioning**

```javascript
// Future-proof versioning
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/meals', mealRoutes);
app.use('/api/v1/stats', statsRoutes);

// When releasing v2
app.use('/api/v2/meals', mealsV2Routes);
```

---

## Testing

### Unit Tests (Jest)

```javascript
// tests/auth.test.js
describe('Auth', () => {
  test('should register user', async () => {
    const res = await request(app)
      .post('/api/auth/register')
      .send({
        name: 'Test User',
        email: 'test@example.com',
        password: 'password123'
      });

    expect(res.status).toBe(201);
    expect(res.body.token).toBeDefined();
  });

  test('should reject duplicate email', async () => {
    // ... register first user
    const res = await request(app)
      .post('/api/auth/register')
      .send({
        name: 'Another User',
        email: 'test@example.com',  // same email
        password: 'password123'
      });

    expect(res.status).toBe(400);
  });
});
```

Run tests:
```bash
npm test
```

---

## Environment Variables Summary

```bash
# Database
MONGODB_URI=mongodb+srv://user:pass@cluster.mongodb.net/health_app

# Security
JWT_SECRET=your_super_secret_key_32_chars_minimum
JWT_EXPIRE=7d

# Server
PORT=5000
NODE_ENV=development

# CORS
CORS_ORIGIN=http://localhost:8080,http://192.168.1.100:8080
```

