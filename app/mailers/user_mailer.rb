class UserMailer < ApplicationMailer

  include Rails.application.routes.url_helpers

  def welcome
    @greeting = "Hi"
    mail to: params[:to], subject: "【TripConcierge】ようこそ！旅の準備を始めましょう"
  end

  def invite_to_trip
    @trip = params[:trip]
    @inviter = params[:inviter]
    @token = params[:invitation_token]
    @invitation_url = Rails.application.routes.url_helpers.invitation_accept_url(token: @token, host: Rails.application.config.action_mailer.default_url_options[:host], protocol: Rails.application.config.action_mailer.default_url_options[:protocol])
    mail(
      to: params[:to], 
      subject: "【TripConcierge】#{@inviter.nickname}さんから旅の招待状が届いています"
    )
  end
end