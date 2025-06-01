#Author : Nevethan Alagaratnam

###############################################
#########      CONFIGS         ################
###############################################

#ConnectionString information
# You can get 'server' and 'database name' variables from the CONFIGS in TAS or from the database in SQL Server Management Studio (SSMS)
$server = "TAS-DB-2019" # Data server 
$db = "TAS_STANDARD_MASTER_CM_TOOL_FROM" # Database name'

#ConnectionString

#With user ID and password
#$connectionstring = "Data server=$server;Initial Catalog=$db;Integrated Security=false;User Id = adm1; Password=mgetmk"

#Windows authentication
$connectionstring = "Data server=$server;Initial Catalog=$db;Integrated Security=true;"

$maxCharLength = 2147483647 #Invoking a sqlcmd has a Default char length limit of 4000 characters(It doesnt get everything). So, put the limit to 

#######################################################################

$frontSystemIds = @(454,541,529,637,543,499,504,512,459,514) -join ',' # The Schema/frontSystem id(s) you want to transfer

#######################################################################
