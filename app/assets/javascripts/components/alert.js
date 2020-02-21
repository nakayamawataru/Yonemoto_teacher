$(document).ready(function() {
  document.initAlertOutRankCalenderPicker = function () {
    $('#datepicker').datetimepicker({
      viewMode: 'days',
      format: 'YYYY-MM-DD',
      locale: 'ja'
    })

    $('#datepicker').on("dp.change", function () {
      const date = $('.date-fillter').val()
      $.ajax({
        type: 'GET',
        url: '/alerts?type=out_rank',
        dataType: 'script',
        contentType: 'text/javascript',
        data: {
          date: date
        }
      })
    })

    $('.previous-date, .next-date').on('click', function () {
      $('.modal-loading').show()
    })
  }

  document.initAlertTopRankCalenderPicker = function () {
    $('#top_rank_datepicker').datetimepicker({
      viewMode: 'days',
      format: 'YYYY-MM-DD',
      locale: 'ja'
    })

    $('#top_rank_datepicker').on("dp.change", function () {
      const date_top_rank = $('.date-top-rank-fillter').val()
      $.ajax({
        type: 'GET',
        url: '/alerts?type=top_rank',
        dataType: 'script',
        contentType: 'text/javascript',
        data: {
          date_top_rank: date_top_rank
        }
      })
    })

    $('.previous-date, .next-date').on('click', function () {
      $('.modal-loading').show()
    })
  }

  document.initAlertOutRankCalenderPicker()
  document.initAlertTopRankCalenderPicker()

  $(".page, .first, .prev, .next_page, .last").on('click', function () {
    $('.modal-loading').show()
  })
})

$(document).ajaxStart(function () {
  $('.modal-loading').show()
})

$(document).ajaxStop(function () {
  $('.modal-loading').hide()
})
