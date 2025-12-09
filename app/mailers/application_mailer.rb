class ApplicationMailer < ActionMailer::Base
  default from: "TripConcierge <trip.concierge.contact@gmail.com>"
  layout "mailer"

  include ActionController::Base.instance_variable_get(:@_helpers) || Rails.application.routes.url_helpers
end
