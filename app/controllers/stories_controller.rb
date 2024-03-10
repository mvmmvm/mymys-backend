# デバッグのため、"p"表示は残す

class StoriesController < ApplicationController
    def index
        @stories = Story.all
        
    end
    def show
    end
    def create
        @room = Room.create(story: Story.new)
        render json: @room
    end

    ## デバッグ用
    # def hoge
    #     story_model = Story.find(params[:id])
    #     story = story_model.all

    #     p story

    #     @characters = Character.where(story_id: params[:id])


    #     if @characters.present?
    #         names = @characters.map{|chara| chara.name }
    #     else
    #         names = ["佐藤佑樹", "御堂拡", "浄明寺遥"]
    #     end

    #     set =  validate(story.match(/舞台(：|:|は)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:))/m), 2)
    #     body = validate(story.match(/事件のストーリー(：|:|は)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:)|$)/m), 2)
    #     weapon = validate(story.match(/凶器(：|:|は)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:))/m) , 2)
    #     place = validate(story.match(/犯行場所(：|:|は)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:))/m), 2)
    #     time = validate(story.match(/犯行時刻(：|:|は)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:))/m), 2)
    #     victim = validate(story.match(/被害者の名前(：|:|は)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:))/m), 2)
    #     v_gender =  validate(story.match(/高橋信夫の性別(：|:|は)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:))/m), 2)
    #     v_personality =  validate(story.match(/高橋信夫の性格(：|:|は)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:))/m), 2)
    #     v_job = validate(story.match(/高橋信夫の職業(：|:|は)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:))/m), 2)
    #     criminal = validate(story.match(/(人物(1|１)|佐藤佑樹)、(人物(2|２)|御堂拡)、(人物(3|３)|浄明寺遥)のうち#{victim}.+犯人.+?(：|:|は)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:))/m), 8)
    #     confession = validate(story.match(/その人物が#{victim}を殺害した理由.+独白させてください(：|:)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:)|$)/m), 2)

    #     story_model.update(
    #         name: "ストーリー#{story_model.id}",
    #         set: set,
    #         body: body,
    #         weapon: weapon,
    #         place: place,
    #         time: time,
    #         victim: victim,
    #         v_gender: v_gender,
    #         v_personality: v_personality,
    #         v_job: v_job,
    #         all: story,
    #         confession: confession
    #     )
    #     evidence = []


    #     names.each_with_index do |name, count|

    #         p "----------------"
    #         p name
    #         p "----------------"

    #         count += 1
    #         p count
    #         fw_count = count.to_s.tr("A-Z0-9","Ａ-Ｚ０-９")
    #         p fw_count
    #         gender = validate(story.match(/#{name}の性別(：|:|は)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:))/m), 2)
    #         p gender
    #         personality =  validate(story.match(/#{name})の性格(：|:|は)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:))/m), 2)
    #         p personality
    #         job = validate(story.match(/#{name})の職業(：|:|は)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:))/m), 2)
    #         p job
    #         introduce = validate(story.match(/#{name})のここにいる理由と自身の秘密の内容と事件直前に取った行動を独白させてください(：|:)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:))/m), 2)
    #         p introduce
    #         stuff = validate(story.match(/#{name})の秘密の証拠品(：|:|は)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:))/m), 2)
    #         p stuff
    #         evidence = [
    #             validate(story.match(/#{name})が事件後に他の人物に聞いたり現場を調べてわかったことか他の人物の行動に関すること(１|1)を独白させてください(：|:)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:))/m), 3),
    #             validate(story.match(/#{name})が事件後に他の人物に聞いたり現場を調べてわかったことか他の人物の行動に関すること(２|2)を独白させてください(：|:)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:))/m), 3),
    #             validate(story.match(/#{name})が事件後に他の人物に聞いたり現場を調べてわかったことか他の人物の行動に関すること(３|3)を独白させてください(：|:)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:))/m), 3)
    #         ]
    #         p evidence
    #         p reason
    #         p criminal

    #         identification = [count.to_s, fw_count, name]
    #         p identification
    #         p identification.any? { |i| criminal.include?(i) }
    #         if identification.any? { |i| criminal.include?(i) }
    #             is_criminal = true
    #         else
    #             is_criminal = false
    #         end
    #         p "======================="
    #         p @characters

    #         room = Room.find_by(story: story_model)
    #         p room
    #         if room.blank?
    #             room = Room.create(
    #                 story: story_model
    #             )
    #         end

    #         if @characters.present?
    #             p @characters[count-1]
    #             p "hue"
    #             @characters[count-1].update(
    #                 story: story_model,
    #                 name: name,
    #                 gender: gender,
    #                 personality: personality,
    #                 job: job,
    #                 introduce: introduce,
    #                 stuff: stuff,
    #                 evidence: evidence,
    #                 reason: reason,
    #                 is_criminal: is_criminal
    #             )
    #             character = @characters[count-1]
    #         else
    #             p "howa"
    #             character = Character.create(
    #                 story: story_model,
    #                 name: name,
    #                 gender: gender,
    #                 personality: personality,
    #                 job: job,
    #                 introduce: introduce,
    #                 stuff: stuff,
    #                 evidence: evidence,
    #                 reason: reason,
    #                 is_criminal: is_criminal
    #             )

    #         end

    #         player = Player.find_by(room: room, character: character)
    #         if player.nil?
    #             Player.create(room: room, character: character, name: name)
    #         end
    #     end
    # end
    # def validate(content, index)
    #     p content
    #     if content.nil?
    #         ""
    #     else
    #         p content[index]
    #         if content[index]
    #             content[index].gsub("\s", "")
    #         else
    #             nil
    #         end
    #     end
    # end
end
