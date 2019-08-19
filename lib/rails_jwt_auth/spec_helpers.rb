module RailsJwtAuth
  module SpecHelpers
    def sign_in(user)
      allow_any_instance_of(RailsJwtAuth::AuthenticableHelper)
        .to receive(:authenticate!).and_return(true)

      allow_any_instance_of(RailsJwtAuth::AuthenticableHelper)
        .to receive(:current_user).and_return(user.class.find(user.id))
    end

    def sign_out
      allow_any_instance_of(RailsJwtAuth::AuthenticableHelper)
        .to receive(:authenticate!).and_call_original

      allow_any_instance_of(RailsJwtAuth::AuthenticableHelper)
        .to receive(:current_user).and_call_original
    end
  end
end
