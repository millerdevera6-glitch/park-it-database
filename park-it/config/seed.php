<?php
/**
 * File: park-it/config/seed.php
 * Purpose: One-time initializer for the 50-space parking zone and staff_user accounts
 */

require_once __DIR__ . '/database.php';

$messages = [];
$error = '';

try {
    $pdo->beginTransaction();

    // 1. Configure Parking Zone with fixed capacity of 50 spaces
    $stmtZoneCount = $pdo->query("SELECT COUNT(*) FROM public.parking_zone");
    $zoneCount = (int)$stmtZoneCount->fetchColumn();

    if ($zoneCount === 0) {
        // Count any currently active transactions just in case
        $stmtActive = $pdo->query("SELECT COUNT(*) FROM public.\"transaction\" WHERE status = 'Active'");
        $activeCount = (int)$stmtActive->fetchColumn();

        $stmtInsertZone = $pdo->prepare("
            INSERT INTO public.parking_zone (zone_name, max_capacity, current_active_count)
            VALUES (:zone_name, :max_capacity, :current_active_count)
        ");
        $stmtInsertZone->execute([
            ':zone_name'            => 'Main Parking Lot',
            ':max_capacity'         => 50,
            ':current_active_count' => $activeCount
        ]);
        $messages[] = "Created default parking zone 'Main Parking Lot' with max_capacity = 50.";
    } else {
        $messages[] = "Parking zone record(s) already exist in public.parking_zone.";
    }

    // 2. Seed initial Admin and Staff accounts if they do not exist yet
    $defaultUsers = [
        [
            'username' => 'admin',
            'password' => 'admin123',
            'role'     => 'Admin'
        ],
        [
            'username' => 'staff',
            'password' => 'staff123',
            'role'     => 'Staff'
        ]
    ];

    $stmtCheckUser = $pdo->prepare("SELECT user_id FROM public.staff_user WHERE username = :username");
    $stmtInsertUser = $pdo->prepare("
        INSERT INTO public.staff_user (username, password_hash, role)
        VALUES (:username, :password_hash, :role)
    ");

    foreach ($defaultUsers as $u) {
        $stmtCheckUser->execute([':username' => $u['username']]);
        if (!$stmtCheckUser->fetch()) {
            $stmtInsertUser->execute([
                ':username'      => $u['username'],
                ':password_hash' => password_hash($u['password'], PASSWORD_DEFAULT),
                ':role'          => $u['role']
            ]);
            $messages[] = "Created {$u['role']} account: username '{$u['username']}' / password '{$u['password']}'.";
        } else {
            $messages[] = "User '{$u['username']}' already exists in public.staff_user.";
        }
    }

    $pdo->commit();
} catch (Exception $e) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    $error = $e->getMessage();
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Initial Setup - Park It DBMS</title>
    <link rel="stylesheet" href="<?= BASE_URL ?>/assets/css/style.css">
</head>
<body>
<div class="auth-wrapper">
    <div class="card" style="max-width: 550px; width: 100%;">
        <h2>Park It – Initial Database Seed</h2>
        <?php if ($error): ?>
            <div class="alert alert-danger"><?= htmlspecialchars($error) ?></div>
        <?php else: ?>
            <div class="alert alert-success">Database initialization completed successfully!</div>
            <ul style="line-height: 1.8; margin-bottom: 20px;">
                <?php foreach ($messages as $msg): ?>
                    <li><?= htmlspecialchars($msg) ?></li>
                <?php endforeach; ?>
            </ul>
            <p><a href="<?= BASE_URL ?>/auth/login.php" class="btn btn-primary">Proceed to Login Page</a></p>
        <?php endif; ?>
    </div>
</div>
</body>
</html>