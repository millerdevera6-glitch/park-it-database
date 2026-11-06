<?php
/**
 * File: park-it/modules/vehicles/edit.php
 * Purpose: Update Registered Vehicle Information (CRUD - Update)
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../includes/functions.php';

requireLogin();

$vehicleId = (int)($_GET['id'] ?? $_POST['vehicle_id'] ?? 0);

$stmt = $pdo->prepare("SELECT vehicle_id, license_plate, vehicle_type FROM public.vehicle WHERE vehicle_id = :id");
$stmt->execute([':id' => $vehicleId]);
$vehicle = $stmt->fetch();

if (!$vehicle) {
    setFlash('danger', 'Vehicle record not found.');
    header('Location: ' . BASE_URL . '/modules/vehicles/index.php');
    exit;
}

$error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $licensePlate = strtoupper(trim($_POST['license_plate'] ?? ''));
    $vehicleType  = trim($_POST['vehicle_type'] ?? '');

    if ($licensePlate === '' || strlen($licensePlate) > 20) {
        $error = 'Please enter a valid license plate number (1 to 20 characters).';
    } elseif (!preg_match('/^[A-Z0-9\-\s]+$/', $licensePlate)) {
        $error = 'License plate may only contain letters, numbers, spaces, and hyphens.';
    } elseif (!in_array($vehicleType, ['Car', 'Motorcycle'], true)) {
        $error = 'Vehicle type must be Car or Motorcycle.';
    } else {
        // Check if another vehicle already owns this license plate
        $stmtDup = $pdo->prepare("
            SELECT vehicle_id
            FROM public.vehicle
            WHERE license_plate = :license_plate AND vehicle_id != :vehicle_id
            LIMIT 1
        ");
        $stmtDup->execute([
            ':license_plate' => $licensePlate,
            ':vehicle_id'    => $vehicleId
        ]);

        if ($stmtDup->fetch()) {
            $error = "Another vehicle is already registered with license plate '{$licensePlate}'.";
        } else {
            $stmtUpdate = $pdo->prepare("
                UPDATE public.vehicle
                SET license_plate = :license_plate,
                    vehicle_type  = :vehicle_type
                WHERE vehicle_id = :vehicle_id
            ");
            $stmtUpdate->execute([
                ':license_plate' => $licensePlate,
                ':vehicle_type'  => $vehicleType,
                ':vehicle_id'    => $vehicleId
            ]);

            setFlash('success', "Vehicle #{$vehicleId} updated to {$licensePlate} ({$vehicleType}).");
            header('Location: ' . BASE_URL . '/modules/vehicles/index.php');
            exit;
        }
    }
}

$pageTitle = 'Edit Vehicle';
require_once __DIR__ . '/../../includes/header.php';
?>

<div class="page-header">
    <h1>Edit Registered Vehicle #<?= (int)$vehicle['vehicle_id'] ?></h1>
    <a href="<?= BASE_URL ?>/modules/vehicles/index.php" class="btn btn-secondary">&larr; Back to Module 1</a>
</div>

<div class="card" style="max-width: 480px;">
    <h2>Vehicle Details</h2>

    <?php if ($error): ?>
        <div class="alert alert-danger"><?= htmlspecialchars($error) ?></div>
    <?php endif; ?>

    <form method="POST" action="<?= BASE_URL ?>/modules/vehicles/edit.php">
        <input type="hidden" name="vehicle_id" value="<?= (int)$vehicle['vehicle_id'] ?>">

        <div class="form-group">
            <label for="license_plate">License Plate Number *</label>
            <input
                type="text"
                id="license_plate"
                name="license_plate"
                class="form-control"
                maxlength="20"
                value="<?= htmlspecialchars($_POST['license_plate'] ?? $vehicle['license_plate']) ?>"
                required
            >
        </div>

        <div class="form-group">
            <label for="vehicle_type">Vehicle Type *</label>
            <?php $selectedType = $_POST['vehicle_type'] ?? $vehicle['vehicle_type']; ?>
            <select id="vehicle_type" name="vehicle_type" class="form-control" required>
                <option value="Car" <?= $selectedType === 'Car' ? 'selected' : '' ?>>Car</option>
                <option value="Motorcycle" <?= $selectedType === 'Motorcycle' ? 'selected' : '' ?>>Motorcycle</option>
            </select>
        </div>

        <div style="display: flex; gap: 10px;">
            <button type="submit" class="btn btn-primary">Save Changes</button>
            <a href="<?= BASE_URL ?>/modules/vehicles/index.php" class="btn btn-secondary">Cancel</a>
        </div>
    </form>
</div>

<?php require_once __DIR__ . '/../../includes/footer.php'; ?>