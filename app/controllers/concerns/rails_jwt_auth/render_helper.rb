module RailsJwtAuth
  module RenderHelper
    def render_session(jwt, user)
      auth_field = RailsJwtAuth.auth_field_name
      render json: {session: {jwt: jwt, auth_field => user[auth_field]}}, status: 201
    end

    def render_registration(resource)
      render json: resource, root: true, status: 201
    end

    def render_profile(resource)
      render json: resource, root: true, status: 200
    end

    def render_204
      head 204
    end

    def render_404
      head 404
    end

    def render_410
      head 410
    end

    def render_422(errors)
      render json: {errors: errors}, status: 422
    end
  end
end
