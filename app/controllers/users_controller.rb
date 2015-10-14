require "net/http"
require "uri"
class UsersController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :set_user,:except => [:iscas,:iscasCallback,:iscasLogin ,:get_current_access_token]

#Method name:iscas
#Des:redirect_to 网络帐号系统
#Author Name:liujinxia
  def iscas
    redirect_to "https://124.16.141.142/oauth/authorize?client_id=7&client_secret=h9LAQKuwdM3oaMhT&redirect_uri=http://localhost:3000/users/iscasCallback&response_type=code"
  end

#Method name:iscasCallback
#Des:after login and 授权 from 网络帐号系统,call this method to get the accessToken and user basic Info
#Author Name:liujinxia
  def iscasCallback
    code = params[:code]
    logger.debug "code : #{code}"
    accessToken = getAccessTokenByCode(code)
    if accessToken==nil
      redirect_to root_path
    else
      userInfo = getUserInfoByAccessToken(accessToken)
      userEmail = getUserEmail(userInfo)
      redirect_to "http://localhost:3000/users/iscasLogin?userEmail=#{userEmail}"
    end
  end

#Method name:iscasLogin
#Des:we got the user Info and sign in the gitlab
#Author Name:liujinxia
  def iscasLogin
    #设置标记位，以免影响gitlab原版的正常使用
    session[:nfs]="1"
    loginUrl = URI.parse("http://localhost:3000/users/sign_in")
    useremail = params[:userEmail]
    params = {}
    params["user[login]"] = useremail
    #查询并判断该用户的信息是否在gitlab中存在
    user = User.find_by(email: useremail)


    #user存在，即已经注册过了
    if user!=nil
      params["user[password]"] = useremail
      params["user[remember_me]"] = '0'
      http = Net::HTTP.new(loginUrl.host, loginUrl.port)
      req = Net::HTTP::Post.new(loginUrl.path)
      req.set_form_data(params)

      res = http.request(req)
      session[:authenticity_token] = User.find_by(email:useremail).authentication_token
      redirect_to root_path
    else
      #帮助用户实现注册
      registerUrl = URI.parse("http://localhost:3000/users")
      params1 = {}
      logger.info "userEmail=#{useremail}"
      params1["user[email]"] = useremail
      params1["user[password]"] = useremail
      params1["user[name]"] = useremail.split("@")[0]
      logger.info "name:#{params1["user[name]"]}"
      params1["user[username]"] = useremail.split("@")[0]
      logger.info "username:#{params1["user[username]"]}"
      http1 = Net::HTTP.new(registerUrl.host, registerUrl.port)
      req1 = Net::HTTP::Post.new(registerUrl.path)
      req1.set_form_data(params1)
      res1 = http1.request(req1)
      redirect_to root_path
    end
  end

#Method name:get_current_access_token
#Des: 获取当前用户的access_token
#Author Name:liujinxia
  def get_current_access_token
    access_token = cookies[:access_token_from_iscas]
    access_token
  end

  def show
    @contributed_projects = contributed_projects.joined(@user).
      reject(&:forked?)

    @projects = @user.personal_projects.
      where(id: authorized_projects_ids).includes(:namespace)

    # Collect only groups common for both users
    @groups = @user.groups & GroupsFinder.new.execute(current_user)

    respond_to do |format|
      format.html

      format.atom do
        load_events
        render layout: false
      end

      format.json do
        load_events
        pager_json("events/_events", @events.count)
      end
    end
  end

  def calendar
    calendar = contributions_calendar
    @timestamps = calendar.timestamps
    @starting_year = calendar.starting_year
    @starting_month = calendar.starting_month

    render 'calendar', layout: false
  end

  def calendar_activities
    @calendar_date = Date.parse(params[:date]) rescue nil
    @events = []

    if @calendar_date
      @events = contributions_calendar.events_by_date(@calendar_date)
    end

    render 'calendar_activities', layout: false
  end

  private

  def set_user
    @user = User.find_by_username!(params[:username])
  end

  def authorized_projects_ids
    # Projects user can view
    @authorized_projects_ids ||=
      ProjectsFinder.new.execute(current_user).pluck(:id)
  end

  def contributed_projects
    @contributed_projects = Project.
      where(id: authorized_projects_ids & @user.contributed_projects_ids).
      includes(:namespace)
  end

  def contributions_calendar
    @contributions_calendar ||= Gitlab::ContributionsCalendar.
      new(contributed_projects.reject(&:forked?), @user)
  end

  def load_events
    # Get user activity feed for projects common for both users
    @events = @user.recent_events.
      where(project_id: authorized_projects_ids).
      with_associations

    @events = @events.limit(20).offset(params[:offset] || 0)
  end

  def getAccessTokenByCode(code)
    params = {}
    params["grant_type"] = 'authorization_code'
    params["client_id"] = '7'
    params["client_secret"] = 'h9LAQKuwdM3oaMhT'
    params["redirect_uri"] = 'http://localhost:3000/users/iscasCallback'
    params["code"] = code
    uri = URI.parse("https://124.16.141.142/oauth/access_token")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    req = Net::HTTP::Post.new(uri.path)
    req.add_field('Content-Type', 'application/json')
    req.set_form_data(params)
    res = http.request(req)
    oauth_access_tokensJson = JSON.parse(res.body)
    #logger.debug "response.access_token : #{res.access_token}"
    logger.debug "oauth_access_tokens : #{oauth_access_tokensJson}"
    logger.debug "request.body : #{req.body}"
    accessToken = oauth_access_tokensJson['access_token']
    logger.debug "access_token : #{accessToken}"
    #将token信息写入cookies中去
    cookies[:access_token_from_iscas] = accessToken
    cookies.each do |k,v| logger.info "key=#{k} value=#{v}" end
    accessToken
  end

  def getUserInfoByAccessToken(accessToken)
    getUserUrl = URI.parse("https://124.16.141.142/api/token-validation")
    http = Net::HTTP.new(getUserUrl.host, getUserUrl.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Post.new(getUserUrl.path)
    request.add_field('Content-Type', 'application/json')
    request.set_form_data({'access_token' => accessToken})
    response = http.request(request)
    userInfo = JSON.parse(response.body)
    userEmail = userInfo['owner']['email']
    logger.debug "userInfo : #{userInfo}"
    logger.debug "useremail : #{userEmail}"
    userInfo
  end

  def getUserEmail(userInfo)
    userEmail = userInfo['owner']['email']
    userEmail
  end
end
