. (Join-Path $PSScriptRoot utils.ps1)
. (Join-Path $PSScriptRoot docker-completion.ps1)

$global:DockerCompletion = @{}

$script:flagRegex = "^  (-[^, =]+),? ?(--[^= ]+)?"

function script:Get-Containers($filter)
{
    if ($filter -eq $null)
    {
       $names = docker ps -a --no-trunc --format "{{.Names}}"
    }
    else
    {
       $names = docker ps -a --no-trunc --format "{{.Names}}" ($filter | ForEach-Object { "--filter", $_ })
    }

    $names | ForEach-Object{ $_.Split(",") }
}

function script:Get-Images()
{
    docker images --no-trunc | ConvertFrom-Docker
}

function script:Get-AutoCompleteResult
{
    param([Parameter(ValueFromPipeline=$true)] $value)
    
    Process
    {
        New-Object System.Management.Automation.CompletionResult $value
    }
}

function script:Get-TabCompletion([array]$commandElements, [int]$indexOfCommandToComplete = -1)
{
    if ($indexOfCommandToComplete -lt 0)
    {
        # Complete next item
    } else {
        
    }
}

filter script:MatchingCommand($commandName)
{
    if ($_.StartsWith($commandName))
    {
        $_
    }
}

function DockerTabExpansion($lastBlock) {
    Get-DockerCompletion $lastBlock
}

$completion_Docker = {
    param($commandName, $commandAst, $cursorPosition)

    $command = $null
    $commandParameters = @{}
    $state = "Unknown"

    $text = $commandAst.Extent.ToString().Substring(0, $cursorPosition)
    $text | Out-File c:\temp\commandText.txt
    $results = Get-DockerCompletion $text
    $results | Format-Table | Out-File c:\temp\commandresults.txt
    $results | Get-AutoCompleteResult 
    # $text | Format-TAble | Out-File c:\temp\commandtext.txt

    # ($commandName | Format-Table | Out-File c:\temp\commandname.txt) 
    # ($commandAst | Format-Table | Out-File c:\temp\commandAst.txt) 
    # ($cursorPosition | Format-Table | Out-File c:\temp\commandPosition.txt) 

    # $wordToComplete = $commandAst.CommandElements | Where-Object { $_.ToString() -eq $commandName } | Foreach-Object { $commandAst.CommandElements.IndexOf($_) }

    # for ($i=1; $i -lt $commandAst.CommandElements.Count; $i++)
    # {
    #     $p = $commandAst.CommandElements[$i].ToString()

    #     if ($p.StartsWith("-"))
    #     {
    #         if ($state -eq "Unknown" -or $state -eq "Options")
    #         {
    #             $commandParameters[$i] = "Option"
    #             $state = "Options"
    #         }
    #         else
    #         {
    #             $commandParameters[$i] = "CommandOption"
    #             $state = "CommandOptions"
    #         }
    #     } 
    #     else 
    #     {
    #         if ($state -ne "CommandOptions")
    #         {
    #             $commandParameters[$i] = "Command"
    #             $command = $p
    #             $state = "CommandOptions"
    #         } 
    #         else 
    #         {
    #             $commandParameters[$i] = "CommandOther"
    #         }
    #     }
    # }

    # if ($global:DockerCompletion.Count -eq 0)
    # {
    #     $global:DockerCompletion["commands"] = @{}
    #     $global:DockerCompletion["options"] = @()
        
    #     docker --help | ForEach-Object {
    #         Write-Output $_
    #         if ($_ -match "^\s{2,3}(\w+)\s+(.+)")
    #         {
    #             $global:DockerCompletion["commands"][$Matches[1]] = @{}
                
    #             $currentCommand = $global:DockerCompletion["commands"][$Matches[1]]
    #             $currentCommand["options"] = @()
    #         }
    #         elseif ($_ -match $flagRegex)
    #         {
    #             $global:DockerCompletion["options"] += $Matches[1]
    #             if ($Matches[2] -ne $null)
    #             {
    #                 $global:DockerCompletion["options"] += $Matches[2]
    #              }
    #         }
    #     }

    # }
    
    # if ($wordToComplete -eq $null)
    # {
    #     $commandToComplete = "Command"
    #     if ($commandParameters.Count -gt 0)
    #     {
    #         if ($commandParameters[$commandParameters.Count] -eq "Command")
    #         {
    #             $commandToComplete = "CommandOther"
    #         }
    #     } 
    # } else {
    #     $commandToComplete = $commandParameters[$wordToComplete]
    # }

    # switch ($commandToComplete)
    # {
    #     "Command" { $global:DockerCompletion["commands"].Keys | MatchingCommand -Command $commandName | Sort-Object | Get-AutoCompleteResult }
    #     "Option" { $global:DockerCompletion["options"] | MatchingCommand -Command $commandName | Sort-Object | Get-AutoCompleteResult }
    #     "CommandOption" { 
    #         $options = $global:DockerCompletion["commands"][$command]["options"]
    #         if ($options.Count -eq 0)
    #         {
    #             docker $command --help | ForEach-Object {
    #             if ($_ -match $flagRegex)
    #                 {
    #                     $options += $Matches[1]
    #                     if ($Matches[2] -ne $null)
    #                     {
    #                         $options += $Matches[2]
    #                     }
    #                 }
    #             }
    #         }

    #         $global:DockerCompletion["commands"][$command]["options"] = $options
    #         $options | MatchingCommand -Command $commandName | Sort-Object | Get-AutoCompleteResult
    #     }
    #     "CommandOther" {
    #         switch ($command)
    #         {
    #             "start" { FilterContainers $commandName "status=created", "status=exited" }
    #             "stop" { FilterContainers $commandName "status=running" }
    #             { @("run", "rmi", "history", "push", "save", "tag") -contains $_ } { CompleteImages $commandName }
    #             default { FilterContainers $commandName }
    #         }
            
    #     }
    #     default { $global:DockerCompletion["commands"].Keys | MatchingCommand -Command $commandName }
    # }
}

