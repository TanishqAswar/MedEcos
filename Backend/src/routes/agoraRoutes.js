const express = require('express');
const router = express.Router();
const agoraController = require('../controllers/agoraController');

router.get('/token', agoraController.generateToken);

module.exports = router;
