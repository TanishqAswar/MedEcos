require('dotenv').config();
const express = require('express');
const cors = require('cors');
const connectDB = require('./config/database');

const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Connect to Database
connectDB();

// Routes
app.use('/api/auth', require('./routes/auth'));
app.use('/api/doctors', require('./routes/doctors'));
app.use('/api/patients', require('./routes/patients'));
app.use('/api/pharmacists', require('./routes/pharmacists'));
app.use('/api/lab-testers', require('./routes/labTesters'));
app.use('/api/appointments', require('./routes/appointments'));
app.use('/api/prescriptions', require('./routes/prescriptions'));
app.use('/api/lab-tests', require('./routes/labTests'));
app.use('/api/pharmacy-orders', require('./routes/pharmacyOrders'));

// Health check
app.get('/', (req, res) => {
  res.json({
    message: 'MedEcos API',
    version: '1.0.0',
    endpoints: {
      auth: '/api/auth',
      doctors: '/api/doctors',
      patients: '/api/patients',
      pharmacists: '/api/pharmacists',
      labTesters: '/api/lab-testers',
      appointments: '/api/appointments',
      prescriptions: '/api/prescriptions',
      labTests: '/api/lab-tests',
      pharmacyOrders: '/api/pharmacy-orders'
    }
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Something went wrong!' });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});

module.exports = app;
