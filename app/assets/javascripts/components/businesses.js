$(document).ready(function () {
  var dateToday = new Date();
  dateToday.setHours(0, 0, 0, 0);
  $('#time_crawler_datepicker').datetimepicker({
    format: 'LT',
    locale: 'ja',
    stepping: 30,
    ignoreReadonly: true,
    minDate: dateToday,
    disabledTimeIntervals: [
      [moment().hour(21).minutes(00), moment().hour(24).minutes(00)]
    ]
  });

  $("#business_logo_review_message").on("change", function () {
    const image = window.URL.createObjectURL(this.files[0]);
    $(".image-review-message").css("display", "-webkit-flex");
    $(".image-review-message").css("display", "flex");
    $(".image_preview img").attr("src", image);
    $("#remove_logo_review_message").val(1);
  });

  $(".delete-logo").on("click", function () {
    $(".image-review-message").css("display", "none");
    $(".image_preview img").attr("src", "");
    $("#business_logo_review_message").val("");
    $("#remove_logo_review_message").val(0);
  });
});
