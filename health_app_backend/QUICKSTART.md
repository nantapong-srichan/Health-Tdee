# Quick Start Guide

## 1. Prerequisites

- Node.js 16+ 
- npm or yarn
- MongoDB Atlas account (free tier available)
- Git

## 2. Setup MongoDB

1. Go to [MongoDB Atlas](https://www.mongodb.com/cloud/atlas)
2. Create a free account
3. Create a new cluster (shared tier is free)
4. Create a database user with username and strong password
5. Get connection string (looks like: `mongodb+srv://user:password@cluster.mongodb.net/health_app`)

## 3. Install Dependencies

```bash
cd health_app_backend
npm install
```

## 4. Configure Environment

1. Copy `.env.example` to `.env`:

```bash
cp .env.example .env
```

2. Edit `.env` and add your MongoDB connection string:

```
MONGODB_URI=mongodb+srv://your_username:your_password@your_cluster.mongodb.net/health_app
JWT_SECRET=generate_a_random_string_here_make_it_at_least_32_characters_long
JWT_EXPIRE=7d
PORT=5000
NODE_ENV=development
CORS_ORIGIN=http://localhost:3000,http://192.168.1.100:8080
```

## 5. Run Development Server

```bash
npm run dev
```

Expected output:
```
✓ MongoDB connected: cluster.mongodb.net
✓ Server running on http://localhost:5000
✓ Environment: development
```

## 6. Test API

Visit in browser or use curl:

```bash
# Health check
curl http://localhost:5000/api/health

# Register
curl -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"John","email":"john@test.com","password":"pass123"}'
```

## 7. Connect Flutter App

Update `lib/services/api_service.dart`:

```dart
static const String baseUrl = 'http://192.168.1.100:5000/api';
// Replace 192.168.1.100 with your machine's IP address
```

Get your IP:
```bash
# Windows
ipconfig

# Mac/Linux
ifconfig
```

## 8. Deploy to Production

### Option A: Railway

1. Push to GitHub
2. Connect to [Railway](https://railway.app)
3. Add environment variables
4. Deploy automatically

### Option B: Heroku

```bash
npm install -g heroku-cli
heroku login
heroku create your-app-name
git push heroku main
```

### Option C: AWS EC2

1. Launch EC2 instance (Node.js AMI)
2. SSH into instance
3. Clone repo
4. Install dependencies
5. Start with PM2

## 9. Monitoring

### View Logs

```bash
# Development
npm run dev

# Production with PM2
pm2 logs health-api
```

### Monitor Database

MongoDB Atlas provides built-in monitoring dashboard.

## 10. Troubleshooting

### "Cannot connect to MongoDB"
- Check connection string in `.env`
- Ensure IP whitelist includes your IP (or allow all)
- Verify database user credentials

### "CORS error in Flutter"
- Check `CORS_ORIGIN` matches your app's IP
- Ensure backend is running before app

### "Invalid JWT token"
- Clear app cache and re-login
- Check `JWT_SECRET` is same on server

### "Port 5000 already in use"
```bash
# Kill process using port 5000
lsof -ti:5000 | xargs kill -9
# Or change PORT in .env to 5001, 5002, etc
```

## 11. API Documentation

- Full API docs: [API_DOCUMENTATION.md](./API_DOCUMENTATION.md)
- Architecture guide: [ARCHITECTURE.md](./ARCHITECTURE.md)
- Flutter integration: [FLUTTER_INTEGRATION.md](./FLUTTER_INTEGRATION.md)

## 12. Project Structure

```
health_app_backend/
├── config/          # Database connection
├── models/          # MongoDB schemas (User, Meal)
├── controllers/     # Business logic
├── routes/          # API endpoints
├── middleware/      # Authentication, error handling
├── utils/           # Validators, helpers
├── server.js        # Express app entry
├── package.json     # Dependencies
├── .env             # Environment config (create this)
└── API_DOCUMENTATION.md  # API reference
```

## 13. Common Tasks

### Add new endpoint

1. Create controller in `controllers/`
2. Create route in `routes/`
3. Mount route in `server.js`
4. Test with curl/Postman

### Add new model field

1. Update schema in `models/`
2. Run migration (manual for existing data)
3. Update validators in `utils/validators.js`

### Debug database queries

Enable MongoDB query logging:
```javascript
mongoose.set('debug', true);
```

## Support

For issues:
1. Check logs: `npm run dev`
2. Verify `.env` configuration
3. Test endpoint with curl first
4. Check MongoDB Atlas status

