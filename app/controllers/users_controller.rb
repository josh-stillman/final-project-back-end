require 'activerecord-import'
require 'csv'


class UsersController < ApplicationController

  def matched_transactions
    #filter transactions by user
    #filter transactions by analyzed months -- model method to return this array
    #subsequent model method to spit out matched transactions.

    #also need to get the business for each matched transaction
    #then include nested business
    me = User.find(params[:id])
    @transactions = me.matched_transactions
    render json: @transactions.order(date: :desc), user_id: params[:id]

  end

  def unmatched_transactions
    me = User.find(params[:id])
    @transactions = me.matched_untransactions
    render json: @transactions.order(date: :desc), user_id: params[:id]
  end

  def load_new_month
    me = User.find(params[:id])
    if me.load_new_month
      render json: {success: true}
    else
      render json: {success: false}
    end
  end

  def businesses
    me = User.find(params[:id])
    @businesses = me.businesses
    render json: @businesses.where.not(id: 1), each_serializer: MatchedBusinessSerializer, user_id: params[:id]
  end

  def show
    @user = User.find(params[:id])
    render json: @user, each_serializer: UserSerializer
  end

  def create

    @user = User.new(name: params[:username], password: params[:password])

    if @user.valid?
      @user.save
      render json: @user
    else
      render json: {errors: @user.errors.full_messages}
    end
    #@user.valid? ? render json: @user : render json: @user.errors.messages
    #render json: @user
  end

  def import_csv
    puts "hello, user with id of #{params[:id]}"
    puts params[:file]

    columns = [:date, :description, :original, :amount, :category, :user_id]
    values = []
    # i = 1

    CSV.foreach(params[:file].path, headers: true) do |row|
      # if i == 3
      #   break
      # end
      # i += 1
      # row_date = Date.strptime(row[0], '%m/%d/%Y')
      # puts [row_date, row[1], row[2], row[3].to_f, row[5], 1]

      unless row[4] == "credit"
        row_date = Date.strptime(row[0], '%m/%d/%y')
        row_array = [row_date, row[1], row[2], row[3].to_f, row[5], params[:id]]
        values << row_array
      end
      x = User.find(params[:id])
      x.newest_transaction_month
    end

    if User.find(params[:id]).transactions == []
      Transaction.import columns, values, :validate => false
    else
      Transaction.import columns, values, :validate => true
    end
    render json: {success: true}
  end

  private

  def user_params
    params.require(:username, :password)
  end


end
