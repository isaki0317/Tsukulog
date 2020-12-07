Rails.application.routes.draw do

  devise_for :end_users, controllers: {
    sessions: 'end_users/sessions',
    registrations: 'end_users/registrations'
  }
  devise_for :admin, controllers: {
    sessions: 'admin/sessions',
  }
  #チャット機能に関するAdmin側のルーティングを追加する必要がある
  namespace :admin do
    get 'top' => 'homes', as: 'top'
    get 'search' => 'searchs', as: 'search'
    resources :genres, only: [:index, :create, :updete, :destroy]
    resources :contacts, only: [:index, :show, :update]
    resources :comments, only: [:destroy]
    resources :posts, only: [:index, :show, :update, :destroy]
    resources :end_users, only: [:index, :show, :edit, :update, :destroy]
  end

  scope module: :end_user do
    resources :chats  #showの部分を確認する
    root 'homes#top'
    get 'about' => 'homes#about'
    get 'search' => 'searchs#search', as: 'search'
    delete 'notifications/destroy_all' => 'notifications#destroy_all'
    resources :end_users, only: [:show, :edit, :update] do
      resource :relationships, only: [:create, :destroy]
      get :follows, on: :member
      get :followers, on: :member
      collection do
        get 'quit'
  	    patch 'out'
  	  end
    end
    resources :contacts, only: [:create]
    resources :posts do
      resources :works, only: [:destroy]
      resources :materials, only: [:destroy]
      resources :comments, only: [:create, :destroy]
      resource :bookmarks, only: [:create, :destroy]
      resource :favorites, only: [:create, :destroy]
    end
  end
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
