class NotificationsController < BaseController
  def index
    @notifications = Notification.id_desc.page(params[:page]).per(DEFAULT_PER_PAGE)
    respond_to do |format|
      format.html
      format.js { render layout: false }
    end
  end

  def show
    redirect_to edit_notification_path @notification
  end

  def create
    if @notification.save
      flash[:success] = '作成に成功しました'
      redirect_to edit_notification_path(@notification)
    else
      flash.now[:danger] = '作成に失敗しました'
      render :new
    end
  end

  def update
    if @notification.save
      flash[:success] = '更新成功しました'
      redirect_to edit_notification_path(@notification)
    else
      flash.now[:danger] = '更新に失敗しました'
      render :edit
    end
  end

  def destroy
    if @notification.destroy
      flash[:success] = '削除しました'
    else
      flash[:danger] = '削除できませんでした'
    end
    redirect_to notifications_path
  end
end
