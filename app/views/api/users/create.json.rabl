object @user => nil

node(:user)  { partial 'users/show', object: @user } if @user
node(:token) { partial 'tokens/show', object: @token } if @token
