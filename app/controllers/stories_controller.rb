# デバッグのため、"p"表示は残す

class StoriesController < ApplicationController
    def index
        @stories = Story.where.not(
            name: nil,
            set: nil,
            body: nil,
            weapon: nil,
            place: nil,
            time: nil,
            victim: nil,
            v_gender: nil,
            v_personality: nil,
            v_job: nil,
            confession: nil,
            all: nil,
        ).order(created_at: :desc)
        p @stories
        render json: @stories
    end
    def show
    end
    def create
        @room = Room.create(story: Story.new)
        render json: @room
    end

    def update
        p "---------------------------"
        @room = Room.find(params[:id])
        p @room
        @story = Story.find(@room.story.id)
        p @story
        if @story.all
            p "aru"
            @chats = @story
        else
            p "nai"
            @players = create_story(@room, @story)
            @room.update(story: @story)
            
        end
        p @players
        render json: @players
    end

    def validate(content, index)
        p content
        if content.nil?
            ""
        else
            p content[index]
            if content[index]
                content[index].gsub("\s", "")
            else
                nil
            end
        end
    end

    private

    def player_params
        params.require(:players).permit(:victim, :v_gender, player: [[:name, :gender]])
    end
    def create_story(room, story)
        p "-----^-"
        p player_params
        p "-----^-"

        @names = []
        @genders = []
        @players = player_params[:player]
        @victim = player_params[:victim]
        @v_gender = player_params[:v_gender]
        @players.each do |player|
            @names.push(player[:name])
            @genders.push(player[:gender])
        end    

        # 1.times do
            @chats = request_gpt
            p @chats

            @set = validate(@chats.match(/舞台(：|:|は)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:))/m), 2)
            @set = @set.gsub(/#{@names[0]}|#{@names[1]}|#{@names[2]}|#{@victim}|#{@v_gender}/, "#{@names[0]}" => "[人物1]", "#{@names[1]}" => '[人物2]', "#{@names[2]}" => "[人物3]", "#{@victim}" => "[被害者]")
            @body = validate(@chats.match(/事件のストーリー(：|:|は)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:))/m) , 2)
            @body = @body.gsub(/#{@names[0]}|#{@names[1]}|#{@names[2]}|#{@victim}|#{@v_gender}/, "#{@names[0]}" => "[人物1]", "#{@names[1]}" => '[人物2]', "#{@names[2]}" => "[人物3]", "#{@victim}" => "[被害者]")
            @weapon = validate(@chats.match(/凶器(：|:|は)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:))/m) , 2)
            @weapon = @weapon.gsub(/#{@names[0]}|#{@names[1]}|#{@names[2]}|#{@victim}|#{@v_gender}/, "#{@names[0]}" => "[人物1]", "#{@names[1]}" => '[人物2]', "#{@names[2]}" => "[人物3]", "#{@victim}" => "[被害者]")
            @place = validate(@chats.match(/犯行場所(：|:|は)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:))/m), 2)
            @place = @place.gsub(/#{@names[0]}|#{@names[1]}|#{@names[2]}|#{@victim}|#{@v_gender}/, "#{@names[0]}" => "[人物1]", "#{@names[1]}" => '[人物2]', "#{@names[2]}" => "[人物3]", "#{@victim}" => "[被害者]")
            @time = validate(@chats.match(/犯行時刻(：|:|は)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:))/m), 2)
            @time = @time.gsub(/#{@names[0]}|#{@names[1]}|#{@names[2]}|#{@victim}|#{@v_gender}/, "#{@names[0]}" => "[人物1]", "#{@names[1]}" => '[人物2]', "#{@names[2]}" => "[人物3]", "#{@victim}" => "[被害者]")
            @v_personality = validate(@chats.match(/#{@victim}の性格(：|:|は)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:))/m), 2)
            @v_personality = @v_personality.gsub(/#{@names[0]}|#{@names[1]}|#{@names[2]}|#{@victim}|#{@v_gender}/, "#{@names[0]}" => "[人物1]", "#{@names[1]}" => '[人物2]', "#{@names[2]}" => "[人物3]", "#{@victim}" => "[被害者]")
            @v_job = validate(@chats.match(/#{@victim}の職業(：|:|は)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:))/m), 2)
            @v_job = @v_job.gsub(/#{@names[0]}|#{@names[1]}|#{@names[2]}|#{@victim}|#{@v_gender}/, "#{@names[0]}" => "[人物1]", "#{@names[1]}" => '[人物2]', "#{@names[2]}" => "[人物3]", "#{@victim}" => "[被害者]")
            @criminal = validate(@chats.match(/#{@names[0]}、#{@names[1]}、#{@names[2]}のうち#{@victim}.+犯人.+?(：|:|は)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:))/m), 2)
            @confession = validate(@chats.match(/その人物が#{@victim}を殺害した理由をその人物の秘密の内容に強く関連させて独白させてください(：|:)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:)|$)/m), 2)
            @confession = @confession.gsub(/#{@names[0]}|#{@names[1]}|#{@names[2]}|#{@victim}|#{@v_gender}/, "#{@names[0]}" => "[人物1]", "#{@names[1]}" => '[人物2]', "#{@names[2]}" => "[人物3]", "#{@victim}" => "[被害者]")
            @main_part = [@set, @body, @weapon, @place, @time, @victim, @v_gender, @v_personality, @v_job, @criminal, @confession]
           
            if @main_part.any? { |content| content.blank? }
                raise StandardError.new("Responsed contents including NULL.")
            end
            Story.transaction do

                story.update!(
                    name: "ストーリー#{story.id}",
                    set: @set,
                    body: @body,
                    weapon: @weapon,
                    place: @place,
                    time: @time,
                    victim: @victim,
                    v_gender: @v_gender,
                    v_personality: @v_personality,
                    v_job: @v_job,
                    confession: @confession,
                    all: @chats
                )

                @characters = Character.where(story: story)
                @players = []
                if @characters.blank?
                    @characters = []

                    @names.each_with_index do |name, count|
                        @gender = validate(@chats.match(/#{name}の性別(：|:|は)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:))/m), 2)
                        @personality = validate(@chats.match(/#{name}の性格(：|:|は)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:))/m), 2)
                        @personality = @personality.gsub(/#{@names[0]}|#{@names[1]}|#{@names[2]}|#{@victim}|#{@v_gender}/, "#{@names[0]}" => "[人物1]", "#{@names[1]}" => '[人物2]', "#{@names[2]}" => "[人物3]", "#{@victim}" => "[被害者]")
                        @job = validate(@chats.match(/#{name}の職業(：|:|は)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:))/m), 2)
                        @job = @job.gsub(/#{@names[0]}|#{@names[1]}|#{@names[2]}|#{@victim}|#{@v_gender}/, "#{@names[0]}" => "[人物1]", "#{@names[1]}" => '[人物2]', "#{@names[2]}" => "[人物3]", "#{@victim}" => "[[被害者]]")
                        @introduce = validate(@chats.match(/#{name}のここにいる理由と自身の秘密の内容と事件直前に取った行動を独白させてください(：|:)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:))/m), 2)
                        @introduce = @introduce.gsub(/#{@names[0]}|#{@names[1]}|#{@names[2]}|#{@victim}|#{@v_gender}/, "#{@names[0]}" => "[人物1]", "#{@names[1]}" => '[人物2]', "#{@names[2]}" => "[人物3]", "#{@victim}" => "[被害者]")
                        @stuff = validate(@chats.match(/#{name}の秘密の証拠品(：|:|は)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:))/m), 2)
                        @stuff = @stuff.gsub(/#{@names[0]}|#{@names[1]}|#{@names[2]}|#{@victim}|#{@v_gender}/, "#{@names[0]}" => "[人物1]", "#{@names[1]}" => '[人物2]', "#{@names[2]}" => "[人物3]", "#{@victim}" => "[被害者]")
                        @evidence = [
                            validate(@chats.match(/#{name}が事件後に他の人物に聞いたり現場を調べてわかったことか他の人物の行動に関すること(１|1)を独白させてください(：|:)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:))/m), 3).gsub(/#{@names[0]}|#{@names[1]}|#{@names[2]}|#{@victim}|#{@v_gender}/, "#{@names[0]}" => "[人物1]", "#{@names[1]}" => '[人物2]', "#{@names[2]}" => "[人物3]", "#{@victim}" => "[被害者]"),
                            validate(@chats.match(/#{name}が事件後に他の人物に聞いたり現場を調べてわかったことか他の人物の行動に関すること(２|2)を独白させてください(：|:)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:))/m), 3).gsub(/#{@names[0]}|#{@names[1]}|#{@names[2]}|#{@victim}|#{@v_gender}/, "#{@names[0]}" => "[人物1]", "#{@names[1]}" => '[人物2]', "#{@names[2]}" => "[人物3]", "#{@victim}" => "[被害者]"),
                            validate(@chats.match(/#{name}が事件後に他の人物に聞いたり現場を調べてわかったことか他の人物の行動に関すること(３|3)を独白させてください(：|:)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:))/m), 3).gsub(/#{@names[0]}|#{@names[1]}|#{@names[2]}|#{@victim}|#{@v_gender}/, "#{@names[0]}" => "[人物1]", "#{@names[1]}" => '[人物2]', "#{@names[2]}" => "[人物3]", "#{@victim}" => "[被害者]")
                        ]
                        character_part = [@gender, @personality, @job, @introduce, @stuff, @evidence]

                        if character_part.any? { |content| content.blank? }
                            raise StandardError.new("Responsed contents including NULL.")
                        end

                        if @introduce.length < 3
                            raise StandardError.new("Responsed contents including NULL.")
                        end

                        if @evidence.any? { |content| content.length < 3 }
                            raise StandardError.new("Responsed contents including NULL.")
                        end
                        if @criminal.include?(name)
                            @is_criminal = true
                        else
                            @is_criminal = false
                        end

                        @character = Character.create!(
                            story: story,
                            name: "人物#{count + 1}",
                            gender: @gender,
                            personality: @personality,
                            job: @job,
                            introduce: @introduce,
                            stuff: @stuff,
                            evidence: @evidence,
                            is_criminal: @is_criminal
                        )
                        @characters.push(@character)
                        @player = Player.create!(
                            character: @character,
                            room: room,
                            name: name
                        )
                        @players.push(@player)
                        
                    end
                    count = 0
                    @characters.each do |character|
                        if character.is_criminal
                            count+= 1
                        end
                    end
                    if count > 1 || count == 0
                        raise StandardError.new("Responsed contents include something wrong.")
                    end
                end
            
            end

        @players
    end

    def request_gpt
        p ENV['ACCESS_TOKEN']
        p "------"
        names = []
        genders = []

        players = player_params[:player]
        victim = player_params[:victim]
        v_gender = player_params[:v_gender]
        players.each do |player|
            names.push(player[:name])
            genders.push(player[:gender])
        end

        @client = OpenAI::Client.new(
            access_token: ENV['ACCESS_TOKEN'],
            request_timeout: 600
        )
        
        p @client
        suspects = names.join("、")
        tmp_names = names.dup
        all_char = tmp_names.push(victim).join("、")  

        main_str =
            "[条件]\n"\
            "ミステリーの下記の設定を条件通りに作ってください。"\
            "既に設定があるものについてはそのままにしておいてください。"\
            "人物たちとは#{all_char}のことです。"\
            "人物たちのうちの1人が#{victim}を殺害した犯人です。"\
            "人物同士での共謀・協力はさせないでください。"\
            "人物たちは自分以外の人物の行動について1つ以上知っていることがあります。"\
            "秘密の証拠品には人物たちの名前を出さないでください。"\
            "人物の秘密の内容と秘密の証拠品は強く関連させてください。"\
            "秘密の証拠品は必ず設定し、重複させないでください。"\
            "人物たちに、事件前後、他の人物の持つ秘密に関係する情報を知る機会はなかったことにしてください。"\
            "人物たちの秘密の内容は下記から1つ選びすべて別々のものにしてください。"\
            "恋愛/病気や健康状態/職場でのトラブル/逮捕歴/同性愛/薬物やアルコールの依存/不倫/身体的な制約/過去の仕事やキャリア/自己の能力やスキルに関する不安/被害経験（いじめ、虐待、暴力など）/過去の自殺未遂/逮捕歴/学業成績/反社会的なグループや組織への所属/身体的な制約やハンディキャップ/精神的な障害や病気/薬物の使用経験/自身の過去のトラウマ/プライベートな写真や動画/過去の仕事の失敗/学歴/秘密のプロジェクトや計画/自身の身体的な問題/他人からの評価や批判/借金/学校や職場での評価/自己の過去の失敗や過ち\n\n"\
            "[設定]\n"\
            "登場人物は全員、会話や心理描写などあらゆる場面で必ずフルネーム[#{all_char}]で呼び合うようにしてください。\n"\
            "事件の舞台:\n"\
            "事件:殺人\n"\
            "事件のストーリー:\n"\
            "犯行場所:\n"\
            "犯行時刻:\n"\
            "凶器:\n"\
            "被害者の名前:#{victim}\n"\
            "#{victim}の性別:#{v_gender}\n"\
            "#{victim}の性格:\n"\
            "#{victim}の職業:\n"


        character_str = ""
        p "------------------"
        p names
        p "------------------"
        names.zip(genders) do |name, gender|
            character_str +=
                "#{name}の性別:#{gender}\n"\
                "#{name}の性格:\n"\
                "#{name}の職業:\n"\
                "#{name}のここにいる理由と自身の秘密の内容と事件直前に取った行動を独白させてください:「」\n"\
                "#{name}の秘密の証拠品:\n"\
                "#{name}が事件後に他の人物に聞いたり現場を調べてわかったことか他の人物の行動に関すること1を独白させてください:「」\n"\
                "#{name}が事件後に他の人物に聞いたり現場を調べてわかったことか他の人物の行動に関すること2を独白させてください:「」\n"\
                "#{name}が事件後に他の人物に聞いたり現場を調べてわかったことか他の人物の行動に関すること3を独白させてください:「」\n"
        end

        character_reason_str = ""

        last_str = \
            "#{suspects}のうち#{victim}を殺害した犯人は誰ですか:\n"\
            "その人物が#{victim}を殺害した理由をその人物の秘密の内容に強く関連させて独白させてください:「」"

        @query = main_str + character_str + character_reason_str + last_str

        p @query

        response = @client.chat(
        parameters: {
            frequency_penalty: 0,
            messages: [
                { role: "user", content: @query }
            ],
            model: "gpt-3.5-turbo-16k",
            presence_penalty: 0,
            temperature: 1,
            top_p: 1
        })
        p response

        @chats = response.dig("choices", 0, "message", "content")

    end
end
