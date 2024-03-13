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
    def new
        
    end

    def show
        render json: @room
        # @room = Room.find(params[:id])
        # @chats = Story.find(@room.story.id)
        # @players = Player.where(room: @room)

    end

    def chats
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
            create_story(@room, @story)


            # TODO:
            @check_chara = Character.where(story: @story)
            count = 0
            @check_chara.each do |chara|
                if chara.is_criminal
                    count += 1
                end
                if count > 1
                    chara.is_criminal = false
                    chara.save!
                    p "duplicated criminal"
                end
            end
            @room.update(story: @story)
        end
        redirect_to @room
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

    def create_story(room, story)

        name1 = "佐藤佑樹"
        name2 = "御堂拡"
        name3 = "浄明寺遥"
        gender1 = "男性"
        gender2= "男性"
        gender3 = "男性"
        error_count = 0

        # 1.times do
            @chats = request_gpt([name1, name2, name3], [gender1, gender2, gender3])
            p @chats

            @set =  validate(@chats.match(/舞台(：|:|は)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:))/m), 2)
            @body = validate(@chats.match(/事件のストーリー(：|:|は)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:))/m) , 2)
            @weapon = validate(@chats.match(/凶器(：|:|は)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:))/m) , 2)
            @place = validate(@chats.match(/犯行場所(：|:|は)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:))/m), 2)
            @time = validate(@chats.match(/犯行時刻(：|:|は)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:))/m), 2)
            @victim = validate(@chats.match(/被害者の名前(：|:|は)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:))/m), 2)
            @v_gender =  validate(@chats.match(/高橋信夫の性別(：|:|は)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:))/m), 2)
            @v_personality =  validate(@chats.match(/高橋信夫の性格(：|:|は)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:))/m), 2)
            @v_job = validate(@chats.match(/高橋信夫の職業(：|:|は)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:))/m), 2)
            @criminal = validate(@chats.match(/#{name1}、#{name2}、#{name3}のうち#{@victim}.+犯人.+?(：|:|は)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:))/m), 2)
            @confession = validate(@chats.match(/その人物が高橋信夫を殺害した理由をその人物の秘密の内容に強く関連させて独白させてください(：|:)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:)|$)/m), 2)
            main_part = [@chats, @set, @body, @weapon, @place, @time, @victim, @v_gender, @v_personality, @v_job, @criminal, @confession]

            # if main_part.any? { |content| content.nil? }
            #     error_count += 1
            #     p "including nil."
            #     next
            # end

            story.update(all: @chats)

            story.update(
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
                confession: @confession
            )

            @characters = Character.where(story: story)
            character_error = false
            if @characters.blank?

                [name1, name2, name3].each_with_index do |name, count|
                    count += 1
                    fw_count = count.to_s.tr("A-Z0-9","Ａ-Ｚ０-９")
                    @gender = validate(@chats.match(/#{name}の性別(：|:|は)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:))/m), 2)
                    @personality =  validate(@chats.match(/#{name}の性格(：|:|は)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:))/m), 2)
                    @job = validate(@chats.match(/#{name}の職業(：|:|は)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:))/m), 2)
                    @introduce = validate(@chats.match(/#{name}のここにいる理由と自身の秘密の内容と事件直前に取った行動を独白させてください(：|:)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:))/m), 2)
                    @stuff = validate(@chats.match(/#{name}の秘密の証拠品(：|:|は)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:))/m), 2)
                    @evidence = [
                        validate(@chats.match(/#{name}が事件後に他の人物に聞いたり現場を調べてわかったことか他の人物の行動に関すること(１|1)を独白させてください(：|:)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:))/m), 3),
                        validate(@chats.match(/#{name}が事件後に他の人物に聞いたり現場を調べてわかったことか他の人物の行動に関すること(２|2)を独白させてください(：|:)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:))/m), 3),
                        validate(@chats.match(/#{name}が事件後に他の人物に聞いたり現場を調べてわかったことか他の人物の行動に関すること(３|3)を独白させてください(：|:)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:))/m), 3)
                    ]

                    character_part = [@gender, @personality, @job, @introduce, @stuff, @evidence]

                    if character_part.any? { |content| content.nil? }
                        character_error = true
                        break
                    end

                    @identification = [count.to_s, fw_count, name]




                    p @identification
                    @criminal
                    if @identification.any? { |i| @criminal.include?(i) }
                        @is_criminal = true
                    else
                        @is_criminal = false
                    end


                    @character = Character.create(
                        story: story,
                        name: name,
                        gender: @gender,
                        personality: @personality,
                        job: @job,
                        introduce: @introduce,
                        stuff: @stuff,
                        evidence: @evidence,
                        is_criminal: @is_criminal
                    )
                    @players = Player.create(
                        character: @character,
                        room: room,
                        name: name
                    )
                end
            end
            # if character_error
            #     error_count += 1
            #     p "including nil."
            #     next
            # else
            #     break
            # end

        # end
        # if error_count == 2
        #     raise StandardError.new("Responsed contents including NULL 2 times.")
        # end
        @players


    end

    def request_gpt(names, genders)

        @client = OpenAI::Client.new(
            access_token: ENV['ACCESS_TOKEN'],
            request_timeout: 600
        )
        p @client
        joined_names = names.join("、")

        main_str =
            "[条件]\n"\
            "ミステリーの下記の設定を条件通りに作ってください。"\
            "既に設定があるものについてはそのままにしておいてください。"\
            "人物たちとは#{joined_names}のことです。"\
            "人物たちのうちの1人が高橋信夫を殺害した犯人です。"\
            "人物同士での共謀・協力はさせないでください。"\
            "人物たちは自分以外の人物の行動について1つ以上知っていることがあります。"\
            "秘密の証拠品には人物たちの名前を出さないでください。"\
            "人物の秘密の内容と秘密の証拠品は強く関連させてください。"\
            "秘密の証拠品は必ず設定し、重複させないでください。"\
            "人物たちに、事件前後、他の人物の持つ秘密に関係する情報を知る機会はなかったことにしてください。"\
            "職業に警察官、刑事、探偵を設定しないでください。"\
            "人物たちの秘密の内容は下記から1つ選びすべて別々のものにしてください。"\
            "恋愛/病気や健康状態/職場でのトラブル/逮捕歴/同性愛/薬物やアルコールの依存/不倫/身体的な制約/過去の仕事やキャリア/自己の能力やスキルに関する不安/被害経験（いじめ、虐待、暴力など）/過去の自殺未遂/逮捕歴/学業成績/反社会的なグループや組織への所属/身体的な制約やハンディキャップ/精神的な障害や病気/薬物の使用経験/自身の過去のトラウマ/プライベートな写真や動画/過去の仕事の失敗/学歴/秘密のプロジェクトや計画/自身の身体的な問題/他人からの評価や批判/借金/学校や職場での評価/自己の過去の失敗や過ち\n\n"\
            "[設定]\n"\
            "事件の舞台:\n"\
            "事件:殺人\n"\
            "事件のストーリー:\n"\
            "犯行場所:\n"\
            "犯行時刻:\n"\
            "凶器:\n"\
            "被害者の名前:高橋信夫\n"\
            "高橋信夫の性別:男性\n"\
            "高橋信夫の性格:\n"\
            "高橋信夫の職業:\n"


        character_str = ""
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
            "#{joined_names}のうち高橋信夫を殺害した犯人は誰ですか:\n"\
            "その人物が高橋信夫を殺害した理由をその人物の秘密の内容に強く関連させて独白させてください:「」"

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
