$(document).ready(function() {
  $('.message-select').change(function() {
    $('#filter-for-message').submit();
  });

  $('.pattern-select').on('change', function () {
    const idSmsPattern = this.value;
    show_content_pattern_message(idSmsPattern, '.content-message', '.pattern-content');
  });

  $('.csv-sms-pattern-select').on('change', function () {
    const idSmsPattern = this.value;
    show_content_pattern_message(idSmsPattern, '.csv-sms-content-message', '.csv-sms-pattern-content');
  });

  function show_content_pattern_message(idSmsPattern, classBox, classTextArea) {
    if (idSmsPattern != "") {
      $(classBox).css('display', 'block');

      $.ajax({
        type: 'GET',
        url: '/api/sms_patterns/content_pattern',
        dataType: 'json',
        data: {
          id: idSmsPattern
        },
        success: function (response) {
          $(classTextArea).text(response.content);
        }
      });
    } else {
      $(classBox).css('display', 'none');
    }
  }

  $('.email-pattern-select').on('change', function () {
    const idEmailPattern = this.value;
    show_content_email_pattern_message(idEmailPattern, '.email-content-message', '.email-pattern-content');
  });

  $('.csv-email-pattern-select').on('change', function () {
    const idEmailPattern = this.value;
    show_content_email_pattern_message(idEmailPattern, '.csv-email-content-message', '.csv-email-pattern-content');
  });

  function show_content_email_pattern_message(idEmailPattern, classBox, classTextArea) {
    if (idEmailPattern != "") {
      $(classBox).css('display', 'block');

      $.ajax({
        type: 'GET',
        url: '/api/email_patterns/content_pattern',
        dataType: 'json',
        data: {
          id: idEmailPattern
        },
        success: function (response) {
          $(classTextArea).text(response.content);
        }
      });
    } else {
      $(classBox).css('display', 'none');
    }
  }
})
