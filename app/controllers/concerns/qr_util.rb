require 'rqrcode'

module QrUtil
  QR_TYPES = [
    [ 1, '通常タイプ： 「お名前入力」、「スタッフ選択」必須' ],
    [ 2, '匿名タイプ： 「お名前入力」、「スタッフ選択」省略' ],
    [ 3, 'SMSタイプ： 「お名前入力」、「電話番号入力」、「スタッフ選択」必須' ],
    [ 4, '短縮タイプ： 「全て省略」 ＊現状は Google 専用' ]
  ]

  def make_qr_image
    case params[:qr_type].to_i
    when 1
      path = generate_qr("/qr/normal?business_id=#{@business.id}")
      SettingQr::Normal.init_qr(@business, path)
    when 2
      path = generate_qr("/qr/anonymous?business_id=#{@business.id}")
      SettingQr::Anonymous.init_qr(@business, path)
    when 3
      path = generate_qr("/qr/sms?business_id=#{@business.id}")
      SettingQr::Sms.init_qr(@business, path)
    when 4
      path = generate_qr("/qr/simple?business_id=#{@business.id}")
      SettingQr::Simple.init_qr(@business, path)
    end
  end

  def generate_qr(uri)
    base_url = ENV['DOMAIN']
    qrcode = RQRCode::QRCode.new(base_url + uri)
    path = "tmp/#{SecureRandom.uuid}.png"
    qrcode.as_png(
      resize_gte_to: false,
      resize_exactly_to: false,
      fill: 'white',
      color: 'black',
      size: 180,
      border_modules: 4,
      module_px_size: 6,
      file: path
    )
    path
  end
end
