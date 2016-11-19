class User
  attr_accessor :user_name, :user_id

  def initialize(user_name, user_id)
    @user_name, @user_id = user_name, user_id
  end

  def ==(other)
    user_id == other.user_id
  end

  def eql?(other)
    self == other
  end

  def hash
    user_id.hash
  end
end
