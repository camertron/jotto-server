class GamesController < ActionController::API
  # new: Games that I created that haven't been joined yet.
  # pending: Games that someone else created that are available for me to join.
  # my_turn: Games that are waiting for my move.
  # their_turn: Games that are waiting for the other person to move.
  # complete: Games that either me or my opponent have won.

  # params: player
  def list
    new, pending, my_turn, their_turn, complete = [], [], [], [], []
    # games = Game.includes(:player1).includes(:player2).where("player_states.name = ? OR player2s_games.name = ?", params[:player], params[:player])
    games = Game.all

    games.each do |game|
      if game.player1 && game.player1.name == params[:player]
        if game.player2
          if my_turn?(game, params[:player]) && !game.player1.won?
            my_turn << game
          else
            if game.player1.won? || game.player2.won?
              complete << game
            else
              their_turn << game
            end
          end
        else
          new << game
        end
      elsif game.player1 && game.player1.name != params[:player] && !game.player2
        pending << game
      elsif game.player2 && game.player2.name == params[:player]
        if my_turn?(game, params[:player]) && !game.player2.won?
          my_turn << game
        else
          if game.player2.won? || game.player1.won?
            complete << game
          else
            their_turn << game
          end
        end
      end
    end

    final = []
    final << new.map { |game| compose_game(game, params[:player]).merge(:status => "new") }
    final << pending.map { |game| compose_game(game, params[:player]).merge(:status => "pending") }
    final << my_turn.map { |game| compose_game(game, params[:player]).merge(:status => "my_turn") }
    final << their_turn.map { |game| compose_game(game, params[:player]).merge(:status => "their_turn") }
    final << complete.map { |game| compose_game(game, params[:player]).merge(:status => "complete") }

    render_json(:games => final)
  rescue => e
    render_error_json("Can't list games. #{e.message}")
  end

  # params: player, game_name, word
  def create
    ActiveRecord::Base.transaction do
      game = Game.create!(:name => params[:game_name])
      game.player1 = PlayerState.create!(
        :name  => params[:player],
        :word  => params[:word],
        :board => (65..90).to_a.map { |c| "#{c.chr}-" }.join(" "),
        :game  => game
      )
      game.save!

      render_json(:game => compose_game(game, game.player1.name))
    end
  rescue => e
    render_error_json("Can't create game. #{e.message}")
  end

  # params: player, game_id, word
  def join
    game = Game.find(params[:game_id])

    if game && game.player1.name != params[:player]
      unless game.player2
        ActiveRecord::Base.transaction do
          game.player2 = PlayerState.new(
            :name  => params[:player],
            :word  => params[:word],
            :board => (65..90).to_a.map { |c| "#{c.chr}-" }.join(" "),
            :game  => game
          )

          if game.player2.valid? && game.player2.save
            if game.valid? && game.save
              render_json(:game => compose_game(game, params[:player]))
            else
              render_invalid_json(game)
            end
          else
            render_invalid_json(game.player2)
          end
        end
      else
        if game.player2 == params[:player]
          render_invalid_json(["You've already joined this game."])
        else
          render_invalid_json(["This game already has two players."])
        end
      end
    else
      render_invalid_json(["You're the one who started this game."])
    end
  rescue => e
    render_error_json("Can't join game. #{e.message}")
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

      if !me.won?
        them_hash = char_hash(them.word.downcase)
        count = char_hash(guess_text).inject(0) do |sum, (key, val)|
          sum += [them_hash[key] || 0, val].min
          sum
        end

        guess = me.guesses.new(
          :word => guess_text,
          :count => count
        )

        if guess_text == them.word.downcase
          me.won = true
        end

        ActiveRecord::Base.transaction do
          if guess.save! && me.save!
            attrs = { :guess => guess.attributes, :player => compose_player(me) }
            attrs[:finished] = true if them.won?  # signal the game is over
            render_json(attrs)
          else
            render_invalid_json(guess)
          end
        end
      else
        render_invalid_json(["You've already submitted the correct answer!"])
      end
    else
      render_invalid_json(["It's not your turn yet!"])
    end
  rescue => e
    render_error_json("Can't submit guess. #{e.message}")
  end

  def my_turn
    game = Game.find(params[:game_id])
    render_json(:my_turn => my_turn?(game, params[:player]))
  rescue => e
    render_error_json("Can't check for turn. #{e.message}")
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
    render_error_json("Can't save game. #{e.message}")
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
    word.each_char.to_a.inject({}) do |ret, char|
      ret[char] ||= 0
      ret[char] += 1
      ret
    end
  end

  def compose_game(game, player)
    obj = game.attributes.dup.reject { |key, val| %w(player1 player2).include?(key) }
    if game.player1 && (game.player1.name == player)
      obj[:player] = compose_player(game.player1)
      obj[:opponent] = game.player2 ? game.player2.name : nil
    elsif game.player2 && (game.player2.name == player)
      obj[:player] = compose_player(game.player2)
      obj[:opponent] = game.player1 ? game.player1.name : nil
    else
      obj[:player] = nil
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
      hash[:validation_messages] = model.errors.full_messages
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