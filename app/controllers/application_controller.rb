class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :check_user
  
  private
  def check_user
	@user = nil
	@user = session['user'] if (session.has_key?(:user))
  end
end
