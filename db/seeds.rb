20.times.map { Lorem::Base.new(:paragraphs, 1).output }
        .map { |text| Post.create! body:text }
        .map { |post| Rejection.create! post:post, reason:rand(3) }
        .map { |rejc| rejc.update_attribute(:created_at, Date.new(2014, rand(12)+1, 1)) }
