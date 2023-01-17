 Remove-Item -Path "GUIoutput.txt"
 Remove-Item -Path "finished.txt"
 Remove-Item -Path "cancel.txt"
 #-Force

 Add-Type -AssemblyName System.Windows.Forms
 Add-Type -AssemblyName System.Drawing
 [System.Windows.Forms.Application]::EnableVisualStyles()
    
 $form = New-Object System.Windows.Forms.Form
 $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
 $form.MaximizeBox = $false
 #$form.ControlBox  = $false
 #$form.MinimizeBox = $false
 $form.Icon = "logo.ico"
 $form.Text = "vid2data"
 $form.Size = New-Object System.Drawing.Size(650,600)
 $form.StartPosition = 'CenterScreen'

$BackgroundCover = New-Object System.Windows.Forms.Label
 $BackgroundCover.Location = New-Object System.Drawing.Point(10,10)
 $BackgroundCover.Text = ''

 $doneButton = New-Object System.Windows.Forms.Button
 $doneButton.Location = New-Object System.Drawing.Point(400,150)
 $doneButton.Size = New-Object System.Drawing.Size(75,23)
 $doneButton.Text = 'Done'
# $doneButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
 #$form.CancelButton = $doneButton

$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(25,150)
$progressBar.Size = New-Object System.Drawing.Size(250,30)
$progressBar.Text = "test"
$progressBar.Minimum = 0
$progressBar.Maximum = 100
# Create a new timer
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 1000 # fire event every 1000ms (1s)

# Define the event handler for the timer's tick event
$timer.Add_Tick({
    
	$Processing = Test-Path "GUIoutput.txt"
	
	if ($Processing) {
		
		$BackgroundCover.Text = (Get-Content "processinfo.txt") -join [Environment]::NewLine

		
		$filePath = "progress.txt"
	
# read the contents of the text file


$fileContent = Get-Content $filePath
# convert the file contents to a number
$value = [int]$fileContent
$progressBar.Value = $value
$ProcessingCompleted = Test-Path "finished.txt"
if ($ProcessingCompleted) {
	Remove-Item -Path "GUIoutput.txt"
	$form.Controls.Remove($cancelButton)
	 $form.Controls.Add($doneButton)
}
	



# set the progress bar's value
#$progressBar.Value = $value
	}
    # Update the form's text
    #$form.Text = "Time Elapsed: $timeElapsed"
})

# Start the timer
$timer.Start()
# Create a new progress bar









Function MakeToolTip ()
{
	
	$toolTip = New-Object System.Windows.Forms.ToolTip
$toolTip.InitialDelay = 1000
$toolTip.AutoPopDelay = 10000
# Set the text of the tooltip
	
Return $toolTip
}

$CheckBoxesXLocation = 10
$CheckBoxesYLocation = 400


$keyFramesCheckBox = New-Object System.Windows.Forms.CheckBox
$keyFramesCheckBox.Location = New-Object System.Drawing.Point($CheckBoxesXLocation, $CheckBoxesYLocation)
$keyFramesCheckBox.Size = New-Object System.Drawing.Size(100, 20)
$keyFramesCheckBox.Text = "Key frames"
# Create a new ToolTip object

# Set the text of the tooltip

(MakeToolTip).SetToolTip($keyFramesCheckBox, "Select if you want to include only key frames")



$SameSizeCheckBox = New-Object System.Windows.Forms.CheckBox
$SameSizeCheckBox.Location = New-Object System.Drawing.Point($CheckBoxesXLocation, ($CheckBoxesYLocation+30))
$SameSizeCheckBox.Size = New-Object System.Drawing.Size(100, 20)
$SameSizeCheckBox.Text = "Same Size"

(MakeToolTip).SetToolTip($SameSizeCheckBox, "Select if all of the images in the folder are the exact same width and height. Increases loading speed drastically.")


