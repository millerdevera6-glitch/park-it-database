<?php
/**
 * File: park-it/modules/payments/process.php
 * Purpose: Atomic Server-Side Payment Recording, Transaction Completion, and Space Release
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../includes/functions.php';

requireLogin();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    header('Location: ' . BASE_URL . '/modules/payments/index.php');
    exit;
}

$transactionId = (int)($_POST['transaction_id'] ?? 0);
$paymentMethod = trim($_POST['payment_method'] ?? '');
$isLostTicket  = isset($_POST['is_lost_ticket']) && $_POST['is_lost_ticket'] === '1';

$allowedMethods = ['Cash', 'GCash', 'Maya', 'Credit/Debit Card'];

if ($transactionId <= 0) {
    setFlash('danger', 'Invalid parking transaction ID.');
    header('Location: ' . BASE_URL . '/modules/payments/index.php');
    exit;
}

if (!in_array($paymentMethod, $allowedMethods, true)) {
    setFlash('danger', 'Please select a valid payment method.');
    header('Location: ' . BASE_URL . '/modules/payments/index.php');
    exit;
}

try {
    // Begin atomic database transaction
    $pdo->beginTransaction();

    // 1. Lock and retrieve the transaction record to prevent duplicate/concurrent processing
    $stmtTx = $pdo->prepare("
        SELECT t.transaction_id, t.vehicle_id, t.zone_id, t.entry_time, t.exit_time, t.status,
               v.license_plate, v.vehicle_type
        FROM public.\"transaction\" t
        JOIN public.vehicle v ON t.vehicle_id = v.vehicle_id
        WHERE t.transaction_id = :transaction_id
        FOR UPDATE
    ");
    $stmtTx->execute([':transaction_id' => $transactionId]);
    $tx = $stmtTx->fetch();

    if (!$tx) {
        throw new Exception('Cannot process payment: The specified parking transaction does not exist.');
    }

    if ($tx['status'] !== 'Active') {
        throw new Exception("Cannot process payment: Transaction #{$transactionId} for vehicle {$tx['license_plate']} is already marked as '{$tx['status']}'.");
    }

    // 2. Verify that no payment record already exists for this transaction_id
    $stmtCheckPay = $pdo->prepare("
        SELECT payment_id
        FROM public.payment
        WHERE transaction_id = :transaction_id
        LIMIT 1
    ");
    $stmtCheckPay->execute([':transaction_id' => $transactionId]);
    if ($stmtCheckPay->fetch()) {
        throw new Exception("Cannot process payment: A payment record already exists for Transaction #{$transactionId}.");
    }

    // 3. Lock the associated parking zone row
    $stmtZone = $pdo->prepare("
        SELECT zone_id, current_active_count
        FROM public.parking_zone
        WHERE zone_id = :zone_id
        FOR UPDATE
    ");
    $stmtZone->execute([':zone_id' => (int)$tx['zone_id']]);
    $zone = $stmtZone->fetch();

    if (!$zone) {
        throw new Exception('Associated parking zone record was not found.');
    }

    // 4. Calculate authoritative exit timestamp and parking fee on the server
    $exitTime = date('Y-m-d H:i:s');
    $feeData  = calculateParkingFee(
        $tx['entry_time'],
        $exitTime,
        $tx['vehicle_type'],
        $isLostTicket
    );
    $amountDue = $feeData['total_amount'];

    // 5. Record the payment in public.payment FIRST
    $stmtInsertPayment = $pdo->prepare("
        INSERT INTO public.payment (transaction_id, amount, payment_method, payment_time)
        VALUES (:transaction_id, :amount, :payment_method, :payment_time)
        RETURNING payment_id
    ");
    $stmtInsertPayment->execute([
        ':transaction_id' => $transactionId,
        ':amount'         => $amountDue,
        ':payment_method' => $paymentMethod,
        ':payment_time'   => $exitTime
    ]);
    $paymentId = (int)$stmtInsertPayment->fetchColumn();

    if ($paymentId <= 0) {
        throw new Exception('Failed to record payment in the database.');
    }

    // 6. After successful payment insertion, mark the transaction as Completed and record exit_time
    $stmtUpdateTx = $pdo->prepare("
        UPDATE public.\"transaction\"
        SET exit_time      = :exit_time,
            status         = 'Completed',
            is_lost_ticket = :is_lost_ticket
        WHERE transaction_id = :transaction_id
    ");
    $stmtUpdateTx->bindValue(':exit_time', $exitTime, PDO::PARAM_STR);
    $stmtUpdateTx->bindValue(':is_lost_ticket', $isLostTicket, PDO::PARAM_BOOL);
    $stmtUpdateTx->bindValue(':transaction_id', $transactionId, PDO::PARAM_INT);
    $stmtUpdateTx->execute();

    // 7. Decrease the occupied parking-space count by 1 (never dropping below 0)
    $stmtUpdateZone = $pdo->prepare("
        UPDATE public.parking_zone
        SET current_active_count = GREATEST(0, current_active_count - 1)
        WHERE zone_id = :zone_id
    ");
    $stmtUpdateZone->execute([':zone_id' => (int)$tx['zone_id']]);

    // Commit all operations together
    $pdo->commit();

    setFlash(
        'success',
        "Payment of ₱" . number_format($amountDue, 2) . " ({$paymentMethod}) recorded under Receipt #{$paymentId}! Vehicle {$tx['license_plate']} is now cleared to exit."
    );
    header('Location: ' . BASE_URL . '/modules/payments/history.php?receipt_id=' . $paymentId);
    exit;

} catch (Exception $e) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    setFlash('danger', $e->getMessage());
    header('Location: ' . BASE_URL . '/modules/payments/index.php');
    exit;
}
?>
