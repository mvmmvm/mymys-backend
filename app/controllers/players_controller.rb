require 'net/http'
require 'uri'

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
                if @character.is_criminal
                    # リクエストしたプレイヤーが犯人の場合は犯人以外の証拠品を配列にして渡す
                    if !character.is_criminal
                        character.stuff.gsub!("[#{character.name}]", "#{player.name}")
                        character.stuff.gsub!("[被害者]", "#{@victim}")
                        @stuffs.push(character.stuff)
                    end
                end
                @character.attributes.each do |key, value|
                    # nameカラムは単純にプレイヤーのnameで置き換える
                    if key == "name"
                        value.replace(@player[:name])
                    # それ以外のstringカラムは[人物１]、[人物２]..、[被害者]となっている箇所を置き換える
                    elsif value.is_a?(String)
                        value.gsub!("[#{character[:name]}]", "#{player[:name]}")
                        value.gsub!("[被害者]", "#{@victim}")
                    # evidenceは配列なので、一つずつ置き換える
                    elsif key == "evidence"
                        value.each do |evidence|
                            evidence.gsub!("[#{character[:name]}]", "#{player[:name]}")
                            evidence.gsub!("[被害者]", "#{@victim}")
                        end
                    end
                end
                # ストーリーも[人物１]、[人物２]..、[被害者]となっている箇所を置き換える           
                @story.attributes.each do |key, value|
                    # allカラムは開発者デバッグ用カラムで、プレイヤーに見せたくないため、空文字に置き換える
                    if key == "all"
                        value.replace("")
                    # 犯人じゃないプレイヤーの場合は、見られたくないため犯人の自白内容を空文字で置き換える
                    elsif key == "confession" && !@character.is_criminal
                        value.replace("")
                    # それ以外のstring箇所は普通に名前を置き換える
                    elsif value.is_a?(String)
                        value.gsub!("[#{character[:name]}]", "#{player[:name]}")
                        value.gsub!("[被害者]", "#{@victim}")
                    end
                end
            end
        end
        render json: {
            story: @story,
            character: @character,
            stuffs: @stuffs,
            room_id: @room.id,
            solve_count: @room.solve,
            solved: @player.solved
        }    
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
        params.require(:players).permit(:victim, :v_gender, player: [[:name, :gender]])
    end    
end
