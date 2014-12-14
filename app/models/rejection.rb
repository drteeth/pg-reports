class Rejection < ActiveRecord::Base
  belongs_to :post

  enum reason: [ :spam, :boring, :mansplaining ]
end
