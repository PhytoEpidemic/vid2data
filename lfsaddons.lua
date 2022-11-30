local lfsaddons = {}





function lfsaddons.selectFolder(name)
	name = name or "This Folder"
	local bfile = io.open("selectfolder.bat","w")
	bfile:write(
[[
@ECHO OFF
SET "PScommand="POWERSHELL Add-Type -AssemblyName System.Windows.Forms; $FolderBrowse = New-Object System.Windows.Forms.OpenFileDialog -Property @{ValidateNames = $false;CheckFileExists = $false;RestoreDirectory = $true;FileName = ']]..name..[[';};$null = $FolderBrowse.ShowDialog();$FolderName = Split-Path -Path $FolderBrowse.FileName;Write-Output $FolderName""
FOR /F "usebackq tokens=*" %%Q in (`%PScommand%`) DO (
	ECHO %%Q
	SET FOLDER=%%Q
)
EXIT /B
]])
	bfile:close()
	local tf = io.popen([[selectfolder.bat]])
	local FolderPath = tf:read("*l")
	if FolderPath then
		FolderPath = FolderPath
	else
		FolderPath = false
	end
	tf:close()
	os.remove([[selectfolder.bat]])
	return FolderPath
end


function lfsaddons.selectFile(typ,multi,...)
	local filterstring = ""
	local filters = {...}
	for i,ext in ipairs(filters) do
		filterstring = filterstring..[[*.]]..ext
		if filters[i+1] then
			filterstring = filterstring..[[;]]
		end
	end
	name = name or "This Folder"
	local bfile = io.open("chooser.bat","w")
	bfile:write(
[[
<# : chooser.bat
:: launches a File... Open sort of file chooser and outputs choice(s) to the console
:: https://stackoverflow.com/a/15885133/1683264

@echo off
setlocal

for /f "delims=" %%I in ('powershell -noprofile "iex (${%~f0} | out-string)"') do (
    echo %%~I
)
goto :EOF

: end Batch portion / begin PowerShell hybrid chimera #>

Add-Type -AssemblyName System.Windows.Forms
$f = new-object Windows.Forms.OpenFileDialog
$f.InitialDirectory = "]]..Settings.LastFileDir..[["
$f.Filter = "]]..typ..[[(]]..filterstring..[[)|]]..filterstring..[["
$f.ShowHelp = $true
$f.Multiselect = $]]..tostring(multi)..[[

[void]$f.ShowDialog()
if ($f.Multiselect) { $f.FileNames } else { $f.FileName }
]])
	bfile:close()
	local tf = io.popen([[chooser.bat]])
	local files = {}
	for l in tf:lines() do
		if #l > 3 then
			table.insert(files,l)
		end
	end
	if not files[1] then
		return false
	end
	tf:close() 
	os.remove([[chooser.bat]])
	if multi then
		return files
	else
		return files[1]
	end
	
end















return lfsaddons