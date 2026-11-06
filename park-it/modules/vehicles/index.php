<?php
/**
 * File: park-it/modules/vehicles/index.php
 * Purpose: Module 1 - Vehicle Registration, Transaction Creation, and Vehicle CRUD
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../includes/functions.php';

requireLogin();

$formError = '';

// ============================================================================
// HANDLE VEHICLE ENTRY & TRANSACTION CREATION (CREATE)
// ============================================================================
if ($_SERVER['REQUEST_METHOD'] === 'POST' && ($_POST['action'] ?? '') === 'register_entry') {
    $licensePlate = strtoupper(trim($_POST['license_plate'] ?? ''));
    $vehicleType  = trim($_POST['vehicle_type'] ?? '');
    $zoneId       = (int)($_POST['zone_id'] ?? 0);

    // Server-side validation
    if ($licensePlate === '') {
        $formError = 'License plate number is required.';
    } elseif (strlen($licensePlate) > 20) {
        $formError = 'License plate number must not exceed 20 characters.';
    } elseif (!preg_match('/^[A-Z0-9\-\s]+$/', $licensePlate)) {
        $formError = 'License plate may only contain letters, numbers, spaces, and hyphens.';
    } elseif (!in_array($vehicleType, ['Car', 'Motorcycle'], true)) {
        $formError = 'Please select a valid vehicle type (Car or Motorcycle).';
    } elseif ($zoneId <= 0) {
        $formError = 'Please select a valid parking zone.';
    } else {
        try {
            $pdo->beginTransaction();

            // 1. Lock and check the parking zone capacity
            $stmtZone = $pdo->prepare("
                SELECT zone_id, zone_name, max_capacity, current_active_count
                FROM public.parking_zone
                WHERE zone_id = :zone_id
                FOR UPDATE
            ");
            $stmtZone->execute([':zone_id' => $zoneId]);
            $zone = $stmtZone->fetch();

            if (!$zone) {
                throw new Exception('The selected parking zone was not found.');
            }

            if ((int)$zone['current_active_count'] >= (int)$zone['max_capacity']) {
                throw new Exception("Parking zone '{$zone['zone_name']}' is at full capacity ({$zone['current_active_count']}/{$zone['max_capacity']}). New entries are not allowed.");
            }

            // 2. Check if the vehicle is already registered in public.vehicle
            $stmtVehicle = $pdo->prepare("
                SELECT vehicle_id, license_plate, vehicle_type
                FROM public.vehicle
                WHERE license_plate = :license_plate
                LIMIT 1
            ");
            $stmtVehicle->execute([':license_plate' => $licensePlate]);
            $vehicle = $stmtVehicle->fetch();

            if (!$vehicle) {
                // Vehicle is not yet registered -> insert into public.vehicle
                $stmtInsertVehicle = $pdo->prepare("
                    INSERT INTO public.vehicle (license_plate, vehicle_type)
                    VALUES (:license_plate, :vehicle_type)
                    RETURNING vehicle_id
                ");
                $stmtInsertVehicle->execute([
                    ':license_plate' => $licensePlate,
                    ':vehicle_type'  => $vehicleType
                ]);
                $vehicleId = (int)$stmtInsertVehicle->fetchColumn();
            } else {
                $vehicleId = (int)$vehicle['vehicle_id'];

                // Check if the vehicle already has an Active parking transaction
                $stmtActiveCheck = $pdo->prepare("
                    SELECT transaction_id, entry_time
                    FROM public.\"transaction\"
                    WHERE vehicle_id = :vehicle_id AND status = 'Active'
                    LIMIT 1
                ");
                $stmtActiveCheck->execute([':vehicle_id' => $vehicleId]);
                $existingActive = $stmtActiveCheck->fetch();

                if ($existingActive) {
                    throw new Exception("Duplicate Entry Blocked: Vehicle {$licensePlate} already has an active parking transaction (Ticket #{$existingActive['transaction_id']}).");
                }

                // Ensure vehicle type matches the existing registration
                if ($vehicle['vehicle_type'] !== $vehicleType) {
                    throw new Exception("Vehicle {$licensePlate} is already registered as a '{$vehicle['vehicle_type']}'. Please select '{$vehicle['vehicle_type']}' or update the vehicle record in the directory below.");
                }
            }

            // 3. Create the new parking transaction with automatic entry timestamp
            $stmtInsertTx = $pdo->prepare("
                INSERT INTO public.\"transaction\" (vehicle_id, zone_id, entry_time, status, is_lost_ticket)
                VALUES (:vehicle_id, :zone_id, CURRENT_TIMESTAMP, 'Active', false)
                RETURNING transaction_id, entry_time
            ");
            $stmtInsertTx->execute([
                ':vehicle_id' => $vehicleId,
                ':zone_id'    => $zoneId
            ]);
            $newTx = $stmtInsertTx->fetch();

            // 4. Increase the occupied parking-space count by 1
            $stmtUpdateZone = $pdo->prepare("
                UPDATE public.parking_zone
                SET current_active_count = current_active_count + 1
                WHERE zone_id = :zone_id
            ");
            $stmtUpdateZone->execute([':zone_id' => $zoneId]);

            $pdo->commit();

            $formattedTime = date('M d, Y h:i:s A', strtotime($newTx['entry_time']));
            setFlash('success', "Vehicle {$licensePlate} ({$vehicleType}) entered successfully! Ticket #{$newTx['transaction_id']} logged at {$formattedTime}.");
            header('Location: ' . BASE_URL . '/modules/vehicles/index.php');
            exit;

        } catch (Exception $e) {
            if ($pdo->inTransaction()) {
                $pdo->rollBack();
            }
            $formError = $e->getMessage();
        }
    }
}

// ============================================================================
// FETCH DATA FOR DISPLAY (READ)
// ============================================================================
$summary = getParkingSummary($pdo);

// Fetch all parking zones
$zones = $pdo->query("
    SELECT zone_id, zone_name, max_capacity, current_active_count
    FROM public.parking_zone
    ORDER BY zone_id ASC
")->fetchAll();

// Fetch all active parking transactions
$activeTransactions = $pdo->query("
    SELECT t.transaction_id, t.entry_time, t.status,
           v.vehicle_id, v.license_plate, v.vehicle_type,
           z.zone_name
    FROM public.\"transaction\" t
    JOIN public.vehicle v ON t.vehicle_id = v.vehicle_id
    JOIN public.parking_zone z ON t.zone_id = z.zone_id
    WHERE t.status = 'Active'
    ORDER BY t.entry_time DESC
")->fetchAll();

// Fetch all registered vehicles with transaction counts (to determine safe deletion)
$registeredVehicles = $pdo->query("
    SELECT v.vehicle_id, v.license_plate, v.vehicle_type,
           COUNT(t.transaction_id) AS total_transactions,
           SUM(CASE WHEN t.status = 'Active' THEN 1 ELSE 0 END) AS active_transactions
    FROM public.vehicle v
    LEFT JOIN public.\"transaction\" t ON v.vehicle_id = t.vehicle_id
    GROUP BY v.vehicle_id, v.license_plate, v.vehicle_type
    ORDER BY v.vehicle_id DESC
")->fetchAll();

$pageTitle = 'Module 1: Vehicle Registration';
require_once __DIR__ . '/../../includes/header.php';
?>

<div class="page-header">
    <h1>Module 1: Vehicle Registration &amp; Entry</h1>
</div>

<?php if ($summary['total_capacity'] === 0): ?>
    <div class="alert alert-warning">
        No parking zones are configured yet. Please run <a href="<?= BASE_URL ?>/config/seed.php"><strong>config/seed.php</strong></a> first to initialize the 50-space parking zone.
    </div>
<?php elseif ($summary['available_spaces'] <= 0): ?>
    <div class="alert alert-danger">
        <strong>FULL CAPACITY REACHED:</strong> All <?= $summary['total_capacity'] ?> parking spaces are currently occupied. New vehicle entries are disabled until a vehicle exits.
    </div>
<?php endif; ?>

<?php if ($formError): ?>
    <div class="alert alert-danger"><?= htmlspecialchars($formError) ?></div>
<?php endif; ?>

<!-- Capacity Summary Bar -->
<div class="stats-grid">
    <div class="stat-card">
        <div class="stat-title">Total Capacity</div>
        <div class="stat-value"><?= $summary['total_capacity'] ?></div>
    </div>
    <div class="stat-card <?= $summary['available_spaces'] <= 0 ? 'danger' : 'warning' ?>">
        <div class="stat-title">Occupied Spaces</div>
        <div class="stat-value"><?= $summary['occupied_spaces'] ?></div>
    </div>
    <div class="stat-card <?= $summary['available_spaces'] <= 0 ? 'danger' : 'success' ?>">
        <div class="stat-title">Available Spaces</div>
        <div class="stat-value"><?= $summary['available_spaces'] ?></div>
    </div>
</div>

<div class="content-grid">
    <!-- Left Column: Vehicle Entry Registration Form (CREATE) -->
    <div class="card">
        <h2>Register Incoming Vehicle</h2>

        <?php $isLotFull = ($summary['total_capacity'] === 0 || $summary['available_spaces'] <= 0); ?>

        <form method="POST" action="<?= BASE_URL ?>/modules/vehicles/index.php">
            <input type="hidden" name="action" value="register_entry">

            <div class="form-group">
                <label for="license_plate">License Plate Number *</label>
                <input
                    type="text"
                    id="license_plate"
                    name="license_plate"
                    class="form-control"
                    placeholder="e.g. ABC-1234"
                    maxlength="20"
                    value="<?= htmlspecialchars($_POST['license_plate'] ?? '') ?>"
                    required
                    <?= $isLotFull ? 'disabled' : '' ?>
                >
            </div>

            <div class="form-group">
                <label for="vehicle_type">Vehicle Type *</label>
                <select id="vehicle_type" name="vehicle_type" class="form-control" required <?= $isLotFull ? 'disabled' : '' ?>>
                    <option value="">-- Select Vehicle Type --</option>
                    <option value="Car" <?= (($_POST['vehicle_type'] ?? '') === 'Car') ? 'selected' : '' ?>>Car</option>
                    <option value="Motorcycle" <?= (($_POST['vehicle_type'] ?? '') === 'Motorcycle') ? 'selected' : '' ?>>Motorcycle</option>
                </select>
            </div>

            <div class="form-group">
                <label for="zone_id">Parking Zone *</label>
                <select id="zone_id" name="zone_id" class="form-control" required <?= $isLotFull ? 'disabled' : '' ?>>
                    <?php foreach ($zones as $z):
                        $zoneAvailable = (int)$z['max_capacity'] - (int)$z['current_active_count'];
                    ?>
                        <option value="<?= (int)$z['zone_id'] ?>" <?= $zoneAvailable <= 0 ? 'disabled' : '' ?>>
                            <?= htmlspecialchars($z['zone_name']) ?> (<?= $zoneAvailable ?> / <?= (int)$z['max_capacity'] ?> available)
                        </option>
                    <?php endforeach; ?>
                </select>
            </div>

            <button type="submit" class="btn btn-primary btn-block" <?= $isLotFull ? 'disabled' : '' ?>>
                Record Vehicle Entry
            </button>
        </form>
    </div>

    <!-- Right Column: Active Parking Records & Registered Vehicles Directory -->
    <div>
        <!-- Active Parking Transactions Table (READ) -->
        <div class="card">
            <h2>Active Parking Transactions (<?= count($activeTransactions) ?>)</h2>
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
                        </tr>
                    </thead>
                    <tbody>
                        <?php if (empty($activeTransactions)): ?>
                            <tr>
                                <td colspan="6" style="text-align: center; color: #64748b;">No vehicles are currently parked.</td>
                            </tr>
                        <?php else: ?>
                            <?php foreach ($activeTransactions as $tx): ?>
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
                                    <td><span class="badge badge-active"><?= htmlspecialchars($tx['status']) ?></span></td>
                                </tr>
                            <?php endforeach; ?>
                        <?php endif; ?>
                    </tbody>
                </table>
            </div>
        </div>

        <!-- Registered Vehicles Directory (READ, UPDATE, DELETE) -->
        <div class="card">
            <h2>Registered Vehicles Directory (<?= count($registeredVehicles) ?>)</h2>
            <div class="table-responsive">
                <table>
                    <thead>
                        <tr>
                            <th>Vehicle ID</th>
                            <th>License Plate</th>
                            <th>Vehicle Type</th>
                            <th>Total Transactions</th>
                            <th>Current State</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php if (empty($registeredVehicles)): ?>
                            <tr>
                                <td colspan="6" style="text-align: center; color: #64748b;">No vehicles have been registered yet.</td>
                            </tr>
                        <?php else: ?>
                            <?php foreach ($registeredVehicles as $v): ?>
                                <tr>
                                    <td><?= (int)$v['vehicle_id'] ?></td>
                                    <td><strong><?= htmlspecialchars($v['license_plate']) ?></strong></td>
                                    <td>
                                        <span class="badge <?= $v['vehicle_type'] === 'Car' ? 'badge-car' : 'badge-motorcycle' ?>">
                                            <?= htmlspecialchars($v['vehicle_type']) ?>
                                        </span>
                                    </td>
                                    <td><?= (int)$v['total_transactions'] ?></td>
                                    <td>
                                        <?php if ((int)$v['active_transactions'] > 0): ?>
                                            <span class="badge badge-active">Currently Parked</span>
                                        <?php else: ?>
                                            <span style="color: #64748b; font-size: 13px;">Not Parked</span>
                                        <?php endif; ?>
                                    </td>
                                    <td>
                                        <a href="<?= BASE_URL ?>/modules/vehicles/edit.php?id=<?= (int)$v['vehicle_id'] ?>" class="btn btn-sm btn-secondary">Edit</a>

                                        <?php if ((int)$v['total_transactions'] === 0): ?>
                                            <form method="POST" action="<?= BASE_URL ?>/modules/vehicles/delete.php" style="display: inline;" onsubmit="return confirm('Are you sure you want to delete vehicle <?= htmlspecialchars($v['license_plate']) ?>?');">
                                                <input type="hidden" name="vehicle_id" value="<?= (int)$v['vehicle_id'] ?>">
                                                <button type="submit" class="btn btn-sm btn-danger">Delete</button>
                                            </form>
                                        <?php else: ?>
                                            <button type="button" class="btn btn-sm" disabled title="Protected: Vehicle has existing transaction records">Protected</button>
                                        <?php endif; ?>
                                    </td>
                                </tr>
                            <?php endforeach; ?>
                        <?php endif; ?>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</div>

<?php require_once __DIR__ . '/../../includes/footer.php'; ?>