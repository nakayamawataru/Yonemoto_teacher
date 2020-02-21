class MemosController < BaseController

  before_action :load_data, only: %i[index]

  def index
    @search = Business.accessible_by(current_ability).ransack(params[:q])
    @memos = Kaminari.paginate_array(Memo.search(params, current_ability))
                     .page(params[:page])
                     .per(DEFAULT_PER_PAGE)
  end

  private

  def load_data
    @businesses = Business.accessible_by(current_ability)
    @business = current_user.owner? ? current_user.owner_business : @businesses.find_by(id: params[:business_id])
  end
end
