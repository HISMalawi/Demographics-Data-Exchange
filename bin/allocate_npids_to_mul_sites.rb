

def allocate_npids
    sites = [
                {"sitecode" => 367,"user" => "chcb_art_user","pwd" => "chcb_art_user"},
                {"sitecode" => 776,"user" => "sl_art_user","pwd" => "sl_art_pwd"},
                {"sitecode" => 366,"user" => "ckw_art_user","pwd" => "ckw_art_pwd"},
                {"sitecode" => 759,"user" => "bcac_art_user","pwd" => "bcac_art_pwd"},
                {"sitecode" => 855,"user" => "mbt_art_user","pwd" => "mbt_art_pwd"},
                {"sitecode" => 772,"user" => "mdeka_art_user","pwd" => "mdeka_art_pwd"},
            ]

    sites.each do |site|
        protocol = 'http'
        host     = 'localhost'
        port     = 1500
        user     = site['user']
        pwd      = site['pwd']
        sitecode = site['sitecode']
        max_allocation = 2

        login = `curl -X POST "#{protocol}://#{host}:#{port}/v1/login" -H "Content-Type: application/json" -d '{"username": "#{user}","password": "#{pwd}"}'`
            login = JSON.parse(login)
            if login['message'] == 'Login Successful'
            #Checkout how many NPIDs are assigned to the site already
            allocated = LocationNpid.where(location_id: sitecode).count
                if allocated.to_i < max_allocation
                    #assign mores NPIDS
                    unallocated = max_allocation - allocated
                    puts "Assigning "
                    response = `curl -X POST "#{protocol}://#{host}:#{port}/v1/assign_npids" -H "Content-Type: application/json" -H "Authorization: token #{login['access_token']}" -d '{"limit": #{unallocated.to_i}}'`
                else 
                    next
                end
            end
    end
end

begin
    allocate_npids
    puts "Completed"
rescue => exception
    `echo #{exception} >> #{Rails.root}/log/error.log`
    `echo 'bht@dde!' | sudo service couchdb restart` 
    puts "Crushed Trying again after restarting couchdb"
    allocate_npids   
end