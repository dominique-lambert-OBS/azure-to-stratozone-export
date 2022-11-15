#Add performance data to the global array for specified VM

function SetPerformanceInfo{
	param
	(
		# VM 
		[Parameter(Mandatory = $true)]
		$ids,
		[Parameter(Mandatory = $true)]
		[string]$log
	)
	try{
		$vmPerfObjectList = @()
		$endTime = Get-Date
		$startTime = $endTime.AddDays(-30)
		
		$metricName = "Percentage CPU,Available Memory Bytes,Disk Read Operations/Sec,Disk Write Operations/Sec,Network Out Total,Network In Total"
		$vmMetric = Get-AzMetric -ResourceId $ids.rid -MetricName $metricName -EndTime $endTime -StartTime  $startTime -TimeGrain 0:30:00 -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
		
		#TODO

		if(-not $vmMetric){
			$vmPerfMetrics = [pscustomobject]@{
				"MachineId"=$ids.vmID
				"TimeStamp"=Get-Date -format "MM/dd/yyyy HH:mm:ss"
				"CpuUtilizationPercentage"=0
				"AvailableMemoryBytes"=0
				"DiskReadOperationsPerSec"=0
				"DiskWriteOperationsPerSec"=0
				"NetworkBytesPerSecSent"=0
				"NetworkBytesPerSecReceived"=0
				}
			$vmPerfObjectList += $vmPerfMetrics
			return $vmPerfObjectList
		}
		
		$perfDataCount = $vmMetric[0].Data.Count
		if($vmMetric.Count -gt 5){
			for($i =0;$i -lt $perfDataCount; $i++){
				try{
					$myCount0=$vmMetric[0].Data.Count
					$myCount1=$vmMetric[1].Data.Count
					$myCount2=$vmMetric[2].Data.Count
					$myCount3=$vmMetric[3].Data.Count
					$myCount4=$vmMetric[4].Data.Count
					$myCount5=$vmMetric[5].Data.Count
					#ModuleLogMessage "myCount : $myCount0, $myCount1, $myCount2, $myCount3, $myCount4, $myCount5" $log
			
					$meticValue2=0
					if ($i -lt $myCount2) {$meticValue2=[math]::Round(([decimal]$vmMetric[2].Data[$i].Average),10)}
					$meticValue3=0
					#if ($i -lt $myCount3) {$meticValue3=[math]::Round([decimal]$vmMetric[3].Data[$i].Average,10)}
					$meticValue4=0
					#if ($i -lt $myCount4) {$meticValue4=CalculateNetworkDataPerSec([decimal]$vmMetric[4].Data[$i].Total)}
					$meticValue5=0
					#if ($i -lt $myCount5) {CalculateNetworkDataPerSec([decimal]$vmMetric[5].Data[$i].Total)}

					$vmPerfMetrics = [pscustomobject]@{
						"MachineId"=$ids.vmID
						"TimeStamp"=$vmMetric[0].Data[$i].TimeStamp
						"CpuUtilizationPercentage"=[math]::Round($vmMetric[0].Data[$i].Average,10)
						"AvailableMemoryBytes"=[math]::ceiling($vmMetric[1].Data[$i].Average)
						#"DiskReadOperationsPerSec"=[math]::Round(([decimal]$vmMetric[2].Data[$i].Average),10)
						"DiskReadOperationsPerSec"=$meticValue2
						#"DiskWriteOperationsPerSec"=[math]::Round([decimal]$vmMetric[3].Data[$i].Average,10)
						"DiskWriteOperationsPerSec"=$meticValue3
						#"NetworkBytesPerSecSent"=CalculateNetworkDataPerSec([decimal]$vmMetric[4].Data[$i].Total)
						"NetworkBytesPerSecSent"=$meticValue4
						#"NetworkBytesPerSecReceived"=CalculateNetworkDataPerSec([decimal]$vmMetric[5].Data[$i].Total)
						"NetworkBytesPerSecReceived"=$meticValue5
					}
					$vmPerfObjectList += $vmPerfMetrics
				}
				catch{
					ModuleLogMessage "Error - module - vmid:$ids.vmID - $_.Exception.Message" $log
				}
			}
			return $vmPerfObjectList
		}
	}
	catch{
		ModuleLogMessage "Error - module - collection performance for vmID: $ids.vmID. $_" $log
	}
}


# Divide the network data by the time period used in the query
function CalculateNetworkDataPerSec($NetworkTotal){
	try{
		return [math]::Round($NetworkTotal /1800,10)
	}
	catch{
		return 0
	}
}

#write data to log file
function ModuleLogMessage
{
    param(
		[Parameter(Mandatory = $true)]
		[string]$Message,
		[Parameter(Mandatory = $true)]
		[string]$log
	)
	
	try{
    	Add-content $log -value ((Get-Date).ToString() + " - " + $Message)
	}
	catch{
		Write-Host "Unable to Write to log file. $_"
	}
}


Export-ModuleMember -Function SetPerformanceInfo, ModuleLogMessage