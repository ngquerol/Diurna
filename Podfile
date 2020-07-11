workspace 'Diurna'
platform :macos, '10.14'

use_frameworks! :linkage => :static
inhibit_all_warnings!

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
