using namespace System.Net

function Invoke-ListFunctionParameters {
    # Input bindings are passed in via param block.
    param($Request, $TriggerMetadata)

    $APIName = $TriggerMetadata.FunctionName
    Write-LogMessage -user $request.headers.'x-ms-client-principal' -API $APINAME -message 'Accessed this API' -Sev 'Debug'

    # Write to the Azure Functions log stream.
    Write-Information 'PowerShell HTTP trigger function processed a request.'

    # Interact with query parameters or the body of the request.
    $Module = $Request.Query.Module
    $Function = $Request.Query.Function

    $CommandQuery = @{}
    if ($Module) {
        $CommandQuery.Module = $Module
    }
    if ($Function) {
        $CommandQuery.Name = $Function
    }

    $CommonParameters = @('Verbose', 'Debug', 'ErrorAction', 'WarningAction', 'InformationAction', 'ErrorVariable', 'WarningVariable', 'InformationVariable', 'OutVariable', 'OutBuffer', 'PipelineVariable', 'TenantFilter', 'APIName', 'ExecutingUser')
    #temporary until I clean up the coremodule and move things private.
    $TemporaryBlacklist = 'Get-CIPPAuthentication', 'Invoke-CippWebhookProcessing', 'Invoke-ListFunctionParameters', 'New-CIPPAPIConfig', 'New-CIPPGraphSubscription.ps1'
    try {
        $Functions = Get-Command @CommandQuery
        $Results = foreach ($Function in $Functions) {
            if ($Function -In $TemporaryBlacklist) { continue }
            $Parameters = foreach ($Key in $Function.Parameters.Keys) {
                if ($CommonParameters -notcontains $Key) {
                    $Param = $Function.Parameters.$Key
                    [PSCustomObject]@{
                        Name = $Key
                        Type = $Param.ParameterType.FullName
                    }
                }
            }
            [PSCustomObject]@{
                Function   = $Function.Name
                Parameters = @($Parameters)
            }
        }
        $StatusCode = [HttpStatusCode]::OK
        $Results
    }
    catch {
        $Results = "Function Error: $($_.Exception.Message)"
        $StatusCode = [HttpStatusCode]::BadRequest
    }
    # Associate values to output bindings by calling 'Push-OutputBinding'.
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = $StatusCode
            Body       = @($Results)
        })

}