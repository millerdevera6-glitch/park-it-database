<?php
/**
 * File: park-it/config/database.php
 * Purpose: PostgreSQL 18.6 PDO Database Connection
 */

// Set default timezone to Philippine Standard Time
date_default_timezone_set('Asia/Manila');

// Database connection parameters
define('DB_HOST', 'localhost');
define('DB_PORT', '5432');
define('DB_NAME', 'grp_parkitdb');
define('DB_USER', 'postgres');
define('DB_PASS', '12345678'); // <-- Replace with your PostgreSQL password

// Base URL path of the project in XAMPP htdocs (adjust if your folder name differs)
define('BASE_URL', '/park-it');

try {
    $dsn = "pgsql:host=" . DB_HOST . ";port=" . DB_PORT . ";dbname=" . DB_NAME;
    $pdo = new PDO($dsn, DB_USER, DB_PASS, [
        PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES   => false,
    ]);
} catch (PDOException $e) {
    die("<strong>Database Connection Error:</strong> Could not connect to PostgreSQL database <code>" . htmlspecialchars(DB_NAME) . "</code>. Please check your credentials in <code>config/database.php</code>.<br><br>Details: " . htmlspecialchars($e->getMessage()));
}
?>