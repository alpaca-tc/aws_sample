class DatabasesController < ApplicationController
  def show
    User.create!
    render plain: "User: #{User.count}"
  end
end
