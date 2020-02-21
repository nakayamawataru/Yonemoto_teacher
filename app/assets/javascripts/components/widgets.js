$(document).ready(function () {
  $(".widgets-business").change(function () {
    $(".restricted").show()
    const baseUrl = gon.base_url;
    const script = '<div id="meo_review" data-business-id="' + this.value +
      '"></div><script src="' + baseUrl + '/js/widget.js" async></script>';
    $('#script_widget').text(script);
    $('.preview').empty();
    $('.preview').append(script);
  });
  $("#restricted").change(function () {

    $(".restricted").show()
    const baseUrl = gon.base_url;
    let script    = "";
    if ( this.checked ){
      script = '<div id="meo_review" data-restricted="true" data-business-id="' + $(".widgets-business").val() +
        '"></div><script src="' + baseUrl + '/js/widget.js" async></script>';
    } else {
      script = '<div id="meo_review" data-business-id="' + $(".widgets-business").val() +
        '"></div><script src="' + baseUrl + '/js/widget.js" async></script>';
    }

    $('.preview').empty();
    $('.preview').append(script);
    $('#script_widget').text(script);
  });
})
