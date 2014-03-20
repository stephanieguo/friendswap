class UserController < ApplicationController

  #Dashboard page
	def dashboard
		@current_user ||= User.find(session[:user_id]) if session[:user_id]
	end

  #Inbox page
	def inbox
		@current_user ||= User.find(session[:user_id]) if session[:user_id]
    @emails = Email.find_all_by_receiver(@current_user)
	end

	#Shows a user's listings
  def listings
		@current_user ||= User.find(session[:user_id]) if session[:user_id]
		@listings = Listing.find_all_by_user_id(@current_user)
	end

  #Edit a listing
	def edit
		@current_user ||= User.find(session[:user_id]) if session[:user_id]
	end

  #Updates the listing after the user submits an edit
	def update
		@current_user ||= User.find(session[:user_id]) if session[:user_id]
		picture = params[:photo]

  	if picture != nil
    		file = File.new(Rails.root.join('app', 'assets', 'images', picture.original_filename), 'wb')
    		file.write(picture.read)
    		submission_hash = {"email" => params[:email],
                     "bio" => params[:bio],
                     "photo" => picture.original_filename}
        @current_user.update_attributes(submission_hash)
        render :action => 'crop'
    	else
    		submission_hash = {"email" => params[:email],
                     "bio" => params[:bio]}
        @current_user.update_attributes(submission_hash)
        redirect_to :controller => :user, :action => :profile
    	end

	end

  #Post-crop actions
  def post_crop
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
    w = params[:w]
    h = params[:h]
    x1 = params[:x1]
    y1 = params[:y1]

    require 'open-uri'
    if File.exist?(Rails.root.join('app', 'assets', 'images', @current_user.photo))
      img = MiniMagick::Image.open(Rails.root.join('app', 'assets', 'images', @current_user.photo))
      if img[:width] > 800 || img[:height] > 500
        img.resize('800x500')
      end
      img.crop("#{w}x#{h}+#{x1}+#{y1}")
      img.write(Rails.root.join('app', 'assets', 'images', @current_user.uid + '.jpg'))
      img
      submission_hash = {"photo" => @current_user.uid + '.jpg'}
      @current_user.update_attributes(submission_hash)
    end

    redirect_to :controller => :user, :action => :profile
  end

  #Sending an email page
  def email
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end

  #Post email sending, redirects back to inbox
  def post_email
    @email = Email.new
    @email.subject = params[:subject]
    @email.body = params[:body]
    @email.sender = User.find(params[:sender]).id
    @email.receiver = params[:receiver]
    @email.save()
#    flash[:notice] = "Email sent successfully."
    if params[:linkedfrom] == 'listing'
      redirect_to :controller => :listings, :action => :listing, :id => params[:listing]
    else
      redirect_to :controller => :user, :action => :inbox
    end
  end

  #displays the page that has the thread between a user and the sender
  def thread
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
    @emails = Email.all
  end

end