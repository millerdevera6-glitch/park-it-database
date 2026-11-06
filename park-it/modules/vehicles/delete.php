<?php
/**
 * File: park-it/modules/vehicles/delete.php
 * Purpose: Safe Vehicle Deletion (CRUD - Delete)
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../includes/functions.php';

requireLogin();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    header('Location: ' . BASE_URL . '/modules/vehicles/index.php');
    exit;
}

$vehicleId = (int)($_POST['vehicle_id'] ?? 0);

if ($vehicleId <= 0) {
    setFlash('danger', 'Invalid vehicle ID specified.');
    header('Location: ' . BASE_URL . '/modules/vehicles/index.php');
    exit;
}

try {
    // Check if the vehicle exists
    $stmtVeh = $pdo->prepare("SELECT license_plate FROM public.vehicle WHERE vehicle_id = :id");
    $stmtVeh->execute([':id' => $vehicleId]);
    $vehicle = $stmtVeh->fetch();

    if (!$vehicle) {
        setFlash('danger', 'Vehicle record not found.');
        header('Location: ' . BASE_URL . '/modules/vehicles/index.php');
        exit;
    }

    // Check if the vehicle is referenced by any transaction records
    $stmtTxCount = $pdo->prepare("SELECT COUNT(*) FROM public.\"transaction\" WHERE vehicle_id = :id");
    $stmtTxCount->execute([':id' => $vehicleId]);
    $txCount = (int)$stmtTxCount->fetchColumn();

    if ($txCount > 0) {
        setFlash('danger', "Cannot delete vehicle {$vehicle['license_plate']}: It is linked to {$txCount} parking transaction(s). Deletion is blocked to preserve transaction and payment history.");
    } else {
        $stmtDel = $pdo->prepare("DELETE FROM public.vehicle WHERE vehicle_id = :id");
        $stmtDel->execute([':id' => $vehicleId]);
        setFlash('success', "Vehicle {$vehicle['license_plate']} was safely deleted.");
    }
} catch (Exception $e) {
    setFlash('danger', 'Error deleting vehicle: ' . $e->getMessage());
}

header('Location: ' . BASE_URL . '/modules/vehicles/index.php');
exit;
?>