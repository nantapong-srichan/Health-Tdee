# Deployment Guide

Complete guide for deploying to production.

## Option 1: Railway (Recommended for Beginners)

Railway is the easiest option for deploying Node.js + MongoDB.

### Steps

1. **Create GitHub Account & Push Code**

```bash
git init
git add .
git commit -m "Initial commit"
# Push to GitHub
```

2. **Deploy with Railway**

- Go to [railway.app](https://railway.app)
- Sign up with GitHub
- Click "New Project"
- Select "Deploy from GitHub repo"
- Select your repository
- Railway automatically detects Node.js app

3. **Configure Environment Variables**

In Railway dashboard:
- Go to Variables tab
- Add each variable from `.env`:
  - `MONGODB_URI`
  - `JWT_SECRET`
  - `JWT_EXPIRE`
  - `NODE_ENV=production`
  - `CORS_ORIGIN=https://your-app-domain.com,http://your-app-ip:8080`

4. **Get Deployment URL**

Railway provides a public URL: `https://your-app-production.up.railway.app`

5. **Update Flutter App**

```dart
// lib/services/api_service.dart
static const String baseUrl = 'https://your-app-production.up.railway.app/api';
```

### Pros & Cons

✅ **Pros:**
- Very easy setup
- Free tier available
- Auto deploys on GitHub push
- Built-in monitoring

❌ **Cons:**
- Limited free tier resources
- Less control over server config

---

## Option 2: Heroku

Heroku is being phased out but still an option.

### Steps

1. **Install Heroku CLI**

```bash
npm install -g heroku-cli
heroku login
```

2. **Create Heroku App**

```bash
heroku create your-health-api-app
```

3. **Set Environment Variables**

```bash
heroku config:set MONGODB_URI="your-mongodb-uri"
heroku config:set JWT_SECRET="your-secret"
heroku config:set JWT_EXPIRE="7d"
heroku config:set NODE_ENV="production"
```

4. **Deploy**

```bash
git push heroku main
```

5. **View Logs**

```bash
heroku logs --tail
```

### Check Deployment

```bash
heroku open
# Or visit https://your-health-api-app.herokuapp.com/api/health
```

---

## Option 3: AWS EC2 (Most Control)

For full control and scalability.

### Prerequisites

- AWS account
- SSH key pair created

### Steps

1. **Launch EC2 Instance**

- Go to AWS Console → EC2 → Instances → Launch Instance
- Select "Ubuntu Server 22.04 LTS"
- Choose `t3.micro` (free tier eligible)
- Configure security group:
  - Allow SSH (port 22) from your IP
  - Allow HTTP (port 80)
  - Allow HTTPS (port 443)
- Launch and download key pair

2. **Connect to Instance**

```bash
chmod 400 your-key-pair.pem
ssh -i your-key-pair.pem ubuntu@your-ec2-public-ip
```

3. **Install Node.js**

```bash
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
node -v  # Check version
```

4. **Install PM2 (Process Manager)**

```bash
sudo npm install -g pm2
```

5. **Clone Repository**

```bash
cd ~
git clone https://github.com/your-username/health_app_backend.git
cd health_app_backend
npm install
```

6. **Create .env on Server**

```bash
nano .env
```

Paste your environment variables, then `Ctrl+X` to save.

7. **Start with PM2**

```bash
pm2 start server.js --name health-api
pm2 startup
pm2 save
```

8. **Install Nginx (Reverse Proxy)**

```bash
sudo apt-get install -y nginx
sudo nano /etc/nginx/sites-available/default
```

Replace contents with:

```nginx
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name _;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

Restart Nginx:

```bash
sudo systemctl restart nginx
```

9. **Setup SSL with Let's Encrypt (Free)**

```bash
sudo apt-get install -y certbot python3-certbot-nginx
sudo certbot --nginx -d your-domain.com
```

10. **Check Health**

```bash
# SSH into instance and run:
pm2 status
pm2 logs health-api

# From local machine:
curl https://your-domain.com/api/health
```

### Maintenance Commands

```bash
# View logs
pm2 logs health-api

# Restart app
pm2 restart health-api

# Monitor CPU/memory
pm2 monit

# Stop app
pm2 stop health-api

# Update code
cd ~/health_app_backend
git pull
npm install
pm2 restart health-api
```

---

## Option 4: DigitalOcean App Platform (Similar to Railway)

### Steps

1. Go to [DigitalOcean](https://www.digitalocean.com)
2. Create account
3. Go to App Platform
4. Connect GitHub repo
5. Configure environment (same as Railway)
6. Deploy

---

## SSL Certificate (HTTPS)

### Using Let's Encrypt (Free)

```bash
# On your server
sudo apt-get install -y certbot
sudo certbot certonly --standalone -d your-domain.com

# Renewal (auto-renews with cron)
sudo certbot renew --dry-run
```

### Nginx SSL Configuration

```nginx
server {
    listen 443 ssl http2;
    server_name your-domain.com;

    ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name your-domain.com;
    return 301 https://$server_name$request_uri;
}
```

---

## Monitoring & Backup

### Monitor App Health

```bash
# SSH into server
pm2 monit
pm2 logs health-api
```

### Backup MongoDB

```bash
# Automated daily backup
crontab -e
# Add:
0 2 * * * mongodump --uri="your-mongodb-uri" --out=/backups/$(date +\%Y\%m\%d)
```

### Setup Alerts

Using PM2 Plus (free tier):

```bash
pm2 web  # Opens http://localhost:9615
# Or use pm2 monitoring
```

---

## Database Optimization for Production

### Enable Compression

```javascript
// In server.js
const compression = require('compression');
app.use(compression());
```

### Connection Pooling

```javascript
// Mongoose automatically handles this
mongoose.connect(process.env.MONGODB_URI, {
  maxPoolSize: 10,
  minPoolSize: 5,
});
```

### Add Indexes

```javascript
// In models/Meal.js
mealSchema.index({ userId: 1, mealTime: -1 });
mealSchema.index({ userId: 1, createdAt: -1 });

// Run once in MongoDB Atlas
db.meals.createIndex({ userId: 1, mealTime: -1 })
```

---

## Performance Tuning

### Enable Gzip Compression

```bash
npm install compression
```

### Implement Caching

```javascript
npm install redis
const redis = require('redis');
const client = redis.createClient();
```

### Load Testing

```bash
npm install -g artillery
artillery quick --count 100 --num 1000 https://your-api.com/api/health
```

---

## Troubleshooting Production

### App crashes after deploy

```bash
pm2 logs health-api --lines 100
```

### High memory usage

```bash
pm2 monit
# Check for memory leaks
```

### Database connection errors

```bash
# SSH into server
echo "Testing MongoDB connection..."
mongosh "your-mongodb-uri"
```

### CORS errors on mobile

Update `CORS_ORIGIN` in environment:

```
CORS_ORIGIN=https://your-domain.com,http://192.168.1.100:8080
```

---

## Cost Estimates

| Service | Free Tier | Paid |
|---------|-----------|------|
| Railway | 500 hours/month | $5+/month |
| Heroku | None (was $7/month) | $7-25+/month |
| AWS EC2 | 750 hours/year | ~$10-20/month |
| DigitalOcean | - | $4-6/month |
| MongoDB Atlas | 512MB storage | $57+/month |

**Recommended for startups:** Railway + MongoDB Atlas Free = ~$0 first month

---

## Continuous Integration/Deployment

### GitHub Actions Example

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to Railway

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
      - run: npm install
      - run: npm test  # If you have tests
      - name: Deploy to Railway
        env:
          RAILWAY_TOKEN: ${{ secrets.RAILWAY_TOKEN }}
        run: npx railway up
```

---

## Summary

**Development:** `npm run dev` on localhost

**Production:**
1. Push to GitHub
2. Deploy with Railway/Heroku/AWS
3. Configure environment variables
4. Monitor with PM2/Railway dashboard
5. Backup MongoDB regularly

