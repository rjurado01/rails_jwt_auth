module RailsJwtAuth
  module RenderHelper
    def render_201(resource)
      render json: resource, root: true, status: 201
    end

    def render_204
      render json: {}, status: 204
    end

    def render_422(errors)
      render json: {errors: errors}, status: 422
    end
  end
end
