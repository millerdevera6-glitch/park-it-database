
require('dotenv').config();

const express = require('express');
const { Pool } = require('pg');
const cors = require('cors');
const path = require('path');

const app = express();

// Middleware
app.use(express.json());
app.use(cors());
app.use(express.static(__dirname));

// PostgreSQL connection
const pool = new Pool({
    user: process.env.DB_USERNAME || process.env.DB_USER,
    host: process.env.DB_HOST,
    database: process.env.DB_DATABASE || process.env.DB_NAME,
    password: process.env.DB_PASSWORD,
    port: Number(process.env.DB_PORT) || 5432
});

// Homepage
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'index.html'));
});

// DATABASE CONNECTION TEST
app.get('/api/test', async (req, res) => {
    try {
        const result = await pool.query('SELECT NOW()');

        res.json({
            status: 'success',
            message: 'Database connected successfully!',
            timestamp: result.rows[0].now
        });

    } catch (error) {
        console.error('Database connection error:', error.message);

        res.status(500).json({
            status: 'error',
            message: 'Database connection failed.'
        });
    }
});

// READ: Get all parking zones
app.get('/api/zones', async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT zone_id, zone_name, max_capacity, current_active_count
             FROM parking_zone
             ORDER BY zone_id ASC`
        );

        res.json(result.rows);

    } catch (error) {
        console.error('Read error:', error.message);

        res.status(500).json({
            message: 'Failed to retrieve parking zones.'
        });
    }
});

// CREATE: Add a parking zone
app.post('/api/zones', async (req, res) => {
    try {
        const { zone_name, max_capacity } = req.body;
        const capacity = Number(max_capacity);

        if (
            typeof zone_name !== 'string' ||
            !zone_name.trim() ||
            !Number.isInteger(capacity) ||
            capacity <= 0
        ) {
            return res.status(400).json({
                message: 'Please enter a valid zone name and capacity.'
            });
        }

        const result = await pool.query(
            `INSERT INTO parking_zone
             (zone_name, max_capacity, current_active_count)
             VALUES ($1, $2, 0)
             RETURNING *`,
            [zone_name.trim(), capacity]
        );

        res.status(201).json({
            status: 'success',
            message: 'Parking zone created successfully.',
            data: result.rows[0]
        });

    } catch (error) {
        console.error('Create error:', error.message);

        res.status(500).json({
            message: 'Failed to create parking zone.'
        });
    }
});

// UPDATE: Modify a parking zone
app.put('/api/zones/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const { zone_name, max_capacity } = req.body;
        const capacity = Number(max_capacity);

        if (
            typeof zone_name !== 'string' ||
            !zone_name.trim() ||
            !Number.isInteger(capacity) ||
            capacity <= 0
        ) {
            return res.status(400).json({
                message: 'Please enter a valid zone name and capacity.'
            });
        }

        const result = await pool.query(
            `UPDATE parking_zone
             SET zone_name = $1,
                 max_capacity = $2
             WHERE zone_id = $3
             AND current_active_count <= $2
             RETURNING *`,
            [zone_name.trim(), capacity, id]
        );

        if (result.rowCount === 0) {
            const existing = await pool.query(
                'SELECT zone_id, current_active_count FROM parking_zone WHERE zone_id = $1',
                [id]
            );

            if (existing.rowCount === 0) {
                return res.status(404).json({
                    message: 'Parking zone not found.'
                });
            }

            return res.status(400).json({
                message: 'Capacity cannot be lower than the current occupied count.'
            });
        }

        res.json({
            status: 'success',
            message: 'Parking zone updated successfully.',
            data: result.rows[0]
        });

    } catch (error) {
        console.error('Update error:', error.message);

        res.status(500).json({
            message: 'Failed to update parking zone.'
        });
    }
});

// PARK VEHICLE: Increase occupied count
app.put('/api/zones/:id/park', async (req, res) => {
    try {
        const { id } = req.params;

        const result = await pool.query(
            `UPDATE parking_zone
             SET current_active_count = current_active_count + 1
             WHERE zone_id = $1
             AND current_active_count < max_capacity
             RETURNING *`,
            [id]
        );

        if (result.rowCount === 0) {
            const existing = await pool.query(
                'SELECT zone_id FROM parking_zone WHERE zone_id = $1',
                [id]
            );

            if (existing.rowCount === 0) {
                return res.status(404).json({
                    message: 'Parking zone not found.'
                });
            }

            return res.status(400).json({
                message: 'Parking zone is already full.'
            });
        }

        res.json({
            status: 'success',
            message: 'Vehicle parked successfully.',
            data: result.rows[0]
        });

    } catch (error) {
        console.error('Park error:', error.message);

        res.status(500).json({
            message: 'Failed to park vehicle.'
        });
    }
});

// DELETE: Remove a parking zone
app.delete('/api/zones/:id', async (req, res) => {
    try {
        const { id } = req.params;

        const result = await pool.query(
            'DELETE FROM parking_zone WHERE zone_id = $1 RETURNING zone_id',
            [id]
        );

        if (result.rowCount === 0) {
            return res.status(404).json({
                message: 'Parking zone not found.'
            });
        }

        res.json({
            status: 'success',
            message: 'Parking zone deleted successfully.'
        });

    } catch (error) {
        console.error('Delete error:', error.message);

        res.status(500).json({
            message: 'Failed to delete parking zone. Check whether related records prevent deletion.'
        });
    }
});

// Start server AFTER defining all routes
const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
    console.log(`Park It API Server running on port ${PORT}`);
});
