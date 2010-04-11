#gotta parse cmdline args exactly like ssh does
argv=ARGV.dup
while arg=argv.shift
  case arg
  when /\A-[^bcDeFiLlmOoPRSw]*i(.*)\z/
    exec "ssh", *ARGV
  when /\A-[^bcDeFiLlmOoPRSw]*l(.*)\z/
    login=$1.empty? ? argv.shift : $1
  when /\A-[^bcDeFiLlmOoPRSw]*([bcDeFLmOoPRSw])(.*)\z/
    if $2.empty?
      argv.shift
    else
      #do nothing
    end
  when /\A-[^bcDeFiLlmOoPRSw]/
    #do nothing
  else
    break user_host=arg
  end
end
user,host=user_host.split('@',2)
user,host=login||ENV['USER']||File.basename(ENV['HOME']),user unless host

filtered_options=[] #for now, should be good enough
keyfile=ENV['HOME']+"/.ssh/#{user}@#{host}"
unless File.exist?(keyfile)
  #todo: should check if any of the system calls below fail
  puts "connecting to #{user}@#{host} for the first time..."
  puts "generating a key in #{keyfile}..."
  system "ssh-keygen -f #{keyfile} -t rsa" #generate key
  #and upload to server
  pubkeyfile=keyfile+".pub"
  puts "uploading key..."
  puts "(you will now be asked for your password on #{host} twice)"
  system "scp", *filtered_options+[pubkeyfile,user_host+":"]
  system "ssh", *filtered_options+[user_host, 
    "mkdir", ".ssh", "||", "true", ";", 
    "chmod", "0700", ".ssh", ";",
    "cat", File.basename(pubkeyfile), ">>", ".ssh/authorized_keys", ";", 
    "chmod", "0600", ".ssh/authorized_keys", ";",
    "rm", File.basename(pubkeyfile)
  ]
  #(what a stupid PITA. this should be built in to ssh)
end

exec "ssh", "-i", keyfile, *ARGV
