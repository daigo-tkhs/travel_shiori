class AddReservationRequiredToSpots < ActiveRecord::Migration[7.1]
  def change
    add_column :spots, :reservation_required, :boolean
  end
end
