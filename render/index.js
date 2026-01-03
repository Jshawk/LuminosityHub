const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const yaml = require('js-yaml');
const config = yaml.load(fs.readFileSync(path.join(__dirname, 'render.yaml'), 'utf8'));
const auth = require(path.isAbsolute(config.auth_route) ? config.auth_route : path.join(__dirname, path.basename(config.auth_route)));

const app = express();
const PORT = process.env.PORT || config.port || 3000;

// Set up storage for uploaded scripts
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, path.isAbsolute(config.upload_folder) ? config.upload_folder : path.join(__dirname, path.basename(config.upload_folder)));
  },
  filename: function (req, file, cb) {
    cb(null, file.originalname);
  }
});
const upload = multer({ storage: storage });

// Serve static files
app.use(express.static(path.isAbsolute(config.static_folder) ? config.static_folder : path.join(__dirname, path.basename(config.static_folder))));


// Allow public access to /raw/:name
app.get('/raw/:name', (req, res) => {
  const scriptPath = path.join(
    path.isAbsolute(config.upload_folder) ? config.upload_folder : path.join(__dirname, path.basename(config.upload_folder)),
    req.params.name
  );
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
  fs.readdir(path.isAbsolute(config.upload_folder) ? config.upload_folder : path.join(__dirname, path.basename(config.upload_folder)), (err, files) => {
    if (err) return res.status(500).json({ error: 'Failed to list scripts' });
    res.json(files.filter(f => f.endsWith('.lua')));
  });
});

// Simple homepage
app.get('/', (req, res) => {
  res.sendFile(path.join(
    path.isAbsolute(config.static_folder) ? config.static_folder : path.join(__dirname, path.basename(config.static_folder)),
    'index.html')
  );
});

app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});