$DeleteImagesCheckBox = New-Object System.Windows.Forms.CheckBox
$DeleteImagesCheckBox.Location = New-Object System.Drawing.Point($CheckBoxesXLocation, ($CheckBoxesYLocation+60))
$DeleteImagesCheckBox.Size = New-Object System.Drawing.Size(150, 20)
$DeleteImagesCheckBoxTipVid = (MakeToolTip)
$DeleteImagesCheckBoxTipFolder = (MakeToolTip)


 Function ChooseVideoFile ($InitialDirectory)
 {
 Add-Type -AssemblyName System.Windows.Forms
 $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
 $OpenFileDialog.Title = "Please Select File"
 #$OpenFileDialog.InitialDirectory = $InitialDirectory
 $OpenFileDialog.filter = "Video files (*.mp4;*.mov)|*.mp4;*.mov"
 $openFileDialog.ShowHelp = $true
 $OpenFileDialog.ShowDialog()
 ##If ( -eq "Cancel")
 ##{
 ###[System.Windows.Forms.MessageBox]::Show("No File Selected. Please select a file !", "Error", 0,
 ###[System.Windows.Forms.MessageBoxIcon]::Exclamation)
 ##}
 $Global:SelectedFile = $OpenFileDialog.FileName
 Return $SelectedFile #add this return
    
 }
 
 Function ChooseFolder($Message) {
    Add-Type -AssemblyName System.Windows.Forms
$FolderBrowse = New-Object System.Windows.Forms.OpenFileDialog -Property @{ValidateNames = $false;CheckFileExists = $false;RestoreDirectory = $true;FileName = $Message;}
$null = $FolderBrowse.ShowDialog()
$FolderName = Split-Path -Path $FolderBrowse.FileName
return $FolderName
}

 
 $BrowseInputFolder = New-Object System.Windows.Forms.Button
 $BrowseInputFolder.Location = New-Object System.Drawing.Point(300,74)
 $BrowseInputFolder.Size = New-Object System.Drawing.Size(100,23)
 $BrowseInputFolder.Text = 'Browse...'
 $BrowseInputFolder.Add_Click({$x = ChooseFolder -Message "Input Folder"; $InputPathTextBox.Text = $x})
 
 $BrowseInputVideo = New-Object System.Windows.Forms.Button
 $BrowseInputVideo.Location = New-Object System.Drawing.Point(300,74)
 $BrowseInputVideo.Size = New-Object System.Drawing.Size(100,23)
 $BrowseInputVideo.Text = 'Browse...'
 $BrowseInputVideo.Add_Click({$x = ChooseVideoFile; $InputPathTextBox.Text = $x})

 
 
 $BrowseOutputFolder = New-Object System.Windows.Forms.Button
 $BrowseOutputFolder.Location = New-Object System.Drawing.Point(365,380)
 $BrowseOutputFolder.Size = New-Object System.Drawing.Size(100,23)
 $BrowseOutputFolder.Text = 'Browse...'
 $BrowseOutputFolder.add_click({$x = ChooseFolder -Message "Output Folder"; $OutputPathTextBox.Text = $x})
 
 $InputPathTextBox = New-Object System.Windows.Forms.TextBox
 $DimensionsTextBox = New-Object System.Windows.Forms.TextBox
 $CustomFileNameTextBox = New-Object System.Windows.Forms.TextBox
 $CustomCaptionTextBox = New-Object System.Windows.Forms.TextBox
 $OutputPathTextBox = New-Object System.Windows.Forms.TextBox
	
	 $InputPathTextBoxLabel = New-Object System.Windows.Forms.Label
 $InputPathTextBoxLabel.Location = New-Object System.Drawing.Point(10,74)
 $InputPathTextBoxLabel.Size = New-Object System.Drawing.Size(250,23)
 $InputPathTextBoxLabel.Text = 'Input Path:(You can drag and drop into the text box)'
	
	 $DimensionsTextBoxLabel = New-Object System.Windows.Forms.Label

 $DimensionsTextBoxLabel.Location = New-Object System.Drawing.Point(10,124)
 $DimensionsTextBoxLabel.Size = New-Object System.Drawing.Size(500,33)
 $DimensionsTextBoxLabel.Text = 'Dimensions: (format WIDTHxHEIGHT or WIDTH,HEIGHT)(type a single number for 1:1 aspect ratio)(avg to calculate and slice at the average width and height)'
	
	$CustomFileNameTextBoxLabel = New-Object System.Windows.Forms.Label
 $CustomFileNameTextBoxLabel.Location = New-Object System.Drawing.Point(10,194)
 $CustomFileNameTextBoxLabel.Size = New-Object System.Drawing.Size(500,33)
 $CustomFileNameTextBoxLabel.Text = "Custom File Name: (Name for the final sliced images. They will be incremented like this 'filename_(2).png')"
	
	$CustomCaptionTextBoxLabel = New-Object System.Windows.Forms.Label
 $CustomCaptionTextBoxLabel.Location = New-Object System.Drawing.Point(10,264)
 $CustomCaptionTextBoxLabel.Size = New-Object System.Drawing.Size(640,40)
 $CustomCaptionTextBoxLabel.Text = "Custom Caption: (Add a custom caption to write to a file with the same names as the final sliced up images. If there are already caption files that you want to use for the sliced images just type '--keep'. You can also type '--start ' or '--end ' before your caption to add your custom caption to the existing caption.)"
	
	$OutputPathTextBoxLabel = New-Object System.Windows.Forms.Label
 $OutputPathTextBoxLabel.Location = New-Object System.Drawing.Point(10,344)
 $OutputPathTextBoxLabel.Size = New-Object System.Drawing.Size(350,14)
 $OutputPathTextBoxLabel.Text = 'Output Path:(You can drag and drop into the text box)'
	
	
	 $RemoveBlurDropDownLabel = New-Object System.Windows.Forms.Label
 $RemoveBlurDropDownLabel.Location = New-Object System.Drawing.Point(($CheckBoxesXLocation),($CheckBoxesYLocation+90))
 $RemoveBlurDropDownLabel.Size = New-Object System.Drawing.Size(80,23)
 $RemoveBlurDropDownLabel.Text = "Blurry frames threshold:"
	
	
	
	$RemoveBlurDropDown = new-object System.Windows.Forms.combobox
 $RemoveBlurDropDown.Location = new-object System.Drawing.Size(($CheckBoxesXLocation+80),($CheckBoxesYLocation+90))
 $RemoveBlurDropDown.Size = new-object System.Drawing.Size(65,30)
 $RemoveBlurDropDownOptions = @("","2","4","6","8","10","12","14","16","18","20")
 
 foreach($option in $RemoveBlurDropDownOptions)
	{
		[void] $RemoveBlurDropDown.Items.Add($option)
	}
 
 $RemoveBlurDropDown.tabIndex = '0'
 $RemoveBlurDropDown.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList;
	
	(MakeToolTip).SetToolTip($RemoveBlurDropDown, "Threshold blur level for removal. Lower number will remove more frames.")
	
	
 $ChooseTypeDropDownLabel = New-Object System.Windows.Forms.Label
 $ChooseTypeDropDownLabel.Location = New-Object System.Drawing.Point(100,30)
 $ChooseTypeDropDownLabel.Size = New-Object System.Drawing.Size(40,23)
 $ChooseTypeDropDownLabel.Text = 'Type:'
 $form.Controls.Add($ChooseTypeDropDownLabel)
    
    
 $ChooseTypeDropDown = new-object System.Windows.Forms.combobox
 $ChooseTypeDropDown.Location = new-object System.Drawing.Size(140,30)
 $ChooseTypeDropDown.Size = new-object System.Drawing.Size(335,30)
 $ChooseTypeDropDownOptions = @("Video","Folder of images")
 
 foreach($option in $ChooseTypeDropDownOptions)
	{
		[void] $ChooseTypeDropDown.Items.Add($option)
	}
 
 $ChooseTypeDropDown.tabIndex = '0'
 $ChooseTypeDropDown.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList;
 $ChooseTypeDropDown.add_SelectedValueChanged(
 {
    
    

 $form.Controls.Add($InputPathTextBoxLabel)
    
    
 $InputPathTextBox.Location = New-Object System.Drawing.Point(10,99)
 $InputPathTextBox.Size = New-Object System.Drawing.Size(335,23)
 $form.Controls.Add($InputPathTextBox)
 $InputPathTextBox.AllowDrop = $true

$InputPathTextBox.Add_DragDrop({
    # When a file is dropped, get the file path and set it as the text of the text box
    $file = ($_.Data.GetData("FileDrop"))[0]
    $InputPathTextBox.Text = $file
})

$InputPathTextBox.Add_DragEnter({
    # When a file is dragged over the text box, change the cursor to indicate that a file can be dropped here
    $_.Effect = [System.Windows.Forms.DragDropEffects]::All
})


$form.Controls.Add($OutputPathTextBoxLabel)
    
    
 $OutputPathTextBox.Location = New-Object System.Drawing.Point(10,364)
 $OutputPathTextBox.Size = New-Object System.Drawing.Size(335,23)
 $form.Controls.Add($OutputPathTextBox)
 $OutputPathTextBox.AllowDrop = $true

$OutputPathTextBox.Add_DragDrop({
    # When a file is dropped, get the file path and set it as the text of the text box
    $file = ($_.Data.GetData("FileDrop"))[0]
    $OutputPathTextBox.Text = $file
})

$OutputPathTextBox.Add_DragEnter({
    # When a file is dragged over the text box, change the cursor to indicate that a file can be dropped here
    $_.Effect = [System.Windows.Forms.DragDropEffects]::All
})


 $form.Controls.Add($DimensionsTextBoxLabel)
 
  $DimensionsTextBox.Location = New-Object System.Drawing.Point(10,160)
 $DimensionsTextBox.Size = New-Object System.Drawing.Size(335,23)
 $DimensionsTextBox.Text = '512x512'
 $DimensionsTextBox.AcceptsReturn = $true
 $form.Controls.Add($DimensionsTextBox)
 
 
 
  
 $form.Controls.Add($CustomFileNameTextBoxLabel)
 
 

 $CustomFileNameTextBox.Location = New-Object System.Drawing.Point(10,230)
 $CustomFileNameTextBox.Size = New-Object System.Drawing.Size(335,23)
 $CustomFileNameTextBox.Text = ''
 $CustomFileNameTextBox.AcceptsReturn = $true
$CustomFileNameTextBox.Add_KeyPress({
    param($sender, $e)
    # Get the pressed key as a character
    $key = [char]$e.KeyChar

    # Check if the key pressed is backspace
    if ($key -eq [char]8) {
        # Allow the backspace key press
        return
    }

    # Check if the pressed key is a valid character for a file name
    if ([System.IO.Path]::GetInvalidFileNameChars() -contains $key) {
        # If the key is an invalid character, cancel the key press
        $e.Handled = $true
    }
})
$form.Controls.Add($CustomFileNameTextBox)

$CustomCaptionTextBox.Location = New-Object System.Drawing.Point(10,310)
 $CustomCaptionTextBox.Size = New-Object System.Drawing.Size(335,23)
 $CustomCaptionTextBox.Text = ''
 $CustomCaptionTextBox.AcceptsReturn = $true
 $form.Controls.Add($CustomCaptionTextBox)
 
$form.Controls.Add($CustomCaptionTextBoxLabel)

 

$form.Controls.Add($BrowseOutputFolder)
 
 
 
$form.Controls.Add($DeleteImagesCheckBox)

		if($ChooseTypeDropDown.SelectedItem -eq 'Video')
		
	{
	
		$form.Controls.Add($keyFramesCheckBox)
		$form.Controls.Add($RemoveBlurDropDown)
		
	#$Browse.Tag = $ChooseVideoFile
	#
	
	$DeleteImagesCheckBoxTipFolder.RemoveAll()
	
	$DeleteImagesCheckBoxTipVid.SetToolTip($DeleteImagesCheckBox, "Delete the video frames after slicing them.")
	
	$form.Controls.Add($RemoveBlurDropDownLabel)
	
	$form.Controls.Remove($SameSizeCheckBox)
	$DeleteImagesCheckBox.Text = "Delete frames"	
	$form.Controls.Remove($BrowseInputFolder)
	$form.Controls.Add($BrowseInputVideo)
	
	
	
		
	}
	
		if($ChooseTypeDropDown.SelectedItem -eq 'Folder of images')
	{
	$form.Controls.Remove($RemoveBlurDropDown)
	$form.Controls.Remove($RemoveBlurDropDownLabel)
	$DeleteImagesCheckBoxTipVid.RemoveAll()
	$DeleteImagesCheckBoxTipFolder.SetToolTip($DeleteImagesCheckBox, "Delete the original images after slicing. (Always make backups!!!)")
	#$form.Controls.Remove($BrowseInputFolder)
	#$BrowseInputFolder.Tag = $ChooseFolder
	$form.Controls.Remove($keyFramesCheckBox)
		$form.Controls.Add($SameSizeCheckBox)
		$DeleteImagesCheckBox.Text = "Delete Original Images"

		$form.Controls.Remove($BrowseInputVideo)
		$form.Controls.Add($BrowseInputFolder)
		
	
	
		
	}
	

	}
 )
    
 $form.Controls.Add($ChooseTypeDropDown)
    
    
    
    
 $cancelButton = New-Object System.Windows.Forms.Button
 $cancelButton.Location = New-Object System.Drawing.Point(490,500)
 $cancelButton.Size = New-Object System.Drawing.Size(75,23)
 $cancelButton.Text = 'Cancel'
