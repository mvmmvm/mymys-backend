# frozen_string_literal: true
require 'net/http'
require 'uri'
require 'json'
# デバッグのため、"p"表示は残す

class LimitOverError < StandardError; end
class OverLoadError < StandardError; end

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
      @room.update(story: @story)
      RoomChannel.broadcast_to(@room, { type: 'story_created' })
    rescue LimitOverError
      sleep(5)
      RoomChannel.broadcast_to(@room, { type: 'limit_over' })
    rescue OverLoadError
      sleep(5)
      RoomChannel.broadcast_to(@room, { type: 'over_load' })
    rescue StandardError
      sleep(5)
      RoomChannel.broadcast_to(@room, { type: 'story_create_error' })
    end    
    render json: @players
  end

  def validate(content, index)
    p content
    if content.nil?
      ''
    else
      p content[index]
      content[index].gsub(/\s/, "") || nil
    end
  end

  private

  def player_params
    params.require(:players).permit(:room_id, :victim, :v_gender, :set, player: [%i[name gender]])
  end

  def create_story(room, story)
    @names = []
    @player_params = player_params[:player]
    @victim = player_params[:victim]
    @v_gender = player_params[:v_gender]
    @player_params.each do |player|
      @names.push(player[:name])
    end

    @chats, @criminal = request_gpt(room)

    p @chats

    @set = validate(@chats.match(/舞台(：|:|は)\s?((?:.|\s)+?)(?=\s[^：|:\s]+(：|:))/m), 2)
    @set = @set.gsub(/#{@names[0]}|#{@names[1]}|#{@names[2]}|#{@victim}|#{@v_gender}/, (@names[0]).to_s => '[人物1]',
                                                                                       (@names[1]).to_s => '[人物2]', (@names[2]).to_s => '[人物3]', @victim.to_s => '[被害者]')
    @set = player_params[:set] if @set.blank?
    @body = validate(@chats.match(/マーダーミステリーとして導入部分を.+?(：|:)\s?((?:.|\s)+?)(?=\s[^：|:\s]+(：|:))/m), 2)
    @body = @body.gsub(/#{@names[0]}|#{@names[1]}|#{@names[2]}|#{@victim}|#{@v_gender}/, (@names[0]).to_s => '[人物1]',
                                                                                         (@names[1]).to_s => '[人物2]', (@names[2]).to_s => '[人物3]', @victim.to_s => '[被害者]')
    @weapon = validate(@chats.match(/凶器(：|:|は)\s?((?:.|\s)+?)(?=\s[^：|:\s]+(：|:))/m), 2)
    @weapon = @weapon.gsub(/#{@names[0]}|#{@names[1]}|#{@names[2]}|#{@victim}|#{@v_gender}/,
                           (@names[0]).to_s => '[人物1]', (@names[1]).to_s => '[人物2]', (@names[2]).to_s => '[人物3]', @victim.to_s => '[被害者]')
    @place = validate(@chats.match(/犯行場所(：|:|は)\s?((?:.|\s)+?)(?=\s[^：|:\s]+(：|:))/m), 2)
    @place = @place.gsub(/#{@names[0]}|#{@names[1]}|#{@names[2]}|#{@victim}|#{@v_gender}/,
                         (@names[0]).to_s => '[人物1]', (@names[1]).to_s => '[人物2]', (@names[2]).to_s => '[人物3]', @victim.to_s => '[被害者]')
    @time = validate(@chats.match(/犯行時刻(：|:|は)\s?((?:.|\s)+?)(?=\s[^：|:\s]+(：|:))/m), 2)
    @time = @time.gsub(/#{@names[0]}|#{@names[1]}|#{@names[2]}|#{@victim}|#{@v_gender}/, (@names[0]).to_s => '[人物1]',
                                                                                         (@names[1]).to_s => '[人物2]', (@names[2]).to_s => '[人物3]', @victim.to_s => '[被害者]')
    @v_personality = validate(@chats.match(/#{@victim}の性格(：|:|は)\s?((?:.|\s)+?)(?=\s[^：|:\s]+(：|:))/m), 2)
    @v_personality = @v_personality.gsub(/#{@names[0]}|#{@names[1]}|#{@names[2]}|#{@victim}|#{@v_gender}/,
                                         (@names[0]).to_s => '[人物1]', (@names[1]).to_s => '[人物2]', (@names[2]).to_s => '[人物3]', @victim.to_s => '[被害者]')
    @v_job = validate(@chats.match(/#{@victim}の職業(：|:|は)\s?((?:.|\s)+?)(?=\s[^：|:\s]+(：|:))/m), 2)
    @v_job = @v_job.gsub(/#{@names[0]}|#{@names[1]}|#{@names[2]}|#{@victim}|#{@v_gender}/,
                         (@names[0]).to_s => '[人物1]', (@names[1]).to_s => '[人物2]', (@names[2]).to_s => '[人物3]', @victim.to_s => '[被害者]')
    @confession = validate(
      @chats.match(/#{@criminal[:name]}が#{@victim}を殺害した理由をその人物の秘密の内容に強く関連させて独白させてください(：|:)\s?((?:.|\s)+?)(?=\s[^：:\s]+(：|:))/m), 2
    )
    @confession = @confession.gsub(/#{@names[0]}|#{@names[1]}|#{@names[2]}|#{@victim}|#{@v_gender}/,
                                   (@names[0]).to_s => '[人物1]', (@names[1]).to_s => '[人物2]', (@names[2]).to_s => '[人物3]', @victim.to_s => '[被害者]')
    @name = validate(
      @chats.match(/叙情的かつ創造性豊かなストーリー名をネタバレのない範囲で考えてください(：|:)\s?((?:.|\s)+?)(?=(\s[^：:\s]+(：|:)|$))/m), 2
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

      room.update!(victim: @victim)

      @characters = Character.where(story: story)
      @players = []
      if @characters.blank?
        @characters = []

        @player_params.each_with_index do |pp, count|
          # @gender = validate(@chats.match(/#{pp[:name]}の性別(：|:|は)\s?((?:.|\s)+?)(?=\s[^：|:\s]+(：|:))/m), 2)
          @gender = pp[:gender]
          @personality = validate(@chats.match(/#{pp[:name]}の性格(：|:|は)\s?((?:.|\s)+?)(?=\s[^：|:\s]+(：|:))/m), 2)
          @personality = @personality.gsub(/#{@names[0]}|#{@names[1]}|#{@names[2]}|#{@victim}|#{@v_gender}/,
                                           (@names[0]).to_s => '[人物1]', (@names[1]).to_s => '[人物2]', (@names[2]).to_s => '[人物3]', @victim.to_s => '[被害者]')
          @job = validate(@chats.match(/#{pp[:name]}の職業(：|:|は)\s?((?:.|\s)+?)(?=\s[^：|:\s]+(：|:))/m), 2)
          @job = @job.gsub(/#{@names[0]}|#{@names[1]}|#{@names[2]}|#{@victim}|#{@v_gender}/,
                           (@names[0]).to_s => '[人物1]', (@names[1]).to_s => '[人物2]', (@names[2]).to_s => '[人物3]', @victim.to_s => '[被害者]')
          @introduce = validate(
            @chats.match(/#{pp[:name]}のここにいる理由と自身の秘密の内容と事件直前に取った行動と事件直後の行動を、より詳細に.+?独白させてください。.+?(：|:)\s?((?:.|\s)+?)(?=\s[^：|:\s]+(：|:))/m), 2
          )
          @introduce = @introduce.gsub(/#{@names[0]}|#{@names[1]}|#{@names[2]}|#{@victim}|#{@v_gender}/,
                                       (@names[0]).to_s => '[人物1]', (@names[1]).to_s => '[人物2]', (@names[2]).to_s => '[人物3]', @victim.to_s => '[被害者]')
          @stuff = validate(@chats.match(/#{pp[:name]}の秘密の証拠品.*?(：|:)\s?((?:.|\s)+?)(?=\s[^：|:\s]+(：|:))/m), 2)
          @stuff = @stuff.gsub(/#{@names[0]}|#{@names[1]}|#{@names[2]}|#{@victim}|#{@v_gender}/,
                               (@names[0]).to_s => '[人物1]', (@names[1]).to_s => '[人物2]', (@names[2]).to_s => '[人物3]', @victim.to_s => '[被害者]')
          @evidence = [
            validate(@chats.match(/#{pp[:name]}が事件前、事件後に他の人物に聞いたり現場を調べてわかったことや.+?の行動に関する情報1を、.+?が.+?範囲内の行動で、#{pp[:name]}の視点から.+?独白させてください。ただし.+?の秘密の内容.+?(：|:)\s?((?:.|\s)+?)(?=\s[^：|:\s]+(：|:))/m), 2).gsub(
              /#{@names[0]}|#{@names[1]}|#{@names[2]}|#{@victim}|#{@v_gender}/, (@names[0]).to_s => '[人物1]', (@names[1]).to_s => '[人物2]', (@names[2]).to_s => '[人物3]', @victim.to_s => '[被害者]'
            ),
            validate(@chats.match(/#{pp[:name]}が事件前、事件後に他の人物に聞いたり現場を調べてわかったことや.+?の行動に関する情報2を、.+?が.+?範囲内の行動で、#{pp[:name]}の視点から.+?独白させてください。ただし.+?の秘密の内容.+?(：|:)\s?((?:.|\s)+?)(?=\s[^：|:\s]+(：|:))/m), 2).gsub(
              /#{@names[0]}|#{@names[1]}|#{@names[2]}|#{@victim}|#{@v_gender}/, (@names[0]).to_s => '[人物1]', (@names[1]).to_s => '[人物2]', (@names[2]).to_s => '[人物3]', @victim.to_s => '[被害者]'
            ),
          ]
          character_part = [@gender, @personality, @job, @introduce, @stuff, @evidence]

          if character_part.any?(&:blank?) || @introduce.length < 5 || @evidence.any? { |content| content.length < 5 }
            raise StandardError, 'Responsed contents including NULL.'
          end

          @is_criminal = if @criminal[:name] == pp[:name]
                           true
                         else
                           false
                         end
          Character.transaction do

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
            Player.transaction do
              @player = Player.create!(
                character: @character,
                room: room,
                name: pp[:name]
              )
            end
          @players.push(@player)
          end
        end
      end
    end
    @players
  end

  def request_gpt(room)
    names = []
    genders = []

    players = player_params[:player].map(&:to_h)
    victim = player_params[:victim]
    v_gender = player_params[:v_gender]
    set = player_params[:set]
    players.each do |player|
      names.push(player[:name])
    end

    criminal = players.sample
    innocents = players.reject { |player| player == criminal }

    suspects = names.join('、')
    tmp_names = names.dup
    all_char = tmp_names.push(victim).join('、')
    players_and_victim = players + [{name: victim, gender: v_gender}]

    main_str =
      "[条件]\n"\
        'マーダーミステリーの下記の設定を条件通りに作ってください。'\
        '既に設定があるものについてはそのままにしておいてください。'\
        "登場人物は「" + players_and_victim.map { |player| player[:name] }.join('」「') + "」の" + players_and_victim.length.to_s + "人です。彼らは会話や心理描写などあらゆる場面で、絶対にこのフルネームのみを使ってください。指定されたフルネーム以外の名前は絶対に使わないでください。"\
        "#{criminal[:name]}が#{victim}を殺害した犯人です。"\
        '人物同士での共謀・協力はさせないでください。'\
        '人物たちは自分以外の人物の行動について、その人物が独白し、認知している範囲で1つ以上知っていることがあります。'\
        '人物たちの秘密の内容は1人につき1つ設定しすべて別々のものにしてください。'\
        '各人物の秘密の証拠品は、必ず1人につき1つずつ設定してください。証拠品が他の人物と重複しないよう、十分に注意を払ってください。'\
        '人物の秘密の内容と秘密の証拠品は強く関連させてください。'\
        "設定全体を通して、設定していない項目がないか、これらの条件に違反がないことを複数回確認し、必要であれば修正を行ってください。\n\n"\
        "[設定]\n"\
        "事件の舞台:#{set}\n"\
        "事件:殺人\n"\
        "マーダーミステリーとして導入部分をネタバレなく60字程度で:\n"\
        "犯行場所:\n"\
        "犯行時刻:\n"\
        "凶器:\n"\
        "被害者の名前:#{victim}\n"\
        "#{victim}の性別:#{v_gender}\n"\
        "#{victim}の性格:\n"\
        "#{victim}の職業:\n"\
        "犯人:#{criminal[:name]}\n"\

    innocents_str = ''
    innocents.each do |innocent|
      innocents_str +=
        "#{innocent[:name]}の性別:#{innocent[:gender]}\n"\
          "#{innocent[:name]}の性格:\n"\
          "#{innocent[:name]}の職業:\n"\
          "#{innocent[:name]}のここにいる理由と自身の秘密の内容と事件直前に取った行動と事件直後の行動を、より詳細に400~500字程度で独白させてください。秘密の内容や心情、行動の理由などを掘り下げて描写してください:「」\n"\
          "#{innocent[:name]}の秘密の証拠品(#{suspects}という名前はいれないこと):\n"\
    end
    criminal_str = 
      "#{criminal[:name]}の性別:#{criminal[:gender]}\n"\
        "#{criminal[:name]}の性格:\n"\
        "#{criminal[:name]}の職業:\n"\
        "#{criminal[:name]}のここにいる理由と自身の秘密の内容と事件直前に取った行動と事件直後の行動を、より詳細に400~500字程度で独白させてください。秘密の内容や心情、#{victim}を殺害した動機などを掘り下げて描写してください:「」\n"\
        "#{criminal[:name]}の秘密の証拠品(#{suspects}という名前はいれないこと):\n"\

    innocents_evidence_str = ''
    innocents.each do |innocent|
      others = players.reject { |player| player == innocent }
      others.each_with_index do |other, i|
        innocents_evidence_str +=
          "#{innocent[:name]}が事件前、事件後に他の人物に聞いたり現場を調べてわかったことや#{other[:name]}の行動に関する情報#{i+1}を、#{other[:name]}が認知している範囲内の行動で、#{innocent[:name]}の視点からより具体的かつ詳細に100~130字程度で独白させてください。ただし他の人物の秘密の内容や#{criminal[:name]}の事件直前の行動、職業に関係する情報以外にしてください:「」\n"\
      end
    end

    criminal_evidence_str = ''
    innocents.each_with_index do |innocent, i|
      criminal_evidence_str +=
        "#{criminal[:name]}が事件前、事件後に他の人物に聞いたり現場を調べてわかったことや他の人物の行動に関する情報#{i+1}を、#{innocent[:name]}がが認知している範囲内の行動で、#{criminal[:name]}の視点からより具体的かつ詳細に100~130字程度で独白させてください。ただし他の人物の秘密の内容、職業に関係する情報以外にしてください:「」\n"\
    end

    last_str = \
      "#{criminal[:name]}が#{victim}を殺害した理由をその人物の秘密の内容に強く関連させて独白させてください:「」\n"\
        "叙情的かつ創造性豊かなストーリー名をネタバレのない範囲で考えてください:"

    query = main_str + innocents_str + criminal_str + innocents_evidence_str + criminal_evidence_str + last_str

    p query

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
      max_tokens: 4096,
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
    http.use_ssl = true
    http.read_timeout = 600
    request = Net::HTTP::Post.new(uri.request_uri, headers)
    request.body = body.to_json

    p ENV['CLAUDE_ACCESS_TOKEN']

    # リクエストの送信とレスポンスの受信
    response = http.request(request)
    p response

    if response.code == "200"
      parsed_response = JSON.parse(response.body)
      responced_text = parsed_response['content'][0]['text']
    elsif response.code == "429"
      raise LimitOverError
    elsif response.code == "529"
      raise OverLoadError
    else
      raise StandardError
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
  
    return responced_text, criminal
  end
end
