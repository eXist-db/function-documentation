document.addEventListener("DOMContentLoaded", function () {
    const markedOptions = { gfm: true };
    const loginDialog = document.getElementById("loginDialog");
    let timeout = 0;

    // Modal handling
    function showModal(element) {
        element.style.display = "block";
    }

    function hideModal(element) {
        element.style.display = "none";
    }

    hideModal(loginDialog);

    function search() {
        const formData = new FormData(document.getElementById("fun-query-form"));
        formData.append("action", "search");

        fetch("ajax.html", {
            method: "POST",
            body: new URLSearchParams(formData),
        })
            .then((response) => response.text())
            .then((data) => {
                const results = document.getElementById("results");
                results.style.display = "none";
                results.innerHTML = data;
                results.style.display = "block";
                timeout = null;
            });
    }

    function reindexIfLoggedIn(event) {
        event.preventDefault();

        fetch("login", { headers: { Accept: "application/json" } })
            .then((response) => {
                if (!response.ok) throw new Error();
                return response.json();
            })
            .then(reindex)
            .catch(() => showModal(loginDialog));
    }

    function reindex() {
        const messages = document.getElementById("messages");
        const loadIndicator = document.getElementById("f-load-indicator");
        messages.innerHTML = "";
        loadIndicator.style.display = "block";

        fetch("modules/reindex.xql", {
            method: "POST",
            headers: { Accept: "application/json" },
        })
            .then((response) => response.json())
            .then((data) => {
                loadIndicator.style.display = "none";
                if (data.status === "failed") {
                    messages.textContent = data.message;
                } else {
                    window.location.reload();
                }
            });
    }

    loginDialog.querySelector("form").addEventListener("submit", function (event) {
        event.preventDefault();
        const formData = new FormData(this);

        fetch("login", {
            method: "POST",
            body: new URLSearchParams(formData),
            headers: { Accept: "application/json" },
        })
            .then((response) => {
                if (!response.ok) throw new Error();
                return response.json();
            })
            .then(() => {
                hideModal(loginDialog);
                reindex();
            })
            .catch(() => {
                loginDialog.querySelector(".login-message").style.display = "block";
                loginDialog.querySelector(".login-message").textContent = "Login failed!";
            });
    });

    document.getElementById("f-load-indicator").style.display = "none";

    document.getElementById("query-field").addEventListener("keyup", function () {
        const val = this.value;
        if (val.length > 3) {
            if (timeout) clearTimeout(timeout);
            timeout = setTimeout(search, 300);
        }
    });

    document.getElementById("f-btn-reindex").addEventListener("click", reindexIfLoggedIn);
    document.getElementById("f-btn-reindex-regen").addEventListener("click", reindexIfLoggedIn);

    const tooltips = document.querySelectorAll("#fun-query-form [data-toggle='tooltip']");
    tooltips.forEach((tooltip) => {
        tooltip.addEventListener("mouseover", () => {
            tooltip.title = tooltip.getAttribute("data-title") || "Tooltip";
        });
    });
});
