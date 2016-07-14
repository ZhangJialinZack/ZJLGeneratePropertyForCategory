Pod::Spec.new do |s|
  s.name         = "ZJLGeneratePropertyForCategory"
  s.version      = "0.0.1"
  s.summary      = "Generate Properties For iOS Category."
  s.description  = <<-DESC
                      this project provide a class to generate properties for iOS category
                   DESC
  s.homepage     = "https://github.com/ZhangJialinZack/ZJLGeneratePropertyForCategory"
  s.license      = "MIT"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "zhangjialin" => "zhangjialin0611@126.com" }
  s.platform     = :ios
  s.source       = { :git => "https://github.com/ZhangJialinZack/ZJLGeneratePropertyForCategory.git", :tag => "0.0.1" }
  s.source_files  = "Generate"
  s.requires_arc = true
end
