Rails.application.routes.draw do
  root to: "crack_my_pass#new"

  resources :crack_my_pass, only: [:new, :create]


  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
