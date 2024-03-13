class PlayersController < ApplicationController
    def index
        p params[:room_id]
        @players = Room.find(params[:room_id]).players
        p @players
        render json: @players
    end
    def show
        @player = Player.find(params[:id])
        @character = Character.find(@player.character.id)
        render json: @character
    end
    def create
        @names = []
        @players = player_params[:player]
        @victim = player_params[:victim]
        @players.each do |player|
            @names.push(player[:name])
        end
        @story = Room.find(params[:room_id]).story
        @characters = Character.where(story: @story)
        @room = Room.find(params[:room_id])
        Room.transaction do
            @room.update!(
                victim: @victim
            )
            Player.transaction do
                @characters.zip(@names) do |character, name|
                    @player = Player.create!(
                        room: Room.find(params[:room_id]),
                        character: character,
                        name: name
                    )
                    @players.push(@player)
                end
            end
        end
        p @players
        p @room
        render json: @room
    end

    private

    def player_params
        params.require(:players).permit(:victim, :v_gender, player: [[:name, :gender]])
    end    
end
