# Health App Backend

Production-ready Node.js/Express backend for health and nutrition tracking.

## Features

- User authentication with JWT
- Secure password hashing with bcrypt
- MongoDB integration with Mongoose
- Per-user meal history
- Calorie statistics and analytics
- RESTful API with validation
- Error handling and logging

## Project Structure

```
health_app_backend/
├── config/
│   └── database.js          # MongoDB connection
├── models/
│   ├── User.js              # User schema
│   └── Meal.js              # Meal history schema
├── controllers/
│   ├── authController.js    # Authentication logic
│   ├── mealController.js    # Meal CRUD operations
│   └── statsController.js   # Statistics calculations
├── routes/
│   ├── auth.js              # Auth endpoints
│   ├── meals.js             # Meal endpoints
│   └── stats.js             # Statistics endpoints
├── middleware/
│   ├── auth.js              # JWT verification
│   └── errorHandler.js      # Error handling
├── utils/
│   └── validators.js        # Input validation
├── .env                      # Environment variables
├── server.js                # Express app entry point
└── package.json             # Dependencies
```

## Installation

```bash
npm install
```

## Environment Setup

Create `.env` file:

```
PORT=5000
MONGODB_URI=mongodb+srv://user:password@cluster.mongodb.net/health_app
JWT_SECRET=your_super_secret_jwt_key_change_this_in_production
JWT_EXPIRE=7d
NODE_ENV=development
```

## Running

```bash
# Development with auto-reload
npm run dev

# Production
npm start
```

## API Endpoints

See [API_DOCUMENTATION.md](./API_DOCUMENTATION.md) for complete endpoint list.
