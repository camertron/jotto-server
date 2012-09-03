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
      :is => $WORD_LENGTH,
    }
end
