class GamesController < ActionController::API
  WORD_LENGTH = 5

  # params: player
  def list
    available, pending, in_progress = [], [], []

    Game.all.each do |game|
      if game.player1.name == params[:player] && !game.player2
        pending << game
      elsif game.player1.name == params[:player] || game.player2.name == params[:player]
        in_progress << game
      else
        available = []
      end
    end

    final = available.map { |game| compose_game(game, params[:player]).merge(:status => "available") }
    final += pending.map { |game| compose_game(game, params[:player]).merge(:status => "pending") }
    final += in_progress.map { |game| compose_game(game, params[:player]).merge(:status => "in_progress") }

    render_json(:games => final)
  end

  # params: player, game_name, word
  def new
    game = Game.create!(:name => params[:game_name]) do |g|
      g.player1 = PlayerState.create!(
        :name  => params[:player],
        :word  => params[:word],
        :board => (65..90).to_a.map { |c| "#{c.chr}-" }.join(" "),
        :game  => game
      )
    end
    render_json(:game => compose_game(game))
  end

  # params: player, game_id, word
  def join
    game = Game.find(params[:game_id])

    if game && game.player1.name != params[:player]
      game.player2 = PlayerState.create!(
        :name  => params[:player],
        :word  => params[:word],
        :board => (65..90).to_a.map { |c| "#{c.chr}-" }.join(" "),
        :game  => game
      )
      game.save!
      render_json(:game => compose_game(game))
    else
      render_error_json("Can't join game")
    end
  end

  def guess
    game = Game.find(params[:game_id])

    if my_turn?(game, params[:player])
      guess_text = params[:guess_text].downcase

      if params[:player] == game.player1.name
        me = game.player1
        them = game.player2
      else
        me = game.player2
        them = game.player1
      end

      me_hash = char_hash(me.word.downcase)
      count = char_hash(guess_text).count { |key, val| me_hash[key] }

      guess = me.guesses.new(
        :word => guess_text,
        :count => count
      )

      if guess.valid? && guess.save
        render_json(:guess => guess.attributes)
      else
        render_invalid_json(guess)
      end
    else
      render_invalid_json(["It's not your turn yet!"])
    end
  end

  def my_turn
    game = Game.find(params[:game_id])
    render_json(:my_turn => my_turn?(game, params[:player]))
  end

  def save
    game = Game.find(params[:game_id])

    player = if params[:player] == game.player1.name
      game.player1
    else
      game.player2
    end

    player.board = params[:board]

    if player.valid? && player.save
      render_json({})
    else
      render_invalid_json(player)
    end
  rescue => e
    render_error_json(e.message)
  end

  private

  def my_turn?(game, player)
    guess_count = game.player1.guesses.count + game.player2.guesses.count

    if params[:player] == game.player1.name
      # I created the game, so number of guesses must be even
      # for it to be my turn
      (guess_count % 2) == 0
    else
      (guess_count % 2) == 1
    end
  end

  def char_hash(word)
    word.each_char.to_a.inject({}) { |ret, char| ret[char] = true; ret }
  end

  def compose_game(game, player)
    obj = game.attributes.dup.reject { |key, val| %w(player1 player2).include?(key) }
    obj[:player] = if game.player1.name == player
      compose_player(game.player1)
    else
      compose_player(game.player2)
    end
    obj
  end

  def compose_player(player_obj)
    obj = player_obj.dup.attributes
    obj[:guesses] = player_obj.guesses.order("created_at ASC").map(&:attributes)
    obj
  end

  def render_json(hash)
    hash[:http_status] = 200
    hash[:text_status] = "succeeded"
    render :json => hash
  end

  def render_invalid_json(model)
    hash = { :http_status => 400, :text_status => "invalid" }

    if model.is_a?(Array)
      hash[:validation_messages] = model
    else
      hash[:validation_messages] = model.errors.messages.values.flatten
    end

    render :json => hash
  end

  def render_error_json(message, hash = {})
    hash[:http_status] = 500
    hash[:text_status] = "failed"
    hash[:message] = message
    render :json => hash
  end
end