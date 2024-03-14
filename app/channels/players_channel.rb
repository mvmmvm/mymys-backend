class PlayersChannel < ApplicationCable::Channel
  def subscribed
    stream_from "players_channel_#{params[:room_id]}_#{params[:player_id]}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def speak
  end

  def button_clicked(data)
    Rails.logger.info("Received button_clicked action with data: #{data}")
    ActionCable.server.broadcast("players_channel_#{data['room_id']}", { type: 'BUTTON_CLICKED', room_id: data['room_id'] })
  end
end
