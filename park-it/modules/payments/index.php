<?php
/**
 * File: park-it/modules/payments/index.php
 * Purpose: Module 2 - Search Active Vehicle, Compute Parking Fee / Lost Ticket Fee, and Initiate Payment
 */

$pageTitle = 'Module 2: Payment & Vehicle Exit';
require_once __DIR__ . '/../../includes/header.php';

$searchPlate   = strtoupper(trim($_GET['plate'] ?? ''));
$isLostTicket  = isset($_GET['lost_ticket']) && $_GET['lost_ticket'] === '1';
$activeRecord  = null;
$feeDetails    = null;
$searchError   = '';
$currentExitTime = date('Y-m-d H:i:s');

// If a license plate was searched, retrieve its active parking transaction
if ($searchPlate !== '') {
    $stmt = $pdo->prepare("
        SELECT t.transaction_id, t.vehicle_id, t.zone_id, t.entry_time, t.status, t.is_lost_ticket,
               v.license_plate, v.vehicle_type,
               z.zone_name
        FROM public.\"transaction\" t
        JOIN public.vehicle v ON t.vehicle_id = v.vehicle_id
        JOIN public.parking_zone z ON t.zone_id = z.zone_id
        WHERE UPPER(v.license_plate) = :license_plate
          AND t.status = 'Active'
        ORDER BY t.entry_time DESC
        LIMIT 1
    ");
    $stmt->execute([':license_plate' => $searchPlate]);
    $activeRecord = $stmt->fetch();

    if (!$activeRecord) {
        $searchError = "No active parking transaction found for license plate '{$searchPlate}'. Verify the plate number or check if the vehicle has already exited.";
    } else {
        // Use the GET toggle if provided, otherwise fall back to the DB flag
        if (!isset($_GET['lost_ticket'])) {
            $isLostTicket = (bool)$activeRecord['is_lost_ticket'];
        }

        $feeDetails = calculateParkingFee(
            $activeRecord['entry_time'],
            $currentExitTime,
            $activeRecord['vehicle_type'],
            $isLostTicket
        );
    }
}

// Fetch all currently active vehicles for quick selection
$stmtAllActive = $pdo->query("
    SELECT t.transaction_id, t.entry_time,
           v.license_plate, v.vehicle_type,
           z.zone_name
    FROM public.\"transaction\" t
    JOIN public.vehicle v ON t.vehicle_id = v.vehicle_id
    JOIN public.parking_zone z ON t.zone_id = z.zone_id
    WHERE t.status = 'Active'
    ORDER BY t.entry_time ASC
");
$allActiveList = $stmtAllActive->fetchAll();
?>

<div class="page-header">
    <h1>Module 2: Payment &amp; Vehicle Exit</h1>
    <a href="<?= BASE_URL ?>/modules/payments/history.php" class="btn btn-secondary">View Payment &amp; Exit History</a>
</div>

<!-- Parking Fee Tariff Reference Card -->
<div class="card" style="padding: 16px 22px;">
    <div style="display: flex; flex-wrap: wrap; justify-content: space-between; align-items: center; gap: 12px; font-size: 14px;">
        <div><strong>Official Parking Fee Rates:</strong></div>
        <div><span class="badge badge-car">Car</span> First 3 Hours: <strong>&#8369;50.00</strong> | Succeeding Hours: <strong>+&#8369;10.00/hr</strong></div>
        <div><span class="badge badge-motorcycle">Motorcycle</span> First 3 Hours: <strong>&#8369;30.00</strong> | Succeeding Hours: <strong>+&#8369;10.00/hr</strong></div>
        <div><span class="badge" style="background:#fee2e2; color:#991b1b;">Lost Ticket</span> Flat Fee: <strong>&#8369;200.00</strong> (Replaces regular fee)</div>
    </div>
</div>

<?php if ($searchError): ?>
    <div class="alert alert-danger"><?= htmlspecialchars($searchError) ?></div>
<?php endif; ?>

<div class="content-grid">
    <!-- Left Column: Vehicle Search Form -->
    <div>
        <div class="card">
            <h2>1. Search Active Vehicle</h2>
            <form method="GET" action="<?= BASE_URL ?>/modules/payments/index.php">
                <div class="form-group">
                    <label for="plate">License Plate Number *</label>
                    <input
                        type="text"
                        id="plate"
                        name="plate"
                        class="form-control"
                        placeholder="Enter plate (e.g. ABC-1234)"
                        maxlength="20"
                        value="<?= htmlspecialchars($searchPlate) ?>"
                        required
                        autofocus
                    >
                </div>
                <button type="submit" class="btn btn-primary btn-block">Search Active Transaction</button>
                <?php if ($searchPlate !== ''): ?>
                    <a href="<?= BASE_URL ?>/modules/payments/index.php" class="btn btn-secondary btn-block" style="margin-top: 8px;">Clear Search</a>
                <?php endif; ?>
            </form>
        </div>

        <!-- Quick-Select List of Currently Parked Vehicles -->
        <div class="card">
            <h2>Currently Parked Vehicles (<?= count($allActiveList) ?>)</h2>
            <div class="table-responsive">
                <table>
                    <thead>
                        <tr>
                            <th>Plate</th>
                            <th>Type</th>
                            <th>Entry Time</th>
                            <th>Select</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php if (empty($allActiveList)): ?>
                            <tr>
                                <td colspan="4" style="text-align: center; color: #64748b;">No active vehicles in the lot.</td>
                            </tr>
                        <?php else: ?>
                            <?php foreach ($allActiveList as $item): ?>
                                <tr>
                                    <td><strong><?= htmlspecialchars($item['license_plate']) ?></strong></td>
                                    <td><?= htmlspecialchars($item['vehicle_type']) ?></td>
                                    <td><?= date('h:i A', strtotime($item['entry_time'])) ?></td>
                                    <td>
                                        <a href="<?= BASE_URL ?>/modules/payments/index.php?plate=<?= urlencode($item['license_plate']) ?>" class="btn btn-sm btn-primary">
                                            Select
                                        </a>
                                    </td>
                                </tr>
                            <?php endforeach; ?>
                        <?php endif; ?>
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    <!-- Right Column: Fee Computation & Payment Processing -->
    <div class="card">
        <h2>2. Parking Fee Computation &amp; Checkout</h2>

        <?php if (!$activeRecord): ?>
            <p style="color: #64748b; padding: 20px 0;">
                Search for a vehicle's license plate number on the left (or click <strong>Select</strong> next to a currently parked vehicle) to compute its parking duration and process payment.
            </p>
        <?php else: ?>
            <!-- Lost Ticket Toggle Bar -->
            <div style="background: #f8fafc; border: 1px solid #cbd5e1; padding: 14px 16px; border-radius: 6px; margin-bottom: 20px; display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 10px;">
                <div>
                    <strong>Ticket Status:</strong>
                    <?php if ($isLostTicket): ?>
                        <span class="badge" style="background:#fee2e2; color:#991b1b; margin-left: 6px;">LOST TICKET OVERRIDE APPLIED (Flat &#8369;200.00)</span>
                    <?php else: ?>
                        <span class="badge badge-active" style="margin-left: 6px;">Standard Ticket Present</span>
                    <?php endif; ?>
                </div>
                <div>
                    <?php if ($isLostTicket): ?>
                        <a href="<?= BASE_URL ?>/modules/payments/index.php?plate=<?= urlencode($activeRecord['license_plate']) ?>&amp;lost_ticket=0" class="btn btn-sm btn-secondary">
                            Revert to Regular Fee
                        </a>
                    <?php else: ?>
                        <a href="<?= BASE_URL ?>/modules/payments/index.php?plate=<?= urlencode($activeRecord['license_plate']) ?>&amp;lost_ticket=1" class="btn btn-sm btn-danger">
                            Mark as Lost Ticket (&#8369;200.00)
                        </a>
                    <?php endif; ?>
                </div>
            </div>

            <!-- Transaction & Fee Summary Table -->
            <div class="table-responsive" style="margin-bottom: 20px;">
                <table>
                    <tbody>
                        <tr>
                            <th style="width: 38%;">Transaction / Ticket #</th>
                            <td><strong>#<?= (int)$activeRecord['transaction_id'] ?></strong></td>
                        </tr>
                        <tr>
                            <th>License Plate Number</th>
                            <td><strong style="font-size: 16px;"><?= htmlspecialchars($activeRecord['license_plate']) ?></strong></td>
                        </tr>
                        <tr>
                            <th>Vehicle Type</th>
                            <td>
                                <span class="badge <?= $activeRecord['vehicle_type'] === 'Car' ? 'badge-car' : 'badge-motorcycle' ?>">
                                    <?= htmlspecialchars($activeRecord['vehicle_type']) ?>
                                </span>
                            </td>
                        </tr>
                        <tr>
                            <th>Assigned Parking Zone</th>
                            <td><?= htmlspecialchars($activeRecord['zone_name']) ?></td>
                        </tr>
                        <tr>
                            <th>Entry Date &amp; Time</th>
                            <td><?= date('M d, Y h:i:s A', strtotime($activeRecord['entry_time'])) ?></td>
                        </tr>
                        <tr>
                            <th>Current Exit Date &amp; Time</th>
                            <td><?= date('M d, Y h:i:s A', strtotime($currentExitTime)) ?></td>
                        </tr>
                        <tr>
                            <th>Total Parking Duration</th>
                            <td>
                                <strong><?= htmlspecialchars($feeDetails['duration_formatted']) ?></strong>
                                (Billed as <?= (int)$feeDetails['billed_hours'] ?> hour<?= $feeDetails['billed_hours'] > 1 ? 's' : '' ?>)
                            </td>
                        </tr>
                        <tr>
                            <th>Fee Breakdown</th>
                            <td>
                                <?php if ($feeDetails['is_lost_ticket']): ?>
                                    <span style="color: #991b1b; font-weight: 600;">
                                        Lost Ticket Penalty: Flat &#8369;200.00 (Replaces regular &#8369;<?= number_format($feeDetails['regular_fee'], 2) ?> fee)
                                    </span>
                                <?php else: ?>
                                    First 3 Hours (<?= htmlspecialchars($activeRecord['vehicle_type']) ?>): &#8369;<?= number_format($feeDetails['base_rate'], 2) ?>
                                    <?php if ($feeDetails['succeeding_hours'] > 0): ?>
                                        <br>+ Succeeding Hours (<?= (int)$feeDetails['succeeding_hours'] ?> hr &times; &#8369;10.00): &#8369;<?= number_format($feeDetails['succeeding_fee'], 2) ?>
                                    <?php endif; ?>
                                <?php endif; ?>
                            </td>
                        </tr>
                        <tr style="background-color: #eff6ff;">
                            <th style="font-size: 16px; color: #1e3a8a;">TOTAL AMOUNT DUE</th>
                            <td style="font-size: 22px; font-weight: 700; color: #1e3a8a;">
                                &#8369;<?= number_format($feeDetails['total_amount'], 2) ?>
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>

            <!-- Payment Confirmation Form -->
            <form method="POST" action="<?= BASE_URL ?>/modules/payments/process.php" onsubmit="return confirm('Confirm payment of ₱<?= number_format($feeDetails['total_amount'], 2) ?> and authorize exit for <?= htmlspecialchars($activeRecord['license_plate']) ?>?');">
                <input type="hidden" name="transaction_id" value="<?= (int)$activeRecord['transaction_id'] ?>">
                <input type="hidden" name="is_lost_ticket" value="<?= $isLostTicket ? '1' : '0' ?>">

                <div class="form-group">
                    <label for="payment_method">Select Payment Method *</label>
                    <select id="payment_method" name="payment_method" class="form-control" required>
                        <option value="">-- Choose Payment Method --</option>
                        <option value="Cash">Cash</option>
                        <option value="GCash">GCash</option>
                        <option value="Maya">Maya</option>
                        <option value="Credit/Debit Card">Credit/Debit Card</option>
                    </select>
                </div>

                <button type="submit" class="btn btn-primary btn-block" style="font-size: 15px; padding: 12px;">
                    Record Payment (&#8369;<?= number_format($feeDetails['total_amount'], 2) ?>) &amp; Authorize Vehicle Exit
                </button>
            </form>
        <?php endif; ?>
    </div>
</div>

<?php require_once __DIR__ . '/../../includes/footer.php'; ?>