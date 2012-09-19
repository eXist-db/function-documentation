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
                    $("#results").html(data);
			    }
            });
        }
    });
    
    $("#f-btn-reindex").click(function(ev) {
        ev.preventDefault();
        $("#f-load-indicator").show();
        $.ajax({
            type: "POST",
            url: "ajax.html",
            data: { "action": "reindex" },
            success: function (data) {
                $("#f-load-indicator").hide();
            }
        })
    });
});