$(document).ready(function() {
    $("#query-field").keyup(function() {
        var val = $(this).val();
        if (val.length > 1) {
            var data = $("#fun-query-form").serialize();
            $.ajax({
    		    type: "POST",
			    url: "ajax.html",
			    data: data,
			    success: function (data) {
                    $("#results").html(data);
			    }
            });
        }
    });
});