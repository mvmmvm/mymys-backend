# frozen_string_literal: true

class CharactersController < ApplicationController
  def index
    @characters = Character.where(story_id: params[:story_id]).select(:id, :name, :gender)
    @story = Story.select(:id, :victim, :v_gender).find(params[:story_id])
    render json: { characters: @characters, story: @story }
  end
end
