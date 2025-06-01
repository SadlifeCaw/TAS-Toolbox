#Author : Nevethan Alagaratnam

###############################################
#########      CONFIGS         ################
###############################################

#ConnectionString information
# You can get 'source' and 'database name' variables from the CONFIGS in TAS or from the database in SQL Server Management Studio (SSMS)
$server = "TAS-SHS-SQLT01\CU2303" # Data source 
$db = "CU2303_ENS_TAS_TEST" # Database name'

#ConnectionString

#With user ID and password
#$connectionstring = "Data Source=$source;Initial Catalog=$db;Integrated Security=false;User Id = adm1; Password=adm1"

#Windows authentication
$connectionstring = "Data Source=$server;Initial Catalog=$db;Integrated Security=true;"

$maxCharLength = 2147483647 #Invoking a sqlcmd has a Default char length limit of 4000 characters(It doesnt get everything). So, put the limit to 

#######################################################################

$frontSystemIds = @(226, 224, 223) -join ',' # The Schema/frontSystem id(s) you want to transfer

#######################################################################
