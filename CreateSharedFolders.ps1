Import-Module NTFSSecurity

$sharePath = 'C:\share'
$x500OU = 'OU=KUSTORG,DC=KUSTOV,DC=LOCAL'
$groupsArray = Get-ADGroup -Filter * -SearchBase $x500OU | select Name

foreach($group in $groupsArray) {
    $usersInGroupArray = $(Get-ADGroupMember -Identity $($group.Name) | select Name)
	#Создание групповой директории
    New-Item `
        -ItemType "directory" `
        -Path "C:\share\$($group.Name)"
	
	#Удаление всех прав на директорию
    Clear-NTFSAccess -Path "C:\share\$($group.Name)" -DisableInheritance
	
	#Добавление правил на чтение для групповой директории
    Add-NTFSAccess `
        -Path "C:\share\$($group.Name)" `
        -Account "DC1KUSTOV\$($group.Name)",'DC1KUSTOV\Администратор','DC1KUSTOV\Directors' `
        -AccessRights ReadAndExecute `
        -AccessType Allow
	
	#Запрет на удаление групповой директории
    Add-NTFSAccess `
        -Path "C:\share\$($group.Name)" `
        -Account "DC1KUSTOV\$($group.Name)",'DC1KUSTOV\Администратор','DC1KUSTOV\Directors' `
        -AccessRights Delete `
        -AccessType Deny
	
	#Создание публично-групповой директории
    New-Item `
        -ItemType "directory" `
        -Path "C:\share\$($group.Name)\$($group.Name)_public"
	
	#Удаление всех прав на директорию
    Clear-NTFSAccess -Path "C:\share\$($group.Name)\$($group.Name)_public" -DisableInheritance
	
	#Добавление правил на изменения для публично-групповой директории
    Add-NTFSAccess `
        -Path "C:\share\$($group.Name)\$($group.Name)_public" `
        -Account "DC1KUSTOV\$($group.Name)",'DC1KUSTOV\Администратор','DC1KUSTOV\Directors' `
        -AccessRights Full `
        -AccessType Allow
		
	#Запрет на удаление публично-групповой директории
    Add-NTFSAccess `
        -Path "C:\share\$($group.Name)\$($group.Name)_public" `
        -Account "DC1KUSTOV\$($group.Name)",'DC1KUSTOV\Администратор', 'DC1KUSTOV\Directors' `
        -AccessRights Delete `
        -AccessType Deny

    foreach($user in $usersInGroupArray) {
		#Создание пользовательской директории
        New-Item `
                -ItemType "directory" `
                -Path "C:\share\$($group.Name)\$($user.Name)"
		
		#Удаление всех прав на директорию
        Clear-NTFSAccess -Path "C:\share\$($group.Name)\$($user.Name)" -DisableInheritance
        
		#Добавление правил на изменения для пользовательской директории
        Add-NTFSAccess `
            -Path "C:\share\$($group.Name)\$($user.Name)" `
            -Account "DC1KUSTOV\$($user.Name)",'DC1KUSTOV\Администратор' `
            -AccessRights Full `
            -AccessType Allow
		
		#Запрет на удаление пользовательской директории
        Add-NTFSAccess `
            -Path "C:\share\$($group.Name)\$($user.Name)" `
            -Account "DC1KUSTOV\$($user.Name)",'DC1KUSTOV\Администратор' `
            -AccessRights Delete `
            -AccessType Deny
    }
}