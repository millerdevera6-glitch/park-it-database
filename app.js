
const form = document.getElementById('add-zone-form');
const tableBody = document.getElementById('zones-table-body');
const messageBox = document.getElementById('message');


function showMessage(message, isError = false) {
    messageBox.textContent = message;
    messageBox.style.color = isError ? 'red' : 'green';
}


async function apiRequest(url, options = {}) {
    const response = await fetch(url, options);

    const result = await response.json();

    if (!response.ok) {
        throw new Error(result.message || 'Something went wrong.');
    }

    return result;
}


async function loadZones() {
    try {
        const zones = await apiRequest('/api/zones');

        tableBody.innerHTML = '';

        if (zones.length === 0) {
            tableBody.innerHTML = `
                <tr>
                    <td colspan="5">No parking zones available.</td>
                </tr>
            `;
            return;
        }

        zones.forEach(zone => {
            const row = document.createElement('tr');

            const values = [
                zone.zone_id,
                zone.zone_name,
                zone.max_capacity,
                zone.current_active_count
            ];

            values.forEach(value => {
                const cell = document.createElement('td');
                cell.textContent = value;
                row.appendChild(cell);
            });

            const actions = document.createElement('td');

            const updateButton = document.createElement('button');
            updateButton.textContent = 'Update';
            updateButton.className = 'update-btn';
            updateButton.onclick = () => updateZone(zone);

            const parkButton = document.createElement('button');
            parkButton.textContent = 'Park Vehicle (+1)';
            parkButton.onclick = () => parkVehicle(zone.zone_id);

            const deleteButton = document.createElement('button');
            deleteButton.textContent = 'Delete';
            deleteButton.className = 'delete-btn';
            deleteButton.onclick = () => deleteZone(zone.zone_id);

            actions.append(updateButton, parkButton, deleteButton);
            row.appendChild(actions);

            tableBody.appendChild(row);
        });

    } catch (error) {
        showMessage(error.message, true);
    }
}

form.addEventListener('submit', async (event) => {
    event.preventDefault();

    const zoneName = document.getElementById('zoneName').value.trim();
    const maxCapacity = Number(
        document.getElementById('maxCapacity').value
    );

    if (!zoneName || !Number.isInteger(maxCapacity) || maxCapacity <= 0) {
        showMessage('Enter a valid zone name and capacity.', true);
        return;
    }

    try {
        await apiRequest('/api/zones', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                zone_name: zoneName,
                max_capacity: maxCapacity
            })
        });

        form.reset();
        showMessage('Parking zone created successfully!');

        await loadZones();

    } catch (error) {
        showMessage(error.message, true);
    }
});


async function updateZone(zone) {
    const newName = prompt('Enter new zone name:', zone.zone_name);

    if (newName === null) return;

    if (!newName.trim()) {
        showMessage('Zone name cannot be empty.', true);
        return;
    }

    const newCapacity = prompt(
        'Enter new maximum capacity:',
        zone.max_capacity
    );

    if (newCapacity === null) return;

    const capacity = Number(newCapacity);

    if (!Number.isInteger(capacity) || capacity <= 0) {
        showMessage('Capacity must be a positive whole number.', true);
        return;
    }

    try {
        await apiRequest(`/api/zones/${zone.zone_id}`, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                zone_name: newName.trim(),
                max_capacity: capacity
            })
        });

        showMessage('Parking zone updated successfully!');
        await loadZones();

    } catch (error) {
        showMessage(error.message, true);
    }
}


async function parkVehicle(id) {
    try {
        await apiRequest(`/api/zones/${id}/park`, {
            method: 'PUT'
        });

        showMessage('Vehicle parked successfully!');
        await loadZones();

    } catch (error) {
        showMessage(error.message, true);
    }
}


async function deleteZone(id) {
    if (!confirm('Are you sure you want to delete this parking zone?')) {
        return;
    }

    try {
        await apiRequest(`/api/zones/${id}`, {
            method: 'DELETE'
        });

        showMessage('Parking zone deleted successfully!');
        await loadZones();

    } catch (error) {
        showMessage(error.message, true);
    }
}


document.addEventListener('DOMContentLoaded', loadZones);
