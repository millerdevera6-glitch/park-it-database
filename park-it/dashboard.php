<?php
/**
 * File: park-it/dashboard.php
 * Purpose: Central Overview Dashboard for Staff and Administrators
 */

$pageTitle = 'Dashboard';
require_once __DIR__ . '/includes/header.php';

$summary = getParkingSummary($pdo);

// Count total registered vehicles
$totalVehicles = (int)$pdo->query("SELECT COUNT(*) FROM public.vehicle")->fetchColumn();

// Calculate total payments collected
$totalRevenue = (float)$pdo->query("SELECT COALESCE(SUM(amount), 0.00) FROM public.payment")->fetchColumn();

// Fetch the 5 most recent active parking transactions
$stmtRecent = $pdo->query("
    SELECT t.transaction_id, t.entry_time, t.status,
           v.license_plate, v.vehicle_type,
           z.zone_name
    FROM public.\"transaction\" t
    JOIN public.vehicle v ON t.vehicle_id = v.vehicle_id
    JOIN public.parking_zone z ON t.zone_id = z.zone_id
    WHERE t.status = 'Active'
    ORDER BY t.entry_time DESC
    LIMIT 5
");
$recentActive = $stmtRecent->fetchAll();
?>

<div class="page-header">
    <h1>System Overview Dashboard</h1>
    <div style="display: flex; gap: 10px;">
        <a href="<?= BASE_URL ?>/modules/vehicles/index.php" class="btn btn-primary">+ Register Vehicle Entry</a>
        <a href="<?= BASE_URL ?>/modules/payments/index.php" class="btn btn-secondary">Process Payment &amp; Exit</a>
    </div>
</div>

<div class="stats-grid">
    <div class="stat-card">
        <div class="stat-title">Total Parking Capacity</div>
        <div class="stat-value"><?= $summary['total_capacity'] ?></div>
        <div class="stat-sub">Configured in parking_zone</div>
    </div>

    <div class="stat-card <?= $summary['occupied_spaces'] >= $summary['total_capacity'] && $summary['total_capacity'] > 0 ? 'danger' : 'warning' ?>">
        <div class="stat-title">Occupied Spaces</div>
        <div class="stat-value"><?= $summary['occupied_spaces'] ?></div>
        <div class="stat-sub">Currently parked vehicles</div>
    </div>

    <div class="stat-card <?= $summary['available_spaces'] === 0 ? 'danger' : ($summary['available_spaces'] <= 10 ? 'warning' : 'success') ?>">
        <div class="stat-title">Available Spaces</div>
        <div class="stat-value"><?= $summary['available_spaces'] ?></div>
        <div class="stat-sub">Open spaces ready for entry</div>
    </div>

    <div class="stat-card success">
        <div class="stat-title">Total Revenue Collected</div>
        <div class="stat-value">&#8369;<?= number_format($totalRevenue, 2) ?></div>
        <div class="stat-sub"><?= $totalVehicles ?> registered vehicle(s)</div>
    </div>
</div>

<div class="card">
    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px;">
        <h2 style="border: none; margin: 0; padding: 0;">Recent Active Parking Sessions</h2>
        <a href="<?= BASE_URL ?>/modules/vehicles/index.php" class="btn btn-sm btn-secondary">View All in Module 1</a>
    </div>

    <div class="table-responsive">
        <table>
            <thead>
                <tr>
                    <th>Ticket #</th>
                    <th>License Plate</th>
                    <th>Vehicle Type</th>
                    <th>Parking Zone</th>
                    <th>Entry Date &amp; Time</th>
                    <th>Status</th>
                    <th>Action</th>
                </tr>
            </thead>
            <tbody>
                <?php if (empty($recentActive)): ?>
                    <tr>
                        <td colspan="7" style="text-align: center; color: #64748b;">No active parking transactions right now.</td>
                    </tr>
                <?php else: ?>
                    <?php foreach ($recentActive as $row): ?>
                        <tr>
                            <td>#<?= (int)$row['transaction_id'] ?></td>
                            <td><strong><?= htmlspecialchars($row['license_plate']) ?></strong></td>
                            <td>
                                <span class="badge <?= $row['vehicle_type'] === 'Car' ? 'badge-car' : 'badge-motorcycle' ?>">
                                    <?= htmlspecialchars($row['vehicle_type']) ?>
                                </span>
                            </td>
                            <td><?= htmlspecialchars($row['zone_name']) ?></td>
                            <td><?= date('M d, Y h:i:s A', strtotime($row['entry_time'])) ?></td>
                            <td><span class="badge badge-active"><?= htmlspecialchars($row['status']) ?></span></td>
                            <td>
                                <a href="<?= BASE_URL ?>/modules/payments/index.php?plate=<?= urlencode($row['license_plate']) ?>" class="btn btn-sm btn-primary">
                                    Process Exit
                                </a>
                            </td>
                        </tr>
                    <?php endforeach; ?>
                <?php endif; ?>
            </tbody>
        </table>
    </div>
</div>

<?php require_once __DIR__ . '/includes/footer.php'; ?>