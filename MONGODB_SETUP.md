# 🚀 Quick MongoDB Setup Guide

## ⚠️ Current Status
- ✅ Flutter app compiling successfully
- ✅ API services created
- ⏳ Backend needs MongoDB connection

## Option 1: MongoDB Atlas (Cloud - Recommended for Testing)

### Step 1: Create Free Account
1. Go to https://www.mongodb.com/cloud/atlas
2. Click "Try Free"
3. Create account (use Google, GitHub, or email)

### Step 2: Create Cluster
1. After login, click "Create Deployment"
2. Choose "FREE" tier
3. Select your region (closest to you)
4. Click "Create Deployment"
5. Wait 2-5 minutes for cluster to start

### Step 3: Create Database User
1. In left sidebar, click "Database Access"
2. Click "Add New Database User"
3. Username: `admin`
4. Password: `Admin12345` (or any strong password)
5. Click "Add User"

### Step 4: Get Connection String
1. Click "Drivers" on top menu
2. Select Node.js driver
3. Copy the connection string
4. It will look like:
```
mongodb+srv://admin:Admin12345@cluster0.xxxxx.mongodb.net/?retryWrites=true&w=majority
```

### Step 5: Update .env File
Edit: `g:\senior_project\health_app-backup\health_app_backend\.env`

Replace:
```env
MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/health_app
```

With your connection string:
```env
MONGODB_URI=mongodb+srv://admin:Admin12345@cluster0.xxxxx.mongodb.net/health_app?retryWrites=true&w=majority
```

### Step 6: Allow Network Access
1. In MongoDB Atlas left sidebar, click "Network Access"
2. Click "Add IP Address"
3. Click "Allow access from anywhere" or enter `0.0.0.0/0`
4. Click "Add Entry"

---

## Option 2: Local MongoDB (If Installed)

If you have MongoDB installed locally:

```env
MONGODB_URI=mongodb://localhost:27017/health_app
```

Then start MongoDB:
```bash
mongod
```

---

## Option 3: Test with Mock Data (No Database)

If you want to test right now without MongoDB, I can:
1. Modify the backend to use in-memory storage
2. Data will reset when server restarts
3. Good for testing the Flutter-Backend connection

---

## How to Verify It Works

After setting up MongoDB:

```bash
# Terminal 1: Start backend
cd g:\senior_project\health_app-backup\health_app_backend
npm run dev

# Expected output:
# ✓ Connected to MongoDB
# ✓ Backend running on port 5000
```

Then in another terminal:

```bash
# Terminal 2: Test connection
curl http://localhost:5000/api/health
```

---

## What Do You Want To Do?

1. **Use MongoDB Atlas** (recommended)
   → Follow steps above, update .env, restart backend

2. **Use Local MongoDB**
   → Update .env, start mongod, restart backend

3. **Test Without Database Now**
   → I'll modify backend for in-memory testing

**Which option?** Tell me and I'll help set it up! 🚀
