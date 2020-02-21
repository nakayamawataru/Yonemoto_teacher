# == Schema Information
#
# Table name: plans
#
#  id          :bigint           not null, primary key
#  init_price  :integer
#  month_price :integer
#  name        :string(255)
#  type        :string(255)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class Plan < ApplicationRecord
  self.inheritance_column = :_type_disabled
  has_many :users
  has_many :payment_histories

  ENTRY = 1
  RENTAL = 2
  KEYWORD_MEO = 3
  MEO_BASIC = 4
  MEO_FULL = 5
  NO_PLAN = 6
  DEMO = 6

  def calc_month_fee(user)
    case type
    when 'entry' # "エントリープラン"
      # 5,500円/月
      return month_price
    when 'rental' # "レンタルプラン"
      # 初期費用 60,500円
      # 計測キーワード数に応じて
      return calc_keyword_price(user.pre_keyword_count)
    when 'keyword_meo' # "成果報酬MEO"
      # 対策4キーワード中1キーワードでも上位表示した場合、日額1,000（税別）が課金される成果報酬プラン。
      # 4キーワード全部が上位表示された場合も上限は1,000円（税別）
      if businesses = user.businesses
        price = 0
        businesses.map{|business| price += business.try!(:total_monthly_fees).try!(:last).try!(:value).to_i}
        return price
      end
    when 'meo_basic' # "MEO（固定）"
      # 11,000円/月
      return month_price
    when 'meo_full' # "MEOフルプラン"
      # 16,500円/月
      return month_price
    end
    return 0
  end


  def calc_keyword_price(keyword_count)
    price = 0
    price =
      if (0..5_000).include? keyword_count
        55_000
      elsif (5_001..10_000).include? keyword_count
        75_000
      elsif (10_001..15_000).include? keyword_count
        95_000
      elsif (15_001..20_000).include? keyword_count
        105_000
      elsif (20_001..25_000).include? keyword_count
        110_000
      elsif (25_001..30_000).include? keyword_count
        115_000
      elsif (30_001..35_000).include? keyword_count
        120_000
      elsif (35_001..40_000).include? keyword_count
        125_000
      elsif (40_001..45_000).include? keyword_count
        130_000
      elsif (45_001..50_000).include? keyword_count
        135_000
      elsif (50_001..55_000).include? keyword_count
        140_000
      elsif (55_001..60_000).include? keyword_count
        145_000
      elsif (60_001..65_000).include? keyword_count
        150_000
      elsif (65_001..70_000).include? keyword_count
        160_000
      elsif (70_001..75_000).include? keyword_count
        170_000
      elsif (75_001..80_000).include? keyword_count
        180_000
      elsif (80_001..90_000).include? keyword_count
        190_000
      elsif (90_001..100_000).include? keyword_count
        200_000
      elsif (100_001..150_000).include? keyword_count
        215_000
      elsif (150_001..100_000_000).include? keyword_count
        230_000
      end
    return price
  end
end
