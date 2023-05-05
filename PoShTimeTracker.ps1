Add-Type -AssemblyName PresentationFramework

function Start-Timer
{
    if ($script:timerRunning)
    {
        write-host Clicked, timer running
        $script:timer.Stop()
        $script:ElapsedTimeMins = [Math]::Floor($script:ElapsedTime.TotalMinutes).ToString()
        $hashTable = [ordered]@{
            Task = $script:TaskName
            StartTime = $script:StartTime
            ElapsedTimeMins = $script:ElapsedTimeMins
        }
        $tempObj = New-Object -TypeName PSCustomObject -Property $hashTable
        $script:array += $tempObj
        $script:DataGrid.ItemsSource=@($script:array)

        $script:array | Export-Csv -Path $script:CurrentTimerFullName -NoTypeInformation
    }
    else
    {
        write-host Clicked, timer not running
        $script:timerRunning = $true
    }

    $script:TaskName = $TaskNameTextBox.Text
    $script:TextCurrentTaskValue.Content = $TaskName
    $script:StartTime = Get-Date
    $script:TextStartTimeValue.Content = $StartTime.ToLongDateString() + " " + $StartTime.ToLongTimeString()
    $script:ElapsedTime = 0
    $script:timer = new-object System.Windows.Threading.DispatcherTimer
    #Timer will run every second
    $script:timer.Interval = [TimeSpan]'0:0:1.0'
    #And will invoke the $OnUpdateBlock          
    $script:timer.Add_Tick.Invoke($OnUpdateBlock)
    #Then start the timer            
    $script:timer.Start()
}

[xml]$XamlForm  = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Time Tracker" Height="412" Width="637">
    <Grid>
        <Grid.ColumnDefinitions>
            <ColumnDefinition/>
            <ColumnDefinition/>
        </Grid.ColumnDefinitions>
        <DataGrid Name="DataGrid" Grid.Column="1" HorizontalAlignment="Left" Height="364" Margin="10,10,0,0" VerticalAlignment="Top" Width="296"/>
        <TextBox Name="TaskNameTextBox" HorizontalAlignment="Left" Height="33" Margin="11,39,0,0" TextWrapping="Wrap" Text="Task Name" VerticalAlignment="Top" Width="295"/>
        <Label Content="Task Name" HorizontalAlignment="Left" Margin="11,13,0,0" VerticalAlignment="Top"/>
        <Button Name="StartButton" Content="Start" HorizontalAlignment="Left" Margin="114,77,0,0" VerticalAlignment="Top" Width="75"/>
        <Grid HorizontalAlignment="Left" Height="93" Margin="10,281,0,0" VerticalAlignment="Top" Width="296">
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

    </Grid>
</Window>
"@

$timerRunning = $false
$TimeTrackerFolder = "C:\Users\mastr\Desktop\TestTimer"

$CurrentMonth = Get-Date -Format yyyyMM
$CurrentTimerFileName = "TimeTracker-" + $CurrentMonth + ".csv"
$CurrentTimerFullName = Join-Path -Path $TimeTrackerFolder -ChildPath $CurrentTimerFileName





$XMLnodeReader = New-Object System.Xml.XmlNodeReader $XamlForm
#use the xaml reader to read the xaml file
$Window = [Windows.Markup.XamlReader]::Load( $XMLnodeReader )

#Controls
$TaskNameTextBox = $Window.FindName("TaskNameTextBox")
$start = $Window.FindName("StartButton")
$TextCurrentTaskValue = $Window.FindName("TextCurrentTaskValue")
$TextStartTimeValue = $Window.FindName("TextStartTimeValue")
$TextElapsedTimeValue = $Window.FindName("TextElapsedTimeValue")
$DataGrid = $Window.FindName("DataGrid")

if (Test-Path $CurrentTimerFullName)
{
    $array = import-csv $CurrentTimerFullName
    $script:DataGrid.ItemsSource=@($script:array)
}
else
{
    $array = @()
}

$OnUpdateBlock = ({
    $script:ElapsedTime = New-TimeSpan -Start $Script:StartTime -End (Get-Date)
    $script:ElapsedTimeString = [Math]::Floor($script:ElapsedTime.TotalMinutes).ToString() + " minutes, " + [Math]::Round($ElapsedTime.TotalSeconds,0).ToString() + " seconds"
    $script:TextElapsedTimeValue.Content = $script:ElapsedTimeString    
    if($seconds -eq 0) {  Close-Form  }
})


$TaskNameTextBox.Add_KeyDown({
    if ($_.Key -eq "Enter") 
    {
        Write-Host "Enter pressed"
        Start-Timer
    }
})

$Window.Add_Closing({
    Write-Host Closing
    $script:timer.Stop()
    $script:ElapsedTimeMins = [Math]::Floor($script:ElapsedTime.TotalMinutes).ToString()
    $hashTable = [ordered]@{
        Task = $script:TaskName
        StartTime = $script:StartTime
        ElapsedTimeMins = $script:ElapsedTimeMins
    }
    $tempObj = New-Object -TypeName PSCustomObject -Property $hashTable

    $script:array += $tempObj
    $script:DataGrid.ItemsSource=@($script:array)

    $script:array | Export-Csv -Path $script:CurrentTimerFullName -NoTypeInformation
})


#Add Click
$start.add_click({
    Start-Timer
})

#Start the window
$Window.Showdialog()