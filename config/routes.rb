Rails.application.routes.draw do
  resources :real_estate_images

  resources :real_estate_real_estate_utilities

  resources :real_estate_region_utilities

  resources :real_estate_disadvantages

  resources :real_estate_advantages

  resources :streets

  resources :wards

  resources :districts

  resources :provinces

  resources :real_estate_utilities

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

  root 'home#index'

  resources :home do
    collection do
      get 'index'
    end
  end
  resources :real_estates do
    collection do
      get 'index'
      get 'category'
      get 'view'
      get 'create'
    end
  end
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
  resources :news

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
