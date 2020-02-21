var initialize_calendar
initialize_calendar = function() {
  var calendar = $("#calendar")
  calendar.fullCalendar({
    header: {
      left:   '',
      center: 'title',
      right:  ''
    },
    titleFormat: 'Y年MM月',
    editable: false,
    events: gon.events,
    eventOrder: 'id',
    locale: 'ja'
  })
  $(".fc-prev-button").prop('disabled', true)
}
$(document).ready(function() {
  initialize_calendar()

  $('#calendar').fullCalendar('gotoDate', gon.selected_month)

  $('.calendar-filter-select').change(function() {
    $('#filter-for-calendar').submit()
  })

  $('.btn-show-edit-rank').on('click', function(){
    const meoId = this.dataset.meoId

    $('.section-edit-rank-' + meoId).show()
    $('.section-show-rank-' + meoId).hide()
    $('.rank-meo-history-' + meoId).focus()
  })

  $('.btn-edit-rank').on('click', function () {
    const meoId = this.dataset.meoId
    const rank = $('.rank-meo-history-' + meoId).val()

    $.ajax({
      type: 'POST',
      url: '/calendars/update_rank',
      dataType: 'json',
      data: {
        meo_id: meoId,
        rank: rank
      },
      success: function (res) {
        let divAlert = $('.notification-save-content-review')
        divAlert.empty()
        if (res.status) {
          $('.text-rank-' + meoId).text((res.rank > 0 && res.rank < 21) ? String(res.rank) + '位' : '圏外')
          $('.rank-meo-history-' + meoId).val(res.rank)
          divAlert.append(alert('success', res.message))
        } else {
          divAlert.append(alert('danger', res.message))
        }

        setTimeout(function () {
          $('.notification').fadeOut()
        }, 3000)
      }
    })

    $('.section-show-rank-' + meoId).show()
    $('.section-edit-rank-' + meoId).hide()
  })

  $('.btn-close-edit-rank').on('click', function() {
    const meoId = this.dataset.meoId

    $('.section-show-rank-' + meoId).show()
    $('.section-edit-rank-' + meoId).hide()
  })

  $('.btn-import-rank').on('click', function () {
    $('.modal-loading').show()
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
