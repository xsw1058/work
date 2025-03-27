<#
.Synopsis
change kubectl '$KUBECONFIG' environment variable for the current PowerShell session.

.Description
1. Use the 'up'('k') or 'down'('j') to select config file, then this file will be set as the 
$KUBECONFIG environment variable. also sets the prompt to signify that you are
using $KUBECONFIG environment variable. You can put this script in the system $PATH environment 
variable for easier calling.
2. Make sure the $KUBECONFIGPATH directory contains the kubectl config file, 
the default $KUBECONFIGPATH is "$Home\.kube".
3. This script references ps-menu and python venv. 
https://github.com/chrisseroka/ps-menu.git
https://docs.python.org/3/library/venv.html

.Parameter Path
Path to the directory that contains the kubectl config file. The
default value for this "$Home\.kube".

.Parameter Prompt
The prompt prefix to display when this virtual environment is activated. By
default, this prompt is the name of the $KUBECONFIG file base name.

.Example
s.ps1
select config file as $KUBECONFIG environment variable.

.Example
s.ps1 -Verbose
select config file as $KUBECONFIG environment variable,
and shows extra information about the activation as it executes.

.Example
s.ps1 -Path C:\Users\MyUser\Common\
select config file as $KUBECONFIG environment variable in the specified location.

.Example
s.ps1 -Prompt "MyPython"
select config file as $KUBECONFIG environment variable,
and prefixes the current prompt with the specified string (surrounded in
parentheses) while the virtual environment is active.

.Notes
On Windows, it may be required to enable this s.ps1 script by setting the
execution policy for the user. You can do this by issuing the following PowerShell
command:

PS C:\> Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

For more information on Execution Policies: 
https://go.microsoft.com/fwlink/?LinkID=135170

#>
param(
  [Parameter(Mandatory = $false)]
  [string]
  $Path,
  [Parameter(Mandatory = $false)]
  [string]
  $Prompt
)

<# Function declarations --------------------------------------------------- #>

<#
.Synopsis
# function DrawMenu is forked ps-mu. Some things may have changed. 
# https://github.com/chrisseroka/ps-menu.git

#>
function DrawMenu {
  param($menuItems,$menuPosition,$Multiselect,$selection)
  $l = $menuItems.length
  for ($i = 0; $i -le $l; $i++) {
    if ($null -ne $menuItems[$i]) {
      $item = $menuItems[$i]
      if ($Multiselect)
      {
        if ($selection -contains $i) {
          $item = '[x] ' + $item
        }
        else {
          $item = '[ ] ' + $item
        }
      }
      if ($i -eq $menuPosition) {
        Write-Host "> $($item)" -ForegroundColor Green
      } else {
        Write-Host "  $($item)"
      }
    }
  }
}

<#
.Synopsis
# function Update-Selection is forked ps-mu. Some things may have changed. 
# https://github.com/chrisseroka/ps-menu.git

#>
function Update-Selection {
  param($pos,[array]$selection)
  if ($selection -contains $pos) {
    $result = $selection | Where-Object { $_ -ne $pos }
  }
  else {
    $selection += $pos
    $result = $selection
  }
  $result
}

<#
.Synopsis
# function Menu is forked ps-mu. Some things may have changed. 
# https://github.com/chrisseroka/ps-menu.git

#>

function Menu {
  param([array]$menuItems,[switch]$ReturnIndex = $false,[switch]$Multiselect)
  $vkeycode = 0
  $pos = 0
  $selection = @()
  if ($menuItems.length -gt 0)
  {
    try {
      $startPos = [System.Console]::CursorTop
      [console]::CursorVisible = $false #prevents cursor flickering
      DrawMenu $menuItems $pos $Multiselect $selection
      while ($vkeycode -ne 13 -and $vkeycode -ne 27) {
        $press = $host.ui.rawui.readkey("NoEcho,IncludeKeyDown")
        $vkeycode = $press.virtualkeycode
        if ($vkeycode -eq 38 -or $press.Character -eq 'k') { $pos -- }
        if ($vkeycode -eq 40 -or $press.Character -eq 'j') { $pos++ }
        if ($vkeycode -eq 36) { $pos = 0 }
        if ($vkeycode -eq 35) { $pos = $menuItems.length - 1 }
        if ($press.Character -eq ' ') { $selection = Update-Selection $pos $selection }
        if ($pos -lt 0) { $pos = $menuItems.length - 1 }
        if ($vkeycode -eq 27) { $pos = $null }
        if ($pos -ge $menuItems.length) { $pos = 0 }
        if ($vkeycode -ne 27)
        {
          $startPos = [System.Console]::CursorTop - $menuItems.length
          [System.Console]::SetCursorPosition(0,$startPos)
          DrawMenu $menuItems $pos $Multiselect $selection
        }
      }
    }
    finally {
      [System.Console]::SetCursorPosition(0,$startPos + $menuItems.length)
      [console]::CursorVisible = $true
    }
  }
  else {
    $pos = $null
  }

  if ($ReturnIndex -eq $false -and $null -ne $pos)
  {
    if ($Multiselect) {
      return $menuItems[$selection]
    }
    else {
      return $menuItems[$pos]
    }
  }
  else
  {
    if ($Multiselect) {
      return $selection
    }
    else {
      return $pos
    }
  }
}



