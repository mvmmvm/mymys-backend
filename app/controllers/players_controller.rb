# frozen_string_literal: true

class PlayersController < ApplicationController
  def index
    @players = Room.find(params[:room_id]).players
    render json: @players
  end

  def show
    @player = Player.includes(:room, :character).find(params[:id])
    @room = @player.room
    @players = @room.players
    @character = @player.character
    @story = @character.story
    @characters = @story.characters
    @victim = @room.victim
    @stuffs = []

    @characters.each do |character|
      @players.each do |player|
        next unless character.id == player.character_id

        # プレイヤーIDとキャラクターIDが一致したら[人物１]、[人物２]..、[被害者]となっている箇所を
        # プレイヤーの名前で置き換える
        # リクエストしたプレイヤーが犯人の場合は犯人以外の証拠品を配列にして渡す
        if @character.is_criminal && !character.is_criminal
          character.stuff.gsub!("[#{character.name}]", player.name.to_s)
          character.stuff.gsub!('[被害者]', @victim.to_s)
          @stuffs.push(character.stuff)
        end
        if character.is_criminal
          @criminal_stuff = character.stuff
          @criminal_stuff.gsub!("[#{character[:name]}]", (player[:name]).to_s)
          @criminal_stuff.gsub!('[被害者]', @victim.to_s)
        end
        @character.attributes.each do |key, value|
          # nameカラムは単純にプレイヤーのnameで置き換える
          if key == 'name'
            value.replace(@player[:name])
            # それ以外のstringカラムは[人物１]、[人物２]..、[被害者]となっている箇所を置き換える
          elsif value.is_a?(String)
            value.gsub!("[#{character[:name]}]", (player[:name]).to_s)
            value.gsub!('[被害者]', @victim.to_s)
            # evidenceは配列なので、一つずつ置き換える
          elsif key == 'evidence'
            value.each do |evidence|
              evidence.gsub!("[#{character[:name]}]", (player[:name]).to_s)
              evidence.gsub!('[被害者]', @victim.to_s)
            end
          end
        end
        # ストーリーも[人物１]、[人物２]..、[被害者]となっている箇所を置き換える
        @story.attributes.each do |key, value|
          # allカラムは開発者デバッグ用カラムで、プレイヤーに見せたくないため、空文字に置き換える
          if key == 'all'
            value.replace('')
            # 犯人じゃないプレイヤーの場合は、見られたくないため犯人の自白内容を空文字で置き換える
          elsif key == 'confession' && !@character.is_criminal
            value.replace('')
            # それ以外のstring箇所は普通に名前を置き換える
          elsif value.is_a?(String)
            value.gsub!("[#{character[:name]}]", (player[:name]).to_s)
            value.gsub!('[被害者]', @victim.to_s)
          end
        end
      end
    end
    render json: {
      story: @story,
      character: @character,
      stuffs: @stuffs,
      room: @room,
      criminal_stuff: @criminal_stuff,
      solved: @player.solved
    }
    RoomChannel.broadcast_to(@room, { type: 'room_created' })
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
    render json: @room
  end

  private

  def player_params
    params.require(:players).permit(:victim, :v_gender, player: [%i[name gender]])
  end
end
