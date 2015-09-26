def parse_apps(header, lines)
  headers = header.split("\t")
  apps = []
  lines.each do |line|
    values = line.split("\t")
    apps << values[headers.index("Naam")]
  end
  apps
end

def get_app
  f = File.open("Apps.txt")  
  header = f.readline.sub(/\r\n/,"")
  lines = f.read.split("\r\n")
  f.close
  
  parse_apps(header,lines)
end 

def parse_rfcs_for_app(header, lines)
  headers = header.split("\t")
  apps_with_rfcs = {}
  
  lines.each do |line|
    values = line.split("\t")
    app = values[headers.index("Naam")]
    apps_with_rfcs[app] = [] if apps_with_rfcs[app].nil?
    apps_with_rfcs[app] << values[headers.index("HpSvcId")]
  end
  apps_with_rfcs
end

def get_rfcs_for_app
  f = File.open("Apps with RFC.txt")  
  header = f.readline.sub(/\r\n/,"")
  lines = f.read.split("\r\n")
  f.close
  parse_rfcs_for_app(header, lines)    
end

def parse_rfcs(header, lines)
  headers = header.split("\t")
  rfcs = {}
  
  lines.each do |line|
    values = line.split("\t")
    rfc = values[headers.index("HpSvcId")]
    rfcs[rfc] = {} if rfcs[rfc].nil?
    headers.zip(values).each do |header,value|
      rfcs[rfc][header] = value
    end    
  end
  rfcs
end

def get_rfcs
  f = File.open("RFCs.txt")  
  header = f.readline.sub(/\r\n/,"")
  lines = f.read.split("\r\n")
  f.close
  parse_rfcs(header, lines)    
end

def parse_workorders(header, lines)
  headers = header.split("\t")
  workorders = {}
  
  lines.each do |line|
    values = line.split("\t")
    id = values[headers.index("HpSvcId")]
    workorders[id] = {} if workorders[id].nil?
    headers.zip(values).each do |header,value|
      workorders[id][header] = value
    end    
  end
  workorders
end

def get_workorders
  f = File.open("Werkorders.txt")  
  header = f.readline.sub(/\r\n/,"")
  lines = f.read.split("\r\n")
  f.close
  parse_workorders(header, lines)    
end

def parse_workorders_for_rfc(header, lines)
  headers = header.split("\t")
  result = {}
  
  lines.each do |line|
    values = line.split("\t")
    key = values[headers.index("HpSvcId")]
    result[key] = [] if result[key].nil?
    result[key] << values[headers.index("WorkorderId")]
  end
  result
end

def get_workorders_for_rfc
  f = File.open("RFC With Workorder.txt")  
  header = f.readline.sub(/\r\n/,"")
  lines = f.read.split("\r\n")
  f.close
  parse_workorders_for_rfc(header, lines)    
end


def parse_workorder_sort(header, lines)
  headers = header.split("\t")
  result = []
  lines.each do |line|
    values = line.split("\t")
    result << values[headers.index("Omschrijving")]
  end
  result
end

def get_workorder_sort
  f = File.open("WerkorderSortering.txt")  
  header = f.readline.sub(/\r\n/,"")
  lines = f.read.split("\r\n")
  f.close
  
  parse_workorder_sort(header,lines)
end 

apps = get_app
rfcs = get_rfcs
workorders = get_workorders
rfcs_for_app = get_rfcs_for_app
workorders_for_rfc = get_workorders_for_rfc
workorder_sort = get_workorder_sort

f = File.open("converted.csv", "w")

f.puts "Applicatie\tRFC\tOmschrijving\tStatus\tCategorie\t" + workorder_sort.join("\t")
apps.each do |app|
  line = "\"#{app}\"\t"
  rfcs_for_app[app].each do |app_rfc|
    rfc = rfcs[app_rfc]
    line << "#{rfc["HpSvcId"]}\t\"#{rfc["Omschrijving"]}\"\t#{rfc["Status"]}\t#{rfc["Categorie"]}\t"
    rfcworkorders = workorders_for_rfc[rfc["HpSvcId"]]
    
    workorder_sort.each do |omschrijving|
      cell = "\t"
      rfcworkorders.each do |rfc_workorder|
        workorder = workorders[rfc_workorder]
        cell = "#{workorder["Status"][0]}\t" if workorder["Omschrijving"] == omschrijving 
      end
      line << cell
    end
    f.puts line
    # only appname on first rfc line, insert extra cell
    line = "\t"  
  end
end
f.close

  
