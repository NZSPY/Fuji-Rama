document.addEventListener('DOMContentLoaded', () => {
    const tableBody = document.getElementById('dataTableBody');
    const apiUrl = 'http://192.168.68.100:8080/tables'; // Replace with your actual API endpoint

    async function fetchDataAndPopulateTable() {
        try {
            const response = await fetch(apiUrl);
            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }
            const data = await response.json();

            // Assuming data is an array of objects, and each object represents a row
            // and its keys represent column headers.
            if (data.length > 0) {
                // Populate table headers
                const headerRow = tableBody.previousElementSibling.querySelector('tr');
                Object.keys(data[0]).forEach(key => {
                    const th = document.createElement('th');
                    th.textContent = key;
                    headerRow.appendChild(th);
                });

                // Populate table rows
                data.forEach(item => {
                    const row = document.createElement('tr');
                    Object.values(item).forEach(value => {
                        const td = document.createElement('td');
                        td.textContent = value;
                        row.appendChild(td);
                    });
                    tableBody.appendChild(row);
                });
            }
        } catch (error) {
            console.error('Error fetching or processing data:', error);
        }
    }

    fetchDataAndPopulateTable();
});
