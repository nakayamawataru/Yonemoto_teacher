class DownloadPdfService
  include ActionController::DataStreaming
  attr_accessor :filename, :template, :local_data

  def initialize(filename, template, local_data)
    @filename = filename
    @template = template
    @local_data = local_data
  end

  def perform
    pdf_html = ApplicationController.new.render_to_string pdf: '', template: template, encoding: "UTF-8",
      layout: 'pdf', format: :html, locals: local_data
    pdf = WickedPdf.new.pdf_from_string(pdf_html)
    send_data pdf, filename: filename, type: "text/pdf", disposition: "attachment"
  end
end
