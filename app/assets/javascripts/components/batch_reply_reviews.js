$(document).ready(function () {
  $('.btn-reply-review').on('click', function (event) {
    event.preventDefault();
    saveInfoReplyContent($(this.form))
  })

  function saveInfoReplyContent(form) {
    const content = form.find('textarea[name="content"]')[0].value
    const autoReply = form.find('input[name="auto_reply"]').is(":checked")
    const typeReview = form.find('input[name="type_review"]')[0].value
    const userIds = form.parents(".batch-form").find(".multi-user-select").val()

    $.ajax({
      type: 'POST',
      url: '/setting/batch/reply_reviews',
      dataType: 'json',
      data: {
        content: content,
        auto_reply: autoReply,
        user_ids: userIds,
        type_review: typeReview
      },
      success: function (res) {
        let divAlert = $('.notification-save-content-review')
        divAlert.empty();
        if(res.status) {
          divAlert.append(alert('success', res.type_review + 'の設定を保存しました'))
        } else {
          divAlert.append(alert('danger', res.type_review + 'の設定保存が失敗しました'))
        }

        setTimeout(function () {
          $('.notification').fadeOut()
        }, 3000)
      }
    });
  }

  function alert(className, content) {
    const text =
      '<div class="notification">' +
        '<div class="alert alert-' + className + ' pull-right">' +
          content +
        '</div>' +
      '</div>'

    return text
  }
})
