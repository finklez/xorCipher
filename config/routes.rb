Rails.application.routes.draw do
  resources :crack_my_pass, only: [:new, :create]


  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
