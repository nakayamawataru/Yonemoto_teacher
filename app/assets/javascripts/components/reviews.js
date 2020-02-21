$(document).ready(function () {
  $('.btn-popover').popover({
    trigger: 'focus'
  })

  $(document).ajaxSuccess(function () {
    $('.btn-popover').popover({
      trigger: 'focus'
    })
  })

  $('.review-list').on('click', '.btn-reply', function () {
    const id = this.dataset.id
    const reviewContent = this.dataset.reviewContent
    const replyComment = this.dataset.replyComment == undefined ? '' : this.dataset.replyComment

    $('.btn-save-reply-review').attr('data-id', id)
    $('.content-review').text(reviewContent)
    $('.reply-review-content').val(replyComment)
  })

  $('.btn-save-reply-review').on('click', function () {
    const id = this.dataset.id

    $.ajax({
      url: "/reviews/" + id + "/reply",
      dataType: 'json',
      data: $("#form_reply_review").serialize(),
      method: "POST",
      success: function (res) {
        const replyReviewAction = $('.reply-review-action-' + res.review.id)
        const textReplyReview = $('.text-reply-review-' + res.review.id)
        const replyComment = res.review.reply_content == null ? '' : res.review.reply_content
        let divAlert = $('.notification-save-reply-review')

        divAlert.empty()
        if (res.status) {
          const btnRemoveReply = '<div class="remove-reply-review">' +
                                   '<a class="btn btn-success btn-remove-reply" data-id="' + res.review.id +
                                     '" data-business-id="' + res.review.business_id + '" href="#">' +
                                     '<i class="fa fa-trash-o" ></i >' +
                                   '</a >' +
                                 '</div>'
          const contentReply = '<div class="text-reply-review-' + res.review.id + '">' +
                                 '<span class="btn-popover" data-toggle="popover" data-placement="left" tabindex="0"' +
                                 'data-content="' + replyComment +
                                 '" data-original-title="" title="">あり' +
                                 '</span > ' +
                                 '<p>返信日時：' + res.review.text_reply_update_time + '</p>' +
                               '</div>'

          textReplyReview.empty()
          textReplyReview.append(contentReply)
          $('.btn-reply-' + res.review.id).attr({ "data-reply-comment": replyComment })
          if (replyReviewAction.find('.remove-reply-review')[0] == undefined) {
            replyReviewAction.prepend(btnRemoveReply)
          }
          divAlert.append(alert('success', '返信成功しました'))
        } else {
          divAlert.append(alert('danger', '返信が失敗しました'))
        }

        setTimeout(function () {
          $('.notification').fadeOut()
        }, 3000)
      },
    })

    $('#reply_review_modal').modal('toggle')
  })

  $('.review-list').on('click', '.btn-remove-reply', function () {
    if (confirm("返信を削除しますか？")) {
      const id = this.dataset.id
      const businessId = this.dataset.businessId

      $.ajax({
        url: "/reviews/" + id + "/destroy_reply",
        dataType: 'json',
        data: {
          business_id: businessId
        },
        method: "POST",
        success: function (res) {
          let divAlert = $('.notification-save-reply-review')
          divAlert.empty()

          if (res.status) {
            $('.text-reply-review-' + res.review.id).text('無し')
            $('.btn-reply-' + res.review.id).attr({ "data-reply-comment": '' })
            this.parentElement.remove()
            divAlert.append(alert('success', '返信削除成功しました'))
          } else {
            divAlert.append(alert('danger', '返信削除が失敗しました'))
          }

          setTimeout(function () {
            $('.notification').fadeOut()
          }, 3000)
        }.bind(this)
      })
    }
  })

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
