# app/mailers/user_mailer.rb
# frozen_string_literal: true

class UserMailer < ApplicationMailer
  # メーラー内でルーティングヘルパーを使うためにインクルード（環境依存のバグ対策）
  include Rails.application.routes.url_helpers

  def welcome
    @greeting = 'Hi'
    # subject: '【TripConcierge】ようこそ！旅の準備を始めましょう' を置換
    mail to: params[:to], subject: t('messages.mail.welcome_subject')
  end

  def invite_email
    # with(...) で渡されたパラメータを取得
    @invitation = params[:invitation]
    @inviter = params[:inviter]
    @trip = @invitation.trip
    
    @invite_url = invitation_url(@invitation.token)

    # config/locales/ja.yml から件名を取得
    subject = t('messages.mail.invite_subject', inviter_name: @inviter.nickname || @inviter.email)

    mail(
      to: @invitation.email,
      subject: subject
    )
  end
end