
async function loadZones() {
    const response = await fetch('/api/zones');
    const zones = await response.json();
    const tableBody = document.getElementById('zones-table-body');
    
    tableBody.innerHTML = ''; // Clear old data

    zones.forEach(zone => {
        tableBody.innerHTML += `
            <tr>
                <td>${zone.zone_id}</td>
                <td>${zone.zone_name}</td>
                <td>${zone.max_capacity}</td>
                <td>${zone.current_active_count}</td>
                <td>
                    <button onclick="parkVehicle(${zone.zone_id})">Park Vehicle (+1)</button>
                    <button style="color:red;" onclick="deleteZone(${zone.zone_id})">Delete</button>
                </td>
            </tr>
        `;
    });
}


document.getElementById('add-zone-form').addEventListener('submit', async (e) => {
    e.preventDefault(); // Stop page refresh
    
    const zoneName = document.getElementById('zoneName').value;
    const maxCapacity = document.getElementById('maxCapacity').value;

    await fetch('/api/zones', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ zone_name: zoneName, max_capacity: maxCapacity })
    });

    document.getElementById('add-zone-form').reset(); // Clear inputs
    loadZones(); // Refresh table
});

async function parkVehicle(id) {
    await fetch(`/api/zones/${id}/park`, { method: 'PUT' });
    loadZones(); // Refresh table to show new count
}


async function deleteZone(id) {
    if (confirm('Are you sure you want to delete this zone?')) {
        await fetch(`/api/zones/${id}`, { method: 'DELETE' });
        loadZones(); // Refresh table
    }
}


document.addEventListener('DOMContentLoaded', loadZones);