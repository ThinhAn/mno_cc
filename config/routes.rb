Rails.application.routes.draw do

  # Root

    root 'home#index'

  # / Root

  # Home, shared

    get '/404', to: 'home#error', defaults: { error: '404' }
    get '/422', to: 'home#error', defaults: { error: '422' }
    get '/500', to: 'home#error', defaults: { error: '500' }

    get 'home/result'
    get 'home/index'
    get 'home/back'
    post 'set_width/:width_type' => 'home#set_width'
    # post 'nothing' => 'home#nothing'
    # post 'end_session' => 'home#end_session'
    # post 'track_session' => 'home#track_session'

  # / Home, shared

  # Search
  
    get 'search' => 'home#search'
    get '_search_list' => 'home#_search_list'

  # / Search

  # Real estate

    get 'real_estates/_block_create/:block_id/:group_id' => 'real_estates#_block_create'
    get 'real_estates/_block_item_list/:block_id' => 'real_estates#_block_item_list'
    get 'real_estates/_block_description_item_list/:block_id' => 'real_estates#_block_description_item_list'
    post 'real_estates/preview' => 'real_estates#preview'
    post 'real_estates/create' => 'real_estates#save'
    post 'real_estates/block_create' => 'real_estates#block_save'
    post 'real_estates/save_interact_images'
    post 'real_estates/set_appraisal_company'
    post 'real_estates/delete/:id' => 'real_estates#delete'
    post 'real_estates/change_show_status/:id/:is_show' => 'real_estates#change_show_status'
    post 'real_estates/change_force_hide_status/:id/:is_force_hide' => 'real_estates#change_force_hide_status'
    post 'real_estates/change_favorite_status/:id/:is_favorite' => 'real_estates#change_favorite_status'
    post 'real_estates/approve/:id' => 'real_estates#approve'
    post 'real_estates/user_favorite/:id/:is_add' => 'real_estates#user_favorite'

    get 'real_estates/groups/get_image_for_interact_build/:id' => 'real_estates#groups_get_image_for_interact_build'
    get 'real_estates/groups/get_data_for_interact_view/:id' => 'real_estates#groups_get_data_for_interact_view'

    get 'bat-dong-san/danh-sach' => 'real_estates#list'
    get 'bat-dong-san/danh-sach-:search' => 'real_estates#list'
    get 'bat-dong-san/dang-tin(/:id)' => 'real_estates#create'
    get 'bat-dong-san/chinh-sua(/:id)' => 'real_estates#create'
    get 'bat-dong-san/cua-toi' => 'real_estates#my'
    get 'bat-dong-san/yeu-thich-cua-toi' => 'real_estates#my_favorite'
    get 'bat-dong-san/kiem-duyet' => 'real_estates#pending'
    get 'bat-dong-san/quan-ly' => 'real_estates#manager'

    get 'bat-dong-san/:slug', constraints: { slug: /(\w|-)*\d+/ }, controller: 'real_estates', action: 'view'

    get 'bat-dong-san(/:action(/:id))', controller: 'real_estates', action: 'index'
    get 'real_estates(/:action(/:id))', controller: 'real_estates', action: 'index'

  # / Real estate

  # Project

    get 'projects/set_is_full_status/:id/:is_full' => 'projects#set_is_full_status'
    post 'projects/create' => 'projects#save'
    post 'projects/delete/:id' => 'projects#delete'
    post 'projects/change_show_status/:id/:is_show' => 'projects#change_show_status'
    post 'projects/approve/:id' => 'projects#approve'
    post 'projects/change_force_hide_status/:id/:is_force_hide' => 'projects#change_force_hide_status'
    post 'projects/change_favorite_status/:id/:is_favorite' => 'projects#change_favorite_status'
    post 'projects/user_favorite/:id/:is_add' => 'projects#user_favorite'
    post 'projects/save_interact_images'

    get 'du-an/dang-tin(/:id)' => 'projects#create'
    get 'du-an/chinh-sua(/:id)' => 'projects#create'
    get 'du-an/cua-toi' => 'projects#my'
    get 'du-an/yeu-thich-cua-toi' => 'projects#my_favorite'
    get 'du-an/kiem-duyet' => 'projects#pending'
    get 'du-an/quan-ly' => 'projects#manager'

    get 'du-an/:slug', constraints: { slug: /(\w|-)*\d+/ }, controller: 'projects', action: 'view'

    get 'du-an(/:action(/:id))', controller: 'projects', action: 'index'
    get 'projects(/:action(/:id))', controller: 'projects', action: 'index'

  # / Project

  # Block

    get 'blocks/_create/:project_id(/:id)' => 'blocks#_create'
    get 'blocks/_description_item_list/:project_id' => 'blocks#_description_item_list'
    get 'blocks/get_image_for_interact_build/:id' => 'blocks#get_image_for_interact_build'
    get 'blocks/get_data_for_interact_view/:id' => 'blocks#get_data_for_interact_view'
    post 'blocks/create' => 'blocks#save'
    post 'blocks/delete'
    post 'blocks/save_interact_images'

    get 'blocks/floors/get_image_for_interact_build/:id' => 'blocks#floors_get_image_for_interact_build'
    get 'blocks/floors/get_data_for_interact_view/:id' => 'blocks#floors_get_data_for_interact_view'
    post 'blocks/floors/save_interact_images' => 'blocks#floors_save_interact_images'

  # / Block

  # User

    get 'signup' => 'users#create'
    get 'signin' => 'users#signin'
    get 'signout' => 'users#signout'
    get 'active_account_signin' => 'users#active_account_signin'
    get 'auth/:provider/callback' => 'users#facebook_signin'
    get 'users/:id' => 'users#view'
    post 'register' => 'users#save'
    post 'signin' => 'users#signin_handle'
    post 'users/forgot_password' => 'users#forgot_password_handle'
    post 'users/change_type'
    post 'users/change_password'
    post 'users/cancel_change_email/:id' => 'users#cancel_change_email'


    get 'dang-ky' => 'users#create'
    get 'dang-nhap' => 'users#signin'
    get 'quen-mat-khau' => 'users#forgot_password'
    get 'thanh-vien/quan-ly' => 'users#manager'

    get 'thanh-vien/:id', constraints: { id: /\d+/ }, controller: 'users', action: 'view'

    get 'thanh-vien/:action(/:id)', controller: 'users', action: 'index'
    get 'users/:action(/:id)', controller: 'users', action: 'index'

    post 'dang-nhap' => 'users#signin_handle'

  # / User

  # Contact user info

    get 'contact_user_infos' => 'contact_user_infos#index'
    post 'contact_user_infos/create' => 'contact_user_infos#save'

  # / Contact user info

  # Contact request

    get 'contact_requests/index'
    get 'contact_requests/_index_list'
    get 'contact_requests/_view_statistic/:id' => 'contact_requests#_view_statistic'
    get 'contact_requests' => 'contact_requests#index'
    post 'contact_requests/set_result'

  # / Contact request

  # Session

    get 'sessions' => 'sessions#index'
    get 'sessions/get_data'

  # / Session

  # Appraisal company

    get 'appraisal_companies/autocomplete'
    get 'appraisal_companies/create(/:id)' => 'appraisal_companies#create'
    get 'appraisal_companies/manager'
    get 'appraisal_companies/_manager_list'
    get 'appraisal_companies/appraise'
    get 'appraisal_companies/_appraise_list'
    post 'appraisal_companies/create' => 'appraisal_companies#save'
    post 'appraisal_companies/set_price'
    post 'appraisal_companies/delete/:id' => 'appraisal_companies#delete'

  # / Appraisal company

  # Blog

    get 'blogs/create(/:id)' => 'blogs#create'
    get 'blogs/:id' => 'blogs#view'
    get 'blogs' => 'blogs#index'
    post 'blogs/create' => 'blogs#save'
    post 'blogs/delete'

  # / Blog

  # Image content

    post 'image_contents/upload'

  # / Image content

  # Question

    get 'questions/create'
    get 'questions/manager'
    get 'questions/_manager_list'
    post 'questions/create' => 'questions#save'
    post 'questions/answer' => 'questions#answer'
    post 'questions/pin/:id/:status' => 'questions#pin'
    post 'questions/delete/:id' => 'questions#delete'

  # / Question

  # Mail box

    get 'mail_boxes/compose(/:id)' => 'mail_boxes#compose'
    get 'mail_boxes/inbox'
    get 'mail_boxes/_inbox_list'
    get 'mail_boxes/sent'
    get 'mail_boxes/_sent_list'
    get 'mail_boxes/draft'
    get 'mail_boxes/_draft_list'
    get 'mail_boxes/read/:id' => 'mail_boxes#read'
    get 'mail_boxes' => 'mail_boxes#inbox'
    post 'mail_boxes/send_mail'
    post 'mail_boxes/inbox_remove'
    post 'mail_boxes/sent_remove'
    post 'mail_boxes/delete' => 'mail_boxes#delete'

  # / Mail box

  # Investor

    get 'investors/autocomplete'
    get 'investors/manager'
    get 'investors/_manager_list'
    post 'investors/delete/:id' => 'investors#delete'
    post 'investors/rename'

  # / Investor

  # Temp

    #Business
    get 'businesses/manager'
    get 'businesses/create'
    get 'businesses/create_category'  

    #Province
    get 'provinces/get_full_data/:id' => 'provinces#get_full_data'

    #Temporary file
    post 'temporary_files/upload'

    resources :businesses do
      collection do
        get 'index'
      end
    end
    resources :projects do
      collection do
        get 'index'
        get 'view'
      end
    end
    resources :investors
    resources :project_types
    resources :news
    resources :streets
    resources :wards
    resources :districts
    resources :provinces
    resources :property_utilities
    resources :images
    resources :region_utilities
    resources :disadvantages
    resources :advantages
    resources :planning_status_types
    resources :legal_record_types
    resources :constructional_levels
    resources :directions
    resources :real_estate_types
    resources :street_types
    resources :units
    resources :currencies
    resources :purposes

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

  # / Temp
end
