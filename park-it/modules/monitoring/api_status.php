<?php
/**
 * File: park-it/modules/monitoring/api_status.php
 * Purpose: JSON API Endpoint for Real-Time AJAX Parking Monitoring (Module 3)
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../includes/functions.php';

header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store, no-cache, must-revalidate, max-age=0');

if (!isLoggedIn()) {
    http_response_code(401);
    echo json_encode([
        'success' => false,
        'error'   => 'Unauthorized access. Please log in.'
    ]);
    exit;
}

try {
    // 1. Get synchronized summary metrics (Total: 50, Occupied, Available, Active Vehicles, Status)
    $summary = getParkingSummary($pdo);

    // 2. Fetch parking zone breakdown from public.parking_zone
    $stmtZones = $pdo->query("
        SELECT zone_id, zone_name, max_capacity, current_active_count
        FROM public.parking_zone
        ORDER BY zone_id ASC
    ");
    $zonesRaw = $stmtZones->fetchAll();
    $zones = [];

    foreach ($zonesRaw as $z) {
        $maxCap  = (int)$z['max_capacity'];
        $occ     = (int)$z['current_active_count'];
        $avail   = max(0, $maxCap - $occ);
        $zones[] = [
            'zone_id'              => (int)$z['zone_id'],
            'zone_name'            => $z['zone_name'],
            'max_capacity'         => $maxCap,
            'current_active_count' => $occ,
            'available_spaces'     => $avail
        ];
    }

    // 3. Fetch active parked vehicles for the live monitoring table
    $stmtActive = $pdo->query("
        SELECT t.transaction_id, t.entry_time, t.status,
               v.license_plate, v.vehicle_type,
               z.zone_name
        FROM public.\"transaction\" t
        JOIN public.vehicle v ON t.vehicle_id = v.vehicle_id
        JOIN public.parking_zone z ON t.zone_id = z.zone_id
        WHERE t.status = 'Active'
        ORDER BY t.entry_time DESC
    ");
    $activeRows = $stmtActive->fetchAll();

    $nowStr = date('Y-m-d H:i:s');
    $activeVehiclesList = [];

    foreach ($activeRows as $row) {
        $calc = calculateParkingFee($row['entry_time'], $nowStr, $row['vehicle_type'], false);
        $activeVehiclesList[] = [
            'transaction_id'     => (int)$row['transaction_id'],
            'license_plate'      => $row['license_plate'],
            'vehicle_type'       => $row['vehicle_type'],
            'zone_name'          => $row['zone_name'],
            'entry_time_display' => date('M d, Y h:i:s A', strtotime($row['entry_time'])),
            'duration_formatted' => $calc['duration_formatted'],
            'current_fee'        => number_format($calc['regular_fee'], 2),
            'status'             => $row['status']
        ];
    }

    echo json_encode([
        'success'           => true,
        'total_capacity'    => $summary['total_capacity'],
        'occupied_spaces'   => $summary['occupied_spaces'],
        'available_spaces'  => $summary['available_spaces'],
        'active_vehicles'   => $summary['active_vehicles'],
        'status_code'       => $summary['status_code'],
        'status_text'       => $summary['status_text'],
        'warning_type'      => $summary['warning_type'],
        'warning_message'   => $summary['warning_message'],
        'occupancy_percent' => $summary['occupancy_percent'],
        'zones'             => $zones,
        'active_list'       => $activeVehiclesList,
        'last_updated'      => date('h:i:s A')
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error'   => 'Failed to load monitoring data: ' . $e->getMessage()
    ]);
}
?>