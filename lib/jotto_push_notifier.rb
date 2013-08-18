require 'push_notifier'

class JottoPushNotifier
  class << self

    def notify_of_guess(options = {})
      player_who_guessed = options[:player_who_guessed]
      player_to_notify = options[:player_to_notify]
      guess = options[:guess]

      message = if player_who_guessed.won?
        "#{player_who_guessed.name} just won with #{guess.word.upcase}! You have one more guess before the game ends."
      else
        "#{player_who_guessed.name} just guessed #{guess.word.upcase} (#{guess.count}). It's your turn."
      end

      payload = {
        :aps => {
          :alert => message,
          :sound => "chime"
        }
      }

      notify(player_to_notify.device_token, payload)
    end

    def notify_of_join(options = {})
      game = options[:game]
      message = "#{game.player2.name} just joined the game \"#{game.name}\". It's your turn."

      payload = {
        :aps => {
          :alert => message,
          :sound => "chime"
        }
      }

      notify(game.player1.device_token, payload)
    end

    private

    def notify(device_token, payload)
      push_notifier.notify_device(device_token, payload.to_json)
    end

    def push_notifier
      @push_notifier ||= PushNotifier.new(
        'gateway.sandbox.push.apple.com', 2195,
        "development"
      )
    end

  end
end