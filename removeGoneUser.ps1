$computer = "$computer"

#on remote computer selected above
Invoke-Command -ComputerName $computer -ScriptBlock {



#get ownership/permissions of folders and... 
$sids = Get-ChildItem C:\users\ |
Where{$_.PSIsContainer} |
Get-ACL | 

#show the folders owned by SIDs that do not resolve to an active user existing in AD. 
Where{$_.AccessToString -match 'S-1'} |

#strip extraneous text, and convert to strings
Select @{n='Folder';e={($_.pspath).split("\")[3]}} |
format-table -property folder -HideTableHeaders |
out-string -stream

#strip extranious text again and definitely convert to strings this time
$stringsids = (($sids | out-string) -split '\n').trim() | ? {$_}

#loop through the list of names returned and remove profiles that match WMI objects associated with those names
foreach ($goneuser in $stringsids) {
    $localpath = 'c:\users\' + $goneuser
    echo "$((get-date).tostring()): Profile for $goneuser was removed." | Add-Content C:\RemovedProfiles.log
    
    Get-WmiObject -Class Win32_UserProfile | where-object {$_.localpath -eq $localpath} | 
    Remove-WmiObject
}



}
