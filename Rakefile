# allow requiring of .rb files in 'tasks/lib'
$LOAD_PATH.unshift File.expand_path('lib', File.dirname(__FILE__))

# load all rake tasks
Dir.glob('tasks/*.rake').each { |r| import r }