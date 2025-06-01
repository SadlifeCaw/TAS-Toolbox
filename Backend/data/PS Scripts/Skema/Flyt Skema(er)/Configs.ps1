#Author : Nevethan Alagaratnam

###############################################
#########      CONFIGS         ################
###############################################

#ConnectionString information
# You can get 'source' and 'database name' variables from the CONFIGS in TAS or from the database in SQL Server Management Studio (SSMS)
$server = "TAS-SHS-SQLT00\CU1234" # Data server 
$db = "CU1234_Customer_TAS_ENV" # Database name

#ConnectionString

#With user ID and password
#$connectionstring = "Data Source=$server;Initial Catalog=$db;Integrated Security=false;User Id = none; Password=none"

#Windows authentication
$connectionstring = "Data Source=$server;Initial Catalog=$db;Integrated Security=true;"

$maxCharLength = 2147483647 #Invoking a sqlcmd has a Default char length limit of 4000 characters(It doesnt get everything). So, put the limit to 

#######################################################################

$frontSystemIds = @(226, 224, 223) -join ',' # The Schema/frontSystem id(s) you want to transfer

#######################################################################
