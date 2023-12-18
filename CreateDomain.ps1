#Переменные скрипта. Следует изменить под себя)
$dMode = 'Win2012R2'
$domain = 'kustov.local'
$netbios = 'DC1KUSTOV' #Данная переменная не должна совпадать с названием сервера
$passwd = 'P@ssw0rd'

#Установка всех необходимых пакетов
Install-WindowsFeature AD-Domain-Services `
    -IncludeAllSubFeature `
    -IncludeManagementTools

#Создание домена
Install-ADDSForest `
	-NoRebootOnCompletion `
	-DomainMode $dMode `
	-DomainName $domain `
	-DomainNetbiosName $netbios `
	-ForestMode $dMode `
	-InstallDns `
	-SafeModeAdministratorPassword `
		(ConvertTo-SecureString -String $passwd -AsPlainText -Force)
	#Строчка выше преобразует обычный текст в защищенную строку.

#Перезапускаем сервер
Restart-Computer