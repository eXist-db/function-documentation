$(document).on("ready", function() {
    const markedOptions = { "gfm": true }
    const loginDialog = $("#loginDialog");
    let timeout = 0;

    loginDialog.modal({
        show: false
    });

    function search() {
        const data = $("#fun-query-form").serialize();
        $.ajax({
            type: "POST",
            url: "ajax.html",
            data: data + "&action=search",
            success: function (data) {
                $("#results").fadeOut(100, function() {
                    $(this).html(data);
                    $(this).fadeIn(100);
                    timeout = null;
                });
            }
        });
    }

    function reindexIfLoggedIn(ev) {
        ev.preventDefault();

        $.ajax({
            url: "login",
            dataType: "json",
            success: reindex,
            error: function () {
                $("#loginDialog").modal("show");
            }
        });
    }

    function reindex() {
        $("#messages").empty();
        $("#f-load-indicator").show();
        $.ajax({
            type: "POST",
            dataType: "json",
            url: "modules/reindex.xql",
            success: function (data) {
                $("#f-load-indicator").hide();
                if (data.status == "failed") {
                    // FIXME the server should respond with an error status code
                    $("#messages").text(data.message);
                } else {
                    window.location.reload();
                }
            }
        });
    }

    $("form", loginDialog).on("submit", function(ev) {
        const params = $(this).serialize();
        $.ajax({
            url: "login",
            data: params,
            dataType: "json",
            success: function(data) {
                loginDialog.modal("hide");
                reindex();
            },
            error: function(xhr, textStatus) {
                $(".login-message", loginDialog).show().text("Login failed!");
            }
        });
        return false;
    });
    $("#f-load-indicator").hide();
    $("#query-field").on("keyup", function() {
        const val = $(this).val();
        // fixme search request is delayed by 300ms
        // replace with proper debounce
        if (val.length > 3) {
            if (timeout)
                clearTimeout(timeout);
            timeout = setTimeout(search, 300);
        }
    });
    
    $("#f-btn-reindex").on("click", reindexIfLoggedIn);
    $("#f-btn-reindex-regen").on("click", reindexIfLoggedIn);

    $("#fun-query-form *[data-toggle='tooltip']").tooltip();

});