<#
.Synopsis
Remove all shell session elements added by the s script, including the
addition of the $KUBECONFIG environment variable.

.Parameter NonDestructive
If present, do not remove this function from the global namespace for the
session.

#>
function global:quit ([switch]$NonDestructive) {
  # Revert to original values

  # The prior prompt:
  if (Test-Path -Path Function:_OLD_VIRTUAL_PROMPT) {
    Copy-Item -Path Function:_OLD_VIRTUAL_PROMPT -Destination Function:prompt
    Remove-Item -Path Function:_OLD_VIRTUAL_PROMPT
  }

  # Just remove the KUBECONFIG altogether:
  if (Test-Path -Path Env:KUBECONFIG) {
    Remove-Item -Path env:KUBECONFIG
  }

  # Just remove the _XSW_PROMPT_PREFIX altogether:
  if (Get-Variable -Name "_XSW_PROMPT_PREFIX" -ErrorAction SilentlyContinue) {
    Remove-Variable -Name _XSW_PROMPT_PREFIX -Scope Global -Force
  }

  # Just remove the _XSW_PROMPT_COLOR altogether:
  if (Get-Variable -Name "_XSW_PROMPT_COLOR" -ErrorAction SilentlyContinue) {
    Remove-Variable -Name _XSW_PROMPT_COLOR -Scope Global -Force
  }

  # Leave deactivate function in the global namespace if requested:
  if (-not $NonDestructive) {
    Remove-Item -Path function:quit
  }
}


<# Begin script --------------------------------------------------- #>


try {

  if ($Path) {
    Write-Verbose "Path given as parameter, using '$Path' to determine values"
    $KUBECONFIGPATH = $Path
  }
  else {
    Write-Verbose "Path not given as a parameter, using $Home\.kube as Path."
    $KUBECONFIGPATH = "$Home\.kube"
  }

  quit -nondestructive

  $menuItems = Get-ChildItem -Path $KUBECONFIGPATH\* -Include *.yaml,*.yml -Name | Sort-Object

  if (!$menuItems) {
    Write-Host "No yaml file was found in '$KUBECONFIGPATH' ." -ForegroundColor Magenta
    exit 0
  } else {
    Write-Verbose "Found yaml file : $menuItems"
  }

  $selectKubeFile = Menu @($menuItems)

  Write-Verbose "Setting an environment variable `$env:KUBECONFIG=$KUBECONFIGPATH\$selectKubeFile to the current session."
  $env:KUBECONFIG = "$KUBECONFIGPATH\$selectKubeFile"

  # Next, set the prompt from the command line, or the config file, or
  # just use the name of the virtual environment folder.
  if ($Prompt) {
    Write-Verbose "Prompt specified as argument, using '$Prompt'"
  }
  else {
    Write-Verbose "Got BaseName of '$env:KUBECONFIG' as Prompt"
    $Prompt = (Get-Item "$env:KUBECONFIG").BaseName
  }

  Write-Verbose "Prompt = '$Prompt'"
  Write-Verbose "KUBECONFIGPATH='$KUBECONFIGPATH'"

  Write-Verbose "Setting prompt to '$Prompt'"

  # Set the prompt to include the env name
  # Make sure _OLD_VIRTUAL_PROMPT is global
  function global:_OLD_VIRTUAL_PROMPT { "" }

  Copy-Item -Path function:prompt -Destination function:_OLD_VIRTUAL_PROMPT

  # When the $KUBECONFIG file contains 'prod', it generally means that this is a production environment, 
  # so you must be careful when operating
  if ("$selectKubeFile".contains("prod")) {
    New-Variable -Name _XSW_PROMPT_COLOR -Description "kubeconfig environment prompt color" -Scope Global -Option ReadOnly -Visibility Public -Value "Red"
  } else {
    New-Variable -Name _XSW_PROMPT_COLOR -Description "kubeconfig environment prompt color" -Scope Global -Option ReadOnly -Visibility Public -Value "Green"
  }

  New-Variable -Name _XSW_PROMPT_PREFIX -Description "kubeconfig environment prompt prefix" -Scope Global -Option ReadOnly -Visibility Public -Value $Prompt

  function global:prompt {
    Write-Host -NoNewline -ForegroundColor $_XSW_PROMPT_COLOR "($_XSW_PROMPT_PREFIX) "
    _OLD_VIRTUAL_PROMPT
  }

}
catch {
  Write-Output $PSItem.ToString()
  quit
  exit 1
}
