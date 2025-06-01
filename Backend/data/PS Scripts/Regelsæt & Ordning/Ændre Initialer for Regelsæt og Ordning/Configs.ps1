#Author : Nevethan Alagaratnam

###############################################
#########      CONFIGS         ################
###############################################

#ConnectionString information
# You can get 'server' and 'database name' variables from the CONFIGS in TAS or from the database in SQL Server Management Studio (SSMS)
$server = "tas-db-2019" # Data server 
$db = "TASTestDB3_MASTER" # Database name'

#ConnectionString

#With user ID and password
#$connectionstring = "Data server=$server;Initial Catalog=$db;Integrated Security=false;User Id = adm1; Password=mgetmk"

#Windows authentication
$connectionstring = "Data server=$server;Initial Catalog=$db;Integrated Security=true;"

$maxCharLength = 2147483647 #Invoking a sqlcmd has a Default char length limit of 4000 characters(It doesnt get everything). So, put the limit to 
######################################################################################################

$RegelsætName = 'Ansøgningsrunder og Løse ansøgninger T9' # The name of the regelsæt you want to transfer

$ordning = '' #Ordningen du vil arbejde med.

$InitialFra = 'ANS9' #Det initial der ændres fra
$InitialTil = 'ANS9BU' #Det initial der ændres til

######################################################################################################
