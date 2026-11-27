
import 'dotenv/config';

import express from 'express';
import cors from 'cors';
import helmet from 'helmet';

import { getPool } from './config/database.js';

const app = express();

app.use(helmet());
app.use(cors());
app.use(express.json());

// API kiểm tra Backend
app.get('/api/health', (req, res) => {
  res.json({
    status: 'ok',
    service: 'AssetOne API',
    message: 'Backend is running',
  });
});

// API kiểm tra kết nối SQL Server
app.get('/api/test-db', async (req, res) => {
  try {
    const pool = await getPool();

    const result = await pool.request().query(`
      SELECT TOP (5)
        currency_code,
        currency_name
      FROM assetone.currency
      ORDER BY currency_code;
    `);

    res.json({
      status: 'success',
      database: process.env.DB_NAME,
      total: result.recordset.length,
      data: result.recordset,
    });

  } catch (error) {
    console.error('Database error:', error.message);

    res.status(500).json({
      status: 'error',
      message: 'Cannot connect to AssetOne database',
    });
  }
});

const PORT = Number(process.env.PORT || 3000);

app.listen(PORT, '127.0.0.1', () => {
  console.log(`AssetOne API running at http://127.0.0.1:${PORT}`);
});
