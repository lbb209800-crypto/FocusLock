require('dotenv').config();
const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');

const app = express();

// Middleware
app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// Routes
app.get('/api/health', (req, res) => {
  res.json({ status: 'FocusLock Backend is running ✅' });
});

// AI Lock Screen Generation
app.post('/api/ai/generate-lock-screen', async (req, res) => {
  try {
    const { mood } = req.body;

    if (!mood) {
      return res.status(400).json({ error: 'Mood is required' });
    }

    // TODO: Integrate with ChatGPT/Gemini API
    // For now, return mock data
    const mockResponse = {
      id: 'lock_' + Date.now(),
      title: `${mood} Focus Mode`,
      description: `Your AI-generated lock screen based on your mood: "${mood}". Stay focused and productive!`,
      bioCode: generateBioCode(),
      mood: mood,
      createdAt: new Date().toISOString(),
      isActive: true,
    };

    res.json(mockResponse);
  } catch (error) {
    console.error('Error generating lock screen:', error);
    res.status(500).json({ error: 'Failed to generate lock screen' });
  }
});

// Focus Mode Status
app.post('/api/focus/start', (req, res) => {
  const { userId, duration } = req.body;

  if (!userId || !duration) {
    return res.status(400).json({ error: 'userId and duration are required' });
  }

  res.json({
    success: true,
    message: `Focus mode started for ${duration} minutes`,
    userId: userId,
    startTime: new Date().toISOString(),
    endTime: new Date(Date.now() + duration * 60000).toISOString(),
  });
});

// Health Check
app.get('/', (req, res) => {
  res.json({
    name: 'FocusLock API',
    version: '3.0.0',
    status: 'running',
    endpoints: [
      'GET /api/health',
      'POST /api/ai/generate-lock-screen',
      'POST /api/focus/start',
    ],
  });
});

// Helper function to generate biometric code
function generateBioCode() {
  const codes = [
    '🧠 Focus your mind',
    '💪 Stay strong',
    '🎯 On target',
    '⚡ Full power',
    '🔥 Unstoppable',
  ];
  return codes[Math.floor(Math.random() * codes.length)];
}

// Error handling
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Internal Server Error' });
});

// Start server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 FocusLock Backend running on port ${PORT}`);
  console.log(`📍 http://localhost:${PORT}`);
});

module.exports = app;
