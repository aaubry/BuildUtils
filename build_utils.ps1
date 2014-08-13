
function Patch-Xml($file, $version, $buildNumber, $xpath, $namespaces)
{
	Write-Host "Patching $file"

	$doc = [xml](Get-Content $file -Raw)

	$ns = New-Object System.Xml.XmlNamespaceManager -ArgumentList (New-Object System.Xml.NameTable)
	$namespaces.GetEnumerator() | % { $ns.AddNamespace($_.Key, $_.Value) }
	$node = $doc.SelectSingleNode($xpath, $ns)
	$node.Value = "$version.$buildNumber"

	Set-Content $file $doc.OuterXml
}

function Patch-AssemblyInfo($file, $version, $buildNumber)
{
	Write-Host "Patching $file"

	$smallVersion = [Regex]::Match($version, "^\d+\.\d+").Value

	$code = Get-Content $file -Raw
	$code = [Regex]::Replace($code, 'AssemblyVersion\("[^"]*"\)', "AssemblyVersion(`"$smallVersion.0`")")
	$code = [Regex]::Replace($code, 'AssemblyFileVersion\("[^"]*"\)', "AssemblyFileVersion(`"$smallVersion.0`")")
	$code = [Regex]::Replace($code, 'AssemblyInformationalVersion\("[^"]*"\)', "AssemblyInformationalVersion(`"$version`")")

	Set-Content $file $code
}

function Get-VersionFromTag()
{
	$versionTag = git describe --tags --abbrev=0 #--exact-match
	if(-not ($versionTag -match "^v\d+\.\d+\.\d+$"))
	{
		throw "Missing or invalid version tag"
	}

	$version = $versionTag.TrimStart("v")
	Write-Host "Current version is $version"
	echo $version
}
