class PlayersController < ApplicationController
    def show
        @player = Player.find(params[:id])
        @character = Character.find(@player.character.id)
    end
end
