workspace 'Diurna'
platform :macos, '10.12'

use_frameworks!

def shared_pods
    pod 'Firebase/Database', '~> 6.3'
end

target 'Diurna' do
    project 'App/App'
    shared_pods
end

target 'HackerNewsAPI' do
    project 'HackerNewsAPI/HackerNewsAPI'
    shared_pods
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings.delete('ARCHS')
    end
  end
end
