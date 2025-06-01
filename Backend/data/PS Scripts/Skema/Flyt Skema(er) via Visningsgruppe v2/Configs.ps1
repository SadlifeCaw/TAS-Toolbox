#Author : Nevethan Alagaratnam

###############################################
#########      CONFIGS         ################
###############################################

#ConnectionString information
# You can get 'source' and 'database name' variables from the CONFIGS in TAS or from the database in SQL Server Management Studio (SSMS)
$server = "TAS-SHS-SQLT01\CU4004" # Data source 
$db = "CU4004_FST_TAS_TEST" # Database name'

#ConnectionString

#With admin user ID and password
#$connectionstring = "Data Source=$server;Initial Catalog=$db;Integrated Security=false;User Id = sb1; Password=SB1"

#Windows authentication
$connectionstring = "Data Source=$server;Initial Catalog=$db;Integrated Security=true;"


######################################################################################################
######################################################################################################

$ViewGroup = @("SB - Udbetaling") # The name of the ViewGroup you want to retrieve/create/transfer.

######################################################################################################
######################################################################################################
