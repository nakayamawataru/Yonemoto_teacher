class Download::Pdf::ReportsController < ApplicationController
  def index
    # pdf = DownloadPdfService.new(filename, template, local_data).perform
    generate_pdf = render_to_string pdf: '', template: template, encoding: "UTF-8",
      layout: 'pdf', format: :html, locals: local_data
    send_data generate_pdf, filename: filename, type: "text/pdf", disposition: "attachment"
  end

  private

  def filename
    "business_#{params[:business_id]}_reports_#{params[:type]}.pdf"
  end

  def template
    "download/pdf/reports/#{params[:type]}"
  end

  def local_data
    send("load_#{params[:type]}_data")
  end

  def load_insight_data
    business = Business.accessible_by(current_ability).find_by(id: params[:business_id])
    first_month_from = params[:first_month_from]
    first_month_to = params[:first_month_to]
    second_month_from = params[:second_month_from]
    second_month_to = params[:second_month_to]

    first_ranges = ((first_month_from + '-1').to_date..(first_month_to + '-1').to_date).to_a.map{|m| m.strftime('%Y-%m')}.uniq
    second_ranges = ((second_month_from + '-1').to_date..(second_month_to + '-1').to_date).to_a.map{|m| m.strftime('%Y-%m')}.uniq
    if business.present?
      first_queries_chain = business.insights.queries_chain.where(month_in: first_ranges).sum(:value)
      second_queries_chain = business.insights.queries_chain.where(month_in: second_ranges).sum(:value)
      first_queries_direct = business.insights.queries_direct.where(month_in: first_ranges).sum(:value)
      first_queries_indirect = business.insights.queries_indirect.where(month_in: first_ranges).sum(:value) - first_queries_chain
      second_queries_direct = business.insights.queries_direct.where(month_in: second_ranges).sum(:value)
      second_queries_indirect = business.insights.queries_indirect.where(month_in: second_ranges).sum(:value) - second_queries_chain
    else
      first_queries_direct = 0
      first_queries_indirect = 0
      second_queries_direct = 0
      second_queries_indirect = 0
    end
    {
      business: business,
      first_month_from: first_month_from,
      first_month_to: first_month_to,
      second_month_from: second_month_from,
      second_month_to: second_month_to,
      first_queries_direct: first_queries_direct,
      first_queries_indirect: first_queries_indirect,
      second_queries_direct: second_queries_direct,
      second_queries_indirect: second_queries_indirect
    }
  end

  def load_rank_data
    business = Business.accessible_by(current_ability).find_by(id: params[:business_id])
    month_rank = params[:month_rank]
    {
      business: business,
      month_rank: month_rank
    }
  end
end
