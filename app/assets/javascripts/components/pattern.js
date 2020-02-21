$(document).ready(function () {
  showHideButton();

  $('.edit_pattern_form')
    .on('cocoon:after-insert', function() {
      showHideButton();
    })
    .on("cocoon:after-remove", function() {
      showHideButton();
    });

  function showHideButton() {
    if ($('.pattern-form:visible').length >= 3) {
      $('.btn-add-pattern').hide();
    } else {
      $('.btn-add-pattern').show();
    }

    if ($('.pattern-form:visible').length == 1) {
      $('.btn-remove-pattern').hide();
    } else {
      $('.btn-remove-pattern').show();
    }
  };
})
