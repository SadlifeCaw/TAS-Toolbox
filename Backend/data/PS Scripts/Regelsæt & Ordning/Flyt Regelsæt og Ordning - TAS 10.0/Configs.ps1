#Author : Nevethan Alagaratnam

###############################################
#########      CONFIGS         ################
###############################################

#ConnectionString information
# You can get 'source' and 'database name' variables from the CONFIGS in TAS or from the database in SQL Server Management Studio (SSMS)
$server = "TAS-DB-2019" # Data source 
$db = "TAS_STANDARD_100_TEST" # Database name'

#ConnectionString

#With user ID and password
#$connectionstring = "Data Source=$source;Initial Catalog=$db;Integrated Security=false;User Id = adm1; Password=mgetmk"

#Windows authentication
$connectionstring = "Data Source=$server;Initial Catalog=$db;Integrated Security=true;"

$maxCharLength = 2147483647 #Invoking a sqlcmd has a Default char length limit of 4000 characters(It doesnt get everything). So, put the limit to 
######################################################################################################

$RegelsætName = 'Forsøgsvindmøller på Land - FPL' # The name of the regelsæt you want to transfer

$ordning = 'FPL' #Ordningen du vil arbejde med.

######################################################################################################
