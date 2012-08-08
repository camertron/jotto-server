class PlayerState < ActiveRecord::Base
  attr_accessible :word, :board, :name, :game
  has_many :guesses
  belongs_to :game
end
