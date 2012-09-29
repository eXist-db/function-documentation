
function search() {
    var data = $("#fun-query-form").serialize();
    $.ajax({
	    type: "POST",
	    url: "ajax.html",
	    data: data + "&action=search",
	    success: function (data) {
            $("#results").fadeOut(100, function() {
                $(this).html(data);
                $(this).fadeIn(100, function() {
                    $(".signature").highlight();
                });
                timeout = null;
            });
	    }
    });
}

var timeout = null;

$(document).ready(function() {
    $("#f-load-indicator").hide();
    $("#query-field").keyup(function() {
        var val = $(this).val();
        if (val.length > 3) {
            if (timeout)
                clearTimeout(timeout);
            timeout = setTimeout(search, 300);
        }
    });
    
    $("#f-btn-reindex").click(function(ev) {
        ev.preventDefault();
        $("#f-load-indicator").show();
        $.ajax({
            type: "POST",
            dataType: "json",
            url: "modules/reindex.xql",
            success: function (data) {
                $("#f-load-indicator").hide();
                if (data.status == "failed") {
                    $("#messages").text(data.message);
                } else {
                    window.location.href = ".";
                }
            }
        })
    });
    
    $(".signature").highlight();
});