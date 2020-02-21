class BaseLocationsController < BaseController
  before_action :check_ability!

  def index
    @search = BaseLocation.ransack(params[:q])
    @locations = @search.result(distinct: true).order(:base_address)
                        .page(params[:page]).per(DEFAULT_PER_PAGE)
  end

  def show
    @keyword = '美容院'
  end
end

private

def check_ability!
  authorize! :index, self
end
