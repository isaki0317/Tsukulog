# frozen_string_literal: true

class EndUsers::SessionsController < Devise::SessionsController
  # before_action :reject_inactive_customer, only: [:create]

  # GET /resource/sign_in
  # def new
  #   super
  # end

  # POST /resource/sign_in
  # def create
  #   super
  # end

  # DELETE /resource/sign_out
  # def destroy
  #   super
  # end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_in_params
  #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
  # end
  def after_sign_in_path_for(resource)
    posts_path
  end

  def after_sign_out_path_for(resource)
    root_path
  end

  def new_guest
    end_user = EndUser.guest
    sign_in end_user
    redirect_to posts_path, notice: 'ゲストユーザーとしてログインしました。'
  end

  # def reject_inactive_customer
  #   @end_user = EndUser.find_by(email: params[:end_user][:email])
  #   if @end_user
  #     if @end_user.valid_password?(params[:end_user][:password]) && !@end_user.is_deleted
  #       flash[:danger] = 'お客様は退会済みです。申し訳ございませんが、別のメールアドレスをお使いください。'
  #       redirect_to new_end_user_registration_path
  #     end
  #   end
  # end
end
