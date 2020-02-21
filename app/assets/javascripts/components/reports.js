$(document).ready(function() {
  $('.report-filter-select').change(function() {
    $('#report_form').submit();
  })

  $('#datepicker_first_month_from, #datepicker_first_month_to, #datepicker_second_month_from, #datepicker_second_month_to, #datepicker_month_rank').datetimepicker({
    viewMode: 'months',
    format: 'YYYY-MM',
    locale: 'ja'
  });
})
