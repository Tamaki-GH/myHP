require 'webrick'
server = WEBrick::HTTPServer.new(
  Port: 3000,
  DocumentRoot: '/Users/tamaki/Desktop/myHP'
)
trap('INT') { server.shutdown }
server.start
