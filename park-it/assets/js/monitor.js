/**
 * File: park-it/assets/js/monitor.js
 * Purpose: Real-time AJAX Polling for Module 3 Parking Monitoring Dashboard
 */

document.addEventListener('DOMContentLoaded', function () {
    const POLL_INTERVAL_MS = 3000; // Poll every 3 seconds

    const elTotalCapacity = document.getElementById('stat-total-capacity');
    const elOccupiedSpaces = document.getElementById('stat-occupied-spaces');
    const elAvailableSpaces = document.getElementById('stat-available-spaces');
    const elActiveVehicles = document.getElementById('stat-active-vehicles');
    const elStatusBadge = document.getElementById('stat-status-badge');
    const elCardOccupied = document.getElementById('card-occupied');
    const elCardAvailable = document.getElementById('card-available');
    const elCardStatus = document.getElementById('card-status');
    const elWarningContainer = document.getElementById('monitoring-warning-container');
    const elOccupancyLabel = document.getElementById('occupancy-label');
    const elProgressBar = document.getElementById('occupancy-progress-bar');
    const elZonesTbody = document.getElementById('zones-table-body');
    const elActiveCount = document.getElementById('active-table-count');
    const elActiveTbody = document.getElementById('active-vehicles-tbody');
    const elLastUpdated = document.getElementById('last-updated-time');
    const elBtnRegister = document.getElementById('btn-register-vehicle');
    const elBtnRefresh = document.getElementById('btn-manual-refresh');

    /**
     * Escape HTML characters to prevent XSS when rendering JSON strings into the DOM
     */
    function escapeHtml(str) {
        if (str === null || str === undefined) return '';
        return String(str)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#039;');
    }

    /**
     * Fetch latest parking status from api_status.php and update the DOM
     */
    function fetchParkingStatus() {
        fetch(MONITOR_API_URL, {
            method: 'GET',
            headers: { 'Accept': 'application/json' },
            cache: 'no-store'
        })
            .then(function (response) {
                if (!response.ok) {
                    throw new Error('HTTP error ' + response.status);
                }
                return response.json();
            })
            .then(function (data) {
                if (!data || !data.success) {
                    return;
                }

                // 1. Update core numerical counters
                elTotalCapacity.textContent = data.total_capacity;
                elOccupiedSpaces.textContent = data.occupied_spaces;
                elAvailableSpaces.textContent = data.available_spaces;
                elActiveVehicles.textContent = data.active_vehicles;
                elLastUpdated.textContent = data.last_updated;

                // 2. Update Status Badge & Card Accent Borders
                elStatusBadge.textContent = data.status_text;
                elStatusBadge.className = 'badge ' + (
                    data.status_code === 'full' ? 'badge-danger' :
                        (data.status_code === 'warning' ? 'badge-warning' : 'badge-active')
                );

                elCardOccupied.className = 'stat-card ' + (
                    data.status_code === 'full' ? 'danger' :
                        (data.status_code === 'warning' ? 'warning' : '')
                );

                elCardAvailable.className = 'stat-card ' + (
                    data.status_code === 'full' ? 'danger' :
                        (data.status_code === 'warning' ? 'warning' : 'success')
                );

                elCardStatus.className = 'stat-card ' + (
                    data.status_code === 'full' ? 'danger' :
                        (data.status_code === 'warning' ? 'warning' : 'success')
                );

                // 3. Show / Update / Remove Warning Banners dynamically
                // - warning_type === 'full': All 50 spaces occupied
                // - warning_type === 'low' : 1 to 10 spaces remaining
                // - warning_type === 'none': More than 10 spaces available -> remove warning
                if (data.warning_type === 'full') {
                    elWarningContainer.innerHTML =
                        '<div class="alert alert-danger" id="monitoring-warning-box">' +
                        escapeHtml(data.warning_message) +
                        '</div>';
                } else if (data.warning_type === 'low') {
                    elWarningContainer.innerHTML =
                        '<div class="alert alert-warning" id="monitoring-warning-box">' +
                        escapeHtml(data.warning_message) +
                        '</div>';
                } else {
                    // Remove warning when available spaces increase above 10
                    elWarningContainer.innerHTML = '';
                }

                // 4. Enable or Disable the "+ Register Incoming Vehicle" button when full
                if (elBtnRegister) {
                    if (data.available_spaces <= 0) {
                        elBtnRegister.classList.add('disabled');
                        elBtnRegister.setAttribute('aria-disabled', 'true');
                        elBtnRegister.textContent = 'Lot Full (Entry Disabled)';
                    } else {
                        elBtnRegister.classList.remove('disabled');
                        elBtnRegister.removeAttribute('aria-disabled');
                        elBtnRegister.textContent = '+ Register Incoming Vehicle';
                    }
                }

                // 5. Update Occupancy Progress Bar
                const pct = Number(data.occupancy_percent) || 0;
                elOccupancyLabel.textContent =
                    data.occupied_spaces + ' / ' + data.total_capacity + ' Spaces Occupied (' + pct + '%)';
                elProgressBar.style.width = Math.max(3, pct) + '%';
                elProgressBar.textContent = pct + '%';
                elProgressBar.className = 'progress-bar ' + (
                    data.status_code === 'full' ? 'danger' :
                        (data.status_code === 'warning' ? 'warning' : '')
                );

                // 6. Update Parking Zone Breakdown Table
                if (Array.isArray(data.zones) && elZonesTbody) {
                    if (data.zones.length === 0) {
                        elZonesTbody.innerHTML =
                            '<tr><td colspan="6" style="text-align:center; color:#64748b;">No parking zones configured.</td></tr>';
                    } else {
                        let zonesHtml = '';
                        data.zones.forEach(function (z) {
                            let badgeHtml = '<span class="badge badge-active">AVAILABLE</span>';
                            if (z.available_spaces === 0) {
                                badgeHtml = '<span class="badge badge-danger">FULL</span>';
                            } else if (z.available_spaces <= 10) {
                                badgeHtml = '<span class="badge badge-warning">LOW SPACE (' + z.available_spaces + ' left)</span>';
                            }

                            zonesHtml += '<tr>' +
                                '<td>#' + Number(z.zone_id) + '</td>' +
                                '<td><strong>' + escapeHtml(z.zone_name) + '</strong></td>' +
                                '<td>' + Number(z.max_capacity) + '</td>' +
                                '<td>' + Number(z.current_active_count) + '</td>' +
                                '<td><strong>' + Number(z.available_spaces) + '</strong></td>' +
                                '<td>' + badgeHtml + '</td>' +
                                '</tr>';
                        });
                        elZonesTbody.innerHTML = zonesHtml;
                    }
                }

                // 7. Update Active Parked Vehicles Table
                if (Array.isArray(data.active_list) && elActiveTbody) {
                    elActiveCount.textContent = data.active_list.length;

                    if (data.active_list.length === 0) {
                        elActiveTbody.innerHTML =
                            '<tr><td colspan="8" style="text-align:center; color:#64748b;">No vehicles are currently parked in the lot.</td></tr>';
                    } else {
                        let activeHtml = '';
                        data.active_list.forEach(function (item) {
                            const typeClass = item.vehicle_type === 'Car' ? 'badge-car' : 'badge-motorcycle';
                            const exitUrl = PAYMENT_BASE_URL + '?plate=' + encodeURIComponent(item.license_plate);

                            activeHtml += '<tr>' +
                                '<td>#' + Number(item.transaction_id) + '</td>' +
                                '<td><strong>' + escapeHtml(item.license_plate) + '</strong></td>' +
                                '<td><span class="badge ' + typeClass + '">' + escapeHtml(item.vehicle_type) + '</span></td>' +
                                '<td>' + escapeHtml(item.zone_name) + '</td>' +
                                '<td>' + escapeHtml(item.entry_time_display) + '</td>' +
                                '<td>' + escapeHtml(item.duration_formatted) + '</td>' +
                                '<td>&#8369;' + escapeHtml(item.current_fee) + '</td>' +
                                '<td><a href="' + exitUrl + '" class="btn btn-sm btn-primary">Process Exit</a></td>' +
                                '</tr>';
                        });
                        elActiveTbody.innerHTML = activeHtml;
                    }
                }
            })
            .catch(function (err) {
                console.error('Monitoring poll error:', err);
            });
    }

    // Trigger manual refresh when button is clicked
    if (elBtnRefresh) {
        elBtnRefresh.addEventListener('click', function () {
            fetchParkingStatus();
        });
    }

    // Start automatic polling every 3 seconds
    setInterval(fetchParkingStatus, POLL_INTERVAL_MS);
});