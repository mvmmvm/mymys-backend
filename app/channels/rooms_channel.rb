class RoomsChannel < ApplicationCable::Channel
  def subscribed
    stream_for Room.find(params[:room_id])
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def speak
  end

  def button_to_vote(data)
    Rails.logger.info("Received button_clicked action with data: #{data}")
    ActionCable.server.broadcast('room', { sender: data.user })
    ActionCable.server.broadcast("players_channel_#{data['room_id']}", { type: 'BUTTON_CLICKED', room_id: data['room_id'] })
  end
end
