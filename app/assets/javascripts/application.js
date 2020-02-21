// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, or any plugin's
// vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require rails-ujs
//= require moment
//= require bootstrap-datetimepicker
//= require bootstrap-sprockets
//= require meotool
//= require activestorage
//= require moment
//= require fullcalendar
//= require fullcalendar/locale-all
//= require select2
//= require cocoon

$(document).ready(function() {
  var alert_dom = $('.alert');

  if (alert_dom.length > 0) {
    setTimeout(function() {
      $('.notification').fadeOut();
    }, 3000);
  } else {
    $('.notification').fadeOut();
  }
  $(".select2").select2();

  var selectedValue = $("select.select-role").find(":selected").text()

  if (selectedValue == 'agent' || selectedValue == 'admin') {
    $(".select-agent").hide();
  }

  $("select.select-role").change(function() {
    var selected = $(this).find(":selected").text();
    if (selected == 'agent' || selected == 'admin') {
      $(".select-agent").hide();
    } else {
      $(".select-agent").show();
    }
  })

  $(".datetimepicker").datetimepicker({
    locale: 'ja'
  });

  $('.view-as').on('change', function () {
    window.location.replace('/users/' + this.value + '/managers/new');
  })

  // Modal
  $('.modal-close').click(function(){
    $('#notification-modal').hide();
  });

  $(window).click(function(event){
    if (event.target.id == 'notification-modal') {
      $('#notification-modal').hide();
    }
  });
})
