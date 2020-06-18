function Find-Lines {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false, ValueFromPipeline=$true)][string]
        #Absolute or relative path to a file or directory you want to search.
        $Path,
        [Parameter(Mandatory=$true)][regex]
        #Regex pattern to search the given file/directory for matches.
        $Pattern,
        [switch]
        #Switch to turn off host output and return a nested hashtable.
        $Hashtable=$false 
    )
        
    Begin 
    {
        $piped = $false
        If ($PSCmdlet.MyInvocation.ExpectingInput) { $piped = $true ; Write-Verbose "Path Input is From Pipeline.`n `n" }
        Else 
        {
            if (Test-Path -Path $Path -PathType Container)
            {
                $Files = Get-ChildItem -File -Path $Path
                if (!$Hashtable) { Write-Host "Searching Directory: $Path" }
            }
            Elseif (Test-Path -Path $Path -PathType Leaf) { $Files = @( $(Get-FileObject -Path $Path -Verbose:$false) ) }
            Else { Throw "Path: $Path Does Not Exist." }

            Write-Verbose "Files Type: $($Files.Gettype())"
            Write-Verbose "Files: $Files"
            
        }
        If ($piped) { $lenFiles = $Files.Count }
        Else { $lenFiles = $Files.Length }
        Write-Verbose "Number of Files: $LenFiles"
        
        $Ret = @{} 
    }
        
    Process 
    {
        If ($piped) { $Files = $_ }
        
        foreach ($File in $Files) 
        {
            #If ($Path -match "[a-zA-Z]:") { Write-Host "Test Network Drive Here. Map if not found." -ForegroundColor Red ; return }
            If ($File -match "\.zip|\.7z|\.tar|\.mp\d|\.m\da|\.m\dv|\.mov|\.mvk|\.mpeg|\.wmv|\.flv") { continue }
            If (Test-Path -Path $File.FullName -PathType Container) { continue }
            If ( ($File.GetType()).Name -ne "FileInfo" ) { Write-Error "Type of File: $File is Not Valid." ; continue }
            
            Write-Verbose "File.FullName: $($File.FullName)"

            If (!$Hashtable) { Write-Host "Searching File: " -NoNewline -ForegroundColor Blue ; Write-Host $File -ForegroundColor Magenta}

            $fileBody = Get-Content $File.FullName 

            $matched = $fileBody | Select-String -Pattern $pattern -List

            $lines = $fileBody -split "`n"
            $numbLines = $($lines.Length)
            Write-Verbose "Number of Lines in $File : $numbLines"
            $maxLine = ($numbLines.ToString()).Length
           
            $MatchedLines = @{}
            for ($i=0 ; $i -le ($matched.Length - 1); $i++ ) {
                
                $LineNumber = $matched.LineNumber[$i]
                Write-Debug "MaxLine:$maxLine - LineNumbLen:$(($LineNumber.ToString()).Length)"
                $numbspaces = $maxLine - ($LineNumber.ToString()).Length
                $spaces = ' ' * $numbspaces

                $MatchedLines["$LineNumber"]= $Matched.Line[$i]
                If (!$Hashtable) {
                    Write-Host $spaces -NoNewline
                    Write-Host $matched.LineNumber[$i] -ForegroundColor Cyan -NoNewline
                    Write-Host (" " * 3) -NoNewline
                    Write-Host $matched.Line[$i] -ForegroundColor Green
                }
            }
            If (!$Hashtable) { Write-Host "" }
            $Ret["$File"] = $MatchedLines
        }
    }
        
    End 
    {
        If ($Hashtable) { Return $Ret }       
    }
<#
.SYNOPSIS
Finds line number(s) of pattern matches for a given input.
.DESCRIPTION
Finds and displays colored easy to read ouput of regex matches and their line numbers.
.INPUTS
Supports input to the `-Path` paramater of type `stirng`
Also supports pipeline of FileSystem Ojects. See Examples.
.OUTPUTS
If `-Hashtable` is passed, a hashtable object will be returned  with the following format:
```
  Key   
FileName    {        Key         Value        }
            {   <LineNumber>=<PatternMatch>   } 
.EXAMPLE
Find-Lines -Path results -Pattern 'nc'
 Search the file `results` for `nc`.
.EXAMPLE
Find-Lines -Path ~/Desktop -Pattern 'nc'
Search files in `Desktop` for `nc`
.EXAMPLE
Get-ChildItem -Recurse ~/Documents | Find-Lines -Pattern nc
Search recursivly through the users `Documents` directory for `nc`
.LINK
https://github.com/rbaas293/Find-Lines
#>


}


Function Get-FileObject
{
    [CmdletBinding()]
    param (
        [string]
        #Specified file to get a file object for. Can be an absolute, or relative path. 
        $Path
    )
    If (!(Test-Path -Path $Path -PathType Leaf)) { Throw "Path : $Path is Not a File. "}

    If ($Path -match "\\|/")
    {
        $PreLen = $Path.Length
        $P = $Path

        While ($P -match "\\|/")
        {
            Write-Verbose "P = $P"
            $P = $P | Select-String -Pattern "(?<=\\|/).*" -All | ForEach-Object { $_.Matches } | ForEach-Object { $_.Value }

        }
        Write-Verbose "P = $P   [FINAL]"
        $FileName = $P
        $PostLen = $P.Length
        $ParentPath = -join ($Path.ToCharArray() | Select-Object -First $($PreLen-$PostLen))
    }
    Else { $ParentPath = Get-Location ; $FileName = $Path }

    Get-ChildItem -Path $ParentPath -File | ForEach-Object { If ($_.Name -eq $FileName) { $FileObject = $_ } } 

    If (!$FileObject) { Throw "Could Not Get File Object for Path : $Path"}
    Return $FileObject
}

