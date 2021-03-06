class NotAuthenticatedError < StandardError
end

class AuthenticationTimeoutError < StandardError
end

# Auth Solution borrowed from:
# http://adamalbrecht.com/2014/12/04/add-json-web-token-authentication-to-your-angular-rails-app/
class ApplicationController < ActionController::API
  # getting around CORS issues
  before_filter :cors_set_access_control_headers
  def cors_set_access_control_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'POST, GET, PUT, DELETE, OPTIONS'
    headers['Access-Control-Allow-Headers'] = '*, X-Requested-With, X-Prototype-Version, X-CSRF-Token, Content-Type'
    headers['Access-Control-Max-Age'] = "1728000"
  end
  
  # include implicit render so we can use jbuilder
  include ActionController::ImplicitRender
  
  # TODO: this will need to be skipped on public calls
  # before_action :set_current_user, :authenticate_request

  rescue_from NotAuthenticatedError do
    render json: { error: 'Not Authorized' }, status: :unauthorized
  end
  rescue_from AuthenticationTimeoutError do
    render json: { error: 'Auth token is expired' }, status: 419 # unofficial timeout status code
  end

  private

  # Based on the user_id inside the token payload, find the user.
  def set_current_user
    if decoded_auth_token
      @current_user ||= User.find(decoded_auth_token[:user_id])
    end
  end

  # Check to make sure the current user was set and the token is not expired
  def authenticate_request
    if auth_token_expired?
      fail AuthenticationTimeoutError
    elsif !@current_user
      fail NotAuthenticatedError
    end
  end

  def decoded_auth_token
    @decoded_auth_token ||= AuthToken.decode(http_auth_header_content)
  end

  def auth_token_expired?
    decoded_auth_token && decoded_auth_token.expired?
  end

  # JWT's are stored in the Authorization header using this format:
  # Bearer somerandomstring.encoded-payload.anotherrandomstring
  def http_auth_header_content
    return @http_auth_header_content if defined? @http_auth_header_content
    @http_auth_header_content = begin
      if request.headers['Authorization'].present?
        request.headers['Authorization'].split(' ').last
      else
        nil
      end
    end
  end
end

