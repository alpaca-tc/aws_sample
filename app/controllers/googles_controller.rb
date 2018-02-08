require 'open-uri'

class GooglesController < ApplicationController
  def show
    response = open('https://google.com').read
    render html: response.html_safe
  end
end
