$(document).ready(function () {
  $("#user_logo").on("change", function () {
    const image = window.URL.createObjectURL(this.files[0]);
    $(".image-logo").css("display", "-webkit-flex");
    $(".image-logo").css("display", "flex");
    $(".image_preview img").attr("src", image);
    $("#remove_logo").val(1);
  });

  $(".delete-logo").on("click", function () {
    $(".image-logo").css("display", "none");
    $(".image_preview img").attr("src", "");
    $("#user_logo").val("");
    $("#remove_logo").val(0);
  });

  $("#user_header_logo").on("change", function () {
    const image = window.URL.createObjectURL(this.files[0]);
    $(".image-header-logo").css("display", "-webkit-flex");
    $(".image-header-logo").css("display", "flex");
    $(".image_header_logo_preview img").attr("src", image);
    $("#remove_header_logo").val(1);
  });

  $(".delete-header-logo").on("click", function () {
    $(".image-header-logo").css("display", "none");
    $(".image_header_logo_preview img").attr("src", "");
    $("#user_header_logo").val("");
    $("#remove_header_logo").val(0);
  });
});
