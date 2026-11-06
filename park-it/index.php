<?php
/**
 * File: park-it/index.php
 * Purpose: Root entry point that redirects to Dashboard or Login
 */

require_once __DIR__ . '/config/database.php';
require_once __DIR__ . '/includes/functions.php';

if (isLoggedIn()) {
    header('Location: ' . BASE_URL . '/dashboard.php');
    exit;
} else {
    header('Location: ' . BASE_URL . '/auth/login.php');
    exit;
}
?>