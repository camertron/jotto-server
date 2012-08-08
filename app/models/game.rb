class Game < ActiveRecord::Base
  attr_accessible :name
  belongs_to :player1, :class_name => PlayerState, :foreign_key => "player1"
  belongs_to :player2, :class_name => PlayerState, :foreign_key => "player2"
end