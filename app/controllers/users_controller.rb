class UsersController < ApplicationController
  def new
  end

  def show
    @user = User.find_by(id: params[:id])
    
    if @user.nil? || current_user != @user
      flash[:warning] = "You must be logged in to access this page."
      redirect_to users_login_path
    end
  end  

  def create
    @user = User.new(user_params)
    @user.role = params[:role]
    @user.status = 'pending' if agent?

    if user_params_valid? && agent? && @user.save
      flash[:success] = "Account created with advanced features pending approval"
      session[:user_id] = @user.id
      redirect_to user_path(@user)
    elsif user_params_valid? && @user.save
      flash[:success] = "User created successfully"
      session[:user_id] = @user.id
      redirect_to user_path(@user)
    else
      flash[:warning] = "Invalid entries, please try again"
      redirect_to new_user_path
    end
  end

  def edit
    if !session[:user_id]
      flash[:warning] = "You must be logged in to access this page."
      redirect_to users_login_path
    else
      @user = User.find(params[:id])
      if @user.nil? || current_user != @user
        flash[:warning] = "You must be logged in to access this page."
        redirect_to users_login_path
      end
    end
  end
  
  def update
    @user = current_user
    
    if params[:user][:new_password] == params[:user][:password_verify]
      if @user.update(password: params[:user][:new_password])
        flash[:success] = "Your password has been updated successfully."
        redirect_to user_path(params[:id])
      end
    else
      flash[:danger] = "Invalid credentials.  Please try again."
      redirect_to edit_user_path(params[:id])
    end
  end

  def destroy
    @user = User.find_by(id: params[:id])
    @user.destroy
    session[:user_id] = nil
    flash[:success] = "Your account has been successfully deleted."
    redirect_to root_path
  end
  
  
  def login_form
  end

  def login
    user = User.find_by(username: params[:username])
  
    if user && user.authenticate(params[:password])
      if user.admin? 
        session[:user_id] = user.id
        flash[:success] = "Logged in as an admin"
        redirect_to admin_dashboard_index_path
      else
        session[:user_id] = user.id
        flash[:success] = "Logged in successfully"
        redirect_to user_path(user.id)
      end
    else
      flash[:warning] = "Invalid credentials. Please try again."
      redirect_to users_login_path
    end
  end
  
  
  def logout
    @user = nil
    session[:user_id] = nil
    flash[:success] = "You have successfully logged out"
    redirect_to root_path
  end
  
  private

  def user_params
    params.permit(:username, :password)
  end
  
  def user_params_valid?
    !user_params[:username].empty? && !user_params[:password].empty? && user_params[:password] == params[:password_verify]
  end

  def agent?
    params[:role] == "agent"
  end

  def admin?
    self.username == "admin"
  end
end