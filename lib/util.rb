class Util
  def self.get_app_url
    Rails.env.development? ? 'http://localhost:3000' : 'https://dibs-me.herokuapp.com'
  end
end