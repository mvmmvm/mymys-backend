# frozen_string_literal: true

# デバッグのため、"p"表示は残す

class RoomsController < ApplicationController
  def create
    @room = if params[:story_id]
              Room.create(story: Story.find(params[:story_id]))
            else
              Room.create(story: Story.new)
            end
    render json: @room
  end

  def show
    render json: @room
  end
end
