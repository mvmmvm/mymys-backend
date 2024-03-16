class RoomChannel < ApplicationCable::Channel
  def subscribed
    room = Room.find(params[:room_id])
    stream_for room
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def speak
  end

  def solve(data)
    room = Room.find(data["room_id"])
    player = Player.find(data["player_id"])
    unless player.solved
      player.update(solved: true)
      solve_count = room.increment!(:solve).solve
      RoomChannel.broadcast_to(room, { type: 'solve', solve_count: solve_count, player_id: data["player_id"] })
    end
  end

  def answer(data)
      room = Room.find(data["room_id"])
      player = Player.find(data["player_id"])
    unless player.answered
      player.update(answered: true)
      answer_count = room.increment!(:answer).answer
      RoomChannel.broadcast_to(room, { type: 'answer', answer_count: answer_count, player_id: data["player_id"] })
    end
  end
end
