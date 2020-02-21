$(document).ready(function () {
  $('#time_post').datetimepicker({
    format: 'DD/MM/YYYY HH:mm',
    locale: 'ja',
    stepping: 30,
    ignoreReadonly: true,
    minDate: new Date()
  })

  $('#start_date').datetimepicker({
    format: 'DD/MM/YYYY HH:mm:ss',
    locale: 'ja',
    ignoreReadonly: true
  })

  $('#end_date').datetimepicker({
    format: 'DD/MM/YYYY HH:mm:ss',
    locale: 'ja',
    ignoreReadonly: true,
    minDate: new Date()
  })

  $('#post_image').on('change', function () {
    const image = window.URL.createObjectURL(this.files[0])
    $('.image-post').css('display', '-webkit-flex')
    $('.image-post').css('display', 'flex')
    $('.image_preview img').attr('src', image)
    $('#remove_image').val(1)
  })

  $('.delete-post').on('click', function () {
    $('.image-post').css('display', 'none')
    $('.image_preview img').attr('src', '')
    $('#post_image').val('')
    $('#remove_image').val(0)
  })

  $('.post-type').on('change', function() {
    const type = this.value

    if(type == 'what_news') {
      $('.post-action-types').show()
      $('.post-event-form').hide()
      $('.post-coupon').hide()
    } else if(type == 'event') {
      $('.post-event-form').show()
      $('.post-action-types').show()
      $('.post-coupon').hide()
    } else if(type == 'coupon') {
      $('.post-event-form').show()
      $('.post-coupon').show()
      $('.post-action-types').hide()
    }
  })

  $('.btn-submit-post').on('click', function(e) {
    e.preventDefault()

    const autoPost = $('.auto-post').is(":checked")
    const timePost = $('.time-post').val()

    if(autoPost && timePost == '') {
      $('.error-time-post').show()
    } else {
      var r = confirm("入力した内容で投稿しますが、よろしいでしょうか？");
      if (r == true) {
        this.form.submit()
      }
    }
  })

  $('.auto-post').on('change', function() {
    if ($(this).is(':checked')) {
      $('.time-post').prop('disabled', false)
    } else {
      $('.time-post').prop('disabled', true)
      $('.time-post').val('');
    }
  })

  $('.action-type-post').on('change', function() {
    const actionType = this.value
    const elActionUrl = $('.action-url-post')
    const elActionPhoneNumber = $('.action-phone-number-post')

    if (actionType == 'N0_ACTION') {
      elActionUrl.hide()
      elActionPhoneNumber.hide()
    } else if (actionType == 'CALL') {
      elActionUrl.hide()
      elActionPhoneNumber.show()
    } else {
      elActionUrl.show()
      elActionPhoneNumber.hide()
    }
  })
})
