document.addEventListener("DOMContentLoaded", function () {
    let timeout = 0;

    // Modal handling
    function showModal(element) {
        if (element) element.style.display = "block";
    }

    function hideModal(element) {
        if (element) element.style.display = "none";
    }

    const loginDialog = document.getElementById("loginDialog");
    if (loginDialog) hideModal(loginDialog);

    function search() {
        const form = document.getElementById("fun-query-form");
        if (!form) return;
        const formData = new FormData(form);
        formData.append("action", "search");

        fetch("ajax.html", {
            method: "POST",
            body: new URLSearchParams(formData),
        })
            .then((response) => response.text())
            .then((data) => {
                const results = document.getElementById("results");
                if (results) {
                    results.style.display = "none";
                    results.innerHTML = data;
                    results.style.display = "block";
                    hljs.highlightAll();
                }
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
        if (messages) messages.innerHTML = "";
        if (loadIndicator) loadIndicator.style.display = "block";

        fetch("modules/reindex.xql", {
            method: "POST",
            headers: { Accept: "application/json" },
        })
            .then((response) => response.json())
            .then((data) => {
                if (loadIndicator) loadIndicator.style.display = "none";
                if (data.status === "failed") {
                    if (messages) messages.textContent = data.message;
                } else {
                    window.location.reload();
                }
            });
    }

    if (loginDialog) {
        const form = loginDialog.querySelector("form");
        if (form) {
            form.addEventListener("submit", function (event) {
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
                        const loginMessage = loginDialog.querySelector(".login-message");
                        if (loginMessage) {
                            loginMessage.style.display = "block";
                            loginMessage.textContent = "Login failed!";
                        }
                    });
            });
        }
    }

    const loadIndicator = document.getElementById("f-load-indicator");
    if (loadIndicator) loadIndicator.style.display = "none";

    const queryField = document.getElementById("query-field");
    if (queryField) {
        queryField.addEventListener("keyup", function () {
            const val = this.value;
            if (val.length > 3) {
                if (timeout) clearTimeout(timeout);
                timeout = setTimeout(search, 300);
            }
        });
    }

    const btnReindex = document.getElementById("f-btn-reindex");
    if (btnReindex) {
        btnReindex.addEventListener("click", reindexIfLoggedIn);
    }

    const btnReindexRegen = document.getElementById("f-btn-reindex-regen");
    if (btnReindexRegen) {
        btnReindexRegen.addEventListener("click", reindexIfLoggedIn);
    }

    const tooltips = document.querySelectorAll("#fun-query-form [data-toggle='tooltip']");
    tooltips.forEach((tooltip) => {
        tooltip.addEventListener("mouseover", () => {
            tooltip.title = tooltip.getAttribute("data-title") || "Tooltip";
        });
    });
});
