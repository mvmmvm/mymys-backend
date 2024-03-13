class CharactersController < ApplicationController
  def index
    @characters = Character.where(story_id: params[:story_id])
    @story = Story.find(params[:story_id])
    render json: {characters: @characters, story: @story}
  end
end
