async function fetchData() {
    // اصلاح کنید:
const response = await fetch('https://rama-company.github.io/viral-kan-system/data/predictions.csv');
    return await response.text();
}

function processData(csv) {
    const rows = csv.split('\n');
    const headers = rows[0].split(',');
    const data = [];
    
    for (let i = 1; i < rows.length; i++) {
        const row = rows[i].split(',');
        if (row.length === headers.length) {
            const item = {};
            headers.forEach((header, idx) => {
                item[header.trim()] = row[idx].trim();
            });
            data.push(item);
        }
    }
    return data;
}

function renderCharts(data) {
    // گروه‌بندی بر اساس هشتگ
    const hashtagData = {};
    data.forEach(item => {
        if (!hashtagData[item.hashtag]) {
            hashtagData[item.hashtag] = [];
        }
        hashtagData[item.hashtag].push(parseFloat(item.viral_prob));
    });
    
    // محاسبه میانگین
    const hashtagAverages = [];
    for (const hashtag in hashtagData) {
        const avg = hashtagData[hashtag].reduce((a, b) => a + b, 0) / hashtagData[hashtag].length;
        hashtagAverages.push({
            hashtag,
            avg
        });
    }
    
    // مرتب‌سازی
    hashtagAverages.sort((a, b) => b.avg - a.avg);
    
    // رندر لیست هشتگ‌ها
    const hashtagList = document.getElementById('hashtagList');
    hashtagList.innerHTML = '';
    
    hashtagAverages.slice(0, 5).forEach(item => {
        const el = document.createElement('div');
        el.className = 'hashtag-item';
        el.innerHTML = `
            <strong>${item.hashtag}</strong>
            <span>${item.avg.toFixed(1)}%</span>
        `;
        hashtagList.appendChild(el);
    });
    
    // رندر نمودار
    const ctx = document.getElementById('trendChart').getContext('2d');
    new Chart(ctx, {
        type: 'bar',
        data: {
            labels: hashtagAverages.slice(0, 5).map(i => i.hashtag),
            datasets: [{
                label: 'Viral Probability',
                data: hashtagAverages.slice(0, 5).map(i => i.avg),
                backgroundColor: '#4a90e2'
            }]
        }
    });
}

async function init() {
    const csv = await fetchData();
    const data = processData(csv);
    renderCharts(data);
}

document.addEventListener('DOMContentLoaded', init);
