if (process.env.NODE_ENV !== "production") {
  require("dotenv").config();
}

const express = require('express');
const mongoose = require('mongoose');
const os = require('os');
const productRoutes = require('./routes/productRoutes');
const dataSource = require('./services/dataSource');
const uiRoutes = require('./routes/uiRoutes');
const path = require('path');
const fs = require('fs'); 

const app = express();
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// view engine and static
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'ejs');
app.use(express.static(path.join(__dirname, 'public')));

app.use('/', uiRoutes);
app.use('/products', productRoutes);

const PORT = process.env.PORT || 3000;

// ✅ retry connect Mongo
async function connectWithRetry(mongoUri) {
  let retries = 5;

  while (retries) {
    try {
      console.log("Connecting to:", mongoUri);

      await mongoose.connect(mongoUri, {
        serverSelectionTimeoutMS: 5000,
      });

      console.log("✅ Connected to MongoDB");
      return true;
    } catch (err) {
      console.log(`❌ MongoDB not ready, retrying... (${retries} left)`);
      retries -= 1;
      await new Promise(res => setTimeout(res, 5000));
    }
  }

  console.log("🚨 Fallback to in-memory");
  return false;
}

async function start() {
  const uploadsDir = path.join(__dirname, 'public', 'uploads');
  if (!fs.existsSync(uploadsDir)) {
    fs.mkdirSync(uploadsDir, { recursive: true });
  }

  const mongoUri = process.env.MONGO_URI || 'mongodb://localhost:27017/products_db';

  const usingMongo = await connectWithRetry(mongoUri);

  await dataSource.init(usingMongo);

  app.listen(PORT, () => {
    console.log(`Server listening on http://localhost:${PORT} — hostname: ${os.hostname()}`);
    console.log(`Data source: ${usingMongo ? 'mongodb' : 'in-memory'}`);
  });
}

start();

module.exports = app;