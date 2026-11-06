<?php
/**
 * File: park-it/modules/payments/history.php
 * Purpose: Display Payment Records, Completed Transaction History, Exit Receipts, and Safe Payment Method Updates
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../includes/functions.php';

requireLogin();

// ============================================================================
// HANDLE SAFE PAYMENT METHOD CORRECTION (CRUD - UPDATE)
// ============================================================================
if ($_SERVER['REQUEST_METHOD'] === 'POST' && ($_POST['action'] ?? '') === 'update_payment_method') {
    $paymentId     = (int)($_POST['payment_id'] ?? 0);
    $paymentMethod = trim($_POST['payment_method'] ?? '');
    $allowedMethods = ['Cash', 'GCash', 'Maya', 'Credit/Debit Card'];

    if ($paymentId <= 0 || !in_array($paymentMethod, $allowedMethods, true)) {
        setFlash('danger', 'Invalid payment ID or payment method selected.');
    } else {
        $stmtUpd = $pdo->prepare("
            UPDATE public.payment
            SET payment_method = :payment_method
            WHERE payment_id = :payment_id
        ");
        $stmtUpd->execute([
            ':payment_method' => $paymentMethod,
            ':payment_id'     => $paymentId
        ]);
        setFlash('success', "Payment Record #{$paymentId} payment method updated to '{$paymentMethod}'. Amount and timestamps remain locked to preserve audit integrity.");
    }

    header('Location: ' . BASE_URL . '/modules/payments/history.php?receipt_id=' . $paymentId);
    exit;
}

// ============================================================================
// FETCH SELECTED RECEIPT (IF VIEWING A SPECIFIC EXIT PASS / RECEIPT)
// ============================================================================
$receiptId = (int)($_GET['receipt_id'] ?? 0);
$editId    = (int)($_GET['edit_id'] ?? 0);
$receipt   = null;

if ($receiptId > 0) {
    $stmtReceipt = $pdo->prepare("
        SELECT p.payment_id, p.transaction_id, p.amount, p.payment_method, p.payment_time,
               t.entry_time, t.exit_time, t.status, t.is_lost_ticket,
               v.license_plate, v.vehicle_type,
               z.zone_name
        FROM public.payment p
        JOIN public.\"transaction\" t ON p.transaction_id = t.transaction_id
        JOIN public.vehicle v ON t.vehicle_id = v.vehicle_id
        JOIN public.parking_zone z ON t.zone_id = z.zone_id
        WHERE p.payment_id = :payment_id
        LIMIT 1
    ");
    $stmtReceipt->execute([':payment_id' => $receiptId]);
    $receipt = $stmtReceipt->fetch();
}

// ============================================================================
// FETCH ALL PAYMENT RECORDS & COMPLETED TRANSACTIONS (CRUD - READ)
// ============================================================================
$stmtHistory = $pdo->query("
    SELECT p.payment_id, p.transaction_id, p.amount, p.payment_method, p.payment_time,
           t.entry_time, t.exit_time, t.status, t.is_lost_ticket,
           v.license_plate, v.vehicle_type,
           z.zone_name
    FROM public.payment p
    JOIN public.\"transaction\" t ON p.transaction_id = t.transaction_id
    JOIN public.vehicle v ON t.vehicle_id = v.vehicle_id
    JOIN public.parking_zone z ON t.zone_id = z.zone_id
    ORDER BY p.payment_time DESC, p.payment_id DESC
");
$paymentHistory = $stmtHistory->fetchAll();

// Compute summary statistics
$totalPaymentsCount = count($paymentHistory);
$totalRevenueSum    = 0.00;
foreach ($paymentHistory as $row) {
    $totalRevenueSum += (float)$row['amount'];
}

$pageTitle = 'Payment & Exit History';
require_once __DIR__ . '/../../includes/header.php';
?>

<div class="page-header">
    <h1>Payment Records &amp; Completed Transactions</h1>
    <a href="<?= BASE_URL ?>/modules/payments/index.php" class="btn btn-primary">&larr; Back to Payment &amp; Exit</a>
</div>

<div class="stats-grid">
    <div class="stat-card success">
        <div class="stat-title">Total Revenue Collected</div>
        <div class="stat-value">&#8369;<?= number_format($totalRevenueSum, 2) ?></div>
        <div class="stat-sub">Verified in public.payment</div>
    </div>
    <div class="stat-card">
        <div class="stat-title">Completed Transactions</div>
        <div class="stat-value"><?= $totalPaymentsCount ?></div>
        <div class="stat-sub">Paid &amp; exited vehicles</div>
    </div>
</div>

<?php if ($receipt): 
    $receiptDuration = calculateParkingFee(
        $receipt['entry_time'],
        $receipt['exit_time'] ?? $receipt['payment_time'],
        $receipt['vehicle_type'],
        (bool)$receipt['is_lost_ticket']
    );
?>
    <!-- Official Exit Receipt & Gate Authorization Card -->
    <div class="card" style="border-left: 5px solid #16a34a; background-color: #f0fdf4;">
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px;">
            <h2 style="margin: 0; border: none; color: #166534;">
                Official Payment Receipt #<?= (int)$receipt['payment_id'] ?> — EXIT AUTHORIZED
            </h2>
            <a href="<?= BASE_URL ?>/modules/payments/history.php" class="btn btn-sm btn-secondary">Close Receipt</a>
        </div>

        <div class="table-responsive">
            <table style="background: #ffffff; border-radius: 6px;">
                <tbody>
                    <tr>
                        <th style="width: 25%;">Receipt / Payment ID</th>
                        <td style="width: 25%;"><strong>#<?= (int)$receipt['payment_id'] ?></strong></td>
                        <th style="width: 25%;">Transaction / Ticket #</th>
                        <td style="width: 25%;"><strong>#<?= (int)$receipt['transaction_id'] ?></strong></td>
                    </tr>
                    <tr>
                        <th>License Plate</th>
                        <td><strong><?= htmlspecialchars($receipt['license_plate']) ?></strong> (<?= htmlspecialchars($receipt['vehicle_type']) ?>)</td>
                        <th>Parking Zone</th>
                        <td><?= htmlspecialchars($receipt['zone_name']) ?></td>
                    </tr>
                    <tr>
                        <th>Entry Time</th>
                        <td><?= date('M d, Y h:i:s A', strtotime($receipt['entry_time'])) ?></td>
                        <th>Exit Time</th>
                        <td><?= date('M d, Y h:i:s A', strtotime($receipt['exit_time'])) ?></td>
                    </tr>
                    <tr>
                        <th>Parked Duration</th>
                        <td><?= htmlspecialchars($receiptDuration['duration_formatted']) ?></td>
                        <th>Ticket Classification</th>
                        <td>
                            <?php if ($receipt['is_lost_ticket']): ?>
                                <span class="badge" style="background:#fee2e2; color:#991b1b;">Lost Ticket (Flat &#8369;200.00)</span>
                            <?php else: ?>
                                <span class="badge badge-active">Regular Rate</span>
                            <?php endif; ?>
                        </td>
                    </tr>
                    <tr>
                        <th>Payment Method</th>
                        <td><strong><?= htmlspecialchars($receipt['payment_method']) ?></strong></td>
                        <th>Amount Paid</th>
                        <td style="font-size: 18px; font-weight: 700; color: #166534;">&#8369;<?= number_format((float)$receipt['amount'], 2) ?></td>
                    </tr>
                </tbody>
            </table>
        </div>
    </div>
<?php endif; ?>

<div class="card">
    <h2>Payment &amp; Exit Log (<?= $totalPaymentsCount ?>)</h2>
    <div class="table-responsive">
        <table>
            <thead>
                <tr>
                    <th>Receipt #</th>
                    <th>Ticket #</th>
                    <th>License Plate</th>
                    <th>Type</th>
                    <th>Entry Time</th>
                    <th>Exit Time</th>
                    <th>Ticket Note</th>
                    <th>Amount Paid</th>
                    <th>Method</th>
                    <th>Status</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody>
                <?php if (empty($paymentHistory)): ?>
                    <tr>
                        <td colspan="11" style="text-align: center; color: #64748b;">No completed payments recorded yet.</td>
                    </tr>
                <?php else: ?>
                    <?php foreach ($paymentHistory as $row): ?>
                        <tr>
                            <td><strong>#<?= (int)$row['payment_id'] ?></strong></td>
                            <td>#<?= (int)$row['transaction_id'] ?></td>
                            <td><strong><?= htmlspecialchars($row['license_plate']) ?></strong></td>
                            <td>
                                <span class="badge <?= $row['vehicle_type'] === 'Car' ? 'badge-car' : 'badge-motorcycle' ?>">
                                    <?= htmlspecialchars($row['vehicle_type']) ?>
                                </span>
                            </td>
                            <td><?= date('M d, Y h:i A', strtotime($row['entry_time'])) ?></td>
                            <td><?= $row['exit_time'] ? date('M d, Y h:i A', strtotime($row['exit_time'])) : '—' ?></td>
                            <td>
                                <?php if ($row['is_lost_ticket']): ?>
                                    <span class="badge" style="background:#fee2e2; color:#991b1b;">Lost Ticket</span>
                                <?php else: ?>
                                    <span style="color:#64748b; font-size:13px;">Standard</span>
                                <?php endif; ?>
                            </td>
                            <td><strong>&#8369;<?= number_format((float)$row['amount'], 2) ?></strong></td>
                            <td>
                                <?php if ($editId === (int)$row['payment_id']): ?>
                                    <form method="POST" action="<?= BASE_URL ?>/modules/payments/history.php" style="display:flex; gap:6px; align-items:center;">
                                        <input type="hidden" name="action" value="update_payment_method">
                                        <input type="hidden" name="payment_id" value="<?= (int)$row['payment_id'] ?>">
                                        <select name="payment_method" class="form-control" style="padding:4px 6px; font-size:12px; width:auto;">
                                            <?php foreach (['Cash', 'GCash', 'Maya', 'Credit/Debit Card'] as $m): ?>
                                                <option value="<?= $m ?>" <?= $row['payment_method'] === $m ? 'selected' : '' ?>><?= $m ?></option>
                                            <?php endforeach; ?>
                                        </select>
                                        <button type="submit" class="btn btn-sm btn-primary">Save</button>
                                        <a href="<?= BASE_URL ?>/modules/payments/history.php" class="btn btn-sm btn-secondary">Cancel</a>
                                    </form>
                                <?php else: ?>
                                    <?= htmlspecialchars($row['payment_method']) ?>
                                <?php endif; ?>
                            </td>
                            <td><span class="badge badge-active"><?= htmlspecialchars($row['status']) ?></span></td>
                            <td style="white-space: nowrap;">
                                <a href="<?= BASE_URL ?>/modules/payments/history.php?receipt_id=<?= (int)$row['payment_id'] ?>" class="btn btn-sm btn-primary">Receipt</a>
                                <a href="<?= BASE_URL ?>/modules/payments/history.php?edit_id=<?= (int)$row['payment_id'] ?>" class="btn btn-sm btn-secondary">Edit Method</a>
                                <button type="button" class="btn btn-sm" disabled title="Audit Protected: Completed payment and transaction records cannot be deleted">Audit Locked</button>
                            </td>
                        </tr>
                    <?php endforeach; ?>
                <?php endif; ?>
            </tbody>
        </table>
    </div>
</div>

<?php require_once __DIR__ . '/../../includes/footer.php'; ?>