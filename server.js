require('dotenv').config();
const express = require('express');
const { Pool } = require('pg');
const cors = require('cors');
const path = require('path'); // <--- 1. ADD THIS IMPORT

const app = express();
app.use(express.json());
app.use(cors());
app.use(express.static(__dirname)); // <--- 2. SERVE STATIC FILES (index.html, CSS, JS)

const pool = new Pool({
    user: process.env.DB_USERNAME || process.env.DB_USER,
    host: process.env.DB_HOST,
    database: process.env.DB_DATABASE || process.env.DB_NAME,
    password: String(process.env.DB_PASSWORD || ''),
    port: process.env.DB_PORT,
});

// Root route to serve your index.html homepage
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'index.html')); // <--- 3. ADD THIS ROUTE
});

app.get('/api/zones', async (req, res) => {
    try {
        const result = await pool.query('SELECT zone_id, zone_name, max_capacity, current_active_count FROM parking_zone');
        res.json(result.rows);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// Test route to verify server and PostgreSQL database connection
app.get('/api/test', async (req, res) => {
    try {
        const result = await pool.query('SELECT NOW()');
        res.json({
            status: 'success',
            message: 'Database connected successfully!',
            timestamp: result.rows[0].now
        });
    } catch (err) {
        console.error('Database connection error:', err);
        res.status(500).json({
            status: 'error',
            message: 'Database query failed',
            error: err.message
        });
    }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Park It API Server running on port ${PORT}`);
});

app.post('/api/zones', async (req, res) => {
    try {
        const { zone_name, max_capacity } = req.body;
        await pool.query(
            'INSERT INTO parking_zone (zone_name, max_capacity, current_active_count) VALUES ($1, $2, 0)',
            [zone_name, max_capacity]
        );
        res.json({ status: 'success', message: 'Zone created' });
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});


app.put('/api/zones/:id/park', async (req, res) => {
    try {
        const { id } = req.params;
        await pool.query(
            'UPDATE parking_zone SET current_active_count = current_active_count + 1 WHERE zone_id = $1',
            [id]
        );
        res.json({ status: 'success', message: 'Vehicle parked' });
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

app.delete('/api/zones/:id', async (req, res) => {
    try {
        const { id } = req.params;
        await pool.query('DELETE FROM parking_zone WHERE zone_id = $1', [id]);
        res.json({ status: 'success', message: 'Zone deleted' });
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});