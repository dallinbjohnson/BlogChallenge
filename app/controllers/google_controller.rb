class GoogleController < ApplicationController
  def redirect
    client = Signet::OAuth2::Client.new({
      client_id: ENV.fetch("GOOGLE_CLIENT_ID"),
      client_secret: ENV.fetch("GOOGLE_CLIENT_SECRET"),
      authorization_uri: 'https://accounts.google.com/o/oauth2/auth',
      scope: Google::Apis::CalendarV3::AUTH_CALENDAR,
      redirect_uri: callback_url
    })

    redirect_to client.authorization_uri.to_s
  end

  def callback
    client = Signet::OAuth2::Client.new({
      client_id: ENV.fetch("GOOGLE_CLIENT_ID"),
      client_secret: ENV.fetch("GOOGLE_CLIENT_SECRET"),
      token_credential_uri: 'https://accounts.google.com/o/oauth2/token',
      redirect_uri: callback_url,
      code: params[:code]
    })

    response = client.fetch_access_token!

    session[:authorization] = response

    redirect_to calendars_url
  end

  def calendars
    client = Signet::OAuth2::Client.new({
      client_id: Rails.application.secrets.google_client_id,
      client_secret: Rails.application.secrets.google_client_secret,
      token_credential_uri: 'https://accounts.google.com/o/oauth2/token'
    })

    client.update!(session[:authorization])

    service = Google::Apis::CalendarV3::CalendarService.new
    service.authorization = client

    begin
      @calendar_list = service.list_calendar_lists
    rescue Google::Apis::AuthorizationError => exception
      response = client.refresh!

      session[:authorization] = session[:authorization].merge(response)

      retry
    end
  end

  def events
    client = Signet::OAuth2::Client.new({
      client_id: ENV.fetch("GOOGLE_CLIENT_ID"),
      client_secret: ENV.fetch("GOOGLE_CLIENT_SECRET"),
      token_credential_uri: 'https://accounts.google.com/o/oauth2/token'
    })

    client.update!(session[:authorization])

    service = Google::Apis::CalendarV3::CalendarService.new
    service.authorization = client

    @event_list = service.list_events(params[:calendar_id])

  # This is my trying to intagrate the google maps and google calendar api!
    # @user = []
    # @event_list.items.each do |event|
    #   @user << Geocoder.coordinates(event.location)
    # end
    # geocoded_by :location
    # after_validation :geocode
    # @hash = Gmaps4rails.build_markers(@user) do |user, marker|
    #   marker.lat user.latitude
    #   marker.lng user.longitude
    #   marker.json({:id => user.id })
    #   marker.picture({
    #    "url" => "http://pocoinspired.com/t6/wp-content/uploads/2015/09/lunch-truck-it-favicon.jpg",
    #    "width" => 32,
    #    "height" => 32})
    #   marker.infowindow "<img src='http://pocoinspired.com/t6/wp-content/uploads/2015/09/lunch-truck-it-favicon.jpg', width='50px' />
    #     <br>
    #     <p>#{user.title}</p>"
    # end
  end

  def new_event
    client = Signet::OAuth2::Client.new({
      client_id: Rails.application.secrets.google_client_id,
      client_secret: Rails.application.secrets.google_client_secret,
      token_credential_uri: 'https://accounts.google.com/o/oauth2/token'
    })

    client.update!(session[:authorization])

    service = Google::Apis::CalendarV3::CalendarService.new
    service.authorization = client

    today = Date.today

    event = Google::Apis::CalendarV3::Event.new({
      start: Google::Apis::CalendarV3::EventDateTime.new(date: today),
      end: Google::Apis::CalendarV3::EventDateTime.new(date: today + 1),
      summary: 'New event!'
    })

    service.insert_event(params[:calendar_id], event)

    redirect_to events_url(calendar_id: params[:calendar_id])
  end
end
