$(document).ready(function() {
  $("#errorModal").modal("show");
  $('#errorModal').on('hidden.bs.modal', function () {
    location.reload();
  })
})
