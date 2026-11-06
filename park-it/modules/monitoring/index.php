<?php
/**
 * File: park-it/modules/monitoring/index.php
 * Purpose: Module 3 - Real-Time 50-Space Parking Monitoring Dashboard with AJAX Polling
 */

$pageTitle = 'Module 3: Parking Monitoring System';
require_once __DIR__ . '/../../includes/header.php';

// Initial server-side render data (subsequent updates happen automatically via AJAX)
$summary = getParkingSummary($pdo);

$zones = $pdo->query("
    SELECT zone_id, zone_name, max_capacity, current_active_count
    FROM public.parking_zone
    ORDER BY zone_id ASC
")->fetchAll();

$activeTransactions = $pdo->query("
    SELECT t.transaction_id, t.entry_time, t.status,
           v.license_plate, v.vehicle_type,
           z.zone_name
    FROM public.\"transaction\" t
    JOIN public.vehicle v ON t.vehicle_id = v.vehicle_id
    JOIN public.parking_zone z ON t.zone_id = z.zone_id
    WHERE t.status = 'Active'
    ORDER BY t.entry_time DESC
")->fetchAll();

$nowStr = date('Y-m-d H:i:s');
$isFull = ($summary['available_spaces'] <= 0);
?>

<div class="page-header">
    <div>
        <h1>Module 3: Real-Time Parking Monitoring System</h1>
        <p style="font-size: 14px; color: #64748b; margin-top: 4px;">
            Live capacity tracking powered by PostgreSQL <code>public.parking_zone</code> &amp; AJAX polling
        </p>
    </div>

    <div style="display: flex; align-items: center; gap: 12px; flex-wrap: wrap;">
        <div class="live-indicator">
            <span class="live-dot" id="live-dot"></span>
            <span>Auto-updating (<span id="last-updated-time"><?= date('h:i:s A') ?></span>)</span>
        </div>
        <button type="button" id="btn-manual-refresh" class="btn btn-sm btn-secondary">Refresh Now</button>
        <a
            href="<?= BASE_URL ?>/modules/vehicles/index.php"
            id="btn-register-vehicle"
            class="btn btn-primary <?= $isFull ? 'disabled' : '' ?>"
            <?= $isFull ? 'aria-disabled="true"' : '' ?>
        >
            <?= $isFull ? 'Lot Full (Entry Disabled)' : '+ Register Incoming Vehicle' ?>
        </a>
    </div>
</div>

<!-- Dynamic Warning Banner Container (Updated automatically via AJAX) -->
<div id="monitoring-warning-container">
    <?php if ($summary['warning_type'] === 'full'): ?>
        <div class="alert alert-danger" id="monitoring-warning-box">
            <?= htmlspecialchars($summary['warning_message']) ?>
        </div>
    <?php elseif ($summary['warning_type'] === 'low'): ?>
        <div class="alert alert-warning" id="monitoring-warning-box">
            <?= htmlspecialchars($summary['warning_message']) ?>
        </div>
    <?php endif; ?>
</div>

<!-- 5 Core Monitoring Metrics Cards -->
<div class="stats-grid">
    <!-- 1. Total Parking Capacity: 50 -->
    <div class="stat-card">
        <div class="stat-title">Total Parking Capacity</div>
        <div class="stat-value" id="stat-total-capacity"><?= (int)$summary['total_capacity'] ?></div>
        <div class="stat-sub">Fixed lot capacity (50 spaces)</div>
    </div>

    <!-- 2. Occupied Parking Spaces -->
    <div class="stat-card <?= $summary['status_code'] === 'full' ? 'danger' : ($summary['status_code'] === 'warning' ? 'warning' : '') ?>" id="card-occupied">
        <div class="stat-title">Occupied Parking Spaces</div>
        <div class="stat-value" id="stat-occupied-spaces"><?= (int)$summary['occupied_spaces'] ?></div>
        <div class="stat-sub">Spaces currently in use</div>
    </div>

    <!-- 3. Available Parking Spaces (Total Capacity - Occupied Spaces) -->
    <div class="stat-card <?= $summary['status_code'] === 'full' ? 'danger' : ($summary['status_code'] === 'warning' ? 'warning' : 'success') ?>" id="card-available">
        <div class="stat-title">Available Parking Spaces</div>
        <div class="stat-value" id="stat-available-spaces"><?= (int)$summary['available_spaces'] ?></div>
        <div class="stat-sub">Formula: Total (<?= (int)$summary['total_capacity'] ?>) &minus; Occupied</div>
    </div>

    <!-- 4. Number of Active Vehicles -->
    <div class="stat-card">
        <div class="stat-title">Number of Active Vehicles</div>
        <div class="stat-value" id="stat-active-vehicles"><?= (int)$summary['active_vehicles'] ?></div>
        <div class="stat-sub">Vehicles with status = 'Active'</div>
    </div>

    <!-- 5. Parking Availability Status -->
    <div class="stat-card <?= $summary['status_code'] === 'full' ? 'danger' : ($summary['status_code'] === 'warning' ? 'warning' : 'success') ?>" id="card-status">
        <div class="stat-title">Parking Availability Status</div>
        <div style="margin-top: 8px;">
            <span
                id="stat-status-badge"
                class="badge <?= $summary['status_code'] === 'full' ? 'badge-danger' : ($summary['status_code'] === 'warning' ? 'badge-warning' : 'badge-active') ?>"
                style="font-size: 13px; padding: 6px 10px;"
            >
                <?= htmlspecialchars($summary['status_text']) ?>
            </span>
        </div>
        <div class="stat-sub" style="margin-top: 8px;">Real-time lot status</div>
    </div>
</div>

<!-- Visual Occupancy Meter -->
<div class="card">
    <div style="display: flex; justify-content: space-between; align-items: center;">
        <h2 style="border: none; margin: 0; padding: 0;">Live Lot Occupancy Meter</h2>
        <span style="font-size: 14px; font-weight: 700; color: #334155;" id="occupancy-label">
            <?= (int)$summary['occupied_spaces'] ?> / <?= (int)$summary['total_capacity'] ?> Spaces Occupied (<?= $summary['occupancy_percent'] ?>%)
        </span>
    </div>
    <div class="progress-container">
        <div
            id="occupancy-progress-bar"
            class="progress-bar <?= $summary['status_code'] === 'full' ? 'danger' : ($summary['status_code'] === 'warning' ? 'warning' : '') ?>"
            style="width: <?= max(3, $summary['occupancy_percent']) ?>%;"
        >
            <?= $summary['occupancy_percent'] ?>%
        </div>
    </div>
</div>

<!-- Parking Zone Breakdown Table (from public.parking_zone) -->
<div class="card">
    <h2>Parking Zone Capacity Breakdown (<code>public.parking_zone</code>)</h2>
    <div class="table-responsive">
        <table>
            <thead>
                <tr>
                    <th>Zone ID</th>
                    <th>Zone Name</th>
                    <th>Max Capacity</th>
                    <th>Occupied Spaces (<code>current_active_count</code>)</th>
                    <th>Available Spaces</th>
                    <th>Zone Status</th>
                </tr>
            </thead>
            <tbody id="zones-table-body">
                <?php if (empty($zones)): ?>
                    <tr>
                        <td colspan="6" style="text-align: center; color: #64748b;">No parking zones configured. Run <code>config/seed.php</code>.</td>
                    </tr>
                <?php else: ?>
                    <?php foreach ($zones as $z):
                        $zMax   = (int)$z['max_capacity'];
                        $zOcc   = (int)$z['current_active_count'];
                        $zAvail = max(0, $zMax - $zOcc);
                    ?>
                        <tr>
                            <td>#<?= (int)$z['zone_id'] ?></td>
                            <td><strong><?= htmlspecialchars($z['zone_name']) ?></strong></td>
                            <td><?= $zMax ?></td>
                            <td><?= $zOcc ?></td>
                            <td><strong><?= $zAvail ?></strong></td>
                            <td>
                                <?php if ($zAvail === 0): ?>
                                    <span class="badge badge-danger">FULL</span>
                                <?php elseif ($zAvail <= 10): ?>
                                    <span class="badge badge-warning">LOW SPACE (<?= $zAvail ?> left)</span>
                                <?php else: ?>
                                    <span class="badge badge-active">AVAILABLE</span>
                                <?php endif; ?>
                            </td>
                        </tr>
                    <?php endforeach; ?>
                <?php endif; ?>
            </tbody>
        </table>
    </div>
</div>

<!-- Currently Parked Vehicles Live Table -->
<div class="card">
    <h2>Active Parked Vehicles (<span id="active-table-count"><?= count($activeTransactions) ?></span>)</h2>
    <div class="table-responsive">
        <table>
            <thead>
                <tr>
                    <th>Ticket #</th>
                    <th>License Plate</th>
                    <th>Vehicle Type</th>
                    <th>Parking Zone</th>
                    <th>Entry Date &amp; Time</th>
                    <th>Elapsed Duration</th>
                    <th>Running Fee (Regular)</th>
                    <th>Action</th>
                </tr>
            </thead>
            <tbody id="active-vehicles-tbody">
                <?php if (empty($activeTransactions)): ?>
                    <tr>
                        <td colspan="8" style="text-align: center; color: #64748b;">No vehicles are currently parked in the lot.</td>
                    </tr>
                <?php else: ?>
                    <?php foreach ($activeTransactions as $tx):
                        $calc = calculateParkingFee($tx['entry_time'], $nowStr, $tx['vehicle_type'], false);
                    ?>
                        <tr>
                            <td>#<?= (int)$tx['transaction_id'] ?></td>
                            <td><strong><?= htmlspecialchars($tx['license_plate']) ?></strong></td>
                            <td>
                                <span class="badge <?= $tx['vehicle_type'] === 'Car' ? 'badge-car' : 'badge-motorcycle' ?>">
                                    <?= htmlspecialchars($tx['vehicle_type']) ?>
                                </span>
                            </td>
                            <td><?= htmlspecialchars($tx['zone_name']) ?></td>
                            <td><?= date('M d, Y h:i:s A', strtotime($tx['entry_time'])) ?></td>
                            <td><?= htmlspecialchars($calc['duration_formatted']) ?></td>
                            <td>&#8369;<?= number_format($calc['regular_fee'], 2) ?></td>
                            <td>
                                <a href="<?= BASE_URL ?>/modules/payments/index.php?plate=<?= urlencode($tx['license_plate']) ?>" class="btn btn-sm btn-primary">
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

<script>
    const MONITOR_API_URL = "<?= BASE_URL ?>/modules/monitoring/api_status.php";
    const PAYMENT_BASE_URL = "<?= BASE_URL ?>/modules/payments/index.php";
</script>
<script src="<?= BASE_URL ?>/assets/js/monitor.js"></script>

<?php require_once __DIR__ . '/../../includes/footer.php'; ?>