# $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
 #$form.CancelButton = $cancelButton
 $form.Controls.Add($cancelButton)
    
    

 # Create the OK button
$OKButton = New-Object System.Windows.Forms.Button
$OKButton.Location = New-Object System.Drawing.Point(400, 500)

$OKButton.Size = New-Object System.Drawing.Size(75, 23)
$OKButton.Text = "OK"
$form.Controls.Add($OKButton)

# Add an event handler for the OK button's Click event
$OKButton.Add_Click({
    # Get the text from the text boxes
    $fileorfolder = $ChooseTypeDropDown.SelectedItem
    
    $text1 = $InputPathTextBox.Text
    
    $text2 = $DimensionsTextBox.Text
    
	$keyFramesValue = $keyFramesCheckBox.Checked
	$SameSizeValue = $SameSizeCheckBox.Checked
	$DeleteImagesValue = $DeleteImagesCheckBox.Checked
	$text3 = $CustomFileNameTextBox.Text
	$text4 = $CustomCaptionTextBox.Text
	$text5 = $OutputPathTextBox.Text
	$RemoveBlurLevel = $RemoveBlurDropDown.SelectedItem
    # Write the text to the file
    Out-File -FilePath "GUIoutput.txt" -InputObject "$fileorfolder`n$text1`n$text2`n$keyFramesValue`n$SameSizeValue`n$DeleteImagesValue`n$text3`n$text4`n$text5`n$RemoveBlurLevel" -Encoding ascii -Append
    
   # $form.Close() # Close the form
   # simulate a process that takes 10 seconds
   $progressBar.Value = 1
   $form.Controls.Add($progressBar) 
	 $form.Size = New-Object System.Drawing.Size(560,250)
	  $cancelButton.Location = New-Object System.Drawing.Point(400,150)
	  $BackgroundCover.Size = New-Object System.Drawing.Size(540,100)
	$controlsToRemove = @(
		$InputPathTextBox, 
		$InputPathTextBoxLabel, 
		$OutputPathTextBox, 
		$OutputPathTextBoxLabel, 
		$CustomFileNameTextBox, 
		$CustomFileNameTextBoxLabel, 
		$CustomCaptionTextBox, 
		$CustomCaptionTextBoxLabel,
		$RemoveBlurDropDown,
		$RemoveBlurDropDownLabel,
		$BrowseInputFolder,
		$BrowseInputVideo,
		$BrowseOutputFolder,
		$OKButton,
		$DimensionsTextBox, 
		$DimensionsTextBoxLabel, 
		$ChooseTypeDropDown, 
		$ChooseTypeDropDownLabel, 
		$SameSizeCheckBox, 
		$DeleteImagesCheckBox, 
		$keyFramesCheckBox
	)
	foreach($control in $controlsToRemove)
	{
		$form.Controls.Remove($control)
	}


	 
 $form.Controls.Add($BackgroundCover)
# simulate a process that takes 10 seconds
    

# Rename the executable
Rename-Item -Path "vid2data.exe" -NewName $uniqueName
$luaScript = "makedata.lua"
$arg = "-b"

# Check if README.md exists
if (Test-Path "README.md") {
	Start-Process -FilePath $uniqueName -ArgumentList $luaScript, $arg -RedirectStandardError "error.txt" -PassThru
} else {
	Start-Process -FilePath $uniqueName -ArgumentList $luaScript, $arg -RedirectStandardError "error.txt" -PassThru -WindowStyle Hidden
}







#


})

