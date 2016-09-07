
function Patch-Xml($file, $value, $xpath, $namespaces)
{
	Write-Host "Patching $file"

	$doc = [xml](Get-Content $file -Raw)

	$ns = New-Object System.Xml.XmlNamespaceManager -ArgumentList (New-Object System.Xml.NameTable)
	$namespaces.GetEnumerator() | % { $ns.AddNamespace($_.Key, $_.Value) }
	$node = $doc.SelectSingleNode($xpath, $ns)
	$node.Value = $value

	Set-Content $file $doc.OuterXml
}

function Patch-AssemblyInfo($file, $version)
{
	Write-Host "Patching $file"

	$smallVersion = [Regex]::Match($version, "^\d+\.\d+").Value

	$code = Get-Content $file -Raw
	$code = [Regex]::Replace($code, 'AssemblyVersion\("[^"]*"\)', "AssemblyVersion(`"$smallVersion.0`")")
	$code = [Regex]::Replace($code, 'AssemblyFileVersion\("[^"]*"\)', "AssemblyFileVersion(`"$smallVersion.0`")")
	$code = [Regex]::Replace($code, 'AssemblyInformationalVersion\("[^"]*"\)', "AssemblyInformationalVersion(`"$version`")")

	Set-Content $file $code
}

function Get-VersionFromTag($preReleaseNumber = $null)
{
	$versionTag = git describe --tags --abbrev=0 #--exact-match
	if(-not ($versionTag -match "^v(\d+\.\d+\.)(\d+)$"))
	{
		throw "Missing or invalid version tag"
	}

	if ($preReleaseNumber -eq $null) {
		$version = "$($Matches[1])$($Matches[2])"
	} else {
		$version = "$($Matches[1])$([int]$Matches[2] + 1)-pre$($preReleaseNumber)"
	}

	Write-Host "Current version is $version"
	echo $version
}

function Validate-FileHeaders()
{
  Get-ChildItem -Recurse "*.cs" |
    ? { -not ($_.FullName -match "\\obj\\") } |
    % {
      $firstLine = Get-Content $_ -TotalCount 1
      if(-not ($firstLine -match "//\s*This file is part of YamlDotNet")) {
        Write-Warning "File $($_.FullName) does not start with the license header"
      }
    }
}