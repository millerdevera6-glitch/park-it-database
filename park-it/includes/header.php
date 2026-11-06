<?php
/**
 * File: park-it/includes/header.php
 * Purpose: Common HTML header and top navigation bar for authenticated pages
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/functions.php';

requireLogin();

$flash = getFlash();
$currentUri = $_SERVER['REQUEST_URI'] ?? '';
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?= isset($pageTitle) ? htmlspecialchars($pageTitle) . ' - ' : '' ?>Park It DBMS</title>
    <link rel="stylesheet" href="<?= BASE_URL ?>/assets/css/style.css">
</head>
<body>

<header class="navbar">
    <div class="navbar-brand">
        <a href="<?= BASE_URL ?>/dashboard.php">PARK IT <span>DBMS</span></a>
    </div>

    <nav class="navbar-links">
        <a href="<?= BASE_URL ?>/dashboard.php" class="<?= strpos($currentUri, 'dashboard.php') !== false ? 'active' : '' ?>">Dashboard</a>
        <a href="<?= BASE_URL ?>/modules/vehicles/index.php" class="<?= strpos($currentUri, '/modules/vehicles/') !== false ? 'active' : '' ?>">Module 1: Vehicles &amp; Entry</a>
        <a href="<?= BASE_URL ?>/modules/payments/index.php" class="<?= strpos($currentUri, '/modules/payments/index.php') !== false ? 'active' : '' ?>">Module 2: Payment &amp; Exit</a>
        <a href="<?= BASE_URL ?>/modules/payments/history.php" class="<?= strpos($currentUri, '/modules/payments/history.php') !== false ? 'active' : '' ?>">Payment History</a>
        <a href="<?= BASE_URL ?>/modules/monitoring/index.php" class="<?= strpos($currentUri, '/modules/monitoring/') !== false ? 'active' : '' ?>">Module 3: Live Monitoring</a>
    </nav>

    <div class="navbar-user">
        <span class="user-label">
            <?= htmlspecialchars($_SESSION['username']) ?>
            <span class="badge badge-role"><?= htmlspecialchars($_SESSION['role']) ?></span>
        </span>
        <a href="<?= BASE_URL ?>/auth/logout.php" class="btn btn-sm btn-danger">Logout</a>
    </div>
</header>

<main class="container">
    <?php if ($flash): ?>
        <div class="alert alert-<?= htmlspecialchars($flash['type']) ?>">
            <?= htmlspecialchars($flash['message']) ?>
        </div>
    <?php endif; ?>