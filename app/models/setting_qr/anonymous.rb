# == Schema Information
#
# Table name: setting_qrs
#
#  id          :bigint           not null, primary key
#  type        :string(255)      not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  business_id :bigint           not null
#
# Indexes
#
#  index_setting_qrs_on_business_id  (business_id)
#
# Foreign Keys
#
#  fk_rails_...  (business_id => businesses.id)
#

class SettingQr::Anonymous < SettingQr
  def self.init_qr(business, image_path)
    qr = find_or_initialize_by(business: business)
    result = qr.save
    qr.image.purge
    qr.image.attach(io: open(image_path), filename: "business_#{business.id}_anonymous.png") if result
    File.delete(image_path) if File.exist?(image_path)
    result
  end
end
