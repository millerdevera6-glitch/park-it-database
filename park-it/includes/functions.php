<?php
/**
 * File: park-it/includes/functions.php
 * Purpose: Session management, role authorization, flash messages, capacity synchronization, and fee computation
 */

if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

/**
 * Check if a staff/admin user is currently logged in
 */
function isLoggedIn(): bool {
    return isset($_SESSION['user_id']) && !empty($_SESSION['user_id']);
}

/**
 * Redirect unauthenticated users to the login page
 */
function requireLogin(): void {
    if (!isLoggedIn()) {
        setFlash('danger', 'Please log in to access the system.');
        header('Location: ' . BASE_URL . '/auth/login.php');
        exit;
    }
}

/**
 * Check if the logged-in user holds the Admin role
 */
function isAdmin(): bool {
    return isset($_SESSION['role']) && strtolower($_SESSION['role']) === 'admin';
}

/**
 * Store a one-time flash message in the session
 */
function setFlash(string $type, string $message): void {
    $_SESSION['flash'] = [
        'type'    => $type,
        'message' => $message
    ];
}

/**
 * Retrieve and clear the flash message from the session
 */
function getFlash(): ?array {
    if (isset($_SESSION['flash'])) {
        $flash = $_SESSION['flash'];
        unset($_SESSION['flash']);
        return $flash;
    }
    return null;
}

/**
 * Synchronize public.parking_zone with active transactions and return complete monitoring metrics.
 * Guarantees that current_active_count in public.parking_zone always matches actual active vehicles
 * and calculates Available Spaces = Total Capacity (50) - Occupied Spaces.
 */
function getParkingSummary(PDO $pdo): array {
    // 1. Ensure each parking_zone's current_active_count accurately reflects active transactions
    $stmtSync = $pdo->query("
        SELECT z.zone_id, z.max_capacity, z.current_active_count,
               COUNT(t.transaction_id) AS actual_active
        FROM public.parking_zone z
        LEFT JOIN public.\"transaction\" t
               ON z.zone_id = t.zone_id AND t.status = 'Active'
        GROUP BY z.zone_id, z.max_capacity, z.current_active_count
    ");
    $zonesCheck = $stmtSync->fetchAll();

    foreach ($zonesCheck as $zRow) {
        $actualActive = min((int)$zRow['max_capacity'], (int)$zRow['actual_active']);
        if ((int)$zRow['current_active_count'] !== $actualActive) {
            $stmtFix = $pdo->prepare("
                UPDATE public.parking_zone
                SET current_active_count = :actual_active
                WHERE zone_id = :zone_id
            ");
            $stmtFix->execute([
                ':actual_active' => $actualActive,
                ':zone_id'       => (int)$zRow['zone_id']
            ]);
        }
    }

    // 2. Read authoritative capacity and occupancy from public.parking_zone
    $stmt = $pdo->query("
        SELECT 
            COALESCE(SUM(max_capacity), 0) AS total_capacity,
            COALESCE(SUM(current_active_count), 0) AS occupied_spaces
        FROM public.parking_zone
    ");
    $row = $stmt->fetch();

    // Count active vehicles in public."transaction"
    $activeVehicles = (int)$pdo->query("
        SELECT COUNT(*) FROM public.\"transaction\" WHERE status = 'Active'
    ")->fetchColumn();

    // Fixed capacity of 50 spaces (uses configured zone sum, defaulting to 50)
    $totalCapacity   = (int)($row['total_capacity'] ?? 50);
    if ($totalCapacity <= 0) {
        $totalCapacity = 50;
    }

    $occupiedSpaces  = (int)($row['occupied_spaces'] ?? 0);
    // Available Spaces = Total Capacity - Occupied Spaces
    $availableSpaces = max(0, $totalCapacity - $occupiedSpaces);

    // Determine Parking Availability Status and Warning State
    if ($availableSpaces === 0 || $occupiedSpaces >= $totalCapacity) {
        $statusCode     = 'full';
        $statusText     = 'FULL CAPACITY (No Spaces Available)';
        $warningType    = 'full';
        $warningMessage = "FULL CAPACITY WARNING: All {$totalCapacity} parking spaces are currently occupied ({$occupiedSpaces}/{$totalCapacity}). Incoming vehicle registration is disabled until a vehicle exits.";
    } elseif ($availableSpaces <= 10) {
        $statusCode     = 'warning';
        $statusText     = "LOW SPACE WARNING ({$availableSpaces} Left)";
        $warningType    = 'low';
        $warningMessage = "LOW PARKING SPACE WARNING: Only {$availableSpaces} parking space(s) remain available out of {$totalCapacity}!";
    } else {
        $statusCode     = 'available';
        $statusText     = 'OPEN / SPACES AVAILABLE';
        $warningType    = 'none';
        $warningMessage = '';
    }

    $occupancyPercent = $totalCapacity > 0
        ? min(100, round(($occupiedSpaces / $totalCapacity) * 100, 1))
        : 0;

    return [
        'total_capacity'    => $totalCapacity,
        'occupied_spaces'   => $occupiedSpaces,
        'available_spaces'  => $availableSpaces,
        'active_vehicles'   => $activeVehicles,
        'status_code'       => $statusCode,
        'status_text'       => $statusText,
        'warning_type'      => $warningType,
        'warning_message'   => $warningMessage,
        'occupancy_percent' => $occupancyPercent
    ];
}

/**
 * Calculate parking duration and total fee based on Park It business rules:
 * - Car: First 3 hours = ₱50.00 | Succeeding hours = +₱10.00/hr
 * - Motorcycle: First 3 hours = ₱30.00 | Succeeding hours = +₱10.00/hr
 * - Lost Ticket: Flat ₱200.00 (replaces regular parking fee)
 */
function calculateParkingFee(string $entryTimeStr, string $exitTimeStr, string $vehicleType, bool $isLostTicket = false): array {
    $entryTs = strtotime($entryTimeStr);
    $exitTs  = strtotime($exitTimeStr);

    // Ensure elapsed seconds is never negative
    $elapsedSeconds = max(0, $exitTs - $entryTs);

    // Calculate human-readable hours, minutes, and seconds
    $hours   = (int)floor($elapsedSeconds / 3600);
    $minutes = (int)floor(($elapsedSeconds % 3600) / 60);
    $seconds = (int)($elapsedSeconds % 60);

    $durationFormatted = sprintf('%d hr(s) %d min(s) %d sec(s)', $hours, $minutes, $seconds);

    // Any fraction of an hour counts as 1 billed hour (minimum 1 hour upon entry)
    $billedHours = max(1, (int)ceil($elapsedSeconds / 3600));

    // Base rate for the first 3 hours
    $baseRate        = ($vehicleType === 'Car') ? 50.00 : 30.00;
    $succeedingHours = max(0, $billedHours - 3);
    $succeedingFee   = $succeedingHours * 10.00;
    $regularFee      = $baseRate + $succeedingFee;

    // Lost ticket flat fee (₱200) replaces the regular fee completely
    if ($isLostTicket) {
        $totalAmount = 200.00;
    } else {
        $totalAmount = $regularFee;
    }

    return [
        'elapsed_seconds'    => $elapsedSeconds,
        'duration_formatted' => $durationFormatted,
        'billed_hours'       => $billedHours,
        'base_rate'          => $baseRate,
        'succeeding_hours'   => $succeedingHours,
        'succeeding_fee'     => $succeedingFee,
        'regular_fee'        => $regularFee,
        'is_lost_ticket'     => $isLostTicket,
        'total_amount'       => $totalAmount
    ];
}
?>