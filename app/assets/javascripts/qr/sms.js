$(document).ready(function() {
  $("#input-name").keyup(function() {
    if ($("#input-name").val() != '' && $("#input-phone").val() != '') {
      $(".review-yes").fadeIn();
    } else {
      $(".review-yes").fadeOut();
    }
  })

  $("#input-phone").keyup(function() {
    if ($("#input-name").val() != '' && $("#input-phone").val() != '') {
      $(".review-yes").fadeIn();
    } else {
      $(".review-yes").fadeOut();
    }
  })

  $(".review-yes").click(function() {
    $("#review-box-a").hide();
    $("#review-box-b").show();
  })

  $(".review-no").click(function() {
    $("#review-box-b").hide();
    $("#review-box-a").show();
  })

  $(".staff-submit").click(function() {
    var toName = $("#input-name").val();
    var toPhone = $("#input-phone").val();

    $("#to_name").val(toName);
    $("#to_phone").val(toPhone);
    $(this).parents("form").submit();
  })
})
