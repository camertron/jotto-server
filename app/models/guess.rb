class Guess < ActiveRecord::Base
  attr_accessible :word, :count
  belongs_to :player_state

  validates :word,
    :uniqueness => {
      :scope => :player_state_id, 
      :case_sensitive => false, 
      :message => "You have already guessed that word!"
    },
    :length => {
      :is => GamesController::WORD_LENGTH,
      :message => "Word must be exactly #{GamesController::WORD_LENGTH} letters long."
    }
end
