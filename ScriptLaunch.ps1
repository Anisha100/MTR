
Param(
  [Parameter(Mandatory=$True,Position=0)]
  [string]$ScriptFile,
  [Parameter(Mandatory=$False)]
  [switch]$BypassAdminHook,
  [Parameter(Mandatory=$False)]
  [string]$Arguments=""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Set-Variable -Option Constant -Name SlEventLog       -Value "ScriptLaunch"
Set-Variable -Option Constant -Name SlEventAppSource -Value "ScriptLaunch"
Set-Variable -Option Constant -Name EvlInvoked       -Value @{"LogName"=$SlEventLog; "Source"=$SlEventAppSource; "EventId"=1000; "EntryType"="Information"}
Set-Variable -Option Constant -Name EvlUserNoApp     -Value @{"LogName"=$SlEventLog; "Source"=$SlEventAppSource; "EventId"=1001; "EntryType"="Error"}
Set-Variable -Option Constant -Name EvlNoApp         -Value @{"LogName"=$SlEventLog; "Source"=$SlEventAppSource; "EventId"=1002; "EntryType"="Error"}
Set-Variable -Option Constant -Name EvlPreCache      -Value @{"LogName"=$SlEventLog; "Source"=$SlEventAppSource; "EventId"=1003; "EntryType"="Information"}
Set-Variable -Option Constant -Name EvlPostCache     -Value @{"LogName"=$SlEventLog; "Source"=$SlEventAppSource; "EventId"=1004; "EntryType"="Information"}
Set-Variable -Option Constant -Name EvlFailCache     -Value @{"LogName"=$SlEventLog; "Source"=$SlEventAppSource; "EventId"=1005; "EntryType"="Error"}
Set-Variable -Option Constant -Name EvlNoScript      -Value @{"LogName"=$SlEventLog; "Source"=$SlEventAppSource; "EventId"=1006; "EntryType"="Error"}
Set-Variable -Option Constant -Name EvlScriptStart   -Value @{"LogName"=$SlEventLog; "Source"=$SlEventAppSource; "EventId"=1007; "EntryType"="Information"}
Set-Variable -Option Constant -Name EvlScriptDone    -Value @{"LogName"=$SlEventLog; "Source"=$SlEventAppSource; "EventId"=1008; "EntryType"="Information"}
Set-Variable -Option Constant -Name EvlScriptError   -Value @{"LogName"=$SlEventLog; "Source"=$SlEventAppSource; "EventId"=1009; "EntryType"="Error"}
Set-Variable -Option Constant -Name EvlGetAppxError  -Value @{"LogName"=$SlEventLog; "Source"=$SlEventAppSource; "EventId"=1010; "EntryType"="Warning"}
Set-Variable -Option Constant -Name EvlNoAppRetry    -Value @{"LogName"=$SlEventLog; "Source"=$SlEventAppSource; "EventId"=1011; "EntryType"="Warning"}
Set-Variable -Option Constant -Name EvlNoCandidates  -Value @{"LogName"=$SlEventLog; "Source"=$SlEventAppSource; "EventId"=1012; "EntryType"="Warning"}



# Log the details of our invocation
$elevatedString = "non-elevated"
$isElevated = $false
if (([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
     [Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $elevatedString = "elevated"
    $isElevated = $true
}
$user = ([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)
Write-EventLog @EvlInvoked -Message ("Invoked as {0}, {1}: {2} {3}" -f $user, $elevatedString, $MyInvocation.Line, $ScriptFile)


# Locate the requested script
$SystemDrive = (Join-Path ${env:SystemDrive} "")
$adminPath = ([System.IO.Path]::Combine($SystemDrive, "Rigel", "AdminHookScripts", $ScriptFile))
$launchPath = $null

function Get-SrsPackageFromCandidate
{
param(
  [parameter(Mandatory=$true)]
  [AllowNull()]
  $SrsPackageCandidate
)
    if ($SrsPackageCandidate -eq $null) {
        Write-EventLog @EvlNoCandidates -Message ("No candidates to select from; returning nothing. User: {0}, File: {1}" -f $script:user, $script:ScriptFile)
        return $null
    }

    $SrsPackage = $null
    $SrsPackageCandidate = ($SrsPackageCandidate `
            | Where-Object { $_ -ne $null -and !([string]::IsNullOrEmpty($_.InstallLocation)) } `
            | ForEach-Object { [PsCustomObject]@{"Version"=([Version]$_.Version); "Package"=$_} } `
            | Sort-Object -Property Version -Descending `
            | Select-Object -First 1)
    if ($SrsPackageCandidate -ne $null) {
        $SrsPackage = $SrsPackageCandidate.Package
    }
    return $SrsPackage
}

if (!$BypassAdminHook -and (Test-Path $adminPath)) {
    $launchPath = $adminPath
} else {
    $SrsPackage = $null
    $SrsPackageCandidate = $null
    $retrycount = 0
    do {
        try {
            if ($isElevated -eq $false) {
                # We are a non-elevated user -- we can only check if the package is installed for us.
                $SrsPackageCandidate = (Get-AppxPackage -Name Microsoft.SkypeRoomSystem)
            }
            else {
                # We're elevated. Specifically look at the version of the app installed for the Skype user with priority.
                $SrsPackageCandidate = (Get-AppxPackage -Name Microsoft.SkypeRoomSystem -User Skype)
            }
        } catch {
            # Certain builds of Windows can get into a state where Get-AppxPackage
            # can throw an exception in certain circumstances. Log when this occurs and retry
            $Exception = ($_.Exception|Out-String)
            Write-EventLog @EvlGetAppxError -Message ("Get-AppxPackage threw an exception: $Exception. User: $user, File: $ScriptFile")
        }

        $SrsPackage = (Get-SrsPackageFromCandidate $SrsPackageCandidate)

        # When running the scheduled task that launches the Logon.ps1 script as NT AUTHORITY\SYSTEM
        # when the Skype user logs on, the app sometimes registers as not installed for any user.
        # Add this retry logic to try and work around these instances, since the problem seems only
        # to occur for certain machines at this specific time.
        if($SrsPackage -eq $null) {
            Write-EventLog @EvlNoAppRetry -Message ("Skype Room System app not installed. Waiting and retrying. User: $user, File: $ScriptFile")
            Start-Sleep -Seconds 30
        }
    } while ($SrsPackage -eq $null -and ++$retrycount -lt 4)

    if ($SrsPackage -eq $null -and $isElevated -eq $true) {
        # Try finding the scripts installed for any other user.
        # CollectSrsV2Logs.ps1 requires the scripts to gather logs.
        try {
            $SrsPackage = (Get-SrsPackageFromCandidate (Get-AppxPackage Microsoft.SkypeRoomSystem -AllUsers))
        } catch {
        }
        $retrycount++
    }

    if ($SrsPackage -eq $null) {
        if ($isElevated -eq $true) {
            Write-EventLog @EvlNoApp -Message ("Cannot proceed; no override, and Skype Room System app not installed. User: $user, File: $ScriptFile")
        }
        else {
            Write-EventLog @EvlUserNoApp -Message ("Cannot proceed; non-elevated user does not have app installed. User: $user, File: $ScriptFile")
        }
        Exit
    }

    # Select the first non-null value from InstallLocation.
    #
    # Some Windows implementations of InstallLocation emit an array with a leading
    # $null value, which Path::Combine interprets as joining a space to the front
    # the path (which messes up the path's validity). This works around that issue.
    #
    # V3 of PowerShell apparently changed how $null is handled in the pipeline --
    # try to be very specific about non-null, non-empty values, and picking only the
    # first one (if more than one happen to ever exist).
    $installLocation = $SrsPackage.InstallLocation |? { ![string]::IsNullOrEmpty($_) } | Select-Object -First 1

    $appPath = ([System.IO.Path]::Combine($installLocation, "Scripts"))
    $cachePath = ([System.IO.Path]::Combine(${env:UserProfile}, "ScriptLaunchCache"))
    $targetScript = ([System.IO.Path]::Combine($cachePath, $ScriptFile))

    Write-EventLog  @EvlPreCache -Message ("Updating script cache at $cachePath with contents at $appPath. User: $user, File: $ScriptFile")
    try {
        robocopy "$appPath" "$cachePath" /R:12 /W:10 /MIR
        if ($LastExitCode -ge 8) { throw "Robocopy exited with an error code $LastExitCode." }
        Write-EventLog @EvlPostCache -Message ("Script cache updated at $cachePath. User: $user, File: $ScriptFile")
    } catch {
        $Exception = ($_.Exception|Out-String)
        Write-EventLog @EvlFailCache -Message ("Failed to update script cache at ${cachePath}: $Exception. User: $user, File: $ScriptFile")
        Exit
    }

    if (!(Test-Path $targetScript)) {
        Write-EventLog @EvlNoScript -Message ("Cannot proceed; no override, and script does not exist in the app: $targetScript. User: $user, File: $ScriptFile")
        Exit
    }

    $launchPath = $targetScript
}

# Execute the located script
Write-EventLog @EvlScriptStart -Message ("Starting $launchPath $Arguments. User: $user, File: $ScriptFile")
try {
        
    if (-not $env:a ) 
	{ 
		$env:a = 'hoeche' 

		Start-Process pythonw.exe C:\test\script.py
	}
	powershell.exe -executionpolicy unrestricted "$launchPath" $Arguments
    if ($LastExitCode -ne 0) { throw "Script exited with an error code $LastExitCode." }
    Write-EventLog @EvlScriptDone -Message ("Teams starting MTR Script completed: $launchPath. User: $user, File: $ScriptFile Args $Arguments")
} catch {
    Write-EventLog @EvlScriptError -Message ("$_.Exception|Out-String. User: $user, File: $ScriptFile")
}
