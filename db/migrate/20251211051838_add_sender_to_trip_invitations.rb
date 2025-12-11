class AddSenderToTripInvitations < ActiveRecord::Migration[7.1]
  def change
    add_reference :trip_invitations, :sender, null: false, foreign_key: true
  end
end
