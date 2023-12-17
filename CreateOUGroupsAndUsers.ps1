import-module ActiveDirectory

$OURootName = 'KUSTORG'
$x500Domain = 'DC=KUSTOV,DC=LOCAL'

$OUArray = @(
    [PSCustomObject]@{
        OUName = 'OfficeMain';
        protectedFromDel = $false;
    };
    [PSCustomObject]@{
        OUName = 'OfficeSecondary';
        protectedFromDel = $false;
    };
)

#========Создание организационных подразделений=======

#Проверяем наличие организационного подразделения
try {
    #Создание главного организационного подразделения компании
    Write-Output('Создание главного организационного подразделения:')
    New-ADOrganizationalUnit -Name $OURootName `
        -Path "$x500Domain" `
        -ProtectedFromAccidentalDeletion $($OU.ProtectedFromDel)

    Foreach($OU in $OUArray) {
        #Создание филиала
        Write-Output("    Создание филиала $($OU.OUName)...")
        New-ADOrganizationalUnit -Name $OU.OUName `
            -Path "OU=$OURootName,$x500Domain" `
            -ProtectedFromAccidentalDeletion $false
        
        #Создание доп. организационных подразделений для филиала компании
        New-ADOrganizationalUnit -Name "PC" `
            -Path "OU=$($OU.OUname),OU=$OURootName,$x500Domain" `
            -ProtectedFromAccidentalDeletion $false
        New-ADOrganizationalUnit -Name "Users" `
            -Path "OU=$($OU.OUName),OU=$OURootName,$x500Domain" `
            -ProtectedFromAccidentalDeletion $false
    
    Write-Output('Создание подразделений завершено успешно!')
}
} catch {
    #Вывод финального сообщения
    Write-Output('    Данное организационное подразделение уже существует.')
    #exit
}

Write-Output('=========================================')

#=======Создание групп пользователей========

$ADGroupsArray = @(
    [PSCustomObject]@{
        gName = 'SalesManagers';
        groupCat = 'Security';
        desc = 'This group is created for sales managers'
    },

    [PSCustomObject]@{
        gName = 'Accountants';
        groupCat = 'Security';
        desc = 'This group is created for Accauntants'
    },

    [PSCustomObject]@{
        gName = 'Directors';
        groupCat = 'Security';
        desc = 'This group is created for Directors'
    }
)

#Создание групп пользователей
Write-Output('Создание групп пользователей:')
Foreach($group in $ADGroupsArray) {
    #Проверка доменной структуры на наличие (или отсутствие) группы
    if(!$(Get-ADGroup -Filter "Name -like '$($group.gName)'")) {
        New-ADGroup -Name $($group.gName) `
            -DisplayName $($group.gName) `
            -GroupCategory $($group.groupCat) `
            -GroupScope Global `
            -Description $($group.desc) `
            -Path 'OU=KUSTORG,DC=KUSTOV,DC=LOCAL' `
            -ManagedBy 'Администратор'
        
        #Добавление только что созданной группы в группу "Пользователи домена"
        Add-ADGroupMember -Identity "Пользователи домена" -Members $($group.gName)
        Write-Output("    Группа $($group.gName) создана.")

    } else { Write-Output("    Группа $($group.gName) уже существует.") }
}

Write-Output('=========================================')

#=======Создание пользователей========

Write-Output('Создание пользователей:')

#Импорт пользователей из файла
$ADUsers = Import-Csv -Path 'C:\Users\Администратор\Documents\users.csv'

#Создание пользователей в домене
Foreach($user in $ADUsers) {
    #Проверка существует ли пользователь или нет
    if(!$(Get-ADUser -Filter "Name -like '$($user.username)'")) {
        
        #Создание пользователей в домене
        New-ADUser -Name $($user.username) `
            -Surname $($user.surname) `
            -GivenName $($user.name) `
            -AccountPassword $(
                ConvertTo-SecureString `
                -String $($user.password) `
                -AsPlainText `
                -Force
             ) `
            -Path "OU=Users,OU=$($user.office),OU=$($OURootName),$($x500Domain)" `
            -Enabled $True

        #Добавление в соответствущую группу
        Add-ADGroupMember -Identity $($user.group) -Members $($user.username)

        Write-Output("    Пользователь $($user.username) создан и добавлен в группу $($user.group).")
    } else {
        Write-Output("    Пользователь $($user.username) существует!")
    }
}