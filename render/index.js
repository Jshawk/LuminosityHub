const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const auth = require('./routes/auth');

const app = express();
const PORT = process.env.PORT || 3000;

// Set up storage for uploaded scripts
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, path.join(__dirname, 'scripts'));
  },
  filename: function (req, file, cb) {
    cb(null, file.originalname);
  }
});
const upload = multer({ storage: storage });

// Serve static files
app.use(express.static(path.join(__dirname, 'public')));


// Allow public access to /raw/:name
app.get('/raw/:name', (req, res) => {
  const scriptPath = path.join(__dirname, 'scripts', req.params.name);
  if (!fs.existsSync(scriptPath)) return res.status(404).send('Script not found');
  res.type('text/plain');
  fs.createReadStream(scriptPath).pipe(res);
});

// Require authentication for all other endpoints
app.use(auth);

// Upload endpoint
app.post('/upload', upload.single('script'), (req, res) => {
  res.redirect('/');
});

// List scripts endpoint
app.get('/scripts', (req, res) => {
  fs.readdir(path.join(__dirname, 'scripts'), (err, files) => {
    if (err) return res.status(500).json({ error: 'Failed to list scripts' });
    res.json(files.filter(f => f.endsWith('.lua')));
  });
});

// Simple homepage
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});
