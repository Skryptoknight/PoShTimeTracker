Add-Type -AssemblyName PresentationFramework

# The folder where the files will be created
$TimeTrackerFolder = $env:TEMP


function Start-Timer
{
    if ($script:timerRunning)
    {
        Stop-Timer
    }
    else
    {
        write-host Clicked, timer not running
        $script:timerRunning = $true
    }

    $script:TaskName = $TaskNameTextBox.Text
    $script:TextCurrentTaskValue.Content = $TaskName
    $script:StartTime = Get-Date
    $script:TextStartTimeValue.Content = $StartButtonTime.ToLongDateString() + " " + $StartButtonTime.ToLongTimeString()
    $script:ElapsedTime = 0
    $script:timer = new-object System.Windows.Threading.DispatcherTimer
    #Timer will run every second
    $script:timer.Interval = [TimeSpan]'0:0:1.0'
    #And will invoke the $OnUpdateBlock          
    $script:timer.Add_Tick.Invoke($OnUpdateBlock)
    #Then start the timer            
    $script:timer.Start()
}

function Stop-Timer
{
    #write-host Clicked, timer running
    if ($script:timerRunning)
    {
        $script:timer.Stop()
        $script:timerRunning = $false
        $script:ElapsedTimeMins = [Math]::Floor($script:ElapsedTime.TotalMinutes).ToString()
        $hashTable = [ordered]@{
            Task = $script:TaskName
            StartDate = $script:StartTime
            EndDate = Get-Date
            ElapsedTimeMins = $script:ElapsedTimeMins
            Comments = ""
        }
        $tempObj = New-Object -TypeName PSCustomObject -Property $hashTable
        $script:array += $tempObj
        $script:DataGrid.ItemsSource=@($script:array)

        $script:array | Export-Csv -Path $script:CurrentTimerFullName -NoTypeInformation
    }
}

function Hide-PSWindow
{
    #Based on https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/add-type?view=powershell-7.3

    # Setup C# signature of the ShowWindowAsync function.
    $Signature = '[DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);'

    # Add the ShowWindowAsync function to the PowerShell session as a static method
    $ShowWindowAsync = Add-Type -MemberDefinition $Signature -name NativeMethods -namespace Win32

    #Get Current PowerShell window
    $hWnd = @(Get-Process -Id $PID)[0].MainWindowHandle
    
    # Hide window
    [Win32.NativeMethods]::ShowWindowAsync($hwnd, 0)
}


#The WPF XAML
[xml]$XamlForm  = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    Title="Time Tracker" Height="230" Width="637" MinHeight="230" MinWidth="340" Topmost="True">
    <Grid>
        <Grid.ColumnDefinitions>
            <ColumnDefinition MinWidth="320" MaxWidth="320"/>
            <ColumnDefinition/>
        </Grid.ColumnDefinitions>   
        <DataGrid Name="DataGrid" Grid.Column="1" Margin="10,10,10,10"/>
        <TextBox Name="TaskNameTextBox" HorizontalAlignment="Left" Height="21" Margin="11,39,0,0" TextWrapping="Wrap" Text="Task Name" VerticalAlignment="Top" Width="295"/>
        <Label Content="Task Name" HorizontalAlignment="Left" Margin="11,13,0,0" VerticalAlignment="Top"/>
        <Button Name="StartButton" Content="▶" HorizontalAlignment="Left" Margin="119,65,0,0" VerticalAlignment="Top" Width="26"/>
        <Grid HorizontalAlignment="Left" Height="93" Margin="10,100,0,0" VerticalAlignment="Top" Width="296">
            <Grid.RowDefinitions>
                <RowDefinition/>
                <RowDefinition/>
                <RowDefinition/>
            </Grid.RowDefinitions>
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="119*"/>
                <ColumnDefinition Width="177*"/>
            </Grid.ColumnDefinitions>
            <Label Content="Current Task:" HorizontalAlignment="Center" VerticalAlignment="Center" Height="31" Width="148" Grid.ColumnSpan="2" Margin="-1,0,149,0"/>
            <Label Content="Start Time:" HorizontalAlignment="Left" VerticalAlignment="Top" Height="31" Width="148" Grid.Row="1" Grid.ColumnSpan="2"/>
            <Label Content="Elapsed Time:" HorizontalAlignment="Left" VerticalAlignment="Top" Height="31" Width="148" Grid.Row="2" Grid.ColumnSpan="2"/>
            <Label Name="TextCurrentTaskValue" Content="" HorizontalAlignment="Left" VerticalAlignment="Top" Height="31" Width="177" Grid.Column="1"/>
            <Label Name="TextStartTimeValue" Content="" HorizontalAlignment="Left" VerticalAlignment="Top" Height="31" Width="177" Grid.Column="1" Grid.Row="1"/>
            <Label Name="TextElapsedTimeValue" Content="" HorizontalAlignment="Left" VerticalAlignment="Top" Height="31" Width="177" Grid.Column="1" Grid.Row="2"/>
        </Grid>
        <Button Name="StopButton" Content="■" HorizontalAlignment="Left" Margin="166,65,0,0" VerticalAlignment="Top" Width="26" Foreground="Red"/>
        <CheckBox Name="AlwaysOnTopCheckBox" Content="Always On Top" HorizontalAlignment="Left" Margin="216,10,0,0" VerticalAlignment="Top"/>

    </Grid>
