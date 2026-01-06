class StaticPagesController < ApplicationController

  # ログイン認証はスキップ（未ログインでもLPは見せる）
  skip_before_action :authenticate_user!, only: [:top], raise: false

  def top
    @hide_footer = true
    # routes.rbで制御済みのため、ここでのリダイレクト処理は不要です
  end
end