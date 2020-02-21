class Setting::SesBlacklistEmailsController < BaseController
  def index
    @ses_blacklist_emails = SesBlacklistEmail.all
  end

  def destroy
    if @ses_blacklist_email.destroy
      flash[:success] = '削除しました'
    else
      flash[:danger] = '削除できませんでした'
    end
    redirect_to setting_ses_blacklist_emails_path
  end
end
