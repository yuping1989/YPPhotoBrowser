#YPKit.podspec
Pod::Spec.new do |s|
s.name         = "YPPhotoBrowser"
s.version      = "1.0.0"
s.summary      = "图片浏览器."

s.homepage     = "https://github.com/yuping1989/YPPhotoBrowser"
s.license      = 'MIT'
s.author       = { "Ping Yu" => "290180695@qq.com" }
s.platform     = :ios, "7.0"
s.ios.deployment_target = "7.0"
s.source       = { :git => "https://github.com/yuping1989/YPPhotoBrowser.git", :tag => s.version}
s.source_files = 'YPPhotoBrowser/YPPhotoBrowser/**/*.{h,m}'
s.resources    = 'YBImageBrowser/YBImageBrowser/YBImageBrowser.bundle'
s.requires_arc = true

s.dependency 'SDWebImage'

end