function script:FilterContainers($commandName, $filter)
{
    Get-Containers $filter | MatchingCommand -Command $commandName | Sort-Object | Get-AutoCompleteResult
}

function script:CompleteImages($commandName)
{
    if ($commandName.Contains(":"))
    {
        Get-Images | ForEach-Object { $_.Repository + ":" + $_.Tag } | MatchingCommand -Command $commandName | Sort-Object -Unique | Get-AutoCompleteResult
    } 
    else 
    {
        Get-Images | Select-Object -ExpandProperty Repository | MatchingCommand -Command $commandName |  Sort-Object -Unique | Get-AutoCompleteResult
    }
}

if (Test-Path Function:\TabExpansion) {
    Rename-Item Function:\TabExpansion TabExpansionDockerBackup
}

function TabExpansion($line, $lastWord) {
    $lastBlock = [regex]::Split($line, '[|;]')[-1].TrimStart()

    switch -regex ($lastBlock) {
        # Execute git tab completion for all git-related commands
        "^$(Get-AliasPattern docker) (.*)" { DockerTabExpansion $lastBlock }

        # Fall back on existing tab expansion
        default {
            if (Test-Path Function:\TabExpansionDockerBackup) {
                TabExpansionDockerBackup $line $lastWord
            }
        }
    }
}



function PascalName($name){
    $parts = $name.Split(" ")
    for($i = 0 ; $i -lt $parts.Length ; $i++){
        $parts[$i] = [char]::ToUpper($parts[$i][0]) + $parts[$i].SubString(1).ToLower();
    }
    $parts -join ""
}
function GetHeaderBreak($headerRow, $startPoint=0){
    $i = $startPoint
    while( $i + 1  -lt $headerRow.Length)
    {
        if ($headerRow[$i] -eq ' ' -and $headerRow[$i+1] -eq ' '){
            return $i
            break
        }
        $i += 1
    }
    return -1
}
function GetHeaderNonBreak($headerRow, $startPoint=0){
    $i = $startPoint
    while( $i + 1  -lt $headerRow.Length)
    {
        if ($headerRow[$i] -ne ' '){
            return $i
            break
        }
        $i += 1
    }
    return -1
}
function GetColumnInfo($headerRow){
    $lastIndex = 0
    $i = 0
    while ($i -lt $headerRow.Length){
        $i = GetHeaderBreak $headerRow $lastIndex
        if ($i -lt 0){
            $name = $headerRow.Substring($lastIndex)
            New-Object PSObject -Property @{ HeaderName = $name; Name = PascalName $name; Start=$lastIndex; End=-1}
            break
        } else {
            $name = $headerRow.Substring($lastIndex, $i-$lastIndex)
            $temp = $lastIndex
            $lastIndex = GetHeaderNonBreak $headerRow $i
            New-Object PSObject -Property @{ HeaderName = $name; Name = PascalName $name; Start=$temp; End=$lastIndex}
       }
    }
}
function ParseRow($row, $columnInfo) {
    $values = @{}
    $columnInfo | ForEach-Object {
        if ($_.End -lt 0) {
            $len = $row.Length - $_.Start
        } else {
            $len = $_.End - $_.Start
        }
        $values[$_.Name] = $row.SubString($_.Start, $len).Trim()
    }
    New-Object PSObject -Property $values
}

<#
.SYNOPSIS

Converts from docker output to objects
.DESCRIPTION

Converts from docker tabular output to objects that can be worked with in a familiar way in PowerShell

.EXAMPLE
Get the running containers and 

docker ps -a --no-trunc | ConvertFrom-Docker | ft
#>
function ConvertFrom-Docker{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True,
		ValueFromPipeline=$True)]
		[object[]]$items
    )
    
    begin{
        $positions = $null;
    }
    process {
        foreach ($item in $items)
        {
            if($null -eq $positions) {
                # header row => determine column positions
                $positions  = GetColumnInfo -headerRow $item
            } else {
                # data row => output!
                ParseRow -row $item -columnInfo $positions
            }
        }
    }
    end {
    }
}
