# Controller for viewing a file's blame
class Projects::BlobController < Projects::ApplicationController
  include ExtractsPath
  include ActionView::Helpers::SanitizeHelper
  include PreviewService

  include IscasSearchService
  # Raised when given an invalid file path
  class InvalidPathError < StandardError; end

  before_action :require_non_empty_project, except: [:new, :create]
  before_action :authorize_download_code!
  before_action :authorize_push_code!, only: [:destroy]
  before_action :assign_blob_vars
  before_action :commit, except: [:new, :create]
  before_action :blob, except: [:new, :create]
  before_action :from_merge_request, only: [:edit, :update]
  before_action :require_branch_head, only: [:edit, :update]
  before_action :editor_variables, except: [:show, :preview, :diff]
  before_action :after_edit_path, only: [:edit, :update]



  def new
    commit unless @repository.empty?
  end

  def create
    result = Files::CreateService.new(@project, current_user, @commit_params).execute
    #iscas_search
     enableSearch=IscasSettings.enableSearch
     if enableSearch==true
      message=@commit_params[:commit_message]
      projectId=@project.id
      date=Time.now.strftime("%Y-%m-%dT%H:%M:%S")
      commit
      id=@commit.id
      addCommit(id,message,projectId,date)
     end
    if result[:status] == :success
      flash[:notice] = "Your changes have been successfully committed"
      respond_to do |format|
        format.html { redirect_to namespace_project_blob_path(@project.namespace, @project,File.join(@target_branch, @file_path)) }
        format.json { render json: { message: "success", filePath: namespace_project_blob_path(@project.namespace, @project,File.join(@target_branch, @file_path)) } }
      end
    else
      flash[:alert] = result[:message]
      respond_to do |format|
        format.html { render :new }
        format.json { render json: { message: "failed", filePath: namespace_project_new_blob_path(@project.namespace, @project, @id) } }
      end
    end
  end
 



  def show
    file_name=params[:id]
    index=file_name.rindex('.')
    #get the file type
    file_type=file_name[index..file_name.length-1] 
    office_type=[".doc",".docx",".odt",".ppt",".pptx",".odp",".xls",".xlsx",".ods"]
     if office_type.include?(file_type)
       @blob = @repository.blob_at(@commit.id, @path)
    if @blob
      dir=path_to_tempDir
      new_file_path=path_to_tempDoc
      constructTmpDir(dir)
      if File.exist?(new_file_path)
      else
        threshold=IscasSettings.tmp_office_threshold
        empty_tempDir(dir,threshold)
        writeFile(@blob.data,new_file_path)
      end

      #Convert the office file to pdf
      public_path=path_to_public
      pdf_file_name=pdfFileName
      tempPdf_path=construct_tempPdf_path(public_path)
      @pdf_file_path=File.join("/pdfjs/tempPdf",pdf_file_name)
      tmp_pdf_file_path=File.join(public_path,@pdf_file_path)
      constructTmpDir(tempPdf_path)

      if File.exist?(tmp_pdf_file_path)
      else
        if `pgrep soffice`.size == 0
          spawn('soffice "-accept=socket,port=2002;urp;"')
        else
        # has lanched, convert directly
        threshold=IscasSettings.tmp_pdf_threshold
        empty_tempDir(tempPdf_path,threshold)
        convertToPdf(new_file_path,tmp_pdf_file_path)
        end  
      end
    else
      not_found!
    end
    elsif file_type==".pdf"
      #write to tempPdf directly
       @blob = @repository.blob_at(@commit.id, @path)
       if @blob
        public_path=path_to_public
        pdf_file_name=pdfFileName
        tempPdf_path=construct_tempPdf_path(public_path)
        @pdf_file_path=File.join("/pdfjs/tempPdf",pdf_file_name)
        tmp_pdf_file_path=File.join(public_path,@pdf_file_path)
        constructTmpDir(tempPdf_path)
        if File.exist?(tmp_pdf_file_path)
        else
          threshold=IscasSettings.tmp_pdf_threshold
          empty_tempDir(tempPdf_path,threshold)
          writeFile(@blob.data,tmp_pdf_file_path)
        end
      else
        not_found
      end


    else
      # non-office or pdf file
    end
            
  end


  def edit
    @last_commit = Gitlab::Git::Commit.last_for_path(@repository, @ref, @path).sha
  end

  def update
    result = Files::UpdateService.new(@project, current_user, @commit_params).execute

    if result[:status] == :success
      flash[:notice] = "Your changes have been successfully committed"
      respond_to do |format|
        format.html { redirect_to after_edit_path }
        format.json { render json: { message: "success", filePath: after_edit_path } }
      end
    else
      flash[:alert] = result[:message]
      respond_to do |format|
        format.html { render :edit }
        format.json { render json: { message: "failed", filePath: namespace_project_new_blob_path(@project.namespace, @project, @id) } }
      end
    end
  end

  def preview
    @content = params[:content]
    diffy = Diffy::Diff.new(@blob.data, @content, diff: '-U 3', include_diff_info: true)
    @diff_lines = Gitlab::Diff::Parser.new.parse(diffy.diff.scan(/.*\n/))

    render layout: false
  end

  def destroy
    commit
    id=@commit.id
    result = Files::DeleteService.new(@project, current_user, @commit_params).execute

    if result[:status] == :success
      flash[:notice] = "Your changes have been successfully committed"
      #iscas_search
       enableSearch=IscasSettings.enableSearch
       if enableSearch==true
        deleteCommit(id,@project.id)
       end
       redirect_to namespace_project_tree_path(@project.namespace, @project, @target_branch)
    else
      flash[:alert] = result[:message]
      render :show
    end
  end

  def diff
    @form = UnfoldForm.new(params)
    @lines = @blob.data.lines[@form.since - 1..@form.to - 1]

    if @form.bottom?
      @match_line = ''
    else
      lines_length = @lines.length - 1
      line = [@form.since, lines_length].join(',')
      @match_line = "@@ -#{line}+#{line} @@"
    end

    render layout: false
  end

  private

  def blob
    @blob ||= @repository.blob_at(@commit.id, @path)

    if @blob
      @blob
    else
      if tree = @repository.tree(@commit.id, @path)
        if tree.entries.any?
          redirect_to namespace_project_tree_path(@project.namespace, @project, File.join(@ref, @path)) and return
        end
      end

      return not_found!
    end
  end

  def commit
    @commit = @repository.commit(@ref)
    return not_found! unless @commit
  end

  def assign_blob_vars
    @id = params[:id]
    @ref, @path = extract_ref(@id)

  rescue InvalidPathError
    not_found!
  end

  def after_edit_path
    @after_edit_path ||=
      if from_merge_request
        diffs_namespace_project_merge_request_path(from_merge_request.target_project.namespace, from_merge_request.target_project, from_merge_request) +
          "#file-path-#{hexdigest(@path)}"
      elsif @target_branch.present?
        namespace_project_blob_path(@project.namespace, @project, File.join(@target_branch, @path))
      else
        namespace_project_blob_path(@project.namespace, @project, @id)
      end
  end

  def from_merge_request
    # If blob edit was initiated from merge request page
    @from_merge_request ||= MergeRequest.find_by(id: params[:from_merge_request_id])
  end

  def sanitized_new_branch_name
    @new_branch ||= sanitize(strip_tags(params[:new_branch]))
  end

  def editor_variables
    @current_branch = @ref
    @target_branch = (sanitized_new_branch_name || @ref)

    @file_path =
      if action_name.to_s == 'create'
        if params[:file].present?
          params[:file_name] = params[:file].original_filename
        end
        File.join(@path, File.basename(params[:file_name]))
      else
        @path
      end

    if params[:file].present?
      params[:content] = Base64.encode64(params[:file].read)
      params[:encoding] = 'base64'
    end

    @commit_params = {
      file_path: @file_path,
      current_branch: @current_branch,
      target_branch: @target_branch,
      commit_message: params[:commit_message],
      file_content: params[:content],
      file_content_encoding: params[:encoding]
    }
  end
end
