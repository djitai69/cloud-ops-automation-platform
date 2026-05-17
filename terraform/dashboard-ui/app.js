// const API_URL = "https://z7nq6olijy4fqezeywt7wojrri0penxh.lambda-url.eu-central-1.on.aws/";   "PASTE_API_URL_HERE";
const API_URL = "https://z7nq6olijy4fqezeywt7wojrri0penxh.lambda-url.eu-central-1.on.aws/";

async function loadIncidents() {
    const response = await fetch(API_URL);
    const incidents = await response.json();

    const container = document.getElementById("incident-list");

    incidents.reverse().forEach(i => {
        const div = document.createElement("div");

        div.className = `card ${i.action}`;

        div.innerHTML = `
            <h3>${i.alarm}</h3>
            <p><b>Action:</b> ${i.action}</p>
            <p><b>State:</b> ${i.state}</p>
            <p><b>Time:</b> ${new Date(i.timestamp * 1000)}</p>
            <p><b>ID:</b> ${i.incident_id}</p>
        `;

        container.appendChild(div);
    });
}

loadIncidents();
