Import-Module ActiveDirectory

$WingtipDomain = "DC=wingtip,DC=com"
$ouWingtipUsersName = "Wingtip Users"
$ouWingtipUsersPath = "OU={0},{1}" -f $ouWingtipUsersName, $WingtipDomain
$ouWingtipUsers = Get-ADOrganizationalUnit -Filter { name -eq $ouWingtipUsersName}

if($ouWingtipUsers -ne $null){
  Write-Host ("Organization Unit {0} Has already been created" -f $ouWingtipUsersName)
}

Write-Host ("Creating {0} Organization Unit" -f $ouWingtipUsersName)
New-ADOrganizationalUnit -Name $ouWingtipUsersName -Path $WingtipDomain -ProtectedFromAccidentalDeletion $false 

Write-Host
$CurrentDirectory = Get-Location 
$WingtipGroupsPath = ("{0}\WingtipUsers\WingtipGroups.csv" -f $CurrentDirectory.Path)
$WingtipGroups = Import-csv -path $WingtipGroupsPath
foreach($Group in $WingtipGroups) { 
  Write-Host ("Adding Group: {0}" -f $Group.AccountName)
  New-ADGroup -Path $ouWingtipUsersPath -SamAccountName $Group.AccountName -Name $Group.GroupName -Description $Group.Description -GroupCategory Security -GroupScope Global 
}

Write-Host
# create user accounts
$UserPassword = ConvertTo-SecureString -AsPlainText "Password1" -Force
$WingtipUsersPath = ("{0}\WingtipUsers\WingtipUsers.csv" -f $CurrentDirectory.Path)
$WingtipUsers = Import-csv -path $WingtipUsersPath
foreach($User in $WingtipUsers) { 
  Write-Host ("Adding User: {0}" -f $User.AccountName)
  New-ADUser -Path $ouWingtipUsersPath -SamAccountName $User.AccountName -GivenName  $User.FirstName -Surname $User.LastName -Name $User.UserName -DisplayName $User.UserName -Title $User.Title -Department $User.Dept -AccountPassword $UserPassword -Enabled $true -ChangePasswordAtLogon $false -PasswordNeverExpires $true
}

Write-Host
# assign managers to users
foreach($User in $WingtipUsers) { 
  if($User.Manager -ne ""){
    Write-Host ('Assigning manager ' + $User.Manager + ' to ' + $User.AccountName) 
    Set-ADUser $User.AccountName -Manager $User.Manager
  }
}

Write-Host

$WingtipUsersInGroupsPath = ("{0}\WingtipUsers\WingtipUsersInGroups.csv" -f $CurrentDirectory.Path)
$WingtipUsersInGroups = Import-csv -path $WingtipUsersInGroupsPath
foreach($item in $WingtipUsersInGroups) {
  Write-Host ("Adding user {0} to group {1}" -f $item.User, $item.Group)
  Add-ADGroupMember -Identity ($item.Group) -Members ($item.User)
}
 
Write-Host 
Read-Host -Prompt "Press ENTER to continue"