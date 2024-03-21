# frozen_string_literal: true
require 'net/http'
require 'uri'
require 'json'
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
      all: nil
    ).order(created_at: :desc)
    render json: @stories
  end

  def show; end

  def create
    @story = Story.new
    @room = Room.create(story: @story)
    render json: { story: @story, room: @room }
  end

  def update
    @room = Room.find(params[:room_id])
    @story = @room.story
    begin
      @players = create_story(@room, @story)
    rescue
      RoomChannel.broadcast_to(@room, { type: 'story_create_error' })
    end    
    @room.update(story: @story)
    RoomChannel.broadcast_to(@room, { type: 'story_created' })
    render json: @players
  end

  def validate(content, index)
    # 怪しい挙動がある＆正規表現のブラッシュアップのためpを残す
    p content
    if content.nil?
      ''
    else
      p content[index]
      content[index] || nil
    end
  end

  private

  def player_params
    params.require(:players).permit(:room_id, :victim, :v_gender, :set, player: [%i[name gender]])
  end

  def create_story(room, story)
    @names = []
    @genders = []
    @players = player_params[:player]
    @victim = player_params[:victim]
    @v_gender = player_params[:v_gender]
    @players.each do |player|
      @names.push(player[:name])
      @genders.push(player[:gender])
    end

    begin
      @chats = request_gpt(room)
    rescue
      RoomChannel.broadcast_to(room, { type: 'story_create_error' })
    end

    @set = validate(@chats.match(/舞台(：|:|は)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:))/m), 2)
    @set = @set.gsub(/#{@names[0]}|#{@names[1]}|#{@names[2]}|#{@victim}|#{@v_gender}/, (@names[0]).to_s => '[人物1]',
                                                                                       (@names[1]).to_s => '[人物2]', (@names[2]).to_s => '[人物3]', @victim.to_s => '[被害者]')
    @body = validate(@chats.match(/事件のストーリー(：|:|は)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:))/m), 2)
    @body = @body.gsub(/#{@names[0]}|#{@names[1]}|#{@names[2]}|#{@victim}|#{@v_gender}/, (@names[0]).to_s => '[人物1]',
                                                                                         (@names[1]).to_s => '[人物2]', (@names[2]).to_s => '[人物3]', @victim.to_s => '[被害者]')
    @weapon = validate(@chats.match(/凶器(：|:|は)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:))/m), 2)
    @weapon = @weapon.gsub(/#{@names[0]}|#{@names[1]}|#{@names[2]}|#{@victim}|#{@v_gender}/,
                           (@names[0]).to_s => '[人物1]', (@names[1]).to_s => '[人物2]', (@names[2]).to_s => '[人物3]', @victim.to_s => '[被害者]')
    @place = validate(@chats.match(/犯行場所(：|:|は)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:))/m), 2)
    @place = @place.gsub(/#{@names[0]}|#{@names[1]}|#{@names[2]}|#{@victim}|#{@v_gender}/,
                         (@names[0]).to_s => '[人物1]', (@names[1]).to_s => '[人物2]', (@names[2]).to_s => '[人物3]', @victim.to_s => '[被害者]')
    @time = validate(@chats.match(/犯行時刻(：|:|は)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:))/m), 2)
    @time = @time.gsub(/#{@names[0]}|#{@names[1]}|#{@names[2]}|#{@victim}|#{@v_gender}/, (@names[0]).to_s => '[人物1]',
                                                                                         (@names[1]).to_s => '[人物2]', (@names[2]).to_s => '[人物3]', @victim.to_s => '[被害者]')
    @v_personality = validate(@chats.match(/#{@victim}の性格(：|:|は)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:))/m), 2)
    @v_personality = @v_personality.gsub(/#{@names[0]}|#{@names[1]}|#{@names[2]}|#{@victim}|#{@v_gender}/,
                                         (@names[0]).to_s => '[人物1]', (@names[1]).to_s => '[人物2]', (@names[2]).to_s => '[人物3]', @victim.to_s => '[被害者]')
    @v_job = validate(@chats.match(/#{@victim}の職業(：|:|は)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:))/m), 2)
    @v_job = @v_job.gsub(/#{@names[0]}|#{@names[1]}|#{@names[2]}|#{@victim}|#{@v_gender}/,
                         (@names[0]).to_s => '[人物1]', (@names[1]).to_s => '[人物2]', (@names[2]).to_s => '[人物3]', @victim.to_s => '[被害者]')
    @criminal = validate(
      @chats.match(/#{@names[0]}、#{@names[1]}、#{@names[2]}のうち#{@victim}.+犯人.+?(：|:|は)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:))/m), 2
    )
    @confession = validate(
      @chats.match(/その人物が#{@victim}を殺害した理由をその人物の秘密の内容に強く関連させて独白させてください(：|:)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:))/m), 2
    )
    @confession = @confession.gsub(/#{@names[0]}|#{@names[1]}|#{@names[2]}|#{@victim}|#{@v_gender}/,
                                   (@names[0]).to_s => '[人物1]', (@names[1]).to_s => '[人物2]', (@names[2]).to_s => '[人物3]', @victim.to_s => '[被害者]')
    @name = validate(
      @chats.match(/ストーリー名(叙情的に)(：|:)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:)|$)/m), 2
    )
    @main_part = [@set, @name, @body, @weapon, @place, @time, @victim, @v_gender, @v_personality, @v_job, @criminal,
                  @confession]

    raise StandardError, 'Responsed contents including NULL.' if @main_part.any?(&:blank?)
    raise StandardError, 'Responsed contents including NULL.' if @confession.length < 5

    Story.transaction do
      story.update!(
        name: @name,
        set: @set,
        body: @body,
        weapon: @weapon,
        place: @place,
        time: @time,
        victim: "[被害者]",
        v_gender: @v_gender,
        v_personality: @v_personality,
        v_job: @v_job,
        confession: @confession,
        all: @chats
      )

      Room.update!(victim: @victim)

      @characters = Character.where(story:)
      @players = []
      if @characters.blank?
        @characters = []

        @names.each_with_index do |name, count|
          @gender = validate(@chats.match(/#{name}の性別(：|:|は)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:))/m), 2)
          @personality = validate(@chats.match(/#{name}の性格(：|:|は)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:))/m), 2)
          @personality = @personality.gsub(/#{@names[0]}|#{@names[1]}|#{@names[2]}|#{@victim}|#{@v_gender}/,
                                           (@names[0]).to_s => '[人物1]', (@names[1]).to_s => '[人物2]', (@names[2]).to_s => '[人物3]', @victim.to_s => '[被害者]')
          @job = validate(@chats.match(/#{name}の職業(：|:|は)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:))/m), 2)
          @job = @job.gsub(/#{@names[0]}|#{@names[1]}|#{@names[2]}|#{@victim}|#{@v_gender}/,
                           (@names[0]).to_s => '[人物1]', (@names[1]).to_s => '[人物2]', (@names[2]).to_s => '[人物3]', @victim.to_s => '[被害者]')
          @introduce = validate(
            @chats.match(/#{name}のここにいる理由と自身の秘密の内容と事件直前に取った行動を300字程度で独白させてください(：|:)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:))/m), 2
          )
          @introduce = @introduce.gsub(/#{@names[0]}|#{@names[1]}|#{@names[2]}|#{@victim}|#{@v_gender}/,
                                       (@names[0]).to_s => '[人物1]', (@names[1]).to_s => '[人物2]', (@names[2]).to_s => '[人物3]', @victim.to_s => '[被害者]')
          @stuff = validate(@chats.match(/#{name}の秘密の証拠品(：|:|は)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:))/m), 2)
          @stuff = @stuff.gsub(/#{@names[0]}|#{@names[1]}|#{@names[2]}|#{@victim}|#{@v_gender}/,
                               (@names[0]).to_s => '[人物1]', (@names[1]).to_s => '[人物2]', (@names[2]).to_s => '[人物3]', @victim.to_s => '[被害者]')
          @evidence = [
            validate(@chats.match(/#{name}が事件後に他の人物に聞いたり現場を調べてわかったことか他の人物の行動に関すること(１|1)を独白させてください(：|:)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:))/m), 3).gsub(
              /#{@names[0]}|#{@names[1]}|#{@names[2]}|#{@victim}|#{@v_gender}/, (@names[0]).to_s => '[人物1]', (@names[1]).to_s => '[人物2]', (@names[2]).to_s => '[人物3]', @victim.to_s => '[被害者]'
            ),
            validate(@chats.match(/#{name}が事件後に他の人物に聞いたり現場を調べてわかったことか他の人物の行動に関すること(２|2)を独白させてください(：|:)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:))/m), 3).gsub(
              /#{@names[0]}|#{@names[1]}|#{@names[2]}|#{@victim}|#{@v_gender}/, (@names[0]).to_s => '[人物1]', (@names[1]).to_s => '[人物2]', (@names[2]).to_s => '[人物3]', @victim.to_s => '[被害者]'
            ),
            validate(@chats.match(/#{name}が事件後に他の人物に聞いたり現場を調べてわかったことか他の人物の行動に関すること(３|3)を独白させてください(：|:)\s?((?:.|\s)+?)(?=\s[^(：|:)\s]+(：|:))/m), 3).gsub(
              /#{@names[0]}|#{@names[1]}|#{@names[2]}|#{@victim}|#{@v_gender}/, (@names[0]).to_s => '[人物1]', (@names[1]).to_s => '[人物2]', (@names[2]).to_s => '[人物3]', @victim.to_s => '[被害者]'
            )
          ]
          character_part = [@gender, @personality, @job, @introduce, @stuff, @evidence]

          raise StandardError, 'Responsed contents including NULL.' if character_part.any?(&:blank?)

          raise StandardError, 'Responsed contents including NULL.' if @introduce.length < 5

          raise StandardError, 'Responsed contents including NULL.' if @evidence.any? { |content| content.length < 5 }

          @is_criminal = if @criminal.include?(name)
                           true
                         else
                           false
                         end

          @character = Character.create!(
            story:,
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
          count += 1 if character.is_criminal
        end
        raise StandardError, 'Responsed contents include something wrong.' if count > 1 || count.zero?
      end
    end

    @players
  end

  def request_gpt(room)
    names = []
    genders = []

    players = player_params[:player]
    victim = player_params[:victim]
    v_gender = player_params[:v_gender]
    set = player_params[:set]
    players.each do |player|
      names.push(player[:name])
      genders.push(player[:gender])
    end

    suspects = names.join('、')
    tmp_names = names.dup
    all_char = tmp_names.push(victim).join('、')

    main_str =
      "[条件]\n"\
        'マーダーミステリーの下記の設定を条件通りに作ってください。'\
        '既に設定があるものについてはそのままにしておいてください。'\
        "人物たちとは[#{suspects}]のことです。"\
        "人物たちのうちの1人が#{victim}を殺害した犯人です。"\
        '人物同士での共謀・協力はさせないでください。'\
        '人物たちは自分以外の人物の行動について1つ以上知っていることがあります。'\
        '秘密の証拠品には人物たちの名前を出さないでください。'\
        '人物の秘密の内容と秘密の証拠品は強く関連させてください。'\
        '各人物が知っている情報は、その人物の視点から得られる範囲内のものに限定してください。'\
        '秘密の証拠品は必ず設定し、重複させないでください。'\
        '人物たちに、事件前後、他の人物の持つ秘密に関係する情報を知る機会はなかったことにしてください。'\
        '人物たちの秘密の内容は下記から1つ選びすべて別々のものにしてください。'\
        "恋愛/病気や健康状態/職場でのトラブル/逮捕歴/同性愛/薬物やアルコールの依存/不倫/身体的な制約/過去の仕事やキャリア/自己の能力やスキルに関する不安/被害経験（いじめ、虐待、暴力など）/過去の自殺未遂/逮捕歴/学業成績/反社会的なグループや組織への所属/身体的な制約やハンディキャップ/精神的な障害や病気/薬物の使用経験/自身の過去のトラウマ/プライベートな写真や動画/過去の仕事の失敗/学歴/秘密のプロジェクトや計画/自身の身体的な問題/他人からの評価や批判/借金/学校や職場での評価/自己の過去の失敗や過ち\n\n"\
        "[設定]\n"\
        "登場人物は全員、会話や心理描写などあらゆる場面で必ずフルネーム[#{all_char}]で呼び合うようにしてください。\n"\
        "事件の舞台:#{set}\n"\
        "事件:殺人\n"\
        "事件のストーリー:\n"\
        "犯行場所:\n"\
        "犯行時刻:\n"\
        "凶器:\n"\
        "被害者の名前:#{victim}\n"\
        "#{victim}の性別:#{v_gender}\n"\
        "#{victim}の性格:\n"\
        "#{victim}の職業:\n"

    character_str = ''

    names.zip(genders) do |name, gender|
      character_str +=
        "#{name}の性別:#{gender}\n"\
          "#{name}の性格:\n"\
          "#{name}の職業:\n"\
          "#{name}のここにいる理由と自身の秘密の内容と事件直前に取った行動を300字程度で独白させてください:「」\n"\
          "#{name}の秘密の証拠品:\n"\
          "#{name}が事件後に他の人物に聞いたり現場を調べてわかったことか他の人物の行動に関すること1を独白させてください:「」\n"\
          "#{name}が事件後に他の人物に聞いたり現場を調べてわかったことか他の人物の行動に関すること2を独白させてください:「」\n"\
          "#{name}が事件後に他の人物に聞いたり現場を調べてわかったことか他の人物の行動に関すること3を独白させてください:「」\n"
    end

    character_reason_str = ''

    last_str = \
      "#{suspects}のうち#{victim}を殺害した犯人は誰ですか:\n"\
        "その人物が#{victim}を殺害した理由をその人物の秘密の内容に強く関連させて独白させてください:「」\n"\
        "ストーリー名(叙情的に):\n"\

    query = main_str + character_str + character_reason_str + last_str

    # APIのURL
    uri = URI('https://api.anthropic.com/v1/messages')

    # リクエストヘッダー
    headers = {
      'x-api-key' => ENV['CLAUDE_ACCESS_TOKEN'],
      'anthropic-version' => '2023-06-01',
      'Content-Type' => 'application/json'
    }

    # リクエストボディ
    body = {
      model: 'claude-3-opus-20240229',
      max_tokens: 4000,
      temperature: 0,
      messages: [
        {role: 'user',
          content: [
            type: 'text',
            text: query
          ]
        }
      ]
    }

    # HTTPリクエストの生成
    http = Net::HTTP.new(uri.host, uri.port)
    p uri.host
    p uri.port
    p uri.request_uri
    http.use_ssl = true
    http.read_timeout = 600
    request = Net::HTTP::Post.new(uri.request_uri, headers)
    request.body = body.to_json

    p ENV['CLAUDE_ACCESS_TOKEN']

    # リクエストの送信とレスポンスの受信
    response = http.request(request)
    p response
    p ENV['CLAUDE_ACCESS_TOKEN']

    if response.code == "200"
      parsed_response = JSON.parse(response.body)
      responced_text = parsed_response['content'][0]['text']
    else
      p response.body
      RoomChannel.broadcast_to(room, { type: 'story_create_error' })
      raise StandardError, parsed_response
    end

    # chatgpt用
    # @client = OpenAI::Client.new(
    #   access_token: ENV['GPT_ACCESS_TOKEN'],
    #   request_timeout: 600
    # )

    # response = @client.chat(
    #   parameters: {
    #     frequency_penalty: 0,
    #     messages: [
    #       { role: 'user', content: @query }
    #     ],
    #     model: 'gpt-3.5-turbo-16k',
    #     presence_penalty: 0,
    #     temperature: 0,
    #     top_p: 1
    #   }
    # )
    # @chats = response.dig('choices', 0, 'message', 'content')
  
    responced_text
  end
end
