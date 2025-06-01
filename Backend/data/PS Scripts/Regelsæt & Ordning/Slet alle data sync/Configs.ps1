#Author : Nevethan Alagaratnam

###############################################
#########      CONFIGS         ################
###############################################

#ConnectionString information
# You can get 'server' and 'database name' variables from the CONFIGS in TAS or from the database in SQL Server Management Studio (SSMS)
$server = "BSMSOSSQL01T.prod.sitad.dk\TASTest" # Data server 
$db = "TASTestDB" # Database name'

#ConnectionString

#With user ID and password
#$connectionstring = "Data server=$server;Initial Catalog=$db;Integrated Security=false;User Id = adm1; Password=mgetmk"

#Windows authentication
$connectionstring = "Data server=$server;Initial Catalog=$db;Integrated Security=true;"

$maxCharLength = 999999999 #Invoking a sqlcmd has a Default char length limit of 4000 characters(It doesnt get everything). So, put the limit to 
######################################################################################################

$list_regelsaet = @("'Udbetalingssager T5'","'Ansøgningsrunder og Løse ansøgninger T5'") -join ','

##RegelsætName and Ordning shouldn't be used for this scripts

$RegelsætName = '' # The name of the regelsæt you want to transfer

$ordning = '' #Ordningen du vil arbejde med.

######################################################################################################


