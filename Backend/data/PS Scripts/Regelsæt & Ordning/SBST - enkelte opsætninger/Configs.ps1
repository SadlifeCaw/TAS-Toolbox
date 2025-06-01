#Author : Nevethan Alagaratnam

###############################################
#########      CONFIGS         ################
###############################################

#ConnectionString information
# You can get 'server' and 'database name' variables from the CONFIGS in TAS or from the database in SQL Server Management Studio (SSMS)
$server = "bsm-sos-sql01p\TASPROD" # Data server 
$db = "TASProdDB" # Database name'

#ConnectionString

#With user ID and password
#$connectionstring = "Data server=$server;Initial Catalog=$db;Integrated Security=false;User Id = adm1; Password=mgetmk"

#Windows authentication
$connectionstring = "Data server=$server;Initial Catalog=$db;Integrated Security=true;"

$maxCharLength = 999999999 #Invoking a sqlcmd has a Default char length limit of 4000 characters(It doesnt get everything). So, put the limit to 
######################################################################################################

$ordning_forsystem_ids = @(1471746,1471747) -join ',' #specific ordning_forsystem ids will want to retrieve/transfer

$list_regelsaet = @("'Ansøgningsrunder og Løse ansøgninger T5'") -join ','

$RegelsætName = '' # The name of the regelsæt you want to transfer

$ordning = 'MASTER1' #Ordningen du vil arbejde med.

######################################################################################################


