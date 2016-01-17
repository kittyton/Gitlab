module PreviewService

  #MethodName:convertToPdf
  #Des:Convert office file to pdf
  #Author:liuqingqing
  def convertToPdf(infile,outfile)
    if File.exist?(outfile)
    else
      begin
        cmd="cd /opt/openoffice4/program && python DocumentConverter.py #{infile} #{outfile}"
        `#{cmd}`
        #exe result $?
      rescue
        #wrong message in $!
      end
    end
  end

  #MethodName:writeFile
  #Des:write office file data to a new temp file
  #Author:liuqingqing
  def writeFile(data,filepath)
    File.open(filepath,"wb") do |fout| 
      fout.write data
      STDOUT.flush
    end 
  end

  #MethodName:constructTmpDir
  #Des:create a new dir
  #Author:liuqingqing
  def constructTmpDir(dirpath)
    if File.exist?(dirpath) 
    else
    Dir.mkdir(dirpath)
    end
  end

  #MethodName:path_to_tempDir
  #Des:get tempDoc path 
  #Author:liuqingqing
  def path_to_tempDir
    rep_path=@repository.path_to_repo
    dir=[rep_path,"/tempDoc"].join
    return dir
  end

  #MethodName:doc_file_name
  #Des:get the temp office file name
  #Author:liuqingqing
  def doc_file_name
    name=@path.tr(" ","")
    new_file_name=[@blob.id,name].join
    return new_file_name
  end

  #MethodName:path_to_tempDoc
  #Des:get the temp office file path
  #Author:liuqingqing
  def path_to_tempDoc
    dir=path_to_tempDir
    new_file_name=doc_file_name
    new_file_path=[dir,new_file_name].join("/")
    return new_file_path
  end

 

  #MethodName:pdfFileName
  #Des:get the pdf file name
  #Author:liuqingiqng
  def pdfFileName
    new_file_name=doc_file_name
    index=new_file_name.rindex('.')
    pdf_file_name=[new_file_name[0..index],"pdf"].join
    return pdf_file_name
  end

  #MethodName:path_to_public
  #Des:get the public dir path
  #Author:liuqingiqng
  def path_to_public
    rep_path=@repository.path_to_repo
    public_path=[File.expand_path("../../..",rep_path),"/gitlab/public"].join
    return public_path
  end

  #MethodName:construct_tempPdf_path
  #Des:get the tempPdf path
  #Author:liuqingiqng
  def construct_tempPdf_path(public_path)
    tempPdf_path=[public_path,"/pdfjs/tempPdf"].join
    return tempPdf_path
  end

  #MethodName:compute_all_file_size
  #Des:get the specific dir size
  #Author:liuqingiqng
  def compute_all_file_size(dir)
    size=0
    if File.directory?(dir)
      Dir.foreach(dir) do |entry|
        if entry!="." and entry!=".."
          path=[dir,entry].join("/")
          each_size=File.size(path)
          size=size+each_size
        end
      end
    else
    end
    return size
  end


  #MethodName:LRU
  #Des:LRU replacement strategy when the tmpDir meets the threshold
  #Author:liuqingiqng
  def LRU(dir,threshold)
    size=compute_all_file_size(dir)
    if size>=threshold
      currentTime=Time.new.to_i
      timeBase=0
      toDeletePath=""
      Dir.foreach(dir) do |entry|
        if entry!="." and entry!=".."
          path=[dir,entry].join("/")
          accessTime=File.atime(path).to_i
          at=File.atime(path)
          timeDiff=currentTime-accessTime
          if timeDiff>timeBase
            timeBase=timeDiff
            toDeletePath=path
          end 
        end
      end
      File.delete(toDeletePath)
    end
  end

end
