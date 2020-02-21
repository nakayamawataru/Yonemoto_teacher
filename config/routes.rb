Rails.application.routes.draw do
  root 'businesses#index'

  devise_for :users, only: [:sessions, :omniauth_callbacks, :registrations],
    controllers: {
      sessions: 'users/sessions',
      omniauth_callbacks: 'users/omniauth_callbacks',
      registrations: 'users/registrations'
    }

  # Fix conflict between devise path and resources path
  devise_scope :user do
    post '/users/create', to: 'users#create', as: :create_user
  end

  resources :users, except: %i[create] do
    resources :managers, only: :new
    delete '/remove_card', :to => 'users#remove_card'
    collection do
      post 'update_payment_discount', to: 'users#update_payment_discount'
    end
  end
  resources :businesses do
    member do
      put :connect_google_location
      get :edit_memo
      put :update_memo
    end
  end
  resources :memos
  resources :charts, only: :index do
    collection do
      get 'chart_category', to: 'charts#chart_category'
      get 'iframe', to: 'charts#iframe'
    end
  end
  resources :calendars, only: :index do
    collection do
      post 'export_csv', to: 'calendars#export_csv', defaults: { format: 'csv' }
      post 'export_rank', to: 'calendars#export_rank', defaults: { format: 'csv' }
      get 'image-rank', to: 'calendars#image_rank'
      post 'update_rank', to: 'calendars#update_rank'
    end
  end
  resources :reports, only: :index
  resources :messages, only: %i[index create destroy]
  post "message-import", to: 'messages#import', as: "message_import"
  resources :reviews, only: %i[index show] do
    member do
      get 'fetch', to: 'reviews#fetch'
      post 'reply', to: 'reviews#reply'
      post 'destroy_reply', to: 'reviews#destroy_reply'
    end
    collection do
      get 'export_csv', defaults: { format: 'csv' }
    end
  end
  resources :insights, only: :index do
    member do
      get 'fetch', to: 'insights#fetch'
    end
    collection do
      get 'export_csv', to: 'insights#export'
      post 'export_csv', to: 'insights#export_csv', defaults: { format: 'csv' }
    end
  end
  resources :qr, except: [:new, :create, :edit, :update, :show, :destroy] do
    collection do
      get 'simple', to: 'qr#simple'
      get 'normal', to: 'qr#normal'
      post 'normal_process', to: 'qr#normal_process'
      get 'sms', to: 'qr#sms'
      post 'sms_process', to: 'qr#sms_process'
      get 'anonymous', to: 'qr#anonymous'
      post 'anonymous_process', to: 'qr#anonymous_process'
    end
  end
  resources :base_locations, only: %i[index show]
  resources :locations, only: %i[index]
  namespace :api do
    get 'base_locations/find_base_location', to: 'base_locations#find_base_location'
    get 'sms_patterns/content_pattern', to: 'sms_patterns#content_pattern'
    get 'email_patterns/content_pattern', to: 'email_patterns#content_pattern'
    get 'charts/rank_by_date', to: 'charts#rank_by_date'
    get 'benchmark_business_limit', to: 'users#benchmark_business_limit'
  end

  namespace :setting do
    resources :qr, only: :index
    resources :staffs
    resources :sms, only: [:index, :create]
    resources :qa_reviews, only: [:index, :create]
    resources :goals, only: :index
    resources :widgets, only: :index
    resources :keyword_reviews
    resources :reply_reviews, only: [:index, :create]
    namespace :batch do
      resources :reply_reviews, only: [:index, :create]
    end
    resources :ses_blacklist_emails, only: %i[index destroy]
    resources :email, only: [:index, :create]

    post 'qr', to: 'qr#create', as: 'init_qr'
    post 'goal', to: 'goals#create', as: 'init_goal'
  end
  resources :coupons do
    collection do
      get 'display/:slug', to: 'coupons#display', as: 'display'
      post 'consume/:slug', to: 'coupons#consume', as: 'consume'
    end
    member do
      get 'preview', to: 'coupons#preview'
      post 'sms', to: 'coupons#sms'
    end
  end
  resources :cv do
    collection do
      get ':slug', to: 'cv#display', as: 'display'
      post ':slug', to: 'cv#consume', as: 'consume'
    end
  end

  resources :exports_csv, only: :index do
    collection do
      post 'export', to: 'exports_csv#export', defaults: { format: 'csv' }
      post 'export_statictical_rank', to: 'exports_csv#export_statictical_rank', defaults: { format: 'csv' }
      post 'export_below_top_rank', to: 'exports_csv#export_below_top_rank', defaults: { format: 'csv' }
      post 'export_reviews', to: 'exports_csv#export_reviews', defaults: { format: 'csv' }
    end
  end

  resources :imports, only: :index do
    collection do
      post 'export_template', to: 'imports#export_template', defaults: { format: 'csv' }
      post 'upload_rank'
    end
  end
  resources :calculate_payment_amounts, only: :index
  resources :posts, except: :destroy

  get '/payment' => 'payments#new'
  post '/payment' => 'payments#create'
  resources :payments do
    collection do
      get 'estimate', to: 'payments#estimate'
    end
  end

  get 'widgets/show', to: 'widgets#show'
  get 'js/widget', to: 'widgets#widget'

  resources :alerts, only: :index
  resources :sms_reviews, only: %i[create show update]
  resources :r, controller: :business_reviews, only: :show do
    member do
      get 'platforms'
      get 'platforms_google'
      get 'questions'
      post 'answer'
      get 'template_review'
      get 'feedback'
      post 'send_feedback'
      get 'thank_you'
    end
  end

  namespace :download do
    namespace :pdf do
      resources :reports, only: :index
    end
  end

  resources :notifications

  if Rails.env.development? || Rails.env.staging?
    mount LetterOpenerWeb::Engine, at: '/letter_opener'
  end
end
