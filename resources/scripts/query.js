$(document).ready(function() {
    $("#f-load-indicator").hide();
    $("#query-field").keyup(function() {
        var val = $(this).val();
        if (val.length > 1) {
            var data = $("#fun-query-form").serialize();
            $.ajax({
    		    type: "POST",
			    url: "ajax.html",
			    data: data + "&action=search",
			    success: function (data) {
                    $("#results").fadeOut(200, function() {
                        $(this).html(data).fadeIn(200);
                    });
			    }
            });
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
});