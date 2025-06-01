#Author : Nevethan Alagaratnam

###############################################
#########      CONFIGS         ################
###############################################

#ConnectionString information
# You can get 'server' and 'database name' variables from the CONFIGS in TAS or from the database in SQL Server Management Studio (SSMS)
$server = "TAS-SHS-SQLT00\CU1234" # Data server 
$db = "CU1234_Customer_TAS_ENV" # Database name

#ConnectionString

#With user ID and password
#$connectionstring = "Data server=$server;Initial Catalog=$db;Integrated Security=false;User Id = none; Password=none"

#Windows authentication
$connectionstring = "Data server=$server;Initial Catalog=$db;Integrated Security=true;"

$maxCharLength = 999999999 #Invoking a sqlcmd has a Default char length limit of 4000 characters(It doesnt get everything). So, put the limit to 
######################################################################################################

$ordning_forsystem_ids = @(1471746,1471747) -join ',' #specific ordning_forsystem ids will want to retrieve/transfer

$list_regelsaet = @("'Regelsæt navne eksempel 1', 'Regelsæt navne eksempel2'") -join ','

$RegelsætName = 'Regelsæt navne eksempel 3' # The name of the regelsæt you want to transfer

$ordning = 'EXMPL' #Ordningen du vil arbejde med.

######################################################################################################


