function Find-Lines {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false, ValueFromPipeline=$true)][string]$Path,
        [Parameter(Mandatory=$true)][regex]$Pattern,
        [switch]$Hashtable,
        [switch]$Recursive    
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
            If ($File -match "\.zip|\.7z|\.tar") { continue }
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
}


Function Get-FileObject
{
    [CmdletBinding()]
    param (
        [string]
        #Specified File to get a File Object for. Can be an absolute, or relative path to current directory. 
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

#Get-FileObject -Path .\Find-Lines.psd1 -Verbose
#Find-Lines -Path "C:\Users\rbaas\Documents\ghidra_9.1-BETA_DEV\docs\languages\html" -Pattern "ak" -Verbose
ls "C:\Users\rbaas\Documents\obfu" -R | Find-Lines -Pattern "add" 
