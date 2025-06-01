#Author : Nevethan Alagaratnam

###############################################
#########      CONFIGS         ################
###############################################

#ConnectionString information
# You can get 'server' and 'database name' variables from the CONFIGS in TAS or from the database in SQL Server Management Studio (SSMS)
$server = "tas-db.internal.formpipe.se" # Data server 
$db = "TAS_STANDARD_82_TEST" # Database name'

#ConnectionString

#With user ID and password
#$connectionstring = "Data server=$server;Initial Catalog=$db;Integrated Security=false;User Id = adm1; Password=mgetmk"

#Windows authentication
$connectionstring = "Data server=$server;Initial Catalog=$db;Integrated Security=true;"

$maxCharLength = 999999999 #Invoking a sqlcmd has a Default char length limit of 4000 characters(It doesnt get everything). So, put the limit to 
######################################################################################################

$Status_initials = '' #Initials for the status' you want to transfer. Try to make sure the initial doesnt overlab with others. Fx. 'BY' and 'BYP'. The SQL query will get both. 

$RegelsætName = '' # The name of the regelsæt you want to transfer

$ordning = 'XNEALTRANS' #Ordningen du vil arbejde med.

######################################################################################################


