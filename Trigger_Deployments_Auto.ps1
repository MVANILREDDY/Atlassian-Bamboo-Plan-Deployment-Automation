function Deployment-Trigger
{
param(
[string]$project_name,
[string]$deploymentname,
[string]$rel_version,
[string]$env_name
)
$username='devops'
$upassword='Devps'
$auth = $username + ':' + $upassword
$Encoded = [System.Text.Encoding]::UTF8.GetBytes($auth)
$authorizationInfo = [System.Convert]::ToBase64String($Encoded)
$headers = @{"Authorization"="Basic $($authorizationInfo)"}

          $url_project_id='http://localhost:8085/rest/api/latest/search/projects.json?'+$project_name

$response_project=Invoke-RestMethod -Uri   $url_project_id       -Method GET -Headers $headers
foreach ($project_id in  $response_project.searchResults.searchEntity )
{
	if ( $project_id.projectName -eq   $project_name )
	{
		$project_key=$project_id.key
		Write-Host "project key  "$project_key" found for given project "$project_name
		break 
	}
}
$url_plans='http://localhost:8085/rest/api/latest/project/'+$project_key+'.json?expand=plans'
$url_plan_response=Invoke-RestMethod -Uri   $url_plans        -Method GET -Headers $headers
foreach ($plan in $url_plan_response.plans.plan)
	{
		$url_dep_id='http://localhost:8085/rest/api/latest/deploy/project/forPlan?planKey='+$plan.planKey.key
	$plan_responses=Invoke-RestMethod -Uri  $url_dep_id        -Method GET -Headers $headers
	if ($plan_responses)
	{foreach ($plan_response in $plan_responses)
		{
		 if ( $plan_response.name -eq   $deploymentname )
		 {
			 Write-Host "Deployment-id "$plan_response.id"  found for given deployment "$plan_response.name
		$dep_ver_details_url='http://localhost:8085/rest/api/latest/deploy/dashboard/'+$plan_response.id+'?max-results=10000'
			break 
		}
		}
	$dep_result=Invoke-RestMethod -Uri $dep_ver_details_url   -Method GET -Headers $headers
		Start-Sleep -s 1
		 foreach ($dep_ver_details in $dep_result.environmentStatuses)
		 {
			 if ( $dep_ver_details.deploymentResult.deploymentVersion.name -eq   $rel_version )
				{
					$rel_versionid=$dep_ver_details.deploymentResult.deploymentVersion.id 
					Write-Host "version id"$rel_versionid  " found for given project "$project_name
					break 
				}
		 }
		 foreach ($dep_env_details in $dep_result.environmentStatuses)
		 {
			 if ( $dep_env_details.environment.name -eq   $env_name )
				{
					$environmentid=$dep_env_details.environment.id
					Write-Host "environmentid id "$environmentid  " found for given project "$project_name
					break 
				}
		 }
		
	}

	}
	
	$url_dep = @{ 
	Uri='http://localhost:8085/rest/api/latest/queue/deployment/?environmentId='+$environmentid+'&versionId='+$rel_versionid 
	}
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
Write-Host $url_dep.Uri
$Response=Invoke-RestMethod    @url_dep -Method POST  -Headers $headers -ContentType "application/json"
$Response=Invoke-RestMethod -Uri $v_url     -Method POST  -Headers $headers -ContentType "application/json"

Write-Host  " CHECKING statsus  s s"
$queue_result=$response.link.href
$Queue_response=Invoke-RestMethod -Uri   $queue_result        -Method GET -Headers $headers

Do {
	Write-Host $Queue_response.lifeCycleState
	Start-Sleep -s 10
	$Queue_response=Invoke-RestMethod -Uri   $queue_result        -Method GET -Headers $headers
}
while ($Queue_response.lifeCycleState -ne "FINISHED")
	$rel_time=$Queue_response.finishedDate
	$rel_time=$rel_time/1000
	$rel_time=[int]$rel_time
	$dep_date=(Get-Date 01.01.1970)+([System.TimeSpan]::fromseconds($rel_time))
Write-Host  $deploymentname " FINISHED "
Write-Host  $deploymentname  "status is" $Queue_response.deploymentState " and completed at " $dep_date
}
Deployment-Trigger  -project_name  Firstproject  -deploymentname Shellscriptfirst    -env_name QA   -rel_version release-5


