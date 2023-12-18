Import-Module NTFSSecurity

$sharePath = 'C:\share'
$x500OU = 'OU=KUSTORG,DC=KUSTOV,DC=LOCAL'
$groupsArray = Get-ADGroup -Filter * -SearchBase $x500OU | select Name

foreach($group in $groupsArray) {
    $usersInGroupArray = $(Get-ADGroupMember -Identity $($group.Name) | select Name)

    New-Item `
        -ItemType "directory" `
        -Path "C:\share\$($group.Name)"

    Clear-NTFSAccess -Path "C:\share\$($group.Name)" -DisableInheritance

    Add-NTFSAccess `
        -Path "C:\share\$($group.Name)" `
        -Account "DC1KUSTOV\$($group.Name)",'DC1KUSTOV\Администратор','DC1KUSTOV\Directors' `
        -AccessRights ReadAndExecute `
        -AccessType Allow

    Add-NTFSAccess `
        -Path "C:\share\$($group.Name)" `
        -Account "DC1KUSTOV\$($group.Name)",'DC1KUSTOV\Администратор','DC1KUSTOV\Directors' `
        -AccessRights Delete `
        -AccessType Deny




    New-Item `
        -ItemType "directory" `
        -Path "C:\share\$($group.Name)\$($group.Name)_public"

    Clear-NTFSAccess -Path "C:\share\$($group.Name)\$($group.Name)_public" -DisableInheritance

    Add-NTFSAccess `
        -Path "C:\share\$($group.Name)\$($group.Name)_public" `
        -Account "DC1KUSTOV\$($group.Name)",'DC1KUSTOV\Администратор','DC1KUSTOV\Directors' `
        -AccessRights Full `
        -AccessType Allow

    Add-NTFSAccess `
        -Path "C:\share\$($group.Name)\$($group.Name)_public" `
        -Account "DC1KUSTOV\$($group.Name)",'DC1KUSTOV\Администратор', 'DC1KUSTOV\Directors' `
        -AccessRights Delete `
        -AccessType Deny

    foreach($user in $usersInGroupArray) {
        New-Item `
                -ItemType "directory" `
                -Path "C:\share\$($group.Name)\$($user.Name)"

        Clear-NTFSAccess -Path "C:\share\$($group.Name)\$($user.Name)" -DisableInheritance
        
        Add-NTFSAccess `
            -Path "C:\share\$($group.Name)\$($user.Name)" `
            -Account "DC1KUSTOV\$($user.Name)",'DC1KUSTOV\Администратор' `
            -AccessRights Full `
            -AccessType Allow

        Add-NTFSAccess `
            -Path "C:\share\$($group.Name)\$($user.Name)" `
            -Account "DC1KUSTOV\$($user.Name)",'DC1KUSTOV\Администратор' `
            -AccessRights Delete `
            -AccessType Deny
    }
}