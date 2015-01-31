CHROME ||= 'chrome'
FIREFOX ||= 'firefox'
IE ||= 'internet explorer'

def selenium_home
  platform_family?('windows') ? node['selenium']['windows']['home'] : node['selenium']['linux']['home']
end

def selenium_server_standalone
  "#{selenium_home}/server/selenium-server-standalone.jar"
end

def selenium_version(version)
  version.slice(0, version.rindex('.'))
end

def selenium_chromedriver?(capabilities)
  selenium_browser?(CHROME, capabilities)
end

def selenium_iedriver?(capabilities)
  selenium_browser?(IE, capabilities)
end

def windows_foreground(name, exec, args, username)
  args << %(-log "#{selenium_home}/log/#{name}.log")
  cmd = "#{selenium_home}/bin/#{name}.cmd"

  file cmd do
    content %("#{exec}" #{args.join(' ')})
    action :create
    notifies :request, "windows_reboot[Reboot to start #{name}]"
  end

  windows_shortcut "C:\\Users\\#{username}\\AppData\\Roaming\\Microsoft\\Windows\\Start Menu"\
      "\\Programs\\Startup\\#{name}.lnk" do
    target cmd
    cwd selenium_home
    action :create
  end
end

def windows_firewall(name, port)
  execute "Firewall rule #{name} for port #{port}" do
    command "netsh advfirewall firewall add rule name=\"#{name}\" protocol=TCP dir=in profile=any"\
      " localport=#{port} remoteip=any localip=any action=allow"
    action :run
    not_if "netsh advfirewall firewall show rule name=\"#{name}\" > nul"
  end
end

def autologon(username, password, domain)
  registry_key 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' do
    values [
      { name: 'AutoAdminLogon', type: :string, data: '1' },
      { name: 'DefaultUsername', type: :string, data: username },
      { name: 'DefaultPassword', type: :string, data: password },
      { name: 'DefaultDomainName', type: :string, data: domain }
    ]
    action :create
  end
end

def linux_service(name, exec, args, port, display)
  template "/etc/init.d/#{new_resource.name}" do
    source "#{node['platform_family']}_initd.erb"
    cookbook 'selenium'
    mode '0755'
    variables(
      name: name,
      exec: exec,
      args: args.join(' '),
      port: port,
      display: display
    )
    notifies :restart, "service[#{new_resource.name}]"
  end

  service new_resource.name do
    action [:enable]
  end
end

private

def selenium_browser?(browser, capabilities)
  return false if capabilities.nil?
  capabilities.each do |capability|
    return true if capability[:browserName] == browser
  end
  false
end
