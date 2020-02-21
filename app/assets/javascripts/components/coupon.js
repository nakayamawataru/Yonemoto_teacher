$(document).ready(function() {
  $.ajaxSetup({
    headers: {
      'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')
    }
  });

  $(".send-coupons").click(function() {
    var allVals = [];
    var couponId = gon.coupon_id;
     $('input[name="sms_review_id"]:checked').each(function() {
       allVals.push($(this).val());
     });

     $.ajax({
      url: "/coupons/" + couponId + "/sms",
      data: {
        sms_review_ids: allVals
      },
      method: "POST",
      headers: {'Accept': 'application/javascript'}
    })
  })

  $('.btn-save-sms-review').on('click', function() {
    $.ajax({
      url: "/sms_reviews",
      headers: { 'Accept': 'application/javascript' },
      data: $("#formSmsReview").serialize(),
      method: "POST",
      success: function (data) {
        append_sms_review(data)
      },
    });

    $('#modalSmsForm').modal('toggle');
  })

  $('.list-sms_reviews').on('click', '.btn-edit-modal', function () {
    smsReviewId = this.dataset.smsReviewId;

    $.ajax({
      url: "/sms_reviews/" + smsReviewId,
      headers: { 'Accept': 'application/javascript' },
      method: "GET",
      success: function (data) {
        $('.sms-review-username').val(data.username);
        $('.sms-review-phone-number').val(data.phone_number);
        $('.sms-review-id').val(data.id);
      },
    });

    $('.btn-update-sms-review').css('display', 'initial');
    $('.btn-save-sms-review').css('display', 'none');
  })

  $('.btn-update-sms-review').on('click', function () {
    smsReviewId = this.dataset.smsReviewId;

    $.ajax({
      url: "/sms_reviews/" + smsReviewId,
      headers: { 'Accept': 'application/javascript' },
      data: $("#formSmsReview").serialize(),
      method: "PATCH",
      success: function (data) {
        $('.username-review-id-' + data.id).text(data.username);
        $('.phone-number-review-id-' + data.id).text(data.phone_number);
      },
    });

    $('#modalSmsForm').modal('toggle');
  })

  $("#modalSmsForm").on("hide.bs.modal", function () {
    $("#formSmsReview")[0].reset();
    $('.sms-review-id').val('');
    $('.btn-save-sms-review').css('display', 'initial');
    $('.btn-update-sms-review').css('display', 'none');
  });
})

function readURL(input) {
  $(".attached-image").remove();
  if (input.files && input.files[0]) {
    var reader = new FileReader();

    reader.onload = function (e) {
      $('#img_prev')
        .attr('src', e.target.result)
        .width('auto')
        .height(200);
    };

    reader.readAsDataURL(input.files[0]);
  }
}

function append_sms_review(data) {
  const text = '<tr  class="sms-review">' +
      '<td style="text-align:center;">' +
        '<input type="checkbox" name="sms_review_id" id="sms_review_' + data.id + '" value="' + data.id + '" class="sms-checkbox">' +
      '</td>' +
      '<td class="username-review-id-' + data.id + '">' + data.username + '</td>' +
      '<td class="phone-number-review-id-' + data.id + '">' + data.phone_number + '</td>' +
      '<td></td>' +
      '<td></td>' +
      '<td>' +
        '<button type="button" class="btn btn-success  btn-edit-modal" data-toggle="modal" data-target="#modalSmsForm" data-sms-review-id="' + data.id + '">編集</button>' +
      '</td>' +
    '</tr>';

  $('.list-sms_reviews').prepend(text);
  $('#page-entries-info > b').text($('.sms-review').length);
}
