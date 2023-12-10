#Переменные скрипта. Следует изменить под себя)
$domain = 'kustov.local'
$computerName = 'dc1'
$servIP = '192.168.9.10'
#Это массив сетей для создания областей DHCP
$netArray = @(
	[PSCustomObject]@{
		name = 'officeOne';
		scopeID = '192.168.18.0';
		startRange = '192.168.18.100';
		endRange = '192.168.18.254';
		exStartRange = '192.168.18.1';
		exEndRange = '192.168.18.99';
		netMask = '255.255.255.0';
		router = '192.168.18.1'
	},
	[PSCustomObject]@{
		name = 'officeTwo';
		scopeID = '192.168.27.0';
		startRange = '192.168.27.100';
		endRange = '192.168.27.254';
		exStartRange = '192.168.27.1';
		exEndRange = '192.168.27.99';
		netMask = '255.255.255.0';
		router = '192.168.27.1'
	}
)

#Установка всех необходимых пакетов
Write-Output('Устанавливаем необходимые пакеты...')
Install-WindowsFeature DHCP -IncludeManagementTools | Out-Null

#При выполнении следующей команды netsh на DHCP-сервере на DHCP-сервере создаются группы безопасности DHCP-Администратор istrators и DHCP Users security groups in Local Users and Groups на сервере DHCP
Write-Output('Создаем группы безопасности для DHCP...')
netsh dhcp add securitygroups | Out-Null

#Перезапускаем сервис DHCP
Restart-Service dhcpserver

#Проверяем наличие DHCP-сервера в списке авторизованных серверов AD
try {
    #Добавляем DHCP-сервер в список авторизованных DHCP-серверов AD
    Write-Output('Добавляем сервер в список авторизованных:')
    Add-DhcpServerInDC -DnsName "$computerName.$domain" -IPAddress $servIP 
} catch {
       Write-Output('    Пропускаем... Данный сервер '+$servIP+' уже есть в списке') 
}

#Настраиваем динамическое обновление записей на DNS-сервере для DHCP-клиентов
Set-DhcpServerv4DnsSetting `
	-ComputerName "$computerName.$domain" `
	-DynamicUpdates "Always" `
	-DeleteDnsRRonLeaseExpiry $True

#Создание областей DHCP в домене
Write-Output('Создаем области для DHCP:')
Foreach($net in $netArray) {
    
    #Проверяем существует объект или нет
    if ((Get-DhcpServerv4Scope -ComputerName "$computerName.$domain" | Where-Object {$_.ScopeId -eq $net.scopeID}).type -eq 'Dhcp') { 

        #Если объект DHCP уже существует - мы его пропускаем и переходим к следующему
        Write-Output('    Пропускаем... Такая область ('+$net.name+') уже имеется на сервере')
        continue

    } else {
        try {
            #Создание области для филиала
	        Add-DhcpServerv4Scope `
		        -Name $net.name `
		        -StartRange $net.startRange `
		        -EndRange $net.endRange `
		        -SubnetMask $net.netMask `
		        -State Active
	
	        #Создание списка исключенных адресов для области DHCP
	        Add-DhcpServerv4ExclusionRange `
		        -ScopeID $net.scopeID `
		        -StartRange $net.exStartRange `
		        -EndRange $net.exEndRange 
			
	        #Указание дополнительных параметров для области
	        Set-DhcpServerv4OptionValue `
                -ScopeID $net.scopeID `
		        -Router $net.router `
		        -DnsDomain $domain `
		        -DnsServer $servIP `
		        -ComputerName "$computerName.$domain"
            
            Write-Output('    Область '+$net.scopeID+' создана на сервере '+$computerName)
        
        } catch { Write-Output('    Ошибка Не удалось добавить область '+$net.scopeID+' на DHCP-сервере '+$computerName) }
    }
}