class TwilioTextMessenger
  attr_reader :to_phonenum, :message

  def initialize(to_phonenum, message)
    @to_phonenum = convert_phonenum(to_phonenum)
    @message = message
  end

  def call
    client = Twilio::REST::Client.new
    client.messages.create({
      from: ENV['TWILIO_PHONE_NUMBER'],
      to: to_phonenum,
      body: message
    })
  end

  def convert_phonenum(to_phonenum)
    # TODO: VN code = +84
    country_code = ENV['COUNTRY_CODE']
    to_phonenum = to_phonenum[1..-1] if ["+", "0"].include? to_phonenum.first
    to_phonenum.starts_with?(country_code) ? to_phonenum : (country_code + to_phonenum)
  end
end
