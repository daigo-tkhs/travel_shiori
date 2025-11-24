# app/models/message.rb

class Message < ApplicationRecord
  belongs_to :trip
  belongs_to :user

  # responseはAIからの回答なので、promptがなければ無意味だが、ここではpromptのみを必須とする
  validates :prompt, presence: true
end
