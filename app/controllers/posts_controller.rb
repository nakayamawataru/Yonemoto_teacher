class PostsController < BaseController
  skip_authorize_resource only: %i[index]
  before_action :load_data

  def index
    return unless @business
    @posts = @business.posts.order('id DESC').page(params[:page]).per(DEFAULT_PER_PAGE)
  end

  def show
  end

  def new
  end

  def create
    if @post.save
      if @post.auto_post
        flash[:success] = '作成成功しました'
      else
        error_message = @post.publish
        if error_message.present?
          flash[:danger] = error_message
        else
          flash[:success] = '投稿成功しました'
        end
      end

      redirect_to posts_path(business_id: @post.business.id)
    else
      flash[:danger] = '作成に失敗しました'
      redirect_to action: :new, business_id: model_params[:business_id], post_type: model_params[:post_type], action_type: model_params[:action_type], error: @post.errors.messages
    end
  end

  def edit
    return redirect_to posts_path(business_id: @post.business.id) if @post.successed?
  end

  def update
    return redirect_to posts_path(business_id: @post.business.id) if @post.successed?

    @post.remove_image! if params[:remove_image] == "0"
    if @post.save
      if @post.auto_post
        flash[:success] = '更新成功しました'
      else
        error_message = @post.publish
        if error_message.present?
          flash[:danger] = error_message
        else
          flash[:success] = '投稿成功しました'
        end
      end

      redirect_to posts_path(business_id: @post.business.id)
    else
      flash[:danger] = '更新に失敗しました'
      redirect_to action: :edit, business_id: model_params[:business_id], post_type: model_params[:post_type], action_type: model_params[:action_type], error: @post.errors.messages
    end
  end

  private

  def load_data
    @businesses = Business.accessible_by(current_ability)
    @business = @businesses.find_by id: params[:business_id]
  end
end
