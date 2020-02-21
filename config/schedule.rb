ENV.each { |k, v| env(k, v) }

set :environment, ENV['RAILS_ENV']
set :output, 'log/whenever.log'
set :job_template, "bash -l -c ':job'"
job_type :test, 'cd :path && :task :output'

# every 1.day, :at => '15:00 pm' do # AM00時
#   runner "Business.retrieve_rank_all"
# end

# ============= データ獲得・スクレイピング処理 =============
every 2.hours do
  runner "Business.retrieve_reviews_all"
end

every '0 */2 * * *' do
  runner "Business.retrieve_insights_data"
end

every '5,35 * * * *' do
  runner "BusinessCrawler.retrieve_rank_all_lamda"
end

every '10,40 * * * *' do
  runner "BusinessCrawler.retrieve_rank_all_crawler"
end

# ============= AWS関係処理 =============

# 古いスクレイピング画像削除
every '0 0 15 * *' do
  runner "BusinessCrawler.delete_images_error_s3"
end

# AWSのバウンスメール処理
every 1.hours do
  runner "AmazonMailSqsService.execute"
end

# ============= 決済関係 =============
every '0 1 1 * *' do
  rake "total_monthly_fee:execute"
end

# PM23時50
every 1.day, :at => '23:50' do
  runner "KeywordsHistory.count_keyword_from_meo_history"
end

# AM0時05（コードで月初しか実装しないようにしている）
every 1.day, :at => '0:05' do
  runner "KeywordsHistory.update_pre_keyword_count"
end

# 毎月1日、AM2時（コードで月初しか実装しないようにしている）
every 1.day, :at => '2:00' do
  runner "PaymentHistory.calc_amount"
end

# 毎月14日の23:00に決済する
every '0 23 14 * *' do
  runner "PaymentHistory.exec_payment"
end

# ============= MEO機能の自動処理 =============
# PM13時00 21時00
every '0 13,21 * * *' do
  runner "AutoReplyReview.execute"
end

# 1分目＋31分目
every '1,31 * * * *' do
  runner "AutoPost.execute"
end

# Send scheduled SMS
every 30.minutes do
  runner "Message.exec_requested_sms"
end

# Send scheduled email
every 30.minutes do
  runner "Message.exec_requested_email"
end

# ============= Cronのテスト =============
# Test script to see if cron ran at GMT+0
every '25 23 * * *' do
  test "date"
end
