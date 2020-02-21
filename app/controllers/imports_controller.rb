class ImportsController < ApplicationController
  include ApplicationHelper

  before_action :authenticate_user!
  before_action :check_ability!
  before_action :load_data, only: [:index, :export_template, :upload_rank]

  def index
  end

  def export_template
    file_name = "meo_histories_template_business_#{@business.id}.csv"
    respond_to do |format|
      format.csv { send_data @business.csv_template_meo_histories.encode(Encoding::SJIS, 'utf-8', undef: :replace),
        filename: file_name, type: 'text/csv; charset=shift_jis' }
    end
  end

  def upload_rank
    rank_file = params[:rank_file]
    if rank_file && rank_file.content_type == 'text/csv'
      path = rank_file.path
      detection = CharDet.detect(File.read(path))
      encoding = detection['encoding'] == 'Shift_JIS' ? 'CP932' : detection['encoding']
      CSV.foreach(path, headers: true, encoding: "#{encoding}:UTF-8") do |row|
        date = row[2].to_date rescue nil
        rank = (row[3].to_i <= 0 || row[3].to_i > 20) ? 21 : row[3].to_i
        business_id = row[4]
        keyword_id = row[5]
        can_use_business = @businesses.find_by(id: business_id)
        next unless can_use_business

        meo_history = MeoHistory.find_by(date: date, keyword_id: keyword_id, business_id: business_id)
        if meo_history
          meo_history.update(rank: rank)
        else
          MeoHistory.upload.create(date: date, keyword_id: keyword_id, business_id: business_id, rank: rank) if date
        end
      end

      flash[:success] = '順位Import成功しました'
    else
      flash[:danger] = '順位Importが失敗しました'
    end

    redirect_back(fallback_location: imports_path)
  end

  private

  def check_ability!
    authorize! :index, self
  end

  def load_data
    @businesses = Business.accessible_by(current_ability)
    @business = current_user.owner? ? current_user.owner_business : @businesses.find_by(id: params[:business_id])
  end
end
