class StaticPagesController < ApplicationController
  # 未ログインユーザー（採用担当者含む）に見せるため、Basic認証とログイン認証をスキップ
  skip_before_action :basic_auth, only: [:top], raise: false
  skip_before_action :authenticate_user!, only: [:top], raise: false

  def top
  end
end