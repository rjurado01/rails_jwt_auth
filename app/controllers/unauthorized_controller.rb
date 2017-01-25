class UnauthorizedController < ActionController::Metal
  def self.call(env)
    @respond ||= action(:respond)
    @respond.call(env)
  end

  def respond
    self.response_body = "Unauthorized Action"
    self.status = :unauthorized
  end
end
