# デバッグのため、"p"表示は残す

class RoomsController < ApplicationController
    def create
        if params[:story_id]
            @room = Room.create(story: Story.find(params[:story_id]))
        else
            @room = Room.create(story: Story.new)
        end
        render json: @room
    end
    def show
        render json: @room
    end
end
