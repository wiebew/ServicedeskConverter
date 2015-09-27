def strip_linefeeds(txt)
  # remove pesky linebreaks in cells
  loop { break unless txt.gsub!(/(['][^']*)[\n]([^']*['])/m, '\1|\2')}
  txt.gsub!(/['][|][']/,"'\n'")
  txt.gsub!(/[|]/," ")
  txt
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
  # create a hash to find which rfc's belong to an app
  # based on a file, which needs to be manually edited as service desk does not provide 
  # additonal attributes
  
  f = File.open("Apps with RFC.txt")  
  header = f.readline.sub(/\r\n/,"")
  lines = f.read.split("\r\n")
  f.close
  parse_rfcs_for_app(header, lines)    
end


def add_rfc_attributes(rfc, appId, headers, values)
  # add attributes to an rfc, if it does not exist it is created
  # created to deal with repeating data in every line
  # workorders can be added additionally.
  if rfc.nil?
    rfc = {}
    ['Wijziging;Project;ID',	'Wijziging;ID',	'Wijziging;Korte omschrijving',	'Wijziging;Status', 'Wijziging;Categorie'].each { |key| rfc[key] = values[headers.index(key)] }
    rfc["workorders"] = []
    rfc["appId"] = appId
  end

  rfc["workorders"] << values[headers.index('ID')]
  rfc
end

def add_workorder_attributes(workorder, rfcId, headers, values)
  # add attributes to a workorder, if it does not exist it is created
  if workorder.nil?
    workorder = {}
    ['ID',	'Korte omschrijving',	'Status'].each { |key| workorder[key] = values[headers.index(key)] }
    workorder["rfcId"] = rfcId
  end
  workorder
end

def get_short_status(status)
  short = status[0]
  short = "U" if status == "Is uitgevoerd"
  short
end

def get_app_for_rfc(rfcs_for_app)
  # create a hash for looiking up the app to which an rfc belongs
  app_for_rfcs = {}
  rfcs_for_app.each do |k,v| 
    v.each do |rfcid|
      app_for_rfcs[rfcid] = [] if app_for_rfcs[rfcid].nil?
      app_for_rfcs[rfcid] = k
    end
  end
  app_for_rfcs
end

workorders = rfcs = {}
apps = []
workordersort = []

# maak een lookuptabel om van een rfc de app te weten
rfcs_for_app = get_rfcs_for_app
app_for_rfcs = get_app_for_rfc(rfcs_for_app)

# convert text to lines, remove quotes in fields
lines = strip_linefeeds(File.read("Workorders.txt")).split("\n").map{|item| item.gsub(/[']/,"")}
# get header row and remove from array
headers = lines.shift.split("\t")

# now parse the lines and create the following hashes: rfcs, workorders
# it also creates an array of unique workorderdescriptions, that will be the header row in the matrix
lines.each do |line|
  values = line.split("\t")
  rfcId = values[headers.index("Wijziging;ID")]
  workorderId = values[headers.index("ID")]
  appId = app_for_rfcs[rfcId] 
  if appId.nil?
    # not attached to an application, add it to the unassigned list, add an unassigned app to apps.
    appId = "UNASSIGNED"
    rfcs_for_app[appId] = [] if rfcs_for_app[appId].nil?
    rfcs_for_app[appId] << rfcId unless rfcs_for_app[appId].index(rfcId)
    apps << appId unless apps.index(appId)
  end
  rfcs[rfcId] = add_rfc_attributes(rfcs[rfcId], appId, headers, values)
  workorders[workorderId] = add_workorder_attributes(workorders[workorderId], rfcId, headers, values)
  workordersort <<  workorders[workorderId]["Korte omschrijving"] unless workordersort.index(workorders[workorderId]["Korte omschrijving"])
end

# create a list of apps, sort them on name
rfcs_for_app.each { |k,v| apps << k unless apps.index(k) }
apps.sort!
# make sure unassigned is on the bottom, if there are rfc not belonging to an app
if apps.index("UNASSIGNED") 
  apps.delete_at(apps.index("UNASSIGNED"))
  apps << "UNASSIGNED"
end


# we now have a list of apps, the rfcs belomnging to the app (if no app found, the appname is UNASSIGNED), the workorder belonging to the rfcs
# create the matrix rows are the app, changes, column are the workorder types, in the cell a shortened status is shown

f = File.open("matrix.csv", "w")

f.puts "Applicatie\tRFC\tOmschrijving\tStatus\tCategorie\t" + workordersort.join("\t")
apps.each do |app|
  line = "\"#{app}\"\t"
  rfcs_for_app[app].each do |app_rfc|
    rfc = rfcs[app_rfc]
    line << "#{rfc["Wijziging;ID"]}\t\"#{rfc["Wijziging;Korte omschrijving"]}\"\t#{rfc["Wijziging;Status"]}\t#{rfc['Wijziging;Categorie']}\t"

    workordersort.each do |omschrijving|
      cell = "\t"
      rfc["workorders"].each do |rfc_workorder|
        workorder = workorders[rfc_workorder]
        cell = "#{get_short_status(workorder["Status"])}\t" if workorder["Korte omschrijving"] == omschrijving
      end
      line << cell
    end
    f.puts line
    # only appname on first rfc line, insert extra cell
    line = "\t"
  end
end
