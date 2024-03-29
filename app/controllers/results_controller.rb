# frozen_string_literal: true

class ResultsController < ApplicationController
  def solve
    @names = []
    @player = Player.find(params[:id])
    @room = @player.room
    @players = @room.players.where.not(id: params[:id]).select(:id, :name) unless @player.character.is_criminal?
    @players&.map { |player| @names.push(player) }
    @answered = @player.answered
    render json: { names: @names, room_id: @room.id, answer_count: @room.answer_count, answered: @answered }
  end

  def answer
    @player = Player.find(params[:id])

    return if @player.character.is_criminal

    @criminal = Room.find(answer_params[:room_id].to_i).story.characters.find_by(is_criminal: true)

    if Player.find(answer_params[:suspected].to_i).character == @criminal
      @player.update!(success: true)
    else
      @player.update!(success: false)
    end
  end

  def result
    @player = Player.find(params[:id])
    @room = @player.room
    @players = @room.players
    @story = @room.story
    @victim = @room.victim
    @characters = @story.characters
    @confession = @room.story.confession
    @characters.each do |character|
      @players.each do |player|
        next unless character.id == player.character_id

        # プレイヤーIDとキャラクターIDが一致したら[人物１]、[人物２]..、[被害者]となっている箇所を
        # プレイヤーの名前で置き換える
        @confession.gsub!("[#{character[:name]}]", (player[:name]).to_s)
        @confession.gsub!('[被害者]', @victim.to_s)
        if character.is_criminal
          @criminal = player.name
        end
      end
    end
    @is_criminal = @player.character.is_criminal
    @criminal_win = !@room.players.includes(:character).where(character: { is_criminal: false }).all?(&:success)
    render json: { room_id: @room.id, criminal: @criminal, is_criminal: @is_criminal, criminal_win: @criminal_win, confession: @confession }
  end

  private

  def answer_params
    params.require(:result).permit(:room_id, :suspected)
  end
end
