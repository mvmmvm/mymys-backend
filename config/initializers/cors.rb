# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin AJAX requests.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'localhost:8080', '127.0.0.1:8080', 'https://mymys-frontend-g3ez.vercel.app', 'http://192.168.10.106:8080', 'https://enhanced-especially-piranha.ngrok-free.app', 'https://access.line.me/oauth2/v2.1/login'

    resource '*',
             headers: :any,
             methods: %i[get post put patch delete options head],
             credentials: true
  end
end
