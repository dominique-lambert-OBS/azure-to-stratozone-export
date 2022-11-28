#Add performance data to the global array for specified VM

function CheckMetricValue{
	param
	(
		# VM 
		[Parameter(Mandatory = $true)]
		$metricValue
	)
		try{
				if($metricValue -gt 0){
					return $metricValue
				}
				return 0
		}
		catch{
			ModuleLogMessage "Error - CheckMetricValue - $_.Exception.Message" $log
			return 0
		}
}


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
		#$endTime = "10/31/2022 4:37:00 PM"
		#$startTime =  "10/30/2022 4:37:00 PM"
		
		$metricName = "Percentage CPU,Available Memory Bytes,Disk Read Operations/Sec,Disk Write Operations/Sec,Network Out Total,Network In Total"
		$vmMetric = Get-AzMetric -ResourceId $ids.rid -MetricName $metricName -EndTime $endTime -StartTime  $startTime -TimeGrain 0:30:00 -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
		ModuleLogMessage "Get-AzMetric -ResourceId $ids.rid -MetricName $metricName -EndTime $endTime -StartTime  $startTime -TimeGrain 0:30:00 -WarningAction SilentlyContinue -ErrorAction SilentlyContinue" $log

		$metricNameList = $vmMetric.Name.Value

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
		
		$MyMetricName0=$vmMetric[0].Name.Value
		$MyMetricName1=$vmMetric[1].Name.Value
		$MyMetricName2=$vmMetric[2].Name.Value
		$MyMetricName3=$vmMetric[3].Name.Value
		$MyMetricName4=$vmMetric[4].Name.Value
		$MyMetricName5=$vmMetric[5].Name.Value
		
		ModuleLogMessage "[0] Name.value : $MyMetricName0" $log
		ModuleLogMessage "[1] Name.value : $MyMetricName1" $log
		ModuleLogMessage "[2] Name.value : $MyMetricName2" $log
		ModuleLogMessage "[3] Name.value : $MyMetricName3" $log
		ModuleLogMessage "[4] Name.value : $MyMetricName4" $log
		ModuleLogMessage "[5] Name.value : $MyMetricName5" $log

		$perfDataCount = $vmMetric[0].Data.Count
		$MyMetricCount=$vmMetric.Count
		ModuleLogMessage "MyMetricCount : $MyMetricCount" $log

		$CpuUtilizationPercentageIndex = [array]::IndexOf($metricNameList,"Percentage CPU")
		$AvailableMemoryBytesIndex = [array]::IndexOf($metricNameList,"Available Memory Bytes")
		$DiskReadOperationsPerSecIndex = [array]::IndexOf($metricNameList,"Disk Read Operations/Sec")
		$DiskWriteOperationsPerSecIndex = [array]::IndexOf($metricNameList,"Disk Write Operations/Sec")
		$NetworkBytesPerSecOutIndex = [array]::IndexOf($metricNameList,"Network Out Total")
		$NetworkBytesPerSecInIndex = [array]::IndexOf($metricNameList,"Network In Total")

		$CpuUtilizationPercentageCount=$vmMetric[$CpuUtilizationPercentageIndex].Data.Count
		$AvailableMemoryBytesCount=$vmMetric[$AvailableMemoryBytesIndex].Data.Count
		$DiskReadOperationsPerSecCount=$vmMetric[$DiskReadOperationsPerSecIndex].Data.Count
		$DiskWriteOperationsPerSecCount=$vmMetric[$DiskWriteOperationsPerSecIndex].Data.Count
		$NetworkBytesPerSecOutCount=$vmMetric[$NetworkBytesPerSecOutIndex].Data.Count
		$NetworkBytesPerSecInCount=$vmMetric[$NetworkBytesPerSecInIndex].Data.Count

		ModuleLogMessage "MetricsCounts : $CpuUtilizationPercentageCount, $AvailableMemoryBytesCount, $DiskReadOperationsPerSecCount, $DiskWriteOperationsPerSecCount, $NetworkBytesPerSecOutCount, $NetworkBytesPerSecInCount" $log	

		if($vmMetric.Count -gt 5){
			for($i =0;$i -lt $perfDataCount; $i++){
				try{
					$CpuUtilizationPercentageValue=0
					if ($i -lt $CpuUtilizationPercentageCount) {$CpuUtilizationPercentageValue=[math]::Round($vmMetric[$CpuUtilizationPercentageIndex].Data[$i].Average,10)}
					$AvailableMemoryBytesValue=0
					if ($i -lt $AvailableMemoryBytesCount) {$AvailableMemoryBytesValue=CheckMetricValue([math]::ceiling($vmMetric[$AvailableMemoryBytesIndex].Data[$i].Average))}
					$DiskReadOperationsPerSecValue=0
					if ($i -lt $DiskReadOperationsPerSecCount) {$DiskReadOperationsPerSecValue=CheckMetricValue([math]::Round(([decimal]$vmMetric[$DiskReadOperationsPerSecIndex].Data[$i].Average),10))}
					$DiskWriteOperationsPerSecValue=0
					if ($i -lt $DiskWriteOperationsPerSecCount) {$DiskWriteOperationsPerSecValue=CheckMetricValue([math]::Round([decimal]$vmMetric[$DiskWriteOperationsPerSecIndex].Data[$i].Average,10))}
					$NetworkBytesPerSecOutValue=0
					if ($i -lt $NetworkBytesPerSecOutCount) {$NetworkBytesPerSecOutValue=CalculateNetworkDataPerSec([decimal]$vmMetric[$NetworkBytesPerSecOutIndex].Data[$i].Total)}
					$NetworkBytesPerSecInValue=0
					if ($i -lt $NetworkBytesPerSecInCount) {$NetworkBytesPerSecInValue=CalculateNetworkDataPerSec([decimal]$vmMetric[$NetworkBytesPerSecInIndex].Data[$i].Total)}
					$vmPerfMetrics = [pscustomobject]@{
						"MachineId"=$ids.vmID
						"TimeStamp"=$vmMetric[0].Data[$i].TimeStamp
						"CpuUtilizationPercentage" = $CpuUtilizationPercentageValue
						"AvailableMemoryBytes" = $AvailableMemoryBytesValue
						"DiskReadOperationsPerSec" = $DiskReadOperationsPerSecValue
						"DiskWriteOperationsPerSec" = $DiskWriteOperationsPerSecValue
						"NetworkBytesPerSecSent " = $NetworkBytesPerSecOutValue
						"NetworkBytesPerSecReceived" = $NetworkBytesPerSecInValue
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
		return [math]::Round((CheckMetricValue($NetworkTotal)) /1800,10)
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