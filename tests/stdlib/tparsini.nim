# test the ini common operation
import parsecfg

# ==================================================================
# Create configuration file
var dict1=newCfg()
dict1.setSectionKey("Package","name","hello")
dict1.setSectionKey("Package","--file","app.nim")
dict1.setSectionKey("Author","name","lihf8515")
dict1.setSectionKey("Author","qq","10214028")
dict1.setSectionKey("Author","email","lihaifeng@wxm.com")
dict1.writeCfgFile("config.ini")

# Read configuration file
# A number of the same name keys or section, will take the value of last
var dict2 = loadCfgFile("config.ini")
var pname = dict2.getSectionKey("Package","name")
var name = dict2.getSectionKey("Author","name")
var qq = dict2.getSectionKey("Author","qq")
var email = dict2.getSectionKey("Author","email")
echo pname & "\n" & name & "\n" & qq & "\n" & email

# Modify configuration file
var dict3 = loadCfgFile("config.ini")
dict3.setSectionKey("Author","name","lhf")
dict3.writeCfgFile("config.ini")

# Delete the key in the configuration file
var dict4 = loadCfgFile("config.ini")
dict4.delSectionKey("Author","email")
dict4.writeCfgFile("config.ini")