# Quick Start Guide

Get the MedEcos Medical Ecosystem up and running in minutes!

## Prerequisites

Make sure you have these installed:
- Node.js (v14 or higher) - [Download](https://nodejs.org/)
- MongoDB (v4.4 or higher) - [Download](https://www.mongodb.com/try/download/community)
- npm (comes with Node.js)

## Installation Steps

### 1. Clone the Repository

```bash
git clone https://github.com/TanishqAswar/MedEcos.git
cd MedEcos
```

### 2. Install Dependencies

```bash
npm install
```

This will install:
- express (web framework)
- mongoose (MongoDB ODM)
- bcryptjs (password hashing)
- jsonwebtoken (JWT authentication)
- dotenv (environment variables)
- cors (cross-origin requests)
- And development dependencies

### 3. Set Up Environment Variables

Create a `.env` file:

```bash
cp .env.example .env
```

Edit `.env` with your settings:

```env
MONGODB_URI=mongodb://localhost:27017/medecos
PORT=3000
JWT_SECRET=your_very_secure_random_string_here
NODE_ENV=development
```

**Important**: Generate a secure JWT_SECRET:
```bash
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

### 4. Start MongoDB

#### macOS (with Homebrew):
```bash
brew services start mongodb-community
```

#### Linux (systemd):
```bash
sudo systemctl start mongod
```

#### Windows:
```bash
net start MongoDB
```

#### Docker:
```bash
docker run -d -p 27017:27017 --name mongodb mongo:latest
```

### 5. Start the Application

#### Development Mode (with auto-restart):
```bash
npm run dev
```

#### Production Mode:
```bash
npm start
```

You should see:
```
Server is running on port 3000
MongoDB Connected: localhost
```

## Verify Installation

### Test the API

Open your browser or use curl:

```bash
curl http://localhost:3000
```

You should see:
```json
{
  "message": "MedEcos API",
  "version": "1.0.0",
  "endpoints": {
    "auth": "/api/auth",
    "doctors": "/api/doctors",
    ...
  }
}
```

## Run the Demo

Experience the full ecosystem workflow:

```bash
npm run demo
```

This will:
1. Register 4 users (Doctor, Patient, Pharmacist, Lab Tester)
2. Book an appointment
3. Create a prescription
4. Place a pharmacy order
5. Order and complete a lab test

## Quick API Test

### Register a User

```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com",
    "password": "test123",
    "userType": "patient",
    "phone": "1234567890",
    "address": "123 Test St",
    "additionalInfo": {
      "dateOfBirth": "1990-01-01",
      "gender": "male",
      "bloodGroup": "O+"
    }
  }'
```

### Login

```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "test123"
  }'
```

Save the returned token for authenticated requests!

## API Testing Tools

### Using Postman

1. Import the API endpoints
2. Set up environment variables:
   - `baseUrl`: `http://localhost:3000`
   - `token`: Your JWT token after login
3. Add Authorization header: `Bearer {{token}}`

### Using cURL

```bash
# Set your token
TOKEN="your_jwt_token_here"

# Make authenticated request
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:3000/api/doctors
```

## Running Tests

```bash
npm test
```

## Common Issues

### Port Already in Use

If port 3000 is already in use:

```bash
# Find the process
lsof -i :3000

# Kill it
kill -9 <PID>

# Or change the port in .env
PORT=3001
```

### MongoDB Connection Error

```
Error: connect ECONNREFUSED 127.0.0.1:27017
```

**Solution**: Make sure MongoDB is running
```bash
# Check status
mongod --version

# Start MongoDB
brew services start mongodb-community  # macOS
sudo systemctl start mongod            # Linux
net start MongoDB                      # Windows
```

### JWT Secret Warning

If you see JWT errors, make sure `JWT_SECRET` is set in `.env`

### Dependencies Installation Failed

```bash
# Clear npm cache
npm cache clean --force

# Delete node_modules and package-lock.json
rm -rf node_modules package-lock.json

# Reinstall
npm install
```

## Next Steps

### For Development

1. Read [CONTRIBUTING.md](CONTRIBUTING.md) for coding guidelines
2. Check [ARCHITECTURE.md](ARCHITECTURE.md) to understand the system design
3. Review [API_DOCS.md](API_DOCS.md) for detailed endpoint documentation

### For Production Deployment

1. Read [DEPLOYMENT.md](DEPLOYMENT.md) for deployment guides
2. Review [SECURITY.md](SECURITY.md) for security recommendations
3. Implement rate limiting
4. Set up HTTPS
5. Configure monitoring and logging

## Project Structure

```
MedEcos/
├── config/           # Configuration files
├── models/           # Database models
├── routes/           # API routes
├── middleware/       # Express middleware
├── examples/         # Example scripts
├── tests/            # Test files
├── server.js         # Main server file
├── package.json      # Dependencies
└── .env              # Environment variables (create this)
```

## Useful Commands

```bash
# Development
npm run dev          # Start with auto-restart
npm test             # Run tests
npm run demo         # Run demo workflow

# Production
npm start            # Start server

# Database
mongosh              # MongoDB shell
```

## API Endpoints Quick Reference

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | `/api/auth/register` | Register user | No |
| POST | `/api/auth/login` | Login user | No |
| GET | `/api/doctors` | List doctors | Yes |
| GET | `/api/patients` | List patients | Yes (Doctor) |
| GET | `/api/pharmacists` | List pharmacists | Yes |
| GET | `/api/lab-testers` | List lab testers | Yes |
| POST | `/api/appointments` | Create appointment | Yes (Patient) |
| GET | `/api/appointments` | List appointments | Yes |
| POST | `/api/prescriptions` | Create prescription | Yes (Doctor) |
| GET | `/api/prescriptions` | List prescriptions | Yes |
| POST | `/api/lab-tests` | Create lab test | Yes (Doctor/Patient) |
| GET | `/api/lab-tests` | List lab tests | Yes |
| POST | `/api/pharmacy-orders` | Create order | Yes (Patient) |
| GET | `/api/pharmacy-orders` | List orders | Yes |

## Support

- **Documentation**: Check the docs folder
- **Issues**: [GitHub Issues](https://github.com/TanishqAswar/MedEcos/issues)
- **API Docs**: [API_DOCS.md](API_DOCS.md)

## License

MIT License - See LICENSE file for details

---

**Happy Coding! 🏥💊🔬**
