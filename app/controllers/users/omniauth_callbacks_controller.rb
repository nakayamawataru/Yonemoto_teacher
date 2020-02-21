class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2
    auth_client = request.env["omniauth.auth"]
    uid = auth_client.uid
    refresh_token = auth_client.credentials.refresh_token
    gmail = auth_client.info.email
    # TODO: get google_tokens if need
    puts "==== UID: #{auth_client.uid}"
    puts "==== ACCESS_TOKEN: #{auth_client.credentials.token}"
    puts "==== REFRESH_TOKEN: #{auth_client.credentials.refresh_token}"
    puts "==== GMAIL: #{auth_client.info.email}"

    if session[:business_id].present?
      @business = Business.find(session[:business_id])
      if @business.update(google_account_id: uid, google_account_refresh_token: refresh_token, gmail: gmail)
        flash[:success] = 'GMB連携完了'
        session[:google_connected] = true

        # Update refresh_token for other businesses using same gmail
        Business.where(gmail: gmail).update_all(google_account_id: uid, google_account_refresh_token: refresh_token)
      else
        flash[:danger] = 'GMB連携失敗'
      end
      session.delete(:business_id)
      redirect_to edit_business_path(@business)
    end
  end
end
