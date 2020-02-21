$(document).ready(function() {
  $("#input-name").keyup(function() {
    if ($(this).val() != '') {
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
    $("#to_name").val(toName);
    $(this).parents("form").submit();
  })
})
