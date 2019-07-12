class MessagesController < ApplicationController

  def index
    render_to_slack(text: "hello world!")
  end

  private

  def render_to_slack(args)
    slack_message = ::Slack.new(args)
    slack_args = slack_message.get_slack_args

    render json: slack_args.to_json, status: 200
  end
end
