require 'faraday'
require 'faraday_middleware'
require 'json'
require 'mimemagic'

#
# Basic wrapper for Slack API to sending messages and files.
# You can either send messages via the Slack API, or format them for response _back_
# to Slack when interacting with Slash commands or other actions
# When responding back to Slack actions use Slack::get_slack_args
# When proactively sending messages you can use Slack::post_to_bot_dm
#
# Simplest usage to just send some text:
#   slack = Slack.new({text: "Hellow wurld"})
#   slack.post_to_bot_dm('U12345', 'T123455')
#
# Sending a message with a button
#   slack = Slack.new({text: 'Click me!', actions: [{name: 'some button', text: 'click me!', value: 1234, type: 'button'}]})
#   slack.post_to_bot_dm('U12345', 'T123455')
#
# Sending a file with a message
#   slack = Slack.new({text: 'Here is a pic!', filepath: '/path/to/file.jpg'})
#   slack.post_file_to_bot_dm('U12345', 'T123455')
#


class Slack
  attr_accessor :request, :channel, :text, :params, :attachments, :filepath

  def initialize(opts = {})
    # Default Slack channel based on environment.
    @text = opts.fetch(:text, 'Testing!')
    @action_text = opts.fetch(:action_text, 'Choose an action')
    @actions = opts.fetch(:actions, [])
    @attachments = []
    @filepath = opts.fetch(:filepath, nil)
    @callback_id = opts.fetch(:callback_id, 'dibs')

    # format attachments
    if @actions.any?
      attachments = []
      @actions.each_slice(5) do |a|
        attachments << {
          color: '#3AA3E3',
          text: '', # "#{a[0][:name].titleize}",
          callback_id: 'dibs',
          actions: a
        }
      end
      @attachments = attachments
    end

  end

  # return the args formatted for sending to Slack
  def get_slack_args
    {
      text: @text,
      attachments: @attachments
    }
  end

  private

  # Find an auth row for the given team and return it
  def get_user_auth(slack_team_id)
    # this will raise a ActiveRecord::RecordNotFound exception if the Auth data can't be found
    auth = Auth.where(team_id: slack_team_id).first
    raise ArgumentError.new('No authorizations found for this workspace. Please go through the /provision flow first') if auth.nil?
    auth
  end

  # Centralized location to call the Slack API
  # This will automatically format the API request to the right type depending on the use case (multipart/form-data or application/json)
  # - `api_method` is the Slack API to call
  # - `body` is a hash of arguments
  # - `access_token` is a Slack token that will be passed as an HTTP header bearer token to Slack
  def call_slack_api_json(api_method, body = {}, access_token)
    request_type = body.key?(:file) ? :multipart : :json
    conn = Faraday.new(:url => 'https://slack.com/api/') do |c|
      c.request request_type
      c.adapter Faraday.default_adapter  # make requests with Net::HTTP
    end
    conn.response :logger if Rails.env.development?

    conn.post do |req|
      req.url api_method
      req.headers['Authorization'] = "Bearer #{access_token}"
      req.body = body
    end
  end

end
