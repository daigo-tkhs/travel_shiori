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
    @invitation_url = invitation_accept_url(token: @token)
    mail(
      to: params[:to], 
      subject: "【TripConcierge】#{@inviter.nickname}さんから旅の招待状が届いています"
    )
  end
end