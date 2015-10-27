require "net/http"
require "uri"
class UsersController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :set_user,:except => [:iscas,:iscasCallback,:iscasLogin ,:get_current_access_token]

#Method name:iscas
#Des:redirect_to 网络帐号系统
#Author Name:liujinxia
  def iscas
    url = "#{IscasSettings.network_basic_url}/oauth/authorize?client_id=#{IscasSettings.client_id}&client_secret=#{IscasSettings.client_secret}&redirect_uri=#{IscasSettings.redirect_uri}&response_type=code"
    redirect_to url
  end

#Method name:iscasCallback
#Des:after login and 授权 from 网络帐号系统,call this method to get the accessToken and user basic Info
#Author Name:liujinxia
  def iscasCallback
    code = params[:code]
    access_token_info = get_access_token_info(code)
    accessToken = get_accesstoken_by_code(access_token_info)
    if accessToken==nil
      redirect_to root_path
    else
      userInfo = get_userInfo_by_accesstoken(accessToken)
      userEmail = get_user_email(userInfo)
      username = get_user_name(userInfo)
      redirect_to "#{IscasSettings.gitlab_basic_url}/users/iscasLogin?userEmail=#{userEmail}&username=#{username}"
    end
  end

#Method name:iscasLogin
#Des:we got the user Info and sign in the gitlab
#Author Name:liujinxia
  def iscasLogin
    loginUrl = URI.parse("#{IscasSettings.gitlab_basic_url}/users/sign_in")
    useremail = params[:userEmail]
    username = params[:username]
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
      #将已登陆的用户的_gitlab_session写进cookies中
      response_cookie = res.response['set-cookie'].split(';')[0].split('=')[1]
      cookies[:_gitlab_session] = response_cookie
      redirect_to root_path
    else
      #帮助用户实现注册
      registerUrl = URI.parse("#{IscasSettings.gitlab_basic_url}/users")
      params1 = {}
      params1["user[email]"] = useremail
      params1["user[password]"] = useremail
      params1["user[name]"] = username
      params1["user[username]"] = username
      http1 = Net::HTTP.new(registerUrl.host, registerUrl.port)
      req1 = Net::HTTP::Post.new(registerUrl.path)
      req1.set_form_data(params1)
      res1 = http1.request(req1)

      response_cookie1 = res1.response['set-cookie'].split(';')[0].split('=')[1]
      cookies[:_gitlab_session] = response_cookie1
      redirect_to root_path
    end
  end

#Method name:get_current_access_token
#Des: 获取当前用户的access_token
#Author Name:liujinxia
  def get_current_access_token
    access_token = cookies[:access_token_from_iscas]
    if access_token==nil
      return 0#此处需要重新申请授权access_token
    else
      return access_token
    end
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

  def get_access_token_info(code)
    params = {}
    params["grant_type"] = 'authorization_code'
    params["client_id"] = IscasSettings.client_id
    params["client_secret"] = IscasSettings.client_secret
    params["redirect_uri"] = IscasSettings.redirect_uri
    params["code"] = code
    uri = URI.parse("#{IscasSettings.network_basic_url}/oauth/access_token")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    req = Net::HTTP::Post.new(uri.path)
    req.add_field('Content-Type', 'application/json')
    req.set_form_data(params)
    res = http.request(req)
    oauth_access_tokensJson = JSON.parse(res.body)
    oauth_access_tokensJson
  end

  def get_accesstoken_by_code(oauth_access_tokensJson)
    accessToken = oauth_access_tokensJson['access_token']
    expires_in = oauth_access_tokensJson['expires_in']
    expires = Time.now+expires_in
    #将token信息写入cookies中去,包括access_token，expires
    cookies[:access_token_from_iscas] = {:value=> accessToken, :expires=> expires}
    value = cookies[:access_token_from_iscas]
    accessToken
  end

  def get_userInfo_by_accesstoken(accessToken)
    getUserUrl = URI.parse("#{IscasSettings.network_basic_url}/api/token-validation")
    http = Net::HTTP.new(getUserUrl.host, getUserUrl.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Post.new(getUserUrl.path)
    request.add_field('Content-Type', 'application/json')
    request.set_form_data({'access_token' => accessToken})
    response = http.request(request)
    userInfo = JSON.parse(response.body)
    userEmail = userInfo['owner']['email']
    userInfo
  end

  def get_user_email(userInfo)
    userEmail = userInfo['owner']['email']
    userEmail
  end

  def get_user_name(userInfo)
    username= userInfo['owner']['username']
    username
  end
end
