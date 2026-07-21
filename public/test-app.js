const API_BASE = window.location.origin + '/api';
let authHeader = '';
let chartInstance = null;

document.addEventListener('DOMContentLoaded', async () => {
    const username = prompt('Username:');
    const password = prompt('Password:');
    authHeader = 'Basic ' + btoa(`${username}:${password}`);

    await loadNetworkInfo();

    document.getElementById('channelSelect').addEventListener('change', loadChaincodes);
    document.getElementById('runTestBtn').addEventListener('click', runTest);
});

async function loadNetworkInfo() {
    try {
        const response = await fetch(`${API_BASE}/network/info`, {
            headers: { 'Authorization': authHeader }
        });

        if (!response.ok) throw new Error('Authentication failed');

        const data = await response.json();

        const orgSelect = document.getElementById('orgSelect');
        data.organizations.forEach(org => {
            const opt = document.createElement('option');
            opt.value = org.orgNumber;
            opt.textContent = `${org.name} (Org${org.orgNumber})`;
            orgSelect.appendChild(opt);
        });

        const channelSelect = document.getElementById('channelSelect');
        data.channels.forEach(channel => {
            const opt = document.createElement('option');
            opt.value = channel;
            opt.textContent = channel;
            channelSelect.appendChild(opt);
        });

        await loadChaincodes();
    } catch (error) {
        alert('خطا در بارگذاری اطلاعات شبکه: ' + error.message);
    }
}

async function loadChaincodes() {
    const channel = document.getElementById('channelSelect').value;
    const chaincodeSelect = document.getElementById('chaincodeSelect');
    chaincodeSelect.innerHTML = '';

    try {
        const response = await fetch(`${API_BASE}/channels/${channel}`, {
            headers: { 'Authorization': authHeader }
        });
        const data = await response.json();

        data.chaincodes.forEach(cc => {
            const opt = document.createElement('option');
            opt.value = cc;
            opt.textContent = cc;
            chaincodeSelect.appendChild(opt);
        });
    } catch (error) {
        console.error('Failed to load chaincodes:', error);
    }
}

async function runTest() {
    const tool = document.getElementById('toolSelect').value;
    const scenario = document.getElementById('scenarioSelect').value;
    const channel = document.getElementById('channelSelect').value;
    const chaincode = document.getElementById('chaincodeSelect').value;
    const iotCount = parseInt(document.getElementById('iotCount').value);
    const userCount = parseInt(document.getElementById('userCount').value);
    const tps = parseInt(document.getElementById('tpsTarget').value);
    const duration = parseInt(document.getElementById('duration').value);
    const org = parseInt(document.getElementById('orgSelect').value);

    document.getElementById('runTestBtn').disabled = true;
    document.getElementById('loadingSpinner').style.display = 'block';
    document.getElementById('resultsSection').style.display = 'none';

    try {
        const response = await fetch(`${API_BASE}/test/execute`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': authHeader
            },
            body: JSON.stringify({
                tool, scenario, channel, chaincode,
                iotCount, userCount, tps, duration, org
            })
        });

        if (!response.ok) {
            const error = await response.json();
            throw new Error(error.error || response.statusText);
        }

        const results = await response.json();
        displayResults(results);
    } catch (error) {
        alert('خطا در اجرای تست: ' + error.message);
    } finally {
        document.getElementById('runTestBtn').disabled = false;
        document.getElementById('loadingSpinner').style.display = 'none';
    }
}

function displayResults(results) {
    document.getElementById('resultsSection').style.display = 'block';

    // قرارداد پاسخ سرور (toUiShape در index.js):
    // { success(bool), tps, latency:{avg,min,max}, successCount, failedCount, stdout, stderr, meta }
    const tps = Number(results.tps) || 0;
    const lat = (results.latency && Number(results.latency.avg)) || 0;
    document.getElementById('resultTps').textContent = tps.toFixed(2);
    document.getElementById('resultLatency').textContent = lat.toFixed(2);

    const okCount = Number(results.successCount) || 0;
    const failCount = Number(results.failedCount) || 0;
    const total = okCount + failCount;
    const successRate = total > 0 ? ((okCount / total) * 100).toFixed(2) : '0';
    document.getElementById('resultSuccess').textContent = `${successRate}%`;
    document.getElementById('resultFailed').textContent = failCount;

    if (results.success === false && results.stderr) {
        console.error('Test tool stderr:', results.stderr);
        alert('تست با خطا تمام شد — جزئیات در کنسول مرورگر (stderr ابزار تست).');
    }

    if (chartInstance) {
        chartInstance.destroy();
    }

    const ctx = document.getElementById('performanceChart').getContext('2d');
    chartInstance = new Chart(ctx, {
        type: 'bar',
        data: {
            labels: ['موفق', 'ناموفق', 'TPS', 'Latency (ms)'],
            datasets: [{
                label: 'نتایج تست',
                data: [okCount, failCount, tps, lat],
                backgroundColor: ['#4CAF50', '#f44336', '#2196F3', '#FF9800']
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: true,
            scales: {
                y: {
                    beginAtZero: true
                }
            }
        }
    });
}