# Generate a random unique name for the executable
$uniqueName = -join (65..90 + 97..122 | Get-Random -Count 16 | % {[char]$_}) + '.exe'

Function stopProcess ($uniqueName)
{
	taskkill /f /IM $uniqueName
	
	$filePath = "runningProcesses.txt"
	foreach ($line in Get-Content $filePath) {
		taskkill /f /im $line 
	}
	taskkill /f /IM "ffmpeg.exe"
	Rename-Item -Path $uniqueName -NewName "vid2data.exe"
}
$startTime = Get-Date

$cancelButton.Add_Click({
   
	$Processing = Test-Path "GUIoutput.txt"
	$BackgroundCover.Text = "Canceling..."
	if ($Processing) {
		$startTime = Get-Date
        Set-Variable -Name 'startTime' -Value $startTime -Scope 'global'
		$timer.Stop()
		$progressBar.Maximum = 4
		$progressBar.Value = 0
		$cancelTimer.Start()
		Out-File -FilePath "cancel.txt" -InputObject "c" -Encoding ascii -Append
	} else {
		$form.Close()
		
	}
})



$cancelTimer = New-Object System.Windows.Forms.Timer
$cancelTimer.Interval = 500
$cancelTimer.Add_Tick({
    $currentTime = Get-Date
    $timeElapsed = New-TimeSpan -Start $startTime -End $currentTime
	$progressBar.Value = $timeElapsed.TotalSeconds
	$BackgroundCover.Text = "Canceling..."
	$ProcessingCanceled = Test-Path "finished.txt"
	if ($timeElapsed.TotalSeconds -gt $progressBar.Maximum -or $ProcessingCanceled) {
		
		
		Remove-Item -Path "cancel.txt"
		Remove-Item -Path "GUIoutput.txt"
		$form.Close()
	}
	
})









$form.Add_FormClosing({
	$timer.Stop()
	$cancelTimer.Stop()

	$Processing = Test-Path "GUIoutput.txt"
	$BackgroundCover.Text = "Canceling..."
	
	if ($Processing) {
		Out-File -FilePath "cancel.txt" -InputObject "c" -Encoding ascii -Append
		Start-Sleep -Seconds 2	
	}
	
	stopProcess -uniqueName $uniqueName
})


$doneButton.Add_Click({
	$form.Close()
})
 $form.Topmost = $false
    
 $form.Add_Shown({$form.Activate()})
    

 $form.ShowDialog()
 
 $timer.Stop()
 $cancelTimer.Stop()