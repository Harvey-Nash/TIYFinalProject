class Session < ActiveRecord::Base
  has_many :tokens
end