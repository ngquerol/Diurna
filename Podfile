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
