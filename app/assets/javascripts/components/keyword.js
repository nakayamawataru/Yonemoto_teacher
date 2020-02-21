$(document).ready(function() {
  if ($('.nested-fields').length >= 2) {
    $('.add_fields').hide()
  }

  $('#tab_2')
    .on('cocoon:after-insert', function() {
      if ($('.nested-fields:visible').length >= 2) {
        $('.add_fields').hide()
      } else {
        $('.add_fields').show()
      }
    })
    .on('cocoon:after-remove', function(e) {
      if ($('.nested-fields:visible').length >= 2) {
        $('.add_fields').hide()
      } else {
        $('.add_fields').show()
      }
    })
})
