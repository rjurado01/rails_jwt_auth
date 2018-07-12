module RailsJwtAuth
  module SpecHelpers
    def sign_out
      warn '[DEPRECATION] `sign_out` is deprecated and not needed.  Please remove it.'
    end

    def sign_in(user)
      allow_any_instance_of(RailsJwtAuth::AuthenticableHelper)
        .to receive(:authenticate!).and_return(true)

      allow_any_instance_of(RailsJwtAuth::AuthenticableHelper)
        .to receive(:current_user).and_return(user)
    end
  end
end
