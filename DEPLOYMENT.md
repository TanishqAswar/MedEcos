# MedEcos Deployment Guide

This guide covers different deployment scenarios for the MedEcos Medical Ecosystem.

## Prerequisites

- Node.js (v14 or higher)
- MongoDB (v4.4 or higher)
- npm or yarn package manager

## Local Development

### 1. Install Dependencies

```bash
npm install
```

### 2. Configure Environment

Copy the example environment file and configure it:

```bash
cp .env.example .env
```

Edit `.env` with your settings:

```env
MONGODB_URI=mongodb://localhost:27017/medecos
PORT=3000
JWT_SECRET=your_secure_random_string_here
NODE_ENV=development
```

### 3. Start MongoDB

Make sure MongoDB is running on your system:

```bash
# macOS (with Homebrew)
brew services start mongodb-community

# Linux (systemd)
sudo systemctl start mongod

# Windows
net start MongoDB

# Or using Docker
docker run -d -p 27017:27017 --name mongodb mongo:latest
```

### 4. Run the Application

```bash
# Development mode (with auto-restart)
npm run dev

# Production mode
npm start
```

The API will be available at `http://localhost:3000`

### 5. Test the API

Run the demo script to see the full workflow:

```bash
npm run demo
```

Or run the test suite:

```bash
npm test
```

## Docker Deployment

### Using Docker Compose

Create a `docker-compose.yml` file:

```yaml
version: '3.8'

services:
  mongodb:
    image: mongo:latest
    container_name: medecos-mongodb
    ports:
      - "27017:27017"
    volumes:
      - mongodb_data:/data/db
    environment:
      - MONGO_INITDB_DATABASE=medecos

  api:
    build: .
    container_name: medecos-api
    ports:
      - "3000:3000"
    depends_on:
      - mongodb
    environment:
      - MONGODB_URI=mongodb://mongodb:27017/medecos
      - PORT=3000
      - JWT_SECRET=your_secure_jwt_secret
      - NODE_ENV=production
    restart: unless-stopped

volumes:
  mongodb_data:
```

Create a `Dockerfile`:

```dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./

RUN npm ci --only=production

COPY . .

EXPOSE 3000

CMD ["node", "server.js"]
```

Deploy:

```bash
docker-compose up -d
```

## Cloud Deployment

### Heroku

1. Install Heroku CLI and login:
```bash
heroku login
```

2. Create a new Heroku app:
```bash
heroku create medecos-app
```

3. Add MongoDB Atlas or Heroku MongoDB add-on:
```bash
heroku addons:create mongolab:sandbox
```

4. Set environment variables:
```bash
heroku config:set JWT_SECRET=your_secure_jwt_secret
heroku config:set NODE_ENV=production
```

5. Deploy:
```bash
git push heroku main
```

### AWS (Elastic Beanstalk)

1. Install EB CLI:
```bash
pip install awsebcli
```

2. Initialize EB application:
```bash
eb init -p node.js medecos-app
```

3. Create environment:
```bash
eb create medecos-env
```

4. Set environment variables:
```bash
eb setenv MONGODB_URI=your_mongodb_uri JWT_SECRET=your_jwt_secret
```

5. Deploy:
```bash
eb deploy
```

### Google Cloud Platform (App Engine)

Create `app.yaml`:

```yaml
runtime: nodejs18

env_variables:
  MONGODB_URI: "your_mongodb_uri"
  JWT_SECRET: "your_jwt_secret"
  NODE_ENV: "production"

automatic_scaling:
  min_instances: 1
  max_instances: 10
```

Deploy:

```bash
gcloud app deploy
```

### DigitalOcean

1. Create a droplet with Node.js
2. SSH into the droplet
3. Clone the repository
4. Install dependencies
5. Set up environment variables
6. Use PM2 for process management:

```bash
npm install -g pm2
pm2 start server.js --name medecos
pm2 save
pm2 startup
```

## Database Setup

### MongoDB Atlas (Cloud)

1. Create account at [mongodb.com/cloud/atlas](https://www.mongodb.com/cloud/atlas)
2. Create a cluster
3. Get connection string
4. Update `MONGODB_URI` in environment variables

Connection string format:
```
mongodb+srv://username:password@cluster.mongodb.net/medecos?retryWrites=true&w=majority
```

### Self-Hosted MongoDB

Ensure MongoDB is secured:

```bash
# Enable authentication
mongod --auth

# Create admin user
mongo
use admin
db.createUser({
  user: "admin",
  pwd: "securepassword",
  roles: ["userAdminAnyDatabase"]
})
```

## Security Considerations

### Production Checklist

- [ ] Use strong JWT secret (minimum 32 characters)
- [ ] Enable HTTPS (use reverse proxy like Nginx)
- [ ] Set secure CORS policy
- [ ] Enable rate limiting
- [ ] Use environment variables for sensitive data
- [ ] Enable MongoDB authentication
- [ ] Regular security updates
- [ ] Implement request validation
- [ ] Enable logging and monitoring
- [ ] Use helmet.js for security headers

### SSL/TLS Setup with Nginx

```nginx
server {
    listen 80;
    server_name your-domain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl;
    server_name your-domain.com;

    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

## Monitoring and Logging

### PM2 Monitoring

```bash
# View logs
pm2 logs medecos

# Monitor resources
pm2 monit

# View status
pm2 status
```

### Application Logging

Consider adding logging libraries:

```bash
npm install winston morgan
```

## Backup Strategy

### Database Backup

```bash
# Backup
mongodump --uri="mongodb://localhost:27017/medecos" --out=/backup/$(date +%Y%m%d)

# Restore
mongorestore --uri="mongodb://localhost:27017/medecos" /backup/20240201
```

### Automated Backups

Create a cron job for regular backups:

```bash
# Edit crontab
crontab -e

# Add backup job (daily at 2 AM)
0 2 * * * /path/to/backup-script.sh
```

## Performance Optimization

### MongoDB Indexes

Add indexes for frequently queried fields:

```javascript
// In your models
schema.index({ email: 1 });
schema.index({ userType: 1 });
schema.index({ appointmentDate: 1 });
```

### Caching

Consider adding Redis for caching:

```bash
npm install redis
```

### Load Balancing

Use Nginx or HAProxy for load balancing multiple instances.

## Troubleshooting

### Common Issues

**Cannot connect to MongoDB:**
- Check MongoDB is running
- Verify connection string
- Check firewall settings

**Authentication errors:**
- Verify JWT_SECRET is set
- Check token expiration
- Ensure user exists in database

**Port already in use:**
```bash
# Find process using port 3000
lsof -i :3000

# Kill the process
kill -9 <PID>
```

## Scaling

### Horizontal Scaling

1. Use load balancer
2. Deploy multiple instances
3. Use shared session store (Redis)
4. Use MongoDB replica set

### Vertical Scaling

1. Increase server resources (CPU, RAM)
2. Optimize database queries
3. Implement caching
4. Use connection pooling

## Support

For issues or questions:
- Check documentation in the repository
- Search existing issues on GitHub
- Create a new issue with detailed information

---

**Important**: Always test deployments in a staging environment before production!
