Shibcert::Application.routes.draw do

  root to: redirect("/#{I18n.default_locale}")

  scope '(:locale)', locale: /ja|en/ do  
    root "certs#index", as: "locale_root"
    match '/'  => 'certs#index', :via => :post
    
    post "certs/request_post"
    get "certs/request_result/:id", to: 'certs#request_result', \
        as: 'request_result'

    post "certs/disable_post/:id",  to: 'certs#disable_post', \
        as: 'disable_post'         
    get "certs/disable_result/:id", to: 'certs#disable_result', \
        as: 'disable_result'

#    post "certs/renew_post/:id",  to: 'certs#renew_post', \
#        as: 'renew_post'         
#    get "certs/renew_result/:id", to: 'certs#renew_result', \
#        as: 'renew_result'

    resources :certs do
      member do
        post "edit_memo_remote"
      end
    end

#    resources :cert_states
#    resources :cert_types
#    resources :users
#    resources :roles
#    resources :requests
    
    get '/auth/:provider/callback' => 'sessions#create'
    get '/auth/:failure' => 'sessions#failure'
    get '/signout' => 'sessions#destroy', :as => :signout
    
    get  'admin',              to: 'admin#index'
    post 'admin',              to: 'admin#index'
    get  'admin/user/:id',     to: 'admin#user'
    post 'admin/user/:id',     to: 'admin#user'
    get  'admin/cert/:id',     to: 'admin#cert'
    post 'admin/cert/:id',     to: 'admin#cert'
    get  'admin/sync/',        to: 'admin#sync'
    post 'admin/sync/',        to: 'admin#sync'
    get  'admin/show/:type',   to: 'admin#show'
    post "admin/update_post/", to: 'admin#update_post'
    get  'admin/clear/',       to: 'admin#clear'
    get  'admin/error/:id',    to: 'admin#error'
    post 'admin/error/:id',    to: 'admin#error'
    post "admin/disable_post/:id",   to: 'admin#disable_post'
    get  "admin/disable_result/:id", to: 'admin#disable_result'
    post "admin/delete_post/:id",    to: 'admin#delete_post'
    get  "admin/delete_result/:id",  to: 'admin#delete_result'
#    get  "admin/delete_result/:id",  to: 'admin#delete_result', \
#          as: 'delete_result'

    # The priority is based upon order of creation: first created -> highest priority.
    # See how all your routes lay out with "rake routes".
    
    # You can have the root of your site routed with "root"
    # root 'welcome#index'
    
    # Example of regular route:
    #   get 'products/:id' => 'catalog#view'
    
    # Example of named route that can be invoked with purchase_url(id: product.id)
    #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase
    
    # Example resource route (maps HTTP verbs to controller actions automatically):
    #   resources :products
    
    # Example resource route with options:
    #   resources :products do
    #     member do
    #       get 'short'
    #       post 'toggle'
    #     end
    #
    #     collection do
    #       get 'sold'
    #     end
    #   end
    
    # Example resource route with sub-resources:
    #   resources :products do
    #     resources :comments, :sales
    #     resource :seller
    #   end
    
    # Example resource route with more complex sub-resources:
    #   resources :products do
    #     resources :comments
    #     resources :sales do
    #       get 'recent', on: :collection
    #     end
    #   end
    
    # Example resource route with concerns:
    #   concern :toggleable do
    #     post 'toggle'
    #   end
    #   resources :posts, concerns: :toggleable
    #   resources :photos, concerns: :toggleable
    
    # Example resource route within a namespace:
    #   namespace :admin do
    #     # Directs /admin/products/* to Admin::ProductsController
    #     # (app/controllers/admin/products_controller.rb)
    #     resources :products
    #   end
  end

  # メール連携API
  get  'mail',            to: 'mail#index'
  get  'mail/processor',  to: 'mail#processor'
  post 'mail/processor',  to: 'mail#processor'

  # UPKI-PASS試験用ダミーAPI
  get 'upki-pass',                 to: 'passtest#index'
  post 'upki-pass/recvcert',       to: 'passtest#recvcert'
#  get 'upki-pass/recvcert',        to: 'passtest#recvcert'
  post 'upki-pass/recvrevocation', to: 'passtest#recvrevocation'
#  get 'upki-pass/recvrevocation',  to: 'passtest#recvrevocation'

end
