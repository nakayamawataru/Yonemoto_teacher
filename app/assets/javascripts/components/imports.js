$(document).ready(function() {
  $('.calendar-filter-select').change(function() {
    $('#filter-for-calendar').submit()
  })

  $('.btn-import-rank').on('click', function () {
    $('.modal-loading').show()
  })
})