</Window>

"@

$timerRunning = $false

$CurrentMonth = Get-Date -Format yyyyMMdd
$CurrentTimerFileName = "TimeTracker-" + $CurrentMonth + ".csv"
$CurrentTimerFullName = Join-Path -Path $TimeTrackerFolder -ChildPath $CurrentTimerFileName


$XMLnodeReader = New-Object System.Xml.XmlNodeReader $XamlForm
#use the xaml reader to read the xaml file
$Window = [Windows.Markup.XamlReader]::Load( $XMLnodeReader )

#Controls
$TaskNameTextBox = $Window.FindName("TaskNameTextBox")
$StartButton = $Window.FindName("StartButton")
$StopButton = $Window.FindName("StopButton")
$TextCurrentTaskValue = $Window.FindName("TextCurrentTaskValue")
$AlwaysOnTopCheckBox = $Window.FindName("AlwaysOnTopCheckBox")
$TextStartTimeValue = $Window.FindName("TextStartTimeValue")
$TextElapsedTimeValue = $Window.FindName("TextElapsedTimeValue")
$DataGrid = $Window.FindName("DataGrid")

#Import previous data if it exists
if (Test-Path $CurrentTimerFullName)
{
    $array = @(import-csv $CurrentTimerFullName)
    $script:DataGrid.ItemsSource=@($script:array)
}
else
{
    $array = @()
}

#On Update Block
$OnUpdateBlock = ({
    $script:ElapsedTime = New-TimeSpan -Start $Script:StartTime -End (Get-Date)
    $script:ElapsedTimeString = [Math]::Floor($script:ElapsedTime.TotalMinutes).ToString() + " minutes, " + [Math]::Round($ElapsedTime.TotalSeconds,0).ToString() + " seconds"
    $script:TextElapsedTimeValue.Content = $script:ElapsedTimeString    
    if($seconds -eq 0) {  Close-Form  }
})


#Start timer if enter is pressed in text box
$TaskNameTextBox.Add_KeyDown({
    if ($_.Key -eq "Enter") 
    {
        Write-Host "Enter pressed"
        Start-Timer
    }
})

#Run this code when closing window
$Window.Add_Closing({
    Write-Host Closing
    Stop-Timer
})


#StartButton Click Event
$StartButton.add_click({
    Start-Timer
})

#StopButton Click Event
$StopButton.add_click({
    if ($script:timerRunning)
    {
        Stop-Timer
    }
})

#AlwaysOnTopCheckBox Click Event
$AlwaysOnTopCheckBox.add_click({
    if ($AlwaysOnTopCheckBox.IsChecked)
    {
        $Window.Topmost = $true
    }
    else 
    {
        $Window.Topmost = $false
    }
    
})

<# Hiding of the window disabled as it could potentially cause powershell processes stuck in the background.

$PsProcess = Get-WmiObject Win32_Process -Filter "processID = '$PID'"
$ParentPsProcess = Get-WmiObject Win32_Process -Filter "processID = '$($PsProcess.ParentProcessId)'"

if ($ParentPsProcess.ProcessName -notlike "*code*" -and $PsProcess.ProcessName -notlike "*powershell_ise*")
{
    Hide-PSWindow
}

#>


#Start the window
$Window.Showdialog()