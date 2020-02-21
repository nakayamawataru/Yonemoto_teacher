function readURL(input, id) {
  if (input.files && input.files[0]) {
    var reader = new FileReader();

    reader.onload = function (e) {
      $('#preview-img-' + id).attr('style', 'background-image:url(' + e.target.result + ')');
    }

    reader.readAsDataURL(input.files[0]);
  }
}
