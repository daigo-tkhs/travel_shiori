# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Rails.env.test? 以外で Basic認証を適用
  before_action :basic_auth, unless: -> { Rails.env.test? }
  
  # Deviseコントローラーが動く時だけ、パラメータ設定メソッドを実行
  before_action :configure_permitted_parameters, if: :devise_controller?
  
  include Pundit::Authorization
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  # サインイン後のリダイレクト先を決定
  def after_sign_in_path_for(resource)
    # 1. InvitationsController#accept で保存された「元のURL」があればそこへ戻す
    # (これにより、招待メール→ログイン→自動的に招待画面へ戻る動きが実現します)
    stored_location = stored_location_for(resource)
    return stored_location if stored_location

    # 2. 保存された場所がなければ、デフォルトの旅程一覧へ
    trips_path
  end

  protected

  def configure_permitted_parameters
    # 新規登録時(sign_up)に nickname を許可
    devise_parameter_sanitizer.permit(:sign_up, keys: [:nickname])

    # プロフィール編集時(account_update)にも nickname を許可
    devise_parameter_sanitizer.permit(:account_update, keys: [:nickname])
  end

  def after_sign_out_path_for(_resource_or_scope)
    # ログアウト後のリダイレクト先をログイン画面に設定
    new_user_session_path
  end

  private

  def basic_auth
    authenticate_or_request_with_http_basic do |username, password|
      username == ENV['BASIC_AUTH_USER'] && password == ENV['BASIC_AUTH_PASSWORD']
    end
  end
  
  def user_not_authorized
    flash[:alert] = "この操作を行う権限がありません。"
    # 権限がない場合、一つ前のページに戻す（なければルートパス）
    redirect_back(fallback_location: root_path)
  end
end