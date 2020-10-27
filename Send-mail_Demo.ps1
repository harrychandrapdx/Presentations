$emailcred = ""
$smtp = ""

$failed = Get-SqlAgentJobHistory -ServerInstance sql2019-01 -Since Midnight -OutcomesType Failed | where StepName -ne "(Job outcome)" 


if($failed){
    $Subject = $failed.JobName + " has failed!"
    $Body = $failed.JobName + " failed at " + $failed.RunDate + " with the following error message: "  
    
} else {
    $Subject = "No Jobs Failure Found!" 
    $Body  = "No failed jobs!"
}

Send-MailMessage -To $To -From $From -Subject $Subject -Body $Body -SmtpServer $smtp -Credential $emailcred
