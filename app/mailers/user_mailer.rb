# frozen_string_literal: true

class UserMailer < ApplicationMailer
  include Rails.application.routes.url_helpers

  def default_url_options
    if Rails.env.production?
      { host: 'travel-shiori.onrender.com', protocol: 'https' }
    else
      { host: 'localhost', port: 3000, protocol: 'http' }
    end
  end

  def welcome
    @greeting = 'Hi'
    mail to: params[:to], subject: t('messages.mail.welcome_subject')
  end

  def invite_email
    @invitation = params[:invitation]
    @inviter = params[:inviter]
    @trip = @invitation.trip
    
    @invite_url = invitation_url(@invitation.token)

    subject = t('messages.mail.invite_subject', inviter_name: @inviter.nickname || @inviter.email)

    mail(
      to: @invitation.email,
      subject: subject
    )
  end
end