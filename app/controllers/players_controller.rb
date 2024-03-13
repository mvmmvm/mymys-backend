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
        @story = Room.find(params[:room_id]).story
        @characters = Character.where(story: @story)
        @players = []
        @names = ["いちこ","ふたみ","さんご"]
        @characters.zip(@names) do |character, name|
            @player = Player.create(
                room: Room.find(params[:room_id]),
                character: character,
                name: name
            )
            @players.push(@player)
        end
        p @players
        render json: @players
    end
end
