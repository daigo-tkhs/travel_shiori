class UserMailer < ApplicationMailer

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.user_mailer.welcome.subject
  #
  def welcome
    @greeting = "Hi"

    # ▼ 修正箇所: params[:to] を使うように変更します
    mail to: params[:to], subject: "Welcome to TripConcierge!"
  end
end