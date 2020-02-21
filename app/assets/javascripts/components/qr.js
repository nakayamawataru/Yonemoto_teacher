$(document).ready(function() {
  initDisplayQrImage();
  $('.select-qr-type').change(function() {
    initDisplayQrImage();
  })
})

function initDisplayQrImage() {
  $(".display-qr").hide();
  var selectedQrType = $('.select-qr-type').find(':selected').val();
  if (selectedQrType == '4') {
    $('.simple-qr-image').show();
  } else if (selectedQrType == '1') {
    $('.normal-qr-image').show();
  } else if (selectedQrType == '3') {
    $('.sms-qr-image').show();
  } else if (selectedQrType == '2') {
    $('.anonymous-qr-image').show();
  }
